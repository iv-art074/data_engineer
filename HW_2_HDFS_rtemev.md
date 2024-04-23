В файле keywords.csv дана статистика поисковых запросов.   
С помощью алгоритма mapreduce посчитайте сколько раз в этом файле встречается каждое слово. Не учитывайте количество поисковых запросов, которое указано во втором столбце shows.  
В качестве ответа приведите код файлов mapper.py и reducer.py  

#### Mapper ####  
```  
req_w = [] #объявление списка

with open('reqs_after_mapper.csv', 'w') as f_mapper:
  with open('keywords.csv') as f:
    for i, line  in enumerate(f):
       if i==0:  #пропуск заголовка
         next
       else:
         req, num = line.strip().split(',') #получаем столбцы
         req_w += req.strip().split(' ') #заполняем список
  for j in req_w:      
    #print(j)
    f_mapper.write(f'{j},1\n')  #сохраняем
```
#### Shufffle ####  
``` cat reqs_after_mapper.csv | sort > reqs_sorted.csv ```  

#### Reducer ####  
```
previous_req_w = None
req_w_count = 0

with open('reqs_sorted.csv') as f:
    for i, line in enumerate(f):
        req_word, one = line.strip().split(',')
        one = int(one)
        
        if previous_req_w:
            if previous_req_w == req_word:
                req_w_count += one
            else:
                print(previous_req_w, req_w_count)
                req_w_count = one   
        else:
            req_w_count = one
        
        previous_req_w = req_word

   #    if i > 50:
   #        break
        
print(previous_req_w, req_w_count)
```  
