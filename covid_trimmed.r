#!/usr/bin/env Rscript
#
# Weight, Scale and Shift (WSS) Code
#
# Copyright 2021 Graeme Ackland, The University of Edinburgh,
#                James Ackland, The University of Cambridge
#
#### Header ####

if(interactive()){
  # Remove existing variables
  rm(list = ls())
}

# Read packages used by the script
library(readr, warn.conflicts = FALSE, quietly = TRUE)
library(dplyr, warn.conflicts = FALSE, quietly = TRUE)
library(tidyr, warn.conflicts = FALSE, quietly = TRUE)
library(ggplot2, warn.conflicts = FALSE, quietly = TRUE)
library(lubridate, warn.conflicts = FALSE, quietly = TRUE)
library(zoo, warn.conflicts = FALSE, quietly = TRUE)
library(RColorBrewer, warn.conflicts = FALSE, quietly = TRUE)

# Set the working directory from where the script is run.
setwd(".")

# Turn off scientific notation.
options(scipen = 999)

#### Read data ####
# Base URL to get the data
baseurl <- "https://api.coronavirus.data.gov.uk/v2/data?"

# Start and end date - the data to collect data from
startdate <- as.Date("2020/07/25")
#  To one week ago (-7)
enddate <-  Sys.Date()-7

# Total cases, deaths, tests
casesurl <- paste0(baseurl,
                   "areaType=nation&",
                   "areaCode=E92000001&",
                   "metric=newCasesBySpecimenDate&",
                   "metric=newDeaths28DaysByDeathDate&",
                   "metric=newPCRTestsByPublishDate&",
                   "format=csv")

# Explicitly define the types for the columns
coltypes <- cols(col_character(), col_character(),col_character(),
                 col_date(format="%Y-%m-%d"), col_integer(),
                 col_integer(), col_integer())

# Read the data
comdat <-  read_csv(file = casesurl, col_types = coltypes)

# Transform the data
comdat <- comdat %>%  select(date,
                             allCases = newCasesBySpecimenDate,
                             allDeaths = newDeaths28DaysByDeathDate,
                             tests = newPCRTestsByPublishDate,
                             inputCases = newCasesBySpecimenDate,
                             fpCases = newCasesBySpecimenDate) %>%
  filter(date >= startdate &
           date <= enddate ) %>%
  arrange(date)

# All UK cases (to estimate pre-Sept England Cases)
ukcaseurl <- paste0(baseurl,
                    "areaType=overview&",
                    "metric=newPCRTestsByPublishDate&",
                    "format=csv")

# Explicitly define the types for the columns
coltypes <- cols(col_character(), col_character(),col_character(),
                 col_date(format="%Y-%m-%d"), col_integer())
# Read the data
ukcasedat <-  read_csv(file = ukcaseurl, col_types = coltypes)

# Transform the data
ukcasedat <- ukcasedat %>%  select(date = date, tests = newPCRTestsByPublishDate) %>%
  filter(date >= startdate &
           date <= enddate ) %>%
  arrange(date)
# cases by age
ageurl <- paste0(baseurl,
                 "areaType=nation&",
                 "areaCode=E92000001&",
                 "metric=newCasesBySpecimenDateAgeDemographics&",
                 "format=csv")

# Explicitly define the types for the columns
# Age is a character as it giving a range, e.g. 00_04, 05_09, ...
coltypes <- cols(col_character(), col_character(),col_character(),
                 col_date(format="%Y-%m-%d"), col_character(),
                 col_integer(), col_integer(), col_double())

# read in the data
casedat <-  read_csv(file = ageurl, col_types = coltypes)

# Remap the ages column to be the header rows, remove the unassigned,
# 60+ and 00_59 columns, filter dates to be between the start and end
# dates and order the output by date
casedat <- casedat %>%
  select(date = date, age = age, values = cases) %>%
  pivot_wider(id_cols = date, names_from = age, values_from = values) %>%
  select(-unassigned, -"60+", -"00_59") %>%
  filter(date >= startdate & date <= enddate) %>%
  arrange(date)

#deaths by age
deathurl <- paste0(baseurl,
                   "areaType=nation&",
                   "areaCode=E92000001&",
                   "metric=newDeaths28DaysByDeathDateAgeDemographics&",
                   "format=csv")

# Explicitly define the types for the columns
coltypes <- cols(col_character(), col_character(),col_character(),
                 col_date(format="%Y-%m-%d"),col_character(),
                 col_integer(), col_integer(), col_double())
# Read the data
deathdat <-  read_csv(file = deathurl, col_types = coltypes)

# Map the ages column to become column headings for the different age groups
# for dates between the start and end date inclusive and then ensure that we
# end up with the same columns as for the case data above.
deathdat <- deathdat %>%
  select(date = date, age = age, values = deaths) %>%
  pivot_wider(id_cols = date, names_from = age, values_from = values) %>%
  select(-"60+", -"00_59") %>%
  filter(date >= startdate & date <= enddate) %>%
  arrange(date) %>%
  select(names(casedat))#deaths by age


#  Read in the Vaccination data
vacurl <- paste0(baseurl,
                 "areaType=nation&",
                 "areaCode=E92000001&",
                 "metric=cumVaccinationFirstDoseUptakeByPublishDatePercentage&",
                 "format=csv")

