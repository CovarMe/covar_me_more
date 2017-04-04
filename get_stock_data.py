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

stocks = list()
for ticker in source: 
    print(ticker)
    try: 
        ticker_info = Share(ticker).get_historical(from_date,today)
        stocks += [x['Symbol']+','+x['Date']+','+x['Close'] for x in ticker_info] 
    except: 
        print("Couldn't retrieve info for " + ticker + " from Yahoo.")
        continue

my_df = pd.DataFrame(stocks)
my_df.to_csv('stock_data.csv', index=False, header=False)
