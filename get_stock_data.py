import pandas as pd
import numpy as np
import time
from datetime import datetime, timedelta
from yahoo_finance import Share

# extract the symbol code of the sp500
sp500 = pd.read_csv('SP500.csv')
source = sp500["Symbol"]

today = datetime.strptime(time.strftime("%Y/%m/%d"), "%Y/%m/%d") #string to date
from_date = today - timedelta(days=30) # date - days

today = today.strftime("%Y-%m-%d")
from_date = from_date.strftime("%Y-%m-%d")

print(from_date,today)

ticker_info = Share(source[0]).get_historical(from_date,today)
stock = [(x['Date'],x['Close']) for x in ticker_info] 
stocks = pd.DataFrame(stock,columns=['Date',source[0]]).set_index('Date')
for ticker in source[1:40]: 
    ticker_info = Share(ticker).get_historical(from_date,today)
    stock = [(x['Date'],x['Close']) for x in ticker_info] 
    stock = pd.DataFrame(stock,columns=['Date',ticker]).set_index('Date')
    stocks = pd.concat([stocks,stock], axis=1)
    print(stocks)

stocks.to_csv('stock_data.csv')