# Explicitly define the types for the columns
coltypes <- cols(col_character(), col_character(),col_character(),
                 col_date(format="%Y-%m-%d"), col_double())
# Read the data
vacdat <-  read_csv(file = vacurl, col_types = coltypes)

# Map the ages column to become column headings for the different age groups
# for dates between the start and end date inclusive and then ensure that we
# end up with the same columns as for the case data above.
vacdat <- vacdat %>%
  select(date = date,  values =cumVaccinationFirstDoseUptakeByPublishDatePercentage)
#  Scotland data https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=S92000003&metric=newCasesBySpecimenDate&metric=newDeaths28DaysByDeathDate&metric=newDeaths28DaysByPublishDate&format=csv
# https://www.opendata.nhs.scot/dataset/covid-19-in-scotland/resource/9393bd66-5012-4f01-9bc5-e7a10accacf4

scoturl <-  paste0(baseurl,
                   "areaType=nation&",
                   "areaCode=S92000003&",
                   "metric=newDeaths28DaysByDeathDate&",
                   "metric=newCasesBySpecimenDate&",
                   "metric=newDeaths28DaysByPublishDate&",
                   "format=csv")
coltypes <-  cols(
  date = col_date(format = "%Y-%m-%d"),
  newCasesBySpecimenDate = col_double(),
  newDeaths28DaysByPublishDate = col_double(), 
  newDeaths28DaysByDeathDate = col_double()
)
#  trying and failing to get data from PHS
scotdeaths<- read.csv(file="https://www.opendata.nhs.scot/dataset/covid-19-in-scotland/resource/9393bd66-5012-4f01-9bc5-e7a10accacf4")
#scotdeaths<- read.csv(file="https://www.opendata.nhs.scot/api/3/action/datastore_search?resource_id=9393bd66-5012-4f01-9bc5-e7a10accacf4")
# Read in the data
scotdat <-  read_csv(file = scoturl, col_types = coltypes)

# Transform the data
scotdat <- scotdat %>%  select(date,
                             allCases = newCasesBySpecimenDate,
                             allDeaths = newDeaths28DaysByDeathDate,
                             inputCases = newCasesBySpecimenDate,
                             fpCases = newCasesBySpecimenDate) %>%
  filter(date >= startdate &
           date <= enddate ) %>%
  arrange(date)


#  Regional data
regurl <- paste0(baseurl,
                 "areaType=region&",
                 "metric=newDeaths28DaysByDeathDate&",
                 "metric=newCasesBySpecimenDate&",
                 "format=csv")

# Specify the column types
coltypes <-  cols(
  areaCode = col_character(),
  areaName = col_character(),
  areaType = col_character(),
  date = col_date(format = "%Y-%m-%d"),
  newCasesBySpecimenDate = col_double(),
  newDeaths28DaysByDeathDate = col_double()
)

# Read in the data
regdat <-  read_csv(file = regurl, col_types = coltypes)

# Transform the data
regcases <- regdat %>%  select(date,areaName,areaCode,
                               Cases = newCasesBySpecimenDate
                               ) %>%
  pivot_wider(id_cols = date, names_from = areaName, values_from = Cases) %>%
  filter(date >= startdate &
           date <= enddate )%>%
  arrange(date)

regdeaths <- regdat %>%  select(date,areaName,
                               Deaths = newDeaths28DaysByDeathDate,
                               ) %>%
  pivot_wider(id_cols = date, names_from = areaName, values_from = Deaths) %>%
  filter(date >= startdate &
           date <= enddate )%>%
  arrange(date)
#  Get age data for regions because can't download simultaneously
regurl2 <- paste0(baseurl,
                  "areaType=region&",
                  "metric=newCasesBySpecimenDateAgeDemographics&",
                  "metric=newDeathsBySpecimenDateAgeDemographics&",
                  "format=csv")
# Read in the data
regagedat <-  read_csv(file = regurl2)
# Transform the data
regagedat <- regagedat %>%  select(date, areaName, age, cases) %>%
  filter(date >= startdate &
           date <= enddate ) %>%
  arrange(date)

# Read in the UK government R estimate data from a csv file
coltypes <- cols(
  Date = col_date(format = "%Y-%m-%d"), UK_LowerBound = col_double(),
  UK_UpperBound = col_double(), England_LowerBound = col_double(),
  England_UpperBound = col_double(), EEng_LowerBound = col_double(),
  EEng_UpperBound = col_double(), Lon_LowerBound = col_double(),
  Lon_UpperBound = col_double(), Mid_LowerBound = col_double(),
  Mid_UpperBound = col_double(), NEY_LowerBound = col_double(),
  NEY_UpperBound = col_double(), NW_LowerBound = col_double(),
  NW_UpperBound = col_double(), SE_LowerBound = col_double(),
  SE_UpperBound = col_double(), SW_LowerBound = col_double(),
  SW_UpperBound = col_double()
)
Rest <- read_csv(file="data/R_estimate.csv", col_types = coltypes)

#### Get tests for England pre-Sept by taking the post-Sept fraction of all tests that were in england (0.867)

comdat$tests[1:58] = as.integer(ukcasedat$tests[1:58] * 0.867)
rm(ukcasedat)

