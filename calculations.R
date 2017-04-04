

##############################################################################################
################################ Library #####################################################
##############################################################################################

### Create all possible states

## Use Bekk function from C - Jonas/Nandan source code
dyn.load('./C/bekk_log_lik.so')
source('./R/bekk_model.R')

create_states_returns <- function(t,covariance, d , u, p1, p2, beta_0, beta_1, beta_2, PC1_2){
  init <- list(NULL, c(PC1_2[dim(PC1_2)[1],1 ], PC1_2[dim(PC1_2)[1],2]))
  returns <- NULL
  for(i in 1:t){
    
    for(j in 2:length(init)){
      init2 <- list()
      return_up_up <- beta_0 + beta_1*(init[[j]][1] + u[1]) + beta_2*(init[[j]][2] + u[2])
      return_up_down <- beta_0 + beta_1*(init[[j]][1] + u[1]) + beta_2*(init[[j]][2] + d[2])
      return_down_up <- beta_0 + beta_1*(init[[j]][1] + d[1]) + beta_2*(init[[j]][2] + u[2])
      return_down_down <- beta_0 + beta_1*(init[[j]][1] + d[1]) + beta_2*(init[[j]][2] + d[2])
      returns <- cbind(returns , return_up_up, return_up_down, return_down_up, return_down_down) 
      init2 <- list(init2, c(init[[j]][1] + u[1], init[[j]][2] + u[2]), 
                    c(init[[j]][1] + u[1], init[[j]][2] + d[2]), 
                    c(init[[j]][1] + d[1], init[[j]][2] + u[2]), 
                    c(init[[j]][1] + d[1], init[[j]][2] + d[2]))}
    init <- init2
  }
  returns
}



### Find the best weight allocation for one period problem

optimize_portfolio <- function(ret, covariance,risk_free, alpha){
  lambda <- sqrt(t(ret - rep(risk_free, length(ret)))%*%solve(covariance)%*%
                   (ret - rep(risk_free, length(ret)))/alpha)
  lambda <- as.numeric(lambda)
  weights <- t(ret - rep(risk_free, length(ret)))%*%solve(covariance)/lambda
  weights
}

### Run a DP Algorithm using selected stocks



DP_function <- function(disc_returns, covariances, t, risk_free, prob){
  if(t == 1){
    expected_ret <- prob[1]*prob[2]*disc_returns[,1] + prob[1]*(1-prob[2])*disc_returns[,2] + 
      (1 - prob[1])*prob[2]*disc_returns[,3] + (1-prob[1])*(1-prob[2])*disc_returns[,4]
    weights <-  optimize_portfolio(expected_ret, covariances[[1]], risk_free )
    t(as.matrix(weights))
  } else{
    seq <- c(0,4**c(1:t))
    vec1 <- (seq[length(seq) - 1] + 1):dim(disc_returns)[2]
    vec2 <- (seq[length(seq) - 2] + 1):(seq[length(seq) - 1])
    rt <- disc_returns[,vec1]
    covar <- covariances[vec1]
    weights <- matrix(NA, nrow=dim(disc_returns)[1], ncol=length(vec2))
    k <- 1
    for(i in 1:length(vec2)){
      expected_ret <- prob[1]*prob[2]*rt[,k] + prob[1]*(1-prob[2])*rt[,k+1] + 
        (1 - prob[1])*prob[2]*rt[,k+2] + (1-prob[1])*(1-prob[2])*rt[,k+3]
      weights[,i] <-  optimize_portfolio(expected_ret, covar[[k]], risk_free )
      k <- k + 4
    }
    ww <- cbind(weights, do.call("DP_function", 
                                 list(disc_returns[,-vec1]*(1 + risk_free),covariances[-vec1], t-1, risk_free, prob )))
    ww
  }
}




## Pass final file as data, pass t, pass columns of interest (from 2 to 78)
## Columns: 2:79 -> all columns: pass a vector

data <- final
function_make_everything_work<-function(final,t, columns = c(1:78), 
                                        static_cov = T, risk_free = 0.5/90, alpha){


## Compute the covariance matrix using 2 factors
pmatrix <- final #[,-c(1, dim(final)[2])]
pmatrix <- apply(pmatrix, c(1,2), as.numeric)
pmatrix_s <- scale(pmatrix)
princ <- prcomp(pmatrix_s)
PC1_2 <- predict(princ, newdata=pmatrix_s)[, 1:2]
  
## Select the relevant columns
final <- final[,c(1,columns, dim(final)[2])]


## Wolf - Ledoit covariance matrix

beta_0 <- beta_1 <- beta_2 <- res_var <- rep(NA, dim(pmatrix)[2])

for(i in 1:dim(pmatrix)[2]){
  reg <- lm(pmatrix[,i] ~ PC1_2)
  beta_0[i] <- coef(reg)[1]
  beta_1[i] <- coef(reg)[2]
  beta_2[i] <- coef(reg)[3]
  res <- pmatrix[,i]  - predict(reg)
  res_var[i] <- var(res)
}

F_matrix <- var(PC1_2[,1])*beta_1%*%t(beta_1) + var(PC1_2[,2])*beta_2%*%t(beta_2) + diag(res_var) 
Cov_matrix <- cov(pmatrix)

Full_cov <- 0.7*F_matrix + 0.3*Cov_matrix



## Compute the empirical probabilities of going up and down

prob <- apply(PC1_2, 2, function(x)(sum(x > 0)))
prob <- prob/dim(PC1_2)[1]
u <- apply(PC1_2, 2, function(x)(mean(x[x > 0])))
d <- apply(PC1_2, 2, function(x)(mean(x[x < 0])))

z <- 4**c(1:t)
## Constant covariances
if(static_cov){
  covariances <- list(Full_cov)[rep(1, sum(z))]
} else { 
 pp <- scalar.bekk.fit(as.matrix(final[-c(1, dim(final)[2])]),opts=list(fit = TRUE,
                                                                     lags = 3))
                       param <- pp$param
 ## Bekk Formula
 cov1 <- (1 - sum(param))*Full_cov + param[1]*t(pmatrix_s)%*%diag(seq(1:dim(final)[1]))%*%pmatrix_s + 
         param[2]*cov(pmatrix)
 covariances <- list(Full_cov)[rep(1, sum(z))]
}


disc_returns <- create_states_returns(t,Full_cov, d , u, prob[1], prob[2], beta_0=beta_0, beta_1 = beta_1, beta_2 = beta_2, PC1_2 = PC1_2)
cc <- DP_function(disc_returns , covariances, t - 1, risk_free, prob )

## returns the weights to be selected today
cc[,dim(cc)[2]]
}
