# -*- coding:utf-8 -*- #
from sklearn import datasets,linear_model as lm
from sklearn.model_selection import train_test_split
# add package here

iris = datasets.load_iris()
iris_x = iris.data
iris_y = iris.target
# 使用x_train y_train作为训练集
x_train, x_test, y_train, y_test = train_test_split(iris_x, iris_y, test_size=0.3)


class Solution():
    def solve(self, test_data):
        # call function logisticRegression
        regr = lm.LogisticRegression()  #逻辑回归模型
        regr.fit(x_train, y_train)  #这个模型是符合这个训练集的
        result = regr.predict(test_data)    #预测在这个训练集下算出来的test值
        print result
        return result
        pass

#s = Solution()
#s.solve(4)
#这里本机跑不出来 因为不知道test_data是什么样的