#plot(y=comdat$allCases, x=comdat$date, xlab="Date" , ylab="All cases")
# MAA: Same plot using ggplot
comdat %>% ggplot(aes(x=date,y=allCases)) + geom_line() +
  xlab("Date") + ylab("All cases")


#remove weekend effect,  assuming each weekday has same number of cases over the epidemic, and national averages hold regionally
days <-1:7
weeks<-as.integer(length(comdat$allCases)/7)-1

for(i in 1:weeks){
  for(j in 1:7){
    days[j]<-days[j]+comdat$allCases[7*i+j]
  }
}
casetot=sum(days)
days=7*days/casetot

# REscale comdat and regcases
for(i in 1:length(comdat$allCases)){
  indexday=(i-1)%%7+1
  comdat$allCases[i]=comdat$allCases[i]/days[indexday]
  scotdat$allCases[i]=scotdat$allCases[i]/days[indexday]
  for (area in 2:10){
    regcases[i,area]=regcases[i,area]/days[indexday] 
  }
}

# Fix Xmas anomaly over 12 days in comdat,regcases by linear fit
Xmasav<-1:11
Xmasav[1] = sum(comdat$allCases[153:164])/12
Xmasgrad=comdat$allCases[164]-comdat$allCases[153]
for (i in 153:164){
  comdat$allCases[i]=Xmasav[1]-Xmasgrad*(158.5-i)/12
}
Xmasav[11] = sum(scotdat$allCases[153:164])/12
Xmasgrad=scotdat$allCases[164]-scotdat$allCases[153]
for (i in 153:164){
  scotdat$allCases[i]=Xmasav[11]-Xmasgrad*(158.5-i)/12
}
#  Fix Xmas anomaly in regions
for (area in 2:10){
  Xmasav[area] <- sum(regcases[153:164,area])/12
  Xmasgrad<-regcases[164,area]-regcases[153,area] 
  for (i in 153:164){
    regcases[i,area]<-Xmasav[area]-Xmasgrad*(158.5-i)/12.0
  }  
  }


for (i in 2:ncol(casedat)) {
  for (j in 1:nrow(casedat)) {
    indexday=(j-1)%%7+1
    casedat[j,i] <- as.integer(casedat[j,i]/days[indexday])
  }
}

for (i in 2:ncol(casedat) ){
    Xmasav = sum(casedat[153:164,i])/12
    Xmasgrad=Xmasav/25
    for (iday in 153:164){
        casedat[iday,i]=as.integer(Xmasav-Xmasgrad*(158.5-iday))
    }
}
rm(Xmasav,Xmasgrad,weeks,i,iday,j,indexday)
# Set false positive adjustment at 0.004
for(i in 1:length(comdat$allCases)){
  comdat$fpCases[i]=comdat$allCases[i]-0.004*as.integer(comdat$tests[i])
}
plot(comdat$allCases)
lines(comdat$fpCases, col="red")

# Calculation of Rnumber, generation time = 4 days
genTime=4
#gjaR<-unlist(comdat$allCases,use.names=FALSE)
#rawR<-unlist(comdat$inputCases,use.names=FALSE)

# Create a vector to hold the results
#fpR <- vector(mode=mode(comdat$fpCases),length=length(gjaR))
#bylogR <-fpR
#dfR=data.frame(gjaR=gjaR,x=1:length(gjaR),bylogR=bylogR,fpR=fpR,rawR=rawR,date=comdat$date)
dfR=data.frame(x=1.0:length(comdat$date),date=comdat$date,gjaR=1:length(comdat$date))
dfR$rawR<-dfR$gjaR
dfR$fpR<-dfR$gjaR
dfR$weeklyR<-dfR$gjaR
dfR$bylogR<-dfR$gjaR
 
 #Ito: gjaR[i]<-(1+(comdat$allCases[i]-comdat$allCases[i-1])*2*genTime/(comdat$allCases[i]+comdat$allCases[i-1]))
  #Stratanovitch calculus
for(i in 2:length(dfR$gjaR)){
  dfR$gjaR[i]=(1+(comdat$allCases[i]-comdat$allCases[i-1])*genTime/(comdat$allCases[i-1]))
  dfR$rawR[i]=(1+(comdat$inputCases[i]-comdat$inputCases[i-1])*genTime/(comdat$inputCases[i-1]))
  dfR$fpR[i]=(1+(comdat$fpCases[i]-comdat$fpCases[i-1])*genTime/(comdat$fpCases[i-1]))
  dfR$bylogR[i]=1+log(comdat$allCases[i]/comdat$allCases[i-1])*genTime
}
dfR$rawR[1]=dfR$rawR[2]
dfR$gjaR[1]=dfR$gjaR[2]
dfR$bylogR[1]=dfR$bylogR[2]
dfR$fpR[1]=dfR$fpR[2]
for(i in 4:(length(dfR$weeklyR)-3)){
    day1=i-3
    day7=i+3
    dfR$weeklyR[i]=sum(dfR$gjaR[day1:day7])/7.0
}
#End effect
dfR$weeklyR[length(dfR$weeklyR)]=1.0
dfR$weeklyR[length(dfR$weeklyR)-1]=1.0
dfR$weeklyR[length(dfR$weeklyR)-2]=1.0

