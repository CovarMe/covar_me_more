dyn.load('./C/bekk_log_lik.so')
source('./R/bekk_model.R')

y <- read.csv('../ganter/data/Problemsets Data (Tickers)/all.csv')
y <- apply(y,c(2),diff)
y[is.na(y)] <- 0

# scalar.bekk.filter(as.matrix(y[1:10,2:4]),c(0.9,0.5),k=1)
fit <- scalar.bekk.fit(as.matrix(y[,2:4]),opts=list(fit = TRUE,
                                                    lags = 5))
print(fit$param)
print(fit$obj)
