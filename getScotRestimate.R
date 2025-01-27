#!/usr/bin/env Rscript
#
# Code to get the Scottish reproductive number (R) estimate published by the
# Scottish government. Data is made available under an Open Government Licence.
# For more details see:
# http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
#

library(tibble, warn.conflicts = FALSE, quietly = TRUE)
library(readr, warn.conflicts = FALSE, quietly = TRUE)
library(dplyr, warn.conflicts = FALSE, quietly = TRUE)
library(tidyr, warn.conflicts = FALSE, quietly = TRUE)
library(readxl, warn.conflicts = FALSE, quietly = TRUE)
library(xml2, warn.conflicts = FALSE, quietly = TRUE)
library(rvest, warn.conflicts = FALSE, quietly = TRUE)

# From stackoverflow 14469522
stop_quietly <- function() {
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

# Get the Scottish Government R estimates from the following website
baseurl <- "https://data.gov.scot/coronavirus-covid-19"

# URL data of where the information is held
r_url <- paste0(baseurl, "/data.html")

# Get the URL that holds the time series
read_html(r_url) %>%
  html_nodes(xpath = '//a[contains(text(), "Download the data")]') %>%
  html_attr("href") -> r_path

# Get the file name from the URL
file <- basename(r_path)

# Construct the full data URL
dataurl <- paste0(baseurl, "/", r_path)

# Print available data
message(paste0("\nCurrent data file available: \"",
               gsub("%20", " ", file), "\"."))

# Substitute embedded spaces by underscores.
file <- gsub("%20", "_", file)

# Remove brackets
file <- gsub("[()]", "", file)

# Create a data subdirectory if it does not exist
if (!dir.exists("data/scot-data/")) {

  dir.create("data/scot-data/")
}

# Download the file with the data if it does not already exist
if (!file.exists(paste0("data//scot-data/", file))) {
  download.file(dataurl, destfile = paste0("data/scot-data/", file),
                quiet = TRUE)
}else{
  message("Data file already exists locally, not downloading again.
          Terminating ...\n\n")
  stop_quietly()
}

# Read the contents of the file
# skip the first 3 rows, suppress warning messages about Notes not being dates.
options(warn = -1)
r_est <- suppressMessages(read_excel(paste0("data/scot-data/", file),
                                    sheet = "1.1_R", skip = 3,
                                    col_types = c("date", "text", "numeric")))
options(warn = 1)

# Remove null values
r_est %>% filter(!is.na(Date)) -> r_est

# Get rid of the time in the dates
r_est$Date <- as.Date(r_est$Date, format = "%Y-%m-%d")

# Change into a wide format
r_est %>% pivot_wider(names_from = Variable, values_from = Value) %>%
          select(Date, R_LowerBound = `R lower bound`,
                 R_UpperBound = `R upper bound`) -> r_est

# Write the data to a CSV file
outfile <- "data/R_scottish_estimate.csv"
write_csv(r_est, file = outfile)

# Write message saying data has been output
message("Data has been output to ", outfile, ".")

