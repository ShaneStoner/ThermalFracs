import datetime
import os
from os import listdir
from os.path import isfile, join
import csv

currentdir = os.getcwd() #To return to current directory at end of program

folderpath = input("Folder or working directory: ")

os.chdir(folderpath)

onlyfiles = []

blankspath = '/Users/shane/Desktop/IMPRS/ThermalAnalysis/SoliTOC/Day4Non_samples'

trimfiles = [f for f in listdir(folderpath) if isfile(join(folderpath, f))]

for file in trimfiles:
    if file[-4:] == '.txt':
        onlyfiles.append(file)

#print (".txt file contained in this folder: " + onlyfiles)

###### Latest update, August 13: handling low-temperature runs ######

csvlist = []
xcount = []

duplicatecount = 2

titles = ['date_time', 'temp', 'CO2_scaled', 'PostTemp', 'FlowN',
          'FlowLance', 'Input_mbar', 'Output_mbar','CO2','seconds', 'CO2_normal']

for f in onlyfiles:
    filesplit = f.split(".")
    filename = filesplit[0] + ".csv"
    txt_file = f
    csv_file = filename
    n = 0

    ### Get sample name to name csv file ###



    in_txt_namer = csv.reader(open(f, 'rt'), delimiter = '\t')

    for row in in_txt_namer:
        if n == 0:
            namesample = row[0][17:]
            if namesample[0] == " ":
                namesample = row[0][18:]
            filename = namesample + ".csv"
            if any(filename in s for s in csvlist): #Add error handling for repeat sample names
                filename = namesample + str(duplicatecount) + '.csv'
                duplicatecount = duplicatecount + 1
        n = n+1


    ### Find maximum run temperature ###
    n = 0
    maxtemp = 0

    txt_in = csv.reader(open(f, 'rt'), delimiter = '\t')
    for row in txt_in:
        if n < 7:
            n = n+1
        if n > 6:
            if int(row[1]) > maxtemp:
                maxtemp = int(row[1])

    tempcutoff = maxtemp - 15 #Adjust max to remove cooling process from plots

    ### Add headers and convert .txt into .csv ###

    n = 0
    x = 0
    t = 0

    in_txt = csv.reader(open(f, 'rt'), delimiter = '\t')

    with open(filename, 'w', newline='', encoding='utf-8') as csv_file:
        writer = csv.writer(csv_file, delimiter=',', dialect = "excel")
        while x < 3: #Honestly not sure how this is working anymore...
            for row in in_txt:
                if n == 0: #Header, containing sample named entered into TOC software
                    samplename = row[0][17:]
                    if samplename[0] == " ": #This random space creates a lot of headaches
                        samplename = row[0][18:]
                    x = x+1
                elif n == 6: #Row with column headers
                    writer.writerow(titles)
                    x = x+1
                elif row[0][0] != '#':
                    if int(row[1]) > tempcutoff:
                        x = x+1
                    if x > 45:
                        pass
                    else:
                        sec = int(row[0])
                        time = str(datetime.timedelta(seconds=sec))
                        time_midnight = sec + 3600 #To avoid zeros in the first character (indexing problem)
                        time = str(datetime.timedelta(seconds=time_midnight)) + ' AM' #Simulates excel format required for RampedPyrox package
                        co2_int = int(row[7])
                        if co2_int < 0: #There's always one
                            co2_int = "NA"
                            newrow = row[0:7] + [co2_int] + [co2_int]
                        else:
                            co2_int = str(co2_int)
                            newrow = row[0:7] + [co2_int] + [co2_int]
                        timelist = [time]
                        seconds = row[0]
                        temperature = row[1]
                        postTemp = row[2]
                        FlowN = row[3]
                        FlowLance = row[4]
                        Input_mbar = row[5]
                        output_mbar = row[6]

                        row = newrow + timelist
                        date_time = row[9]
                        t = t+1
                        if co2_int == "NA":
                            co2_int == ''
                        else:
                            co2_scale = str(int(co2_int) - 1000)

                        co2_raw = row[8]

                        newer_row = [date_time] + [temperature] + [co2_scale] + [postTemp] + [FlowN] + [FlowLance] + [Input_mbar] + [output_mbar] + [co2_raw] + [sec]
                        writer.writerows([newer_row])
                n = n+1

    print(samplename + " has a maximum temperature of " + str(maxtemp) + ", with an 'x over max temp' count of " + str(x) + ".")
    csvlist.append(filename)
    xcount.append(x)

os.chdir(currentdir)
