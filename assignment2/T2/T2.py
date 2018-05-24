# -*- coding:utf-8 -*-
import requests
import zipfile
import pandas as pd

from collections import Counter


class Solution():
    def solve(self):
        movieNameOfMovieId1 = ""
        genresCounts = 0
        movieNameOfTheMostRatedMovie = ""

        moviesReader = pd.read_csv('movies.csv')
        ratingsReader = pd.read_csv('ratings.csv')

        #两张表连接，根据on后的列相同做交集（inner）
        mergeRM = pd.merge(ratingsReader, moviesReader, on='movieId', how='inner', sort=True)

        # .item()前的元素是Series类型 加了.item()后是str
        movieNameOfMovieId1 = moviesReader.title[moviesReader.movieId==1].item()

        # .__str()__前的元素也是Series
        genresCounts = moviesReader.genres[moviesReader.movieId==1].__str__().count('|') + 1

        # 第一个【0】前的元素是list 第二个【0】前的是tuple 形如(  ,  ,  ) 整个是str
        movieNameOfTheMostRatedMovie = (Counter(mergeRM.title).most_common(1))[0][0]

        print type(movieNameOfMovieId1)
        print type(genresCounts)
        print type(movieNameOfTheMostRatedMovie)

        return [movieNameOfMovieId1, genresCounts, movieNameOfTheMostRatedMovie]
        pass

s = Solution()
s.solve()