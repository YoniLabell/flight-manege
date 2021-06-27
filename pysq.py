import pymysql
from random import choice
import random as ran


arr=['FIRST','BUSINESS','ECONOMY']
arr1=['A','B','C','D','E','F']
def funk():

    connection = pymysql.connect(host="localhost",user="root",passwd="",database="Flight Management" )
    cursor = connection.cursor()
    for i in range(1000):
          r1=ran.randint(1,25)
          r2=choice([ran.randint(1,6),ran.randint(10,11),ran.randint(16,19),ran.randint(21,21),ran.randint(24,27),ran.randint(29,32),ran.randint(34,37)])
         # r3=ran.randint(4,9)
        #r4=ran.randint(4,9)
          print(r2)
          retrive ="INSERT INTO `tickets` (`tickets_id`, `orders_id`, `flights_id`, `first_name_passenger`, `last_name_passenger`, `id_passenger`, `line`, `chair`, `department`) VALUES (NULL, '"+str(r1)+"', '"+str(r2)+"', 'moshe"+str(i)+"', 'rapaport"+str(i)+"', '"+str(i*9999%1000000)+"', '"+str(i%50)+"', '"+str(arr1[i%6])+"', '"+str(arr[i%3])+"');"
          cursor.execute(retrive)
          connection.commit()
    
    connection.close()
if __name__ == "__main__":
  funk()
  