#Plot various types of smoothing on the R data
plot(x=dfR$date,y=dfR$rawR,ylab="R",xlab="date")
points(x=dfR$date,y=dfR$gjaR,col="red")
lines(x=dfR$date,y=dfR$weeklyR, lwd=3)
lines(y=Rest$England_LowerBound,x=Rest$Date)
lines(y=Rest$England_UpperBound,x=Rest$Date)
# Wanted to plot a Smooth spline discontinuous at
#UK lockdown Oct 31 (day 98) -Dec 2  (day 130) Jan 6 (day 165)  (day 1 = July 25)

# Making the time windows agree
dat <- Rest[Rest$Date >= min(comdat$date) & Rest$Date <= max(comdat$date),]

# Plot
d1 <- as.Date("2020-10-31")
d2 <- as.Date("2020-12-02")
ggplot(dfR) +
           geom_point(aes(x=date,y=rawR),alpha=0.5) +
           geom_point(aes(x=date,y=gjaR),colour="red", alpha=0.5) +
           geom_line(aes(x=date,y=weeklyR),colour="blue") +
           geom_ribbon(data=dat,aes(Date,min=England_LowerBound,max=England_UpperBound),
                       colour="green",alpha=0.25) +
           xlab("Date") + ylab("R value")

# Zoom in
ggplot(dfR) +
  geom_point(aes(x=date,y=rawR),alpha=0.5) +
  geom_point(aes(x=date,y=gjaR),colour="red", alpha=0.5) +
  geom_line(aes(x=date,y=weeklyR),colour="blue") +
    geom_ribbon(data=dat,aes(Date,min=England_LowerBound,max=England_UpperBound),
              colour="green",alpha=0.25) + ylim(0,2.5) +
  xlab("Date") + ylab("R value")


nospl=3
test_delay=7
lock1=98+test_delay
unlock1=130+test_delay
lock2=165+test_delay

smoothweightR<-smooth.spline(dfR$bylogR,df=19,w=sqrt(comdat$allCases))
smoothweightR$date<-comdat$date
smoothweightRfp<-smooth.spline(dfR$fpR,df=19,w=sqrt(comdat$fpCases))
smoothweightRfp$date<-dfR$date
smoothR<-smooth.spline(dfR$bylogR,df=14)
smoothR98<-smooth.spline(dfR$bylogR[1:lock1],df=nospl)
smoothR98$date<-dfR$date[1:lock1]
smoothR130<-smooth.spline(dfR$bylogR[lock1:unlock1],df=nospl)
smoothR130$date<-dfR$date[lock1:unlock1]
smoothR164<-smooth.spline(dfR$bylogR[unlock1:lock2],df=nospl)
smoothR164$x=smoothR164$x+unlock1
smoothR164$date<-dfR$date[unlock1:lock2]
smoothRend<-smooth.spline(dfR$bylogR[lock2:length(dfR$date)],df=nospl)
smoothRend$x=smoothRend$x+lock2
smoothRend$date<-dfR$date[lock2:length(dfR$gjaR)]
dfR$piecewise<-dfR$gjaR
for (i in 1:lock1){dfR$piecewise[i]=smoothR98$y[i]}
for (i in lock1+1:unlock1){dfR$piecewise[i]=smoothR130$y[i-lock1]}
for (i in unlock1+1:lock2){dfR$piecewise[i]=smoothR164$y[i-unlock1]}
for (i in lock2+1:length(dfR$date)){dfR$piecewise[i]=smoothRend$y[i-lock2]}

#Plot R estimate vs data and fits discontinuous at lockdown
#  Have to move the Official R data back by 16 days !

plot(smoothweightR$y,x=smoothweightR$date,ylab="R-number",xlab="Date after Aug 25",ylim=c(0.6,1.4))
#lines(smoothweightRfp$y,x=smoothweightRfp$date,col="blue")
lines(y=Rest$England_LowerBound,x=Rest$Date-16)
lines(y=Rest$England_UpperBound,x=Rest$Date-16)
lines(dfR$piecewise,col="red",lwd=2,x=dfR$date)


lines(predict(loess(gjaR ~ x, data=dfR,span=0.1)),col='red',x=dfR$date)
lines(predict(loess(gjaR ~ x, data=dfR,span=0.2)),col='red',x=dfR$date)
lines(predict(loess(gjaR ~ x, data=dfR,span=0.3)),col='red',x=dfR$date)
lines(predict(loess(gjaR ~ x, data=dfR,span=0.5)),col='red',x=dfR$date)
lines(predict(loess(gjaR ~ x, data=dfR,span=1.0)),col='red',x=dfR$date)
plot(smoothweightR$y,ylab="R-number",xlab="Day")
#  Plot R continuous with many splines.  Not sure when fitting noise here!
for (ismooth in 4:28){
#   lines(smooth.spline(as.vector(gjaR),df=ismooth,w=sqrt(comdat$allCases)))
  lines(smooth.spline(dfR$weeklyR,df=ismooth),col="blue")}
