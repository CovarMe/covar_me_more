# this file contains all controller functions that are called on the different
# routes in cvapp

import string, os, rpy2
import pandas as pd
import pandas.rpy.common as com
import rpy2.robjects as ro
from flask import render_template, flash

tickers = pd.read_csv('stock_data.csv').columns

if os.environ.get('PRESENTATION') != None:
    with open(os.environ.get('PRESENTATION')) as f:
        rmdhtml = f.read().decode('utf-8')

def show_homepage():
    return render_template('index.html')

def show_allocation_form():
    return render_template('allocate.html',
                           tickers=tickers)

def show_allocated_portfolio(form):
    # time_horizon = form['horizon']
    # selected_tickers = form['ticker_selection'].split(',')
    time_horizon = 10
    selected_tickers = ['MMM','AME','ABC','AES','AFL','ALK']
    data = pd.read_csv('stock_data.csv').set_index('Date').sort_index().diff()[1:]
    ro.globalenv['data'] = com.convert_to_r_matrix(data[selected_tickers[:-1]])
    ro.globalenv['time_horizon'] = com.convert_to_r_matrix(data)
    ro.r('source("calculations.R")')
    ro.r('print(data)')
    result = ro.r('function_make_everything_work(data,time_horizon)')
    return render_template('allocated.html',
                           result=np.array(result))
