# libraries are loaded by setup_environment file

# library(readr)
# library(tidyr)
# library(dplyr)
# library(stringr)


# Extract SMR02 data -----------------------------------------------------

# con <- dbConnect(odbc(), dsn = "SMRA", uid = .rs.askForPassword("SMRA Username:"), 
#                  pwd = .rs.askForPassword("SMRA Password:"))


smr02_diabetes <- dbGetQuery(con, "SELECT MAIN_CONDITION, OTHER_CONDITION_1, OTHER_CONDITION_2, OTHER_CONDITION_3, 
                         
                         OTHER_CONDITION_4, OTHER_CONDITION_5, DIABETES, DISCHARGE_DATE,
                         
                         EPISODE_RECORD_KEY, HBTREAT_CURRENTDATE, LOCATION
                         
                         FROM ANALYSIS.SMR02_PI
                         
                         WHERE
                         (discharge_date BETWEEN {d to_date('2017-01-01', 'YYYY-MM-DD')} AND SYSDATE)
                         AND
                         CONDITION_ON_DISCHARGE = '3'
                         AND 
                         (DIABETES IN ('1', '2', '3') 
                         OR MAIN_CONDITION LIKE 'O24%'
                         OR OTHER_CONDITION_1 LIKE 'O24%'
                         OR OTHER_CONDITION_2 LIKE 'O24%'
                         OR OTHER_CONDITION_3 LIKE 'O24%'
                         OR OTHER_CONDITION_4 LIKE 'O24%'
                         OR OTHER_CONDITION_5 LIKE 'O24%')")

# RODBC::odbcCloseAll() #close all open rodbc connections


#Read in hb_lookup file:
hb_lookup <- read_csv(here::here("lookups", "hb_lookup.csv"))

#append hb names to diagnosis2 dataframe
diagnosis2 <- left_join(smr02_diabetes, hb_lookup[c(1:2)], by = c("HBTREAT_CURRENTDATE"="HB"))

diagnosis2 <- diagnosis2 %>% 
  mutate(
    year = (substr(DISCHARGE_DATE, 1, 4))
    )

# Error Counts ------------------------------------------------------------
non_error1 <- c("O240", "O241", "O242", "O243")
exc_error1 <- c("O244", "O249") 
years <- unique(diagnosis2$year)
error_1_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(DIABETES == 1, year %in% years) %>% 
  mutate(
    error_1 = case_when(
      MAIN_CONDITION %in% non_error1 | OTHER_CONDITION_1 %in% non_error1 | OTHER_CONDITION_2 %in% non_error1 | OTHER_CONDITION_3 %in% non_error1 | 
        OTHER_CONDITION_4 %in% non_error1 | OTHER_CONDITION_5 %in% non_error1 & !(MAIN_CONDITION %in% exc_error1) & !(OTHER_CONDITION_1 %in% exc_error1) &
        !(OTHER_CONDITION_2 %in% exc_error1) & !(OTHER_CONDITION_3 %in% exc_error1) & !(OTHER_CONDITION_4 %in% exc_error1) & 
        !(OTHER_CONDITION_5 %in% exc_error1) ~ 'no error', 
      TRUE ~ 'error 1')
  ) %>%
  summarise(error = sum(error_1 == "error 1"), denominator = sum(DIABETES == 1))%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_1_table <- error_1_table[, c('HBName', 'year', "error", "percentage"), drop = F]


error_2_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(DIABETES == 2, year %in% years) %>%
  mutate(
    error_2 = case_when(
      MAIN_CONDITION == 'O244' | OTHER_CONDITION_1 == 'O244' | OTHER_CONDITION_2 == 'O244' |
        OTHER_CONDITION_3 == 'O244' | OTHER_CONDITION_4 == 'O244' | OTHER_CONDITION_5 == 'O244' ~ 'no error',
      TRUE ~ 'error 2')
  ) %>%
  summarise(error = sum(error_2 == "error 2"), denominator = sum(DIABETES == 2))%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_2_table <- error_2_table[, c('HBName', 'year', "error", "percentage")]

  
error_3_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(DIABETES == 3, year %in% years) %>%
  mutate(
    error_3 = case_when(
      MAIN_CONDITION == 'O249' | OTHER_CONDITION_1 == 'O249' | OTHER_CONDITION_2 == 'O249' |
        OTHER_CONDITION_3 == 'O249' | OTHER_CONDITION_4 == 'O249' | OTHER_CONDITION_5 == 'O249' ~ 'no error',
      TRUE ~ 'error 3')
  ) %>%
  summarise(error = sum(error_3 == "error 3"), denominator = sum(DIABETES == 3))%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_3_table <- error_3_table[, c('HBName', 'year', "error", "percentage")]


error_4_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(DIABETES == 4, year %in% years) %>%
  mutate(
    error_4 = case_when(
      str_detect(MAIN_CONDITION, "^O24") | str_detect(OTHER_CONDITION_1, "^O24") | str_detect(OTHER_CONDITION_2, "^O24") | str_detect(OTHER_CONDITION_3, "^O24") | 
        str_detect(OTHER_CONDITION_4, "^O24") | str_detect(OTHER_CONDITION_5, "^O24") ~ 'error 4', T ~ 'no error')
  ) %>%
  summarise(error = sum(error_4 == "error 4"), denominator = sum(DIABETES == 4))%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_4_table <- error_4_table[, c('HBName','year', "error", "percentage")]


error_5_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(year %in% years) %>% 
  mutate(
    error_5 = case_when(
      !is.na(DIABETES) ~ 'no error',
      TRUE ~ 'error 5')
  ) %>%
  summarise(error = sum(error_5 == "error 5"), denominator = n())%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_5_table <- error_5_table[, c('HBName', 'year', "error", "percentage")]


error_6_table <- diagnosis2 %>%
  group_by(HBName, year) %>%
  filter(year %in% years) %>% 
  mutate(
    error_6 = case_when(
      str_detect(MAIN_CONDITION, "^E10") | str_detect(OTHER_CONDITION_1, "^E10") | str_detect(OTHER_CONDITION_2, "^E10") | str_detect(OTHER_CONDITION_3, "^E10") | 
        str_detect(OTHER_CONDITION_4, "^E10") | str_detect(OTHER_CONDITION_5, "^E10") | str_detect(MAIN_CONDITION, "^E11") | str_detect(OTHER_CONDITION_1, "^E11") | 
        str_detect(OTHER_CONDITION_2, "^E11") | str_detect(OTHER_CONDITION_3, "^E11") | str_detect(OTHER_CONDITION_4, "^E11") | str_detect(OTHER_CONDITION_5, "^E11") |
        str_detect(MAIN_CONDITION, "^E12") | str_detect(OTHER_CONDITION_1, "^E12") | str_detect(OTHER_CONDITION_2, "^E12") | str_detect(OTHER_CONDITION_3, "^E12") | 
        str_detect(OTHER_CONDITION_4, "^E12") | str_detect(OTHER_CONDITION_5, "^E12") | str_detect(MAIN_CONDITION, "^E13") | str_detect(OTHER_CONDITION_1, "^E13") | 
        str_detect(OTHER_CONDITION_2, "^E13") | str_detect(OTHER_CONDITION_3, "^E13") | str_detect(OTHER_CONDITION_4, "^E13") | str_detect(OTHER_CONDITION_5, "^E13") |
        str_detect(MAIN_CONDITION, "^E14") | str_detect(OTHER_CONDITION_1, "^E14") | str_detect(OTHER_CONDITION_2, "^E14") | str_detect(OTHER_CONDITION_3, "^E14") | 
        str_detect(OTHER_CONDITION_4, "^E14") | str_detect(OTHER_CONDITION_5, "^E14") ~ 'error 6',
      T ~ 'no error')
  ) %>%
  summarise(error = sum(error_6 == "error 6"), denominator = n())%>%
  mutate(percentage = round(error/denominator*100, digits = 2))
error_6_table <- error_6_table[, c("HBName", 'year', "error", "percentage")]

query_1_table <- diagnosis2 %>% 
  group_by(HBName, year) %>% 
  filter(DIABETES == 9, year %in% years) %>% 
  mutate(
    query = case_when(
      str_detect(MAIN_CONDITION, "^O24") | str_detect(OTHER_CONDITION_1, "^O24") | str_detect(OTHER_CONDITION_2, "^O24") | str_detect(OTHER_CONDITION_3, "^O24") | 
        str_detect(OTHER_CONDITION_4, "^O24") | str_detect(OTHER_CONDITION_5, "^O24") ~ 'ICD present', 
      TRUE ~ 'ICD absent'
    )) %>%
  summarise(error = sum(query == 'ICD present'), denominator = sum(DIABETES == 9)) %>% 
  mutate(percentage = round(error/denominator*100, digits = 2))
query_1_table <- query_1_table[, c("HBName", 'year', "error", "percentage")]

#bind all the tables into one dataframe & and append the source table name to each row

smr02_diabetes_data <- append_source(c("error_1_table", "error_2_table", "error_3_table", 
                                       "error_4_table","error_5_table", "error_6_table", 
                                       "query_1_table"))
smr02_diabetes_data$source <- factor(smr02_diabetes_data$source, 
                                     levels = sort(unique(smr02_diabetes_data$source)),
                                ordered=TRUE)
smr02_diabetes_data$year <- factor(smr02_diabetes_data$year, levels = sort(unique(smr02_diabetes_data$year)), 
                              ordered = TRUE)
smr02_diabetes_data$HBName<- factor(smr02_diabetes_data$HBName, levels = sort(unique(smr02_diabetes_data$HBName)),
                               ordered=TRUE)

colnames(smr02_diabetes_data) <- c("Health Board", "Year", "Count", "Percentage", "Error")

# Write out all the error tables ------------------------------------------

write_rds(smr02_diabetes_data, here::here("data", "smr02_diabetes_data.rds"))