points(dfR$bylogR, col = "red")
lines(smooth.spline(dfR$bylogR,df=14))
# Plot the UB and LB for the UK R estimates, have added a line commented out
# where you can plot your estimate for the R value - add your own data frame
# change date and R to what you called the columns - you probably have to have
# the same number of values corresponding to the same time frame - you may
# also want the range for England rather than the UK. Remove these lines they
# are for your benefit Graeme. You probably wnat to move this plot until after
# you have calculated your own Restimate.
Rest %>% ggplot(aes(x=Date)) + geom_ribbon(aes(Date,min=England_LowerBound,max=England_UpperBound),colour="red",alpha=0.25) +
  ylab("R Estimate") + xlab("Date")  # + geom_line(comdat,aes(date,R))


#Reverse Engineer cases from R-number - requires stratonovich calculus to get reversibility
# Initializations
#rm(PredictCases,PredictCasesSmoothR)
PredictCases <- dfR$bylogR
PredictCasesRaw <- dfR$rawR
PredictCasesSmoothR<- dfR$bylogR
PredictCasesMeanR<- dfR$bylogR
PredictCasesLin <-dfR$gjaR
#  Use the same weekend-adjusted initial condition, regardless of smoothing effect
PredictCases[1]=comdat$allCases[1]
PredictCasesRaw[1]=PredictCases[1]
PredictCasesSmoothR[1]=PredictCases[1]
PredictCasesMeanR[1]<- PredictCases[1]
smoothR<-smooth.spline(dfR$bylogR,df=24)
meanR=mean(dfR$rawR)
for(i in 2:length(dfR$gjaR)){
  PredictCases[i]=PredictCases[i-1]*exp((dfR$bylogR[i]-1)/genTime)
  PredictCasesLin[i]=PredictCases[i-1]*(1.0+(dfR$gjaR[i]-1)/genTime)
  PredictCasesRaw[i]=PredictCasesRaw[i-1]*(1.0+(dfR$rawR[i]-1)/genTime)
  PredictCasesMeanR[i]=PredictCasesMeanR[i-1]*(1.0+(dfR$meanR-1)/genTime)
  
#  Averaging R is not the same as averaging e^R
#  Noise suppresses the growth rate in the model, Smoothed R grows too fast
   ri=smoothR$y[i]  # Fudge factor *0.94663
#   Multiplier chosen to match final cases with df=24
    PredictCasesSmoothR[i]=PredictCasesSmoothR[i-1]*(1.0+(ri-1)/genTime)
  }
plot(PredictCases,x=dfR$date,xlab="Date",ylab="Cases backdeduced from R")
lines(comdat$allCases,x=comdat$date, col="red")
lines(PredictCasesSmoothR,x=dfR$date, col="blue",lwd=2)
#lines(PredictCasesMeanR,x=comdat$date, col="green")
lines(PredictCasesLin,x=comdat$date, col="orange")
sum(PredictCases)
sum(PredictCasesSmoothR)
sum(PredictCasesMeanR)
sum(PredictCasesLin)
sum(comdat$allCases)
#####  Figures and analysis for https://www.medrxiv.org/content/10.1101/2021.04.14.21255385v1


####  From here on we're reproducing figures from https://www.medrxiv.org/content/10.1101/2021.04.14.21255385v1
##### Fig 1. - Heatmaps ####
groups = colnames(casedat[2:20])
# casemelt = melt(as.matrix(casedat[2:20]))
# deathmelt = melt(as.matrix(deathdat[2:20]))
# colourscheme = rgb(1-rescale(casemelt$value), 1, 1-rescale(deathmelt$value))
# casemelt$value2 = colourscheme
# casemap = ggplot() +
#   geom_tile(data = casemelt, aes(Var1, Var2, fill = value)) +
#   scale_fill_gradient(low = "white", high = "blue") +
#   new_scale_fill() +
#   geom_tile(data = deathmelt, aes(Var1, Var2, fill = value)) +
#   scale_fill_gradient(low = "black", high = "red") +
#   new_scale_fill() +
#   geom_tile(data = casemelt, aes(Var1, Var2, fill = value2)) +
#   scale_fill_identity() +
#   labs(x = "Date", y = "Age Group") +
#   theme(legend.position = "none",
#         panel.grid.major = element_blank(),
#         panel.border = element_blank(),
#         panel.background = element_blank())
# print(casemap)
# rm(casemap, casemelt, deathmelt, colourscheme)
#

image(casedat$date, 1:19, as.matrix(casedat[2:20]),
      xlab = "Time", ylab = "Age group", col = hcl.colors(96, "Blues", rev = TRUE),
      axes = F, mgp = c(3.3, 1, 0))
axis.Date(1, at=seq(min(casedat$date), max(casedat$date), by="1 month"), format="%m-%Y")
axis(2, 1:19, labels = groups, las = 1, cex.axis = 0.8)
title(main = "Cases and Deaths")


deathmap = image(deathdat$date, 1:19, as.matrix(deathdat[2:20]),
                xlab = "", ylab = "", col = hcl.colors(96, "Reds", rev = TRUE),
                axes = F, mgp = c(3.3, 1, 0))
axis.Date(1, at=seq(min(deathdat$date), max(deathdat$date), by="1 month"), format="%m-%Y")
axis(2, 1:19, labels = groups, las = 1, cex.axis = 0.8)
title(main = "Deaths heatmap")
rm(deathmap, groups)

