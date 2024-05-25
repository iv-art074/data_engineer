Запустил Кафку  

![image](https://github.com/iv-art074/data_engineer/assets/87374285/f1047641-53b0-4d54-bdfd-d808f7df8e97)  

установил Spark  

![image](https://github.com/iv-art074/data_engineer/assets/87374285/d479c98c-136d-4e48-b13f-bee955ea5f74)  

producer работает  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/20e161de-20f7-4f2d-964a-1f972a299965)  

join работает  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/cce681a5-cb71-4b18-a22e-a4b8514344e9)  

Агрегатная функция здесь  
```
#добавим агрегат - отображать число уникальных айдюков
stat_stream = clean_data.groupBy("id").count()

join_stream = stat_stream.join(users, stat_stream.id == users.id, "left_outer").select(users.user_name, users.user_age, col('count'))
join_stream.writeStream.format("console").outputMode("complete").option("truncate", False).start().awaitTermination()
```  


![image](https://github.com/iv-art074/data_engineer/assets/87374285/9480fbb1-c3f6-4d15-8a45-2739144582fc)

