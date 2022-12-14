SplineCompare <- function(fil = 20, percentiles = c(10, 25, 40, 50, 60, 75, 95), cutoffs=c(200,300,400,500,600,700,800,900))
  {
library(sBIC)
library(grid)
library(gridExtra)
library(mclust)
library(dplyr)
library(zoo)

pvp = viewport()

par(mfrow = c(2,1))

csvlist = list.files(pattern="*.csv")
for (i in 1:length(csvlist)) assign(csvlist[i], read.csv(csvlist[i]))

titles=c()

for (i in (csvlist)){
  t<- i
  titles <- c(titles,t)
}

for (f in csvlist) {
  f_name = f[1]
  f_name = substr(f_name, 1, 7)
  if (f_name[1:7][1] == "smooth_") {
  }
  else {
  dat <- read.csv(f)
  cat("Currently analysing", f, "\n")
  #Compute medians and averages, and format dataframe
  datclip <- data.frame(dat$temp, dat$CO2_scaled, dat$CO2_scaled, dat$CO2_scaled, dat$CO2_scaled,dat$CO2_scaled, dat$CO2_scaled, dat$CO2_scaled)
  datclip <- na.omit(datclip)
  datclip <- stats::aggregate(dat$CO2_scaled, by=list(Temp_av = dat$temp), FUN=mean)
  CO2med <- stats::aggregate(dat$CO2_scaled, by=list(Temp_av = dat$temp), FUN=median)
  colnames(datclip)[2] <- "CO2_av"
  datclip <- cbind(datclip, CO2med)
  colnames(datclip)[4] <- "CO2_med"

  fil_CO2 <- stats::filter(datclip$CO2_av, sides=2, rep(1/fil,fil))
  datclip$fil_CO2 <-fil_CO2
  datclip$CO2_scaled <- datclip$fil_CO2

  tempfracs <- c(285, 330, 380)

  plot(dat$temp, dat$CO2_scaled, col="steelblue4", type='l', lwd=4, main=f,
       xlab="Temp. (C)", ylab="CO2 (IR Detector)", xaxp = c(100, 900, 16)) #True data
  lines(datclip$Temp_av, datclip$CO2_av, col='red', lwd=1.5) #Ave CO2 at each temp
  fit1 <- smooth.spline(datclip$Temp_av, datclip$CO2_av, df=(length(datclip$Temp_av)-1), tol = 0.0001) #spline modeled
  lines(fit1,col="blue",lwd=1.5, lty=1)
  lines(datclip$Temp_av, datclip$CO2_med, col='springgreen2', lwd=1.5) #Med CO2 at each temp
  lines(datclip$Temp_av, datclip$fil_CO2, col="orange", type='l', lwd=2.5) #Filtered averages (20)
  #abline(,,,tempfracs, col = 'red')


  ## Construct dataframe for saving and export
  datclip <- cbind(datclip, fit1$y)
  colnames(datclip)[5] <- "Moving*"
  colnames(datclip)[7] <- "Modelled"
  colnames(datclip)[6] <- "CO2_scaled"
  datclip <- na.omit(datclip)

  #Proportional C
  maxCO2 <- max(datclip$CO2_av)
  datclip$CO2_prop <- datclip$Moving / maxCO2

  datclip <- datclip[2:8]
  datclip <- datclip[c(2,1,3,4,6,5,7)]
  colnames(datclip)[1] <- "temp"

  ### Add missing temps and spline
  datclip_sp <- full_join(data.frame(Temp_av = seq(100, 800, by =1)), datclip, by = c("Temp_av" = "temp"))
  datclip_sp <- data.frame(temp = datclip_sp$Temp_av,
                           CO2_av = na.spline(datclip_sp$CO2_av),
                           CO2_med = na.spline(datclip_sp$CO2_med),
                           Moving = na.spline(datclip_sp$`Moving*`),
                           Modelled = na.spline(datclip_sp$Modelled),
                           CO2_scaled = na.spline(datclip_sp$CO2_scaled))

  filename = paste('smooth_',f, sep="")
  write.csv(datclip_sp, file = filename, row.names=FALSE)
  colnames(datclip)[1] <- "Temp_av"
  datclip <- na.omit(datclip)

  ### CO2 aggregated averages
  sp_fun <- splinefun(datclip$Temp_av, datclip$CO2_av, method='fmm')
  tol = 1.5e-4 * 2
  arealist <- list()
  l=1
  u=1
  cutoffMax <- cutoffs
  for (i in cutoffMax) {
    if (u==1){
      lower <- 100
      upper <- cutoffMax[u]
      u <- u+1
    } else {
      lower <- cutoffMax[l]
      upper <- cutoffMax[u]
      u <- u+1
      l <- l+1
    }
    area <- integrate(sp_fun, lower, upper, subdivisions = 8000, rel.tol = tol)
    #area <- round(arearaw, 2)
    arealist <- c(arealist, area[1])
  }
  area_un <- unlist(arealist)
  maxtemp <- max(dat$temp)
  totalarea <- integrate(sp_fun, 100, maxtemp, subdivisions=8000, rel.tol = tol)[1]
  totalarea_int <- as.numeric(unlist(totalarea))

  ### Find 95% of C temperature values
  #percentiles = c(10, 25, 40, 50, 60, 75, 90)
  percentiletemps <- c()
  temps <- seq(from = 150, to  = 900, by=1)
  for (y in percentiles) {
    area_int_prop <- 0
    x = y / 100
    while (area_int_prop < x) {
      for (i in temps) {
        if (area_int_prop < x) {
          area <- integrate(sp_fun, 100, i, subdivisions=8000, rel.tol = tol)[1]
          area_int <-as.numeric(unlist(area))
          area_int_prop <- area_int / totalarea_int
          if (area_int_prop > x) {
            #cat("The ", y, "th percentile of carbon was measured at ", i, " degrees C. \n")
            percentiletemps <- c(percentiletemps, i)
          }
        }
      }
    }}
  q <- data.frame(percentiles, percentiletemps)
  colnames(q) <- c("th %ile", "Average")

  ### Added fix attempt, september 6
  cutoffMax = c()
  fileroot = gsub("\\..*","",csvlist[1])
  filename = paste(fileroot, ".jpeg", sep="")
  cutoffclip <- c()
  maxtemp <- max(dat$temp)
  for (x in cutoffs) {
    if (x <= maxtemp) {
      cutoffclip <- c(cutoffclip, x)
    }
    else {

    }
  }
  cutoffMax <- sort(c(cutoffclip, maxtemp))


  ### CO2 aggregated medians
  sp_fun <- splinefun(datclip$Temp_av, datclip$CO2_med, method='fmm')
  tol = 1.5e-4 * 2
  arealist <- list()
  l=1
  u=1
  for (i in cutoffMax) {
    if (u==1){
      lower <- 100
      upper <- cutoffMax[u]
      u <- u+1
    } else {
      lower <- cutoffMax[l]
      upper <- cutoffMax[u]
      u <- u+1
      l <- l+1
    }
    area <- integrate(sp_fun, lower, upper, subdivisions = 8000, rel.tol = tol)
    #area <- round(arearaw, 2)
    arealist <- c(arealist, area[1])
  }
  area_un <- unlist(arealist)
  maxtemp <- max(dat$temp)
  totalarea <- integrate(sp_fun, 100, maxtemp, subdivisions=8000, rel.tol = tol)[1]
  totalarea_int <- as.numeric(unlist(totalarea))

  ### Find 95% of C temperature values
  #percentiles = c(10, 25, 40, 50, 60, 75, 90)
  percentiletemps <- c()
  temps <- seq(from = 150, to  = 900, by=1)
  for (y in percentiles) {
    area_int_prop <- 0
    x = y / 100
    while (area_int_prop < x) {
      for (i in temps) {
        if (area_int_prop < x) {
          area <- integrate(sp_fun, 100, i, subdivisions=8000, rel.tol = tol)[1]
          area_int <-as.numeric(unlist(area))
          area_int_prop <- area_int / totalarea_int
          if (area_int_prop > x) {
            cat("The ", y, "th percentile of carbon was measured at ", i, " degrees C. \n")
            percentiletemps <- c(percentiletemps, i)
          }
        }
      }
    }}
  q <- cbind(q, percentiletemps)
  colnames(q) <- c("th %ile","Average", "Median")




  ### CO2 - moving averages
  sp_fun <- splinefun(datclip$Temp_av, datclip$Modelled, method='fmm')
  tol = 1.5e-4 * 2
  arealist <- list()
  l=1
  u=1
  for (i in cutoffMax) {
    if (u==1){
      lower <- 100
      upper <- cutoffMax[u]
      u <- u+1
    } else {
      lower <- cutoffMax[l]
      upper <- cutoffMax[u]
      u <- u+1
      l <- l+1
    }
    area <- integrate(sp_fun, lower, upper, subdivisions = 8000, rel.tol = tol)
    #area <- round(arearaw, 2)
    arealist <- c(arealist, area[1])
  }
  area_un <- unlist(arealist)
  maxtemp <- max(datclip$Temp_av)
  totalarea <- integrate(sp_fun, 100, maxtemp, subdivisions=8000, rel.tol = tol)[1]
  totalarea_int <- as.numeric(unlist(totalarea))

  ### Find 95% of C temperature values
  #percentiles = c(10, 25, 40, 50, 60, 75, 90)
  percentiletemps <- c()
  temps <- seq(from = 150, to  = 900, by=1)
  for (y in percentiles) {
    area_int_prop <- 0
    x = y / 100
    while (area_int_prop < x) {
      for (i in temps) {
        if (area_int_prop < x) {
          area <- integrate(sp_fun, 100, i, subdivisions=8000, rel.tol = tol)[1]
          area_int <-as.numeric(unlist(area))
          area_int_prop <- area_int / totalarea_int
          if (area_int_prop > x) {
            #cat("The ", y, "th percentile of carbon was measured at ", i, " degrees C. \n")
            percentiletemps <- c(percentiletemps, i)
          }
        }
      }
    }}
  q <- cbind(q, percentiletemps)
  colnames(q) <- c("th %ile", "Average", "Median", "Moving")



  ### CO2 - modelled fit
  sp_fun <- splinefun(fit1$x, fit1$y, method='fmm')
  tol = 1.5e-4 * 2
  arealist <- list()
  l=1
  u=1
  for (i in cutoffMax) {
    if (u==1){
      lower <- 100
      upper <- cutoffMax[u]
      u <- u+1
    } else {
      lower <- cutoffMax[l]
      upper <- cutoffMax[u]
      u <- u+1
      l <- l+1
    }
    area <- integrate(sp_fun, lower, upper, subdivisions = 8000, rel.tol = tol)
    #area <- round(arearaw, 2)
    arealist <- c(arealist, area[1])
  }
  area_un <- unlist(arealist)
  maxtemp <- max(dat$temp)
  totalarea <- integrate(sp_fun, 100, maxtemp, subdivisions=8000, rel.tol = tol)[1]
  totalarea_int <- as.numeric(unlist(totalarea))


  ### Find 95% of C temperature values
  #percentiles = c(10, 25, 40, 50, 60, 75, 90)
  percentiletemps <- c()
  temps <- seq(from = 150, to  = 900, by=1)
  for (y in percentiles) {
    area_int_prop <- 0
    x = y / 100
    while (area_int_prop < x) {
      for (i in temps) {
        if (area_int_prop < x) {
          area <- integrate(sp_fun, 100, i, subdivisions=8000, rel.tol = tol)[1]
          area_int <-as.numeric(unlist(area))
          area_int_prop <- area_int / totalarea_int
          if (area_int_prop > x) {
            #cat("The ", y, "th percentile of carbon was measured at ", i, " degrees C. \n")
            percentiletemps <- c(percentiletemps, i)
          }
        }
      }
    }}
  for (i in percentiletemps) {
    abline(,,,i, col='darkgrey', lty=2)
  }

  legend('topright',legend=c('Raw', 'Ave at Temp C', 'Med at Temp C', 'Modelled', 'Moving Ave (15)'),
         col=c("steelblue4", "red", 'springgreen2', "blue", "orange"), lty=1, cex=0.5)

  plot.new()
  q <- cbind(q, percentiletemps)
  colnames(q) <- c("th %ile", "Average", "Median", "Moving", "Modelled")
  percTable <- matrix(, nrow = length(percentiles), ncol=2)
  pushViewport(pvp)
  grid.table(q)
  x = x+1

  }
  }
}

