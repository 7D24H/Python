#-*- coding:utf-8 -*-
from sklearn.cluster import KMeans

class Solution():
    def solve(self, X):
        clf = KMeans(n_clusters=3)
        y_pred = clf.fit_predict(X)
        return y_pred
        pass

s = Solution()
s.solve()