#### AGE GROUPS - Lognormal distribution ####
##We are fixing parameters at the clinical levels from Hawryluk et al.
logmean = 2.534
logsd = 0.613
lndist = dlnorm(1:28, logmean, logsd) #params from Hawryluk et al.
ggplot(data.frame(index = 1:28, prop = lndist)) +
  geom_point(aes(x = index, y = prop)) +
  labs(title = "Discretised Lognormal Distribution (Hawryluk)") +
  xlab("Time to Death") +
  ylab("Proportion of day zero cases")
rm(logmean, logsd)

#### AGE GROUPS - Gamma distribution ####
##We are fixing alpha at the clinical level of 4.447900991. Verity et al. find a global beta of 4.00188764
alpha = 4.447900991
beta = 4.00188764
gamdist = dgamma(1:28, shape = alpha, scale = beta) #params from Verity et al.
ggplot(data.frame(index = 1:28, prop = gamdist)) +
  geom_point(aes(x = index, y = prop)) +
  labs(title = "Discretised Gamma Distribution (Verity)") +
  xlab("Time to Death") +
  ylab("Proportion of day zero cases")
rm(alpha, beta)

#Spread each age group's cases by the distribution
logcases <- casedat
gamcases <- logcases
logcases[2:20] = NA_real_
gamcases[2:20] = NA_real_
for (agegroup in 2:20) {
  for (day in 28:nrow(logcases)) {
    logcases[day,agegroup] = sum(casedat[(day-27):day,agegroup] * rev(lndist))
    gamcases[day,agegroup] = sum(casedat[(day-27):day,agegroup] * rev(gamdist))
  }
}
rm(agegroup, day)

#Spread all cases by the distribution
comdat$logcaseload = 0
comdat$gamcaseload = 0
for (day in 28:nrow(comdat)) {
  comdat$logcaseload[day] = sum(comdat$allCases[(day-27):day] * rev(lndist))
  comdat$gamcaseload[day] = sum(comdat$allCases[(day-27):day] * rev(gamdist))
}
scotdat$logcaseload = 0
scotdat$gamcaseload = 0
for (day in 28:nrow(comdat)) {
  scotdat$logcaseload[day] = sum(scotdat$allCases[(day-27):day] * rev(lndist))
  scotdat$gamcaseload[day] = sum(scotdat$allCases[(day-27):day] * rev(gamdist))
}
#  Spread Regional cases by the lognormal & gammadistribution
reglnpredict<-regdeaths
reggampredict<-regdeaths
for (area in 2:10){
for (day in 28:nrow(comdat)){
  reglnpredict[day,area] = sum(regcases[(day-27):day,area] * rev(lndist))
  reggampredict[day,area] = sum(regcases[(day-27):day,area] * rev(gamdist))}}
rm(day,area)


#  Regional plots, with CFR input by hand


plot(regdeaths$London*55,x=regdeaths$date)
lines(reglnpredict$London,x=reglnpredict$date)
lines(reggampredict$London,x=reglnpredict$date)

plot(regdeaths$`North East`*55,x=regdeaths$date)
lines(reglnpredict$`North East`,x=reglnpredict$date)
plot(regdeaths$`North West`*55,x=regdeaths$date)
lines(y=reglnpredict$`North West`,x=reglnpredict$date)
lines(reglnpredict$`South West`,x=reglnpredict$date)
lines(reglnpredict$`South East`,x=reglnpredict$date)
lines(reglnpredict$`East Midlands` ,x=reglnpredict$date)
lines(reglnpredict$`East of England`,x=reglnpredict$date)
lines(reglnpredict$`West Midlands`,x=reglnpredict$date)
lines(reglnpredict$`Yorkshire and The Humber`,x=reglnpredict$date)

for (area in 2:10){
  lines(reglnpredict[2:279,area])}
#Plots
logcasesageplot = ggplot(logcases, aes(x = date)) +
  geom_line(aes(y = rowSums(logcases[,2:20]))) +
  ggtitle("All age groups separately lognormal distributed")
logcasesageplot
rm(logcasesageplot)





plot#### Fig 2. Distributions ####
distdat = data.frame(days = 1:29, ln = c(lndist, 0), gam = c(gamdist, 0), exp = c(dexp(1:28, rate = 0.1), 0),
                     shift = c(rep(0, 14), 1, rep(0, 14)),
                     avgshift = c(rep(0, 11), rep((1/7),7), rep(0, 11)))
ggplot(data = distdat, aes(x = days)) +
  geom_line(aes(y = ln, color = "Lognormal"), size = 1) +
  geom_line(aes(y = gam, color = "Gamma"), size = 1) +
  geom_line(aes(y = exp, color = "Exponential"), size = 1) +
  geom_line(aes(y = shift, color = "Shift"), size = 1) +
  geom_line(aes(y = avgshift, color = "7-day Average and Shift"), size = 1) +
  labs(title = "Distributions", y = "Fraction of Deaths", x = "Days after case detected",
       colour = "Legend") +
  scale_color_manual(values = c("Lognormal" = "red", "Gamma" = "blue", "Exponential" = "green", "Shift" = "orange", "7-day Average and Shift" = "maroon")) +
  scale_x_continuous(breaks =  0:30) +
  coord_cartesian(ylim=c(0, 0.15)) +
  theme_bw()


