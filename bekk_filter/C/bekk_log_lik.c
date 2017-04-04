#include <R.h>
#include <math.h>
#include "utilities.c"

void scalar_bekk_filter(double *_s, double *_eps, double *ll, double *p, double *_y, int *T, int *N, int *K){

  int t,i,j,n,k;
  double logden, alpha, beta, lambda;
  double ***S, **C, **y, **eps;
  double *work1, **work2;

  *ll = 0;

  lambda  = p[0];
  alpha   = (1-lambda) * p[1];
  beta    = (1-lambda) * (1 - p[1]);

  S     = create_real_array3d(*T,*N,*N);
  C     = create_real_matrix(*N,*N);
  y     = create_and_copy_real_matrix(*T,*N,_y);
  eps   = create_and_copy_real_matrix(*T,*N,_eps);
  work1 = create_real_vector(*N);
  work2 = create_real_matrix(*N,*N);

  // init
  for( i=0; i<*N; ++i) {
    for( j=0; j<=i; ++j ) {
      work2[i][j]=0;
      for( t=0; t<*T; ++t ){ work2[i][j] += y[t][i]*y[t][j]; }
      work2[i][j] /= *T;
      work2[j][i] = work2[i][j];
    }
  }
  chol(S[0],work2,*N);
  chol(C,work2,*N);

  // iterate through all points in the time-series
  for( t=1; t<*T; ++t ){

    // iterate through the k lags
    for( k=1; k<=*K; ++k){

      // check if kth lag actually exists
      if( t >= k ) {

        // create the current sigma from lagged sigma + yy through cholesky update
        chol_up(S[t], S[t-k], y[t-k], *N, beta / k, alpha / k, work1);    
      }

      // sequential choletzky update (sigma + C)
      for( n=0; n<*N; ++n ){
        chol_up(S[t], S[t], C[n], *N, 1, lambda, work1);    
      }

    }

    fwdinv(work2,S[t],*N);
    matvec(eps[t],work2,y[t],*N);
    logden = -0.5*(*N)*log(2*PI);
    for(i=0;i<*N;++i) logden += -log( S[t][i][i] )-0.5*eps[t][i]*eps[t][i];

    // accumulate log likelihood
    *ll += logden;
  }

  // copy results
  real_array3d_copy(S,*T,*N,*N,_s);
  real_matrix_copy(eps,*T,*N,_eps);

  // cleanup
  destroy_real_array3d(S,*T,*N,*N);
  destroy_real_matrix(C,*N,*N);
  destroy_real_matrix(y,*T,*N);
  destroy_real_matrix(eps,*T,*N);
  destroy_real_vector(work1,*N);
  destroy_real_matrix(work2,*N,*N);

}


/*   Rprintf("\n------------------------------\n"); */
/*   for(i=0;i<*N;++i){ */
/*     for(j=0;j<*N;++j){ */
/*       Rprintf("|%f|",S[t][i][j]); */
/*     } */
/*     Rprintf("\n------------------------------\n"); */
/*   } */
