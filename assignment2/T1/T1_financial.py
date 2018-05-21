# -*- coding:utf-8 -*-
import requests
import zipfile
import pandas as pd
#hello
class Solution():
    def solve(self):
        countries = 0
        medianNumber = 0.00

        url = 'https://www.imf.org/external/pubs/ft/wp/2008/Data/wp08266.zip'

        r = requests.get(url)   #使用requests获取WinRAR zip并放到外面一层目录了
        with open("T1.zip", "wb") as code:
            code.write(r.content)

        azip = zipfile.ZipFile('T1.zip')
        azip.extractall('T1')   #解压到T1文件夹

        reader = pd.read_stata('T1\Financial Reform Dataset Dec 2008.dta')

        # df = pd.DataFrame(reader) #可以不要的 和reader一样的
        countries = reader.country.drop_duplicates().size
        medianNumber = reader.country.value_counts().median()

        return [countries, medianNumber]
        pass


s = Solution()
s.solve()