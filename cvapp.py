# import all the required stuff
import os
from os.path import join, dirname
from dotenv import load_dotenv
from flask import Flask
from flask import request
from flask_bower import Bower
from controllers import *

# create a Flask application
app = Flask(__name__)
app.secret_key = 'santidaviddavidejonas'

# inject bower (for front-end resource management)
Bower(app)

@app.route('/')
def home_page():
    return show_homepage() 

@app.route('/about')
def about():
    return show_about() 

@app.route('/allocate',methods=['POST','GET'])
def allocate():
    if request.method == 'POST':
        return show_allocated_portfolio(request.form)
    elif request.method == 'GET':
        return show_allocation_form()
    else:
        return 404

