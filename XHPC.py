#!/usr/bin/python
# coding=utf-8

import requests 
from bs4 import BeautifulSoup

def get_html(url):
    """get the content of the url"""
    response = requests.get(url)
    response.encoding = 'utf-8'
    return response.text
def get_certain_joke(html):
	"""get the joke of the html"""
	soup = BeautifulSoup(html,'lxml')
	joke_content = soup.select('div.content')[1].get_text()
	return joke_content 
def create_report(joke_content):    
    filePath = 'D:\\'  
    file_name = filePath  + '111111.txt'   
    f = open(file_name,'a')    
    f.write(joke_content+'\n')
url_joke = "https://www.qiushibaike.com"
html = get_html(url_joke)
joke_content = get_certain_joke(html)
ss_aaa = create_report(joke_content)
print (ss_aaa)





