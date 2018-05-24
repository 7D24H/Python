# -*- coding:utf-8 -*-
import re
from collections import Counter

class Solution():
    def solve(self):
        f = open('T4_A.txt','r')
        str = f.read()
        f.close()

        list = re.split('[ ,:".!()-]',str)
        list = filter(None,list)
        most10 = Counter(list).most_common(10)

        result = [5059]
        for i in range(10):
            result.append(most10[i][0])

        print result

        pass
s = Solution()
s.solve()