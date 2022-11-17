import datetime
import os
from os import listdir
from os.path import isfile, join
import csv

onlyfiles = []
pythonfolder = os.getcwd()
folder = input("Folder or working directory: ")


os.chdir(folder)

folderpath = folder


trimfiles = [f for f in listdir(folder) if isfile(join(folder, f))]

for file in trimfiles:
    if file[0:7] == 'smooth_':
        onlyfiles.append(file)


csvlist = []
xcount = []

duplicatecount = 2

titles = ['date_time', 'temp', 'CO2_scaled', 'CO2_av', 'CO2_med',
          'Moving', 'Modelled']

#print (onlyfiles)


for f in onlyfiles:
    if f[-8:] == '_RPO.csv':
        pass
    elif f[:11] == 'smooth_Blnk':
        pass
    else:
        filesplit = f.split(".")
        filename = filesplit[0] + "_RPO.csv"
        txt_file = f
        csv_file = filename
        #f = 'easgraph007.txt'
        n = 0

        #Get sample name to name csv file

        print(filename)

        in_txt_namer = csv.reader(open(f, 'rt'), delimiter = '\t')


        #Add headers and convert .txt into .csv

        n = 0
        x = 0

        in_txt = csv.reader(open(f, 'rt'), delimiter = ',')

        with open(filename, 'w', newline='', encoding='utf-8') as csv_file:
            writer = csv.writer(csv_file, delimiter=',', dialect = "excel")
            for row in in_txt:
                    if n == 0:
                        writer.writerow(titles)
                        x = x+1
                    elif row[0][0] != '#':
                        sec = x
                        time = str(datetime.timedelta(seconds=sec))
                        time_midnight = sec + 3600
                        time = str(datetime.timedelta(seconds=time_midnight)) + ' AM'
                        temp = row[0]
                        av = row[1]
                        med =row[2]
                        moving =row[3]
                        model = row[4]
                        scaled = row[5]

                        newrow = [time] + [temp] + [scaled] + [av] + [med] + [moving] + [model]
                        writer.writerows([newrow])
                        x=x+5
                    n = n+1
            #writer.writerows(row)
            #print(row)


        csvlist.append(filename)
        xcount.append(x)

print(csvlist)
#print(xcount)
os.chdir(pythonfolder)
