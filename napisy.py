# -*- coding: utf-8 -*-
"""
Created on Sun Jun 25 20:37:49 2023

@author: t-jan
"""
from nltk.tokenize import word_tokenize

for files in range(111,161):
    path1="C:\\Users\\t-jan\\Desktop\\10 sem\\MO\\lab3\\instancias1a100\\"+str(files)+".txt"
    path2="C:\\Users\\t-jan\\Desktop\\10 sem\\MO\\lab3\\instancias1a100\\p\\"+str(files)+".txt"
    f = open(path1, "r")
    g = open(path2, "w")
    n=int(word_tokenize(f.readline())[0])
    m=f.readline()
    g.write("[")
    for line in range(0,n):
        l=f.readline()
        l= word_tokenize(l)
        new_l = []
        for i in range(0,len(l)):
            if i%2!=0:
                new_l.append(l[i])
        linia=""
        for i in range(0,len(new_l)):
            linia=linia+" "+new_l[i]
        if line!=n-1:
            linia=linia+";"
        g.write(linia)
    g.write("]")
    f.close()
    g.close()
