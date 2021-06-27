import pymysql
import tkinter as tk
from tkinter import messagebox
import inspect

root =tk.Tk() 
color=['red','bisque2','coral','purple','blue']   
connection = pymysql.connect(host="localhost",user="root",passwd="",database="Flight Management" )
cursor = connection.cursor()
def Origin_from_X():
      
      E=getE()
      E.insert(0,"You have to input")
      L=getL()
      name=str(inspect.currentframe().f_code.co_name)

      def ex():
          retrive = "CALL `Origin_from_X`('"+E.get()+"');"
          cursor.execute(retrive)
          n= cursor.description
          rows = cursor.fetchall()
          atl(rows,n,L) 

      BU(name,ex)

def percentage_of_company_name_from_flight():
   
   
      E=getE()
      E.insert(0,"No input")
      L=getL()
      name=str(inspect.currentframe().f_code.co_name)
      
      def ex():        
          retrive = "CALL `percentage_of_company_name_from flight`();"
          cursor.execute(retrive)
          n= cursor.description
          rows = cursor.fetchall()
          atl(rows,n,L) 

      BU(name,ex)


def all_flights_byCompanyName_byDate():

    E=getE()
    E.insert(0,"No input")
    L=getL()
    name=str(inspect.currentframe().f_code.co_name)

    def ex():         
          retrive = "CALL `all_flights_byCompanyName_byDate`();"
          cursor.execute(retrive)
          n= cursor.description
          rows = cursor.fetchall()        
          atl(rows,n,L) 

    BU(name,ex)

    
               

def getNumOfAvailableSeatsPerFlight():
    E=getE()
    E.insert(0,"No input")
    L=getL()
    name=str(inspect.currentframe().f_code.co_name)

    def ex():         
          retrive = "CALL `getNumOfAvailableSeatsPerFlight`();"
          cursor.execute(retrive)
          n= cursor.description
          rows = cursor.fetchall()          
          atl(rows,n,L) 

    BU(name,ex)

def getAllpeopleNameLandingByDate():
    E=getE()
    E.insert(0,"input date")
    L=getL()
    name=str(inspect.currentframe().f_code.co_name)

    def ex():          
          retrive = "CALL `getAllpeopleNameLandingByDate`('"+E.get()+"');"
          cursor.execute(retrive)
          n= cursor.description
          rows = cursor.fetchall()
          atl(rows,n,L) 

    BU(name,ex)

def Q(num):
    switcher = { 
        0: Origin_from_X, 
        1: percentage_of_company_name_from_flight, 
        2: all_flights_byCompanyName_byDate, 
        3: getNumOfAvailableSeatsPerFlight,
        4: getAllpeopleNameLandingByDate,
        "Origin_from_X": 0, 
        "percentage_of_company_name_from_flight": 1, 
        "all_flights_byCompanyName_byDate": 2, 
        "getNumOfAvailableSeatsPerFlight": 3,
        "getAllpeopleNameLandingByDate": 4,
     } 
    return switcher.get(num, "nothing") 
    
def atl(rows,n,L):
    for i in range(len(rows)): 
            for j in range(len(rows[0])):                   
               L.insert(tk.END,str(n[j][0]).upper()+": "+str(rows[i][j]))
def BU(name,ex):
      tk.Button(root,bg=color[Q(name)],borderwidth = 6,                       
                        height=5,
                        width = 40,
                        relief="ridge",
                        text=name,command=ex).grid(row=1,column=2)    

def getE():
    x=tk.StringVar()
    e =tk.Entry (root,textvariable=x)
    e.grid(row=0,column=2) 
    return e

def getL():  
    L=tk.Listbox(root, height=16,
                        width = 40)
    L.grid(row=2,column=2 ,columnspan=4,rowspan=4) 
    return L

def UI(): 
    getL() 
    getE()      
    
    for i in range(0,5):
           tk.Button(root,bg=color[i],borderwidth = 6,                        
                        height=5,
                        width = 40,
                        relief="ridge",
                        text= str(Q(i).__name__),command = Q(i)).grid(row=i,column=1) 

    tk.Button(root,bg='blue',borderwidth = 6,                       
                        height=5,
                        width = 40,
                        relief="ridge",
                        text= "GO").grid(row=1,column=2)                    
 
            
                                
   

if __name__ == "__main__":
    #messagebox.showinfo("DB_UI", "Flight Management")
    #messagebox.showerror("Error", "Error message")
    UI()
    #get()
    root.mainloop()
    connection.close()  