#### AGE GROUPS - Gamma Model ####
#Calculate age-group CFRs to fit Oct-Nov from Gamma
gamageweights = data.frame(agegroup = names(casedat[2:20]), weight = 0, lowerbound = 0, upperbound = 0)
for (agegroup in 2:20) {
  daterange = seq.Date(as.Date("2020-10-01"), as.Date("2020-11-30"), by = "day")
  thesedeaths = unlist(filter(deathdat, date %in% daterange)[,agegroup])
  thesecases = unlist(filter(gamcases, date %in% daterange)[,agegroup])
  model = summary(lm(thesedeaths ~ thesecases))
  gamageweights[agegroup-1, "weight"] <- coef(model)[2,1]
  gamageweights[agegroup-1, "lowerbound"] <- coef(model)[2,1] - (2*coef(model)[2,2])
  gamageweights[agegroup-1, "upperbound"] <- coef(model)[2,1] + (2*coef(model)[2,2])
}
write.csv(gamageweights[10:19,], "forpub.csv")
rm(model)

gampred = gamcases
for (agegroup in 2:20) {
  gampred[,agegroup] = gamcases[, agegroup] * gamageweights$weight[agegroup-1]
}
gampred$allCasesPred = rowSums(gampred[,2:20])

#### AGE GROUPS - Lognormal Model ####
#Calculate age-group CFRs to fit Oct-Nov from Lognormal
logageweights = data.frame(agegroup = names(casedat[2:20]), weight = 0, lowerbound = 0, upperbound = 0)
for (agegroup in 2:20) {
  daterange = seq.Date(as.Date("2020-10-01"), as.Date("2020-11-30"), by = "day")
  thesedeaths = unlist(filter(deathdat, date %in% daterange)[,agegroup])
  thesecases = unlist(filter(logcases, date %in% daterange)[,agegroup])
  model = summary(lm(thesedeaths ~ thesecases))
  logageweights[agegroup-1, "weight"] <- coef(model)[2,1]
  logageweights[agegroup-1, "lowerbound"] <- coef(model)[2,1] - (2*coef(model)[2,2])
  logageweights[agegroup-1, "upperbound"] <- coef(model)[2,1] + (2*coef(model)[2,2])
}
rm(model)

logpred = logcases
for (agegroup in 2:20) {
  logpred[,agegroup] = logcases[, agegroup] * logageweights$weight[agegroup-1]
}
logpred$allCasesPred = rowSums(logpred[,2:20])

#### Original WSS (hardcoded) ####
WSS = data.frame(date = c("28/07/2020", "29/07/2020", "30/07/2020", "31/07/2020", "01/08/2020", "02/08/2020", "03/08/2020", "04/08/2020", "05/08/2020", "06/08/2020", "07/08/2020", "08/08/2020", "09/08/2020", "10/08/2020", "11/08/2020", "12/08/2020", "13/08/2020", "14/08/2020", "15/08/2020", "16/08/2020", "17/08/2020", "18/08/2020", "19/08/2020", "20/08/2020", "21/08/2020", "22/08/2020", "23/08/2020", "24/08/2020", "25/08/2020", "26/08/2020", "27/08/2020", "28/08/2020", "29/08/2020", "30/08/2020", "31/08/2020", "01/09/2020", "02/09/2020", "03/09/2020", "04/09/2020", "05/09/2020", "06/09/2020", "07/09/2020", "08/09/2020", "09/09/2020", "10/09/2020", "11/09/2020", "12/09/2020", "13/09/2020", "14/09/2020", "15/09/2020", "16/09/2020", "17/09/2020", "18/09/2020", "19/09/2020", "20/09/2020", "21/09/2020", "22/09/2020", "23/09/2020", "24/09/2020", "25/09/2020", "26/09/2020", "27/09/2020", "28/09/2020", "29/09/2020", "30/09/2020", "01/10/2020", "02/10/2020", "03/10/2020", "04/10/2020", "05/10/2020", "06/10/2020", "07/10/2020", "08/10/2020", "09/10/2020", "10/10/2020", "11/10/2020", "12/10/2020", "13/10/2020", "14/10/2020", "15/10/2020", "16/10/2020", "17/10/2020", "18/10/2020", "19/10/2020", "20/10/2020", "21/10/2020", "22/10/2020", "23/10/2020", "24/10/2020", "25/10/2020", "26/10/2020", "27/10/2020", "28/10/2020", "29/10/2020", "30/10/2020", "31/10/2020", "01/11/2020", "02/11/2020", "03/11/2020", "04/11/2020", "05/11/2020", "06/11/2020", "07/11/2020", "08/11/2020", "09/11/2020", "10/11/2020", "11/11/2020", "12/11/2020", "13/11/2020", "14/11/2020", "15/11/2020", "16/11/2020", "17/11/2020", "18/11/2020", "19/11/2020", "20/11/2020", "21/11/2020", "22/11/2020", "23/11/2020", "24/11/2020", "25/11/2020", "26/11/2020", "27/11/2020", "28/11/2020", "29/11/2020", "30/11/2020", "01/12/2020", "02/12/2020", "03/12/2020", "04/12/2020", "05/12/2020", "06/12/2020", "07/12/2020", "08/12/2020", "09/12/2020", "10/12/2020", "11/12/2020", "12/12/2020", "13/12/2020", "14/12/2020", "15/12/2020", "16/12/2020", "17/12/2020", "18/12/2020", "19/12/2020", "20/12/2020", "21/12/2020", "22/12/2020", "23/12/2020", "24/12/2020", "25/12/2020", "26/12/2020", "27/12/2020", "28/12/2020", "29/12/2020", "30/12/2020", "31/12/2020", "01/01/21", "02/01/21", "03/01/21", "04/01/21", "05/01/21", "06/01/21", "07/01/21", "08/01/21", "09/01/21", "10/01/21", "11/01/21", "12/01/21", "13/01/21", "14/01/21", "15/01/21", "16/01/21"),
                 values = c(15,15,14,15,16,16,17,17,17,18,19,18,17,17,17,16,16,14,13,13,13,12,12,12,12,12,12,12,13,14,14,13,15,20,24,27,29,31,38,41,39,39,39,38,38,36,37,39,40,41,43,46,48,50,53,58,61,63,64,70,76,81,86,94,101,107,117,125,136,144,151,152,156,165,172,177,185,194,204,210,222,239,251,264,274,280,287,294,294,297,304,312,313,314,337,347,356,356,359,365,374,373,383,391,397,402,402,398,391,383,369,355,340,332,322,305,293,284,277,273,267,266,268,268,267,268,269,271,275,274,277,285,297,309,320,333,356,374,392,409,425,437,447,466,487,502,497,459,483,516,510,589,646,690,730,778,801,890,884,889,918,980,959,939,921,904,885,870,849,821,856,804,751))
WSS$date = dmy(WSS$date)
WSS$date = WSS$date + 12

#### Model Fit Stats ####
#Get Autumn model fits
model = lm(filter(comdat, date %in% daterange)$allDeaths ~ filter(gampred, date %in% daterange)$allCasesPred)
summary(model)

model = lm(filter(comdat, date %in% daterange)$allDeaths ~ filter(logpred, date %in% daterange)$allCasesPred)
summary(model)

model = lm(filter(comdat, date %in% daterange)$allDeaths ~ filter(WSS, date %in% daterange)$values)
summary(model)

#Get overall model fits
model = lm(comdat$allDeaths ~ gampred$allCasesPred)
summary(model)

model = lm(comdat$allDeaths ~ logpred$allCasesPred)
summary(model)

model = lm(filter(comdat, date %in% WSS$date)$allDeaths ~ WSS$values)
summary(model)
rm(model)

#### Model plots ####
#Plot prediction against reality
ggplot(data = comdat, aes(x = date)) +
  geom_line(mapping = aes(y = allDeaths, color = "Deaths (Government Figures)"), size = 1) +
  geom_line(data = gampred, aes(y = allCasesPred, color = "Gamma Model Predicted Deaths"), size = 1) +
  geom_line(data = logpred, aes(y = allCasesPred, color = "Lognormal Model Predicted Deaths"), size = 1) +
  geom_line(data = WSS, aes(y = values, color = "WSS Original"), size = 1) +
  labs(title = "Predicted Deaths vs. Actual Deaths", color = "Legend") +
  ylab("Deaths") +
  xlab("Date") +
  scale_color_manual(values = c("Deaths (Government Figures)" = "Blue",
                                "Gamma Model Predicted Deaths" = "Red",
                                "Lognormal Model Predicted Deaths" = "Green",
                                "WSS Original" = "Orange")) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  theme_bw()


#### Plot all lognormal-derived CFRs ####
rollframe = as.data.frame(apply(logcases[,2:20], 2, rollmean, 7, na.pad = T))
rollframe$date = logcases$date
rollframe = pivot_longer(rollframe, cols = colnames(logcases[11:20]),
                         names_to = "agegroup", names_prefix = "X", values_to = "Cases")

deathroll = as.data.frame(apply(deathdat[,2:20], 2, rollmean, 7, na.pad = T))
deathroll$date = deathdat$date
deathframe = pivot_longer(deathroll, cols = colnames(deathdat[11:20]),
                         names_to = "agegroup", names_prefix = "X", values_to = "Deaths")

rollframe$Deaths = deathframe$Deaths
rollframe$CFR = rollframe$Deaths/rollframe$Cases
rm(deathframe)
rollframe = rollframe[301:(nrow(rollframe)-30),]

plot = ggplot() +
  geom_line(data = rollframe, aes(x = date, y = CFR, color = agegroup), size = 1.1) +
  scale_colour_manual(values = rev(brewer.pal(10,"Set3"))) +
  labs(title = paste("Case Fatality Ratios by age group -  7-day rolling averages"),
       subtitle = "Lognormal model",
       x = "Date", y = "CFR") +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  theme_bw() +
  geom_rect(aes(xmin=as.Date("2020/12/01"), xmax=as.Date("2021/01/16"), ymin=0, ymax=Inf), fill = "red", alpha = 0.1) +
  geom_rect(aes(xmin=as.Date("2021/01/17"), xmax=Sys.Date(), ymin=0, ymax=Inf), fill = "green", alpha = 0.1)
print(plot)


