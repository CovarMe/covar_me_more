# scalar.bekk
scalar.bekk.filter <- function(y,param,k){
  T <- nrow(y)
  N <- ncol(y)
  result <- .C('scalar_bekk_filter', 
               S    = as.double(rep(0,T*N*N)), 
               eps  = as.double(rep(0,T*N)),
               ll   = as.double(0),
               P    = as.double(param),
               Y    = as.double(y),
               T    = as.integer(T), 
               N    = as.integer(N),
               K    = as.integer(k))
  filter <- list( Sig=result$S , eps=result$eps , loglik=result$ll )
  return(filter)
}

scalar.bekk.fit <- function(y,opts){
  if( is.null(opts$lags) ) { lags <- 1 } else { lags <- opts$lags }
  if( is.null(opts$optim.lib) ) { optim.lib <- "optim" } else { optim.lib <- opts$optim.lib }
  if( is.null(opts$param) ) { param.init <- c( 0.9, 0.5 ) } else { param.init <- opts$param.init }
  if( is.null(opts$fit) ){ fit <- TRUE } else { fit <- as.logical( opts$fit ) }
  obj   <- function(x,k){ return( -scalar.bekk.filter(y,x,k)$loglik ) }  
  if( fit==TRUE ){ 
    if( optim.lib=="nlminb" ){
      res <- nlminb( param.init, obj, lower=0, upper=1, k=lags )
    } else if( optim.lib=="optim" ) {
      res <- optim( param.init, obj, k=lags)
    }
    param.est <- res$par
  } else {
    param.est <- param.init 
  }

  filter <- scalar.bekk.filter( y, param.est, k=lags )

  Sig.C  <- array( filter$S , dim=c(nrow(y),ncol(y),ncol(y)) )
  Sig    <- array( 0 , dim=c(nrow(y),ncol(y),ncol(y)) )
  for( t in 1:nrow(y) ) Sig[t,,] = Sig.C[t,,] %*% t(Sig.C[t,,])
  Sig    <- list( Sig=Sig )
  eps    <- data.frame( eps=matrix( filter$eps , nrow(y) , ncol(y) ) )


  # extract and reconstruct parameters
  param.est           <- c((1-param.est[1]) * param.est[2],
                           (1-param.est[1]) * (1-param.est[2]))
  param.est           <- as.array(param.est)
  dimnames(param.est) <- list( c('alpha','beta') )

  list(param = param.est, 
       fit   = Sig, 
       resid = eps,
       obj   = filter$loglik)
}
