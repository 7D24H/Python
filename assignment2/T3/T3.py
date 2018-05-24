#-*- coding:utf-8 -*-

import requests
import zipfile
import pandas as pd

class Solution():
    def solve(self):
        movieName = '' # movieName = 'Lithuania'

        #url = 'https://www.imf.org/external/pubs/ft/wp/2008/Data/wp08266.zip'

        #r = requests.get(url)  # 使用requests获取WinRAR zip并放到外面一层目录了
        #with open("T3.zip", "wb") as code:
         #   code.write(r.content)

        #azip = zipfile.ZipFile('T3.zip')
        #azip.extractall()

        reader = pd.read_stata('Financial Reform Dataset Dec 2008.dta')
        tranReader = reader[reader.Transition==1]   #这里要做个筛选
        group = tranReader.groupby('country')['finreform_n']

        maxList = []    #放各国的最大值
        countryList = []

        #item是tuple ,item[0]是string ，item[1]是series , item[1].values是ndarray
        for item in group:
            #innerList = []  #每个国家自己一年和前年差值的列表
            #for i in range(1,len(item[1].values)):
            #    temp = item[1].values[i] - item[1].values[i-1]
            #    innerList.append(temp)
            s = item[1].values
            maxList.append(max([s[i + 1] - s[i] for i in range(len(s) - 1)])) #一句话替代上面的 牛逼
            countryList.append(item[0])

        movieName = countryList[maxList.index(max(maxList))]

        print movieName

        return movieName
        pass

s = Solution()
s.solve()