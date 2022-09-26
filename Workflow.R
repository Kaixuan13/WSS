# Remove existing variables if in an interactive session.grg
if(interactive()){
  rm(list = ls())
}
source("./getParms.R")
source("./covid_trimmed.r")
source("./ScottishData.R")
source("./Regional.R")
