В файле movies.csv лежит база фильмов. Название фильма записано во втором столбце title.  
Разбейте названия фильмов на отдельные слова и посчитайте какое слово встречается чаще всего.  

Запустил контейнеры  

![изображение](https://github.com/user-attachments/assets/057a1abb-5316-4bbc-a56d-eb92e13fb1b0)  

Добавил Pandas  

![изображение](https://github.com/user-attachments/assets/68be85a6-7e75-4e6b-86f4-4406b930e5ba)  
  
Запустил Python  

![изображение](https://github.com/user-attachments/assets/279e9ced-9d4f-461e-8e92-8f5d760d7281)  

Привел к типу Pandas-датафрейм  

```  
>>> csv_data = spark.read.option('header','True').csv('movies.csv',sep=',')  
>>> pandas_data=csv_data.toPandas()  
>>> p1=pandas_data.title  
>>> p1  
0                                Toy Story (1995)  
1                                  Jumanji (1995)  
2                         Grumpier Old Men (1995)  
3                        Waiting to Exhale (1995)  
4              Father of the Bride Part II (1995)  
                          ...  
9737    Black Butler: Book of the Atlantic (2017)  
9738                 No Game No Life: Zero (2017)  
9739                                 Flint (2017)  
9740          Bungo Stray Dogs: Dead Apple (2018)  
9741          Andrew Dice Clay: Dice Rules (1991)  
Name: title, Length: 9742, dtype: object
```
Разбил на слова с регулярными выражениями с удалением года  

![изображение](https://github.com/user-attachments/assets/359c9ec6-d1d1-4164-bfe5-be03d52ce2cc)  

Итого - чаще всего встречается  'The'

