# libraries are loaded by setup_environment file

# library(odbc)
# library(DBI)
# library(purrr)
# library(zip)


# walk(list.files(here::here("functions"), full.names = TRUE), source)

#database connection
con <- dbConnect(odbc(), dsn = "SMRA", uid = .rs.askForPassword("SMRA Username:"), 
                 pwd = .rs.askForPassword("SMRA Password:"))

#update data quality tab
walk(list.files(here::here("code/data_quality_tab"), full.names = TRUE), source)

#update clinical coding tab
walk(list.files(here::here("code/clinical_coding_tab"), full.names = TRUE), source)

#close database connection 
dbDisconnect(con)
rm(con)

#save a zipped copy of the data
data_list <- paste0(here::here("data"))
zip::zip(paste0(here::here("data_archive", "dq_dashboard_data_"),
           Sys.Date(), ".zip"), data_list, mode="cherry-pick")

#clear environment
rm(list=ls())

