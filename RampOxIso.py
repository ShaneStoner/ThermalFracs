
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import rampedpyrox as rp
import os
from os import listdir
from os.path import isfile, join

onlyfiles = []
successfiles = []
currentdir = os.getcwd()

folderpath = input("Folder or working directory: ")

resamplenum = input("Resample Count: ")

setlamda_str = input("Customize lambda value? Number or 0 (auto-calculated). ")
setlamda = float(setlamda_str)
os.chdir(folderpath)



trimfiles = [f for f in listdir(folderpath) if isfile(join(folderpath, f))]

for file in trimfiles:
    if file[-8:] == '_RPO.csv':
        onlyfiles.append(file)

#print (onlyfiles)
for f in onlyfiles:
    print("Processing " + f)
    tg_data = f
    nt = int(resamplenum)

    tg = rp.RpoThermogram.from_csv(
            tg_data,
            bl_subtract = True, #subtract baseline
            nt = nt)

    #load modules
    import matplotlib.pyplot as plt

    #make a figure
    fig, ax = plt.subplots(2, 2,
            figsize = (8,8),
            sharex = 'col')
    fig.suptitle(str(f))

    #plot results
    ax[0, 0] = tg.plot(
            ax = ax[0, 0],
            xaxis = 'time',
            yaxis = 'rate')

    ax[0, 1] = tg.plot(
            ax = ax[0, 1],
            xaxis = 'temp',
            yaxis = 'rate')

    ax[1, 0] = tg.plot(
            ax = ax[1, 0],
            xaxis = 'time',
            yaxis = 'fraction')

    ax[1, 1] = tg.plot(
            ax = ax[1, 1],
            xaxis = 'temp',
            yaxis = 'fraction')

    #adjust the axes
    ax[0, 1].set_ylim([0, 0.015])
    ax[1, 1].set_xlim([375, 1200])

    #save to csv
    filename = str(f) + "_thermsum.csv"
    #tg.tg_info.to_csv(filename)

    plt.tight_layout()

    #define log10omega, assume constant value of 10
    #value advocated in Hemingway et al. (2017) Biogeosciences
    log10omega = 10

    #define E range (in kJ/mol)
    E_min = 50
    E_max = 400
    nE = 400 #number of points in the vector

    #create the DAEM instance
    daem = rp.Daem.from_timedata(
            tg,
            log10omega = log10omega,
            E_max = E_max,
            E_min = E_min,
            nE = nE)

    #make a figure
    fig,ax = plt.subplots(1, 1,
            figsize = (5, 5))

    lam_best, ax = daem.calc_L_curve(
            tg,
            ax = ax,
            plot = True)

    plt.tight_layout()

    if setlamda > 0:
        lambd = setlamda
    else:
        lambd = 'auto'

    ec = rp.EnergyComplex.inverse_model(
            daem,
            tg,
            lam = lambd)
    #make a figure
    fig,ax = plt.subplots(1, 1,
            figsize = (5,5))

    #plot results
    ax = ec.plot(ax = ax)

    ax.set_ylim([0, 0.042])
    ax.set_xlim([75, 250])
    plt.tight_layout()

    #print in the terminal
    print(ec.ec_info)

    #save to csv
    filename = str(f) + "invdata.csv"
    #ec.ec_info.to_csv(filename)


    #residual rmse for the model fit
    ec.resid
    print(str())

    #regularization roughness norm
    ec.rgh


    ### Isotopes and E distribution values ###

plt.tight_layout()

print("The following files ")
for file in successfiles:
    print(str(file))
print(" all plotted successfully.")
os.chdir(currentdir)
