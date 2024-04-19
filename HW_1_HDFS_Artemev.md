### Необходимо посчитать рейтинг пользователей по количеству выставленных оценок: ###

- Запустите контейнер с любой версией Ubuntu. Скачайте с сайта grouplens.org...movielens/ датасет любого размера.  
- Перенесите файл ratings.csv в контейнер (имя контейнера container_name можно посмотреть в выводе команды docker ps в правом столбце NAME)  
docker cp ratings.csv container_name:/ratings.csv  
- Посчитайте топ-5 пользователей, которые выставили наибольшее количество оценок.  
- В качестве ответа укажите количество оценок, которые выставил первый пользователей получившегося рейтинга. Также приведите команду, которая выводит топ-5 пользователей из пункта 3 в командной строке.  

Образ cloudera-quickstart-vm отказался стартовать в WSL2.  
Решено через https://dev.to/damith/docker-desktop-container-crash-with-exit-code-139-on-windows-wsl-fix-438    
Итого контейнер запущен:  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/a3a33fdd-f695-4b66-b380-bc795cd92ca4)  

файл загружен  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/41be8508-3eb7-4ee4-ae25-5f91088e3bc6)  

база создана, запрос составлен:  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/e0d4d2c8-e463-4162-a3be-91f26935a414)  

ну и соответственно, самый активный пользоваттель с id 547 выставил 2391 оценку  
