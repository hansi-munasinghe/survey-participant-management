# ORCA LIFT R Code:
#   1. cleans data from screener surveys from wave 1 and 2
#   2. determining eligibility for study 
#   3. brings in list by Jade and Anne 
#   4. binds with w2 paper and phone

# Includes code from before J&A list (commented out) for reference
# If you are looking for recruitment (contact info) see code in "ORCA_recruit"
# If you are looking for QC steps, see coe in ORCA_screen_w1-2

#============================================================================
# install.packages("readxl",lib = "C:/CustomR")
# install.packages("tidyverse",lib = "C:/CustomR")
# install.packages("openxlsx",lib = "C:/CustomR")
# install.packages("stingr",lib = "C:/CustomR")
# install.packages("janitor")
# install.packages("randomizeR")
# install.packages("experiment")


# Load libraries
library(readxl)
library(tidyverse)
library(openxlsx)
library(stringr)
library(janitor)
# library(randomizeR)
# library(experiment)

setwd("I:/Projects/Active/_KC METRO/ORCA LIFT/3. Recruitment/Recruitment_DataManagement")

# Define functions ==============================================================================

# This function clean data from screener surveys 
screen_clean <- function(survey_data) {
  survey_data <- survey_data %>%
    rename_with(tolower) %>%
    rename(interested = any_of(c("q6", "q16"))) %>% # q6 vs q16 diff in phone vs online surveys
    rename(used_transit     = q5 ,
           county           = q2 ,
           county_other     = q2_4_text ,
           first_name       = q3_1 ,
           last_name        = q3_2 ,
           nickother_name   = q3_3 ,
           email            = q3_11 ,
           email_additional = q3_12 ,
           phone            = q3_4 ,
           phone_additional = q3_5 ,
           address_line1    = q3_6 ,
           address_line2    = q3_7 ,
           address_city     = q3_8 ,
           address_state    = q3_10 ,
           address_zip      = q3_9 ,
           lang_cantonese   = q4_1 ,
           lang_chinesesimp = q4_2 ,
           lang_chinesetrad = q4_3  ,
           lang_english     = q4_4  ,
           lang_mandarin    = q4_5  ,
           lang_somali      = q4_6 ,
           lang_spanish     = q4_7 ,
           lang_vietnamese  = q4_8  ,
           survey_email     = q15_1 ,
           survey_text      = q15_2 ,
           survey_phone     = q15_4 ,
           survey_mail      = q15_5 ,
           program_abd      = q7_1  ,
           program_hen      = q7_2  ,
           program_hud      = q7_3  ,
           program_section8 = q7_4 ,
           program_pwa      = q7_5  ,
           program_wic      = q7_6 ,
           program_pm       = q7_7 ,
           program_rca      = q7_8  ,
           program_snap     = q7_9  ,
           program_ssi      = q7_10  ,
           program_socialsec = q7_11 ,
           program_ssdi     = q7_12 ,
           program_tanf     = q7_13 ,
           program_sfa      = q7_14 ,
           program_dontknow = q7_15 ,
           program_none     = q7_16  ,
           dob_month        = q17_1 ,
           dob_day          = q17_2 ,
           dob_year         = q17_3 ,
           gender_man       = q10_1 ,
           gender_woman      = q10_2 ,
           gender_notlisted = q10_3 ,
           race_aian        = q11_1 ,
           race_asian       = q11_2 ,
           race_black       = q11_3 ,
           race_latino      = q11_4 ,
           race_nhpi        = q11_5 ,
           race_white       = q11_6 ,
           race_other       = q11_7 ,
           race_other_text  = q11_7_text ,
           householdsize    = q12,
           income_earnedincome    = q14_1 ,
           income_selfemployed   = q14_2 ,
           income_socialsecurity = q14_3 ,
           income_americorps     = q14_4 ,
           income_laborindustry  = q14_5 ,
           income_unemployment   = q14_6 ,
           income_alimony        = q14_7 ,
           income_childsupport   = q14_8 ,
           disability            = q15  ,
           info_request          = q40 ,
           info_how              = q42 ,
           sweep_enter           = q44...109,
           sweep_age             = q44...110,
    ) %>%
    slice(-(1:2)) %>% # remove first two rows
    select(-c(status,
              recipientlastname,
              recipientfirstname,
              recipientemail,
              externalreference,
              distributionchannel,
              )) %>% #remove unnecessary variables
    mutate( # change programs to T/F
      program_abd      =(program_abd == "Aged, Blind, or Disabled Cash Assistance (ABD)"),
      program_hen      =(program_hen == "Housing & Essential Needs (HEN)"),
      program_hud      =(program_hud == "Housing and Urban Development (HUD)"),
      program_section8 =(program_section8 == "Section 8 Housing"),
      program_pwa      =(program_pwa == "Pregnant Women Assistance (PWA)"),
      program_wic      =(program_wic == "Women Infants and Children (WIC)"),
      program_pm       =(program_pm == "Pregnancy Medical"),
      program_rca      =(program_rca == "Refugee Cash Assistance (RCA)"),
      program_snap     =(program_snap == "Supplemental Nutrition Assistance Program (SNAP)/EBT/Basic Food"),
      program_ssi      =(program_ssi == "Supplemental Security Income (SSI)"),
      program_socialsec=(program_socialsec == "Social Security benefits"),
      program_ssdi     =(program_ssdi == "Social Security Disability Insurance (SSDI)"),
      program_tanf     =(program_tanf == "Temporary Assistance for Needy Families (TANF)"),
      program_sfa      =(program_sfa == "State Family Assistance (SFA)"),
      program_dontknow =(program_dontknow == "I receive benefits, but I do not know the name of the program"),
      program_none     =(program_none == "None of these")
    ) %>%
    na_if(-99) %>% # change -99s to NAs
  # generate IDs
    mutate(id_first = toupper(substr(first_name, 1, 3))) %>%
    mutate(id_last = toupper(substr(last_name, 1, 3))) %>%
    unite("unique_name", id_first, id_last, sep = "-", remove = TRUE) %>% #generate IDs
    relocate(unique_name) %>%
  # clean up birthdays
    mutate(dob_month = sprintf("%02d",match(dob_month,month.name))) %>%
    mutate(dob_day = sprintf("%02d", as.integer(dob_day))) %>% # fix to 2 characters 
    mutate(dob_year = as.integer(dob_year)) %>%
    unite("dob_mdy", dob_month:dob_year, sep = "-", remove = FALSE) %>% 
    relocate(dob_mdy, .after = unique_name) %>% 
  # create ID for recruitment purposes
    unite("recruit_id", unique_name, dob_mdy, sep = "-", remove = FALSE) %>%
    relocate(recruit_id)
}

# note:
# that some people wrote in "N/A", "none" etc. into the phone number column
# these need to be removed

# Define function that takes screener data and determines eligibility and group (A vs B)
screen_eligible <- function(survey_data)
  survey_data <- survey_data %>% 
    # filter(used_transit == "Yes")  %>% # used this criteria early on but abandoned
    filter(interested == "Yes, I am interested") %>%
    left_join(county_eligible, by = c("county", "county_other", "address_city", "address_state", "address_zip")) %>%
    filter(county == "King" | county == "Snohomish" | county == "Pierce" | county_keep == 1) %>%
    filter(   is.na(address_line1) == FALSE |
              is.na(email) == FALSE |
              is.na(email_additional) == FALSE |
              is.na(phone) == FALSE |
              is.na(phone_additional) == FALSE
    ) %>%
    filter(     hh1 == "Below" |
                hh2 == "Below" |
                hh3 == "Below" |
                hh4 == "Below" |
                hh5 == "Below" |
                hh6 == "Below" |
                hh7 == "Below" |
                hh8 == "Below" |
                hh9 == "Below" |
                hh10 == "Below" |
                hh11 == "Below" |
                hh12 == "Below" |
                hh13 == "Below" |
                hh14 == "Below" |
                hh15 == "Below" |
                hh16 == "Below" |
                hh17 == "Below" |
                hh18 == "Below" |
                hh19 == "Below" |
                hh20 == "Below"
    )%>%
    # Identify experimental groups
    mutate(
      eligible_group =  case_when (
        program_abd == TRUE |
        program_hen == TRUE |
        program_pwa == TRUE |
        program_rca == TRUE |
        program_ssi == TRUE |
        program_tanf == TRUE |
        program_sfa == TRUE
                          ~ "Group A",
                      TRUE ~ "Group B"
      )
    ) %>%
    relocate(eligible_group) %>%
    filter(first_name != "test") %>%
    filter(first_name != "Test")


# Bring in data ====================================================================

# Screener surveys - wave 1 (phone and online) + wave 2 (online)
# This is what Jade and Anne worked with, so no need to bring in again

screener_w1_online <- read_csv(
  "screener_data/screener_w1+w2/FFPT Screener questions - online_March 7, 2022_19.56.csv",
  col_names = TRUE)

screener_w1_phone <- read_csv(
  "screener_data/screener_w1+w2/FFPT Screener questions - phone_March 7, 2022_19.57.csv",
  col_names = TRUE)

screener_w2_online <- read_csv(
  "screener_data/screener_w1+w2/ORCA LIFT Wave 2 Screener questions - online_March 7, 2022_19.55.csv",
  col_names = TRUE)

# Bring in list by Jade and Anne ( assume = w1 online and phone + w2 online)
editedlist <- read_excel(
  "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\5. Data collection\\Participant Management\\recovery\\EDITEDLIST_Participant list PRIMARY updated 4-6 v1.xlsx",
  sheet = "List with updated contact info",
  col_names = TRUE,
  guess_max = 2500) # this step is slow - time to drink water!
  # guess_max tells R how many rows to look at to determine data type
  # needed when many rows are empty - will incorrectly think columns are T/F etc. 
  # but note that this makes this code slow

# wave 2 phone
screener_w2_phone <- read_csv(
  "screener_data/screener_w1+w2/ORCA LIFT Wave 2 Screener questions - phone_March 16, 2022_16.42.csv",
  col_names = TRUE)

# wave 2 paper (note - wave 1 had no paper surveys)
# this was compiled by Jade with support from language services
# note - rough paper surveys - doing this last min to get demographics to client. clean later
screener_w2_paper <- read_csv(
   "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\3. Recruitment\\Recruitment_DataManagement\\screener_data\\screener_w2\\ORCA LIFT Paper survey clean 4-13-22.csv",
    col_names = T)
 

# Clean data =====================================================================

screener_w2_phone <- screener_w2_phone %>%
  screen_clean() %>%
  mutate(wave = "w2", survey_name = "ORCA LIFT Wave 2 Screener questions - phone")

screener_w2_paper <- screener_w2_paper %>%
  screen_clean()  %>%
  mutate(wave = "w2", survey_name = "paper survey")

# starting with J&A list so no longer need clean w1 online, w1 phone, w2 online
# but need w2 online for sweepstakes
screener_w1_online <- screener_w1_online %>%
  screen_clean() %>%
  mutate(wave = "w1", survey_name = "FFPT Screener questions - online")

screener_w1_phone <- screener_w1_phone %>%
  screen_clean() %>%
  mutate(wave = "w1", survey_name = "FFPT Screener questions - phone")

screener_w2_online <- screener_w2_online  %>%
  screen_clean() %>%
  mutate(wave = "w2", survey_name = "ORCA LIFT Wave 2 Screener questions - online")


# before determining eligiblity, also consider people who said county-other ===========================================
# steps:
  # Got list of "other" counties alongside address info
  # Kate went through list and identified who to keep
# fyi: w2 phone and paper surveys did not go through this process

# list of other counties
# county_other <- screener_all %>%
#   filter(county == "Other (please specify):") %>%
#   select(county, county_other, address_city, address_state, address_zip) %>%
#   distinct()

# export list
# write.xlsx(county_other, file = "screener_data/screener_w1+w2/county_other.xlsx", 
#      colNames = TRUE, rowNames = TRUE, append = FALSE, overwrite = TRUE)

# bring in "other" counties to keep
county_recoded <- read_excel(
  "screener_data/screener_w1+w2/county_other_recode.xlsx",
  sheet = "county_recode",
  col_names = TRUE)

# clean list of other counties to keep
county_eligible <- county_recoded %>%
  select(-Column1) %>%
  filter(county_keep == 1)


# Sweepstakes ====================================================================================

# merge all responses for w2 sweepstakes
# sweepstakes_all <- bind_rows(
#                           screener_w2_online,
#                           screener_w2_phone, 
#                           screener_w2_paper,
#                           )
# 
# # create column counting number of vars missing
# sweepstakes_all$na_count <- (apply(is.na(sweepstakes_all), MARGIN = 1, FUN = sum))
#                           
# # drop duplicates keeping most complete
# sweepstakes_distinct <- sweepstakes_all %>%
#   arrange(na_count)  %>% # arrange missing most first, so that...
#   distinct(unique_name, dob_mdy, .keep_all = T) %>% # ... distinct keeps the first obs
#   select(unique_name, dob_mdy, first_name, last_name, email:lang_vietnamese) %>%
#   distinct(unique_name, dob_mdy, .keep_all=T)

# pick winners - Apr 29
# winners <- sweepstakes_distinct %>%
#   sample_n(10)

# exported list of winners on Apr 29 
# write.xlsx(winners, file = "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\3. Recruitment\\Recruitment_DataManagement\\screener_data\\winners_arp29.xlsx",
#            colNames = TRUE, rowNames = TRUE, append = FALSE, overwrite = TRUE)

# not_unique <- anti_join(sweepstakes_all, sweepstakes_distinct)


# Merge data ============================================================

# notes:
# before J&A list, I merged before determining eligiblity
# reverse process - before I merged then screened, but because J&A list already went through eligibility, screen then merge

# Decide eligibility and experiment groups

eligible_w2_phone <- screen_eligible(screener_w2_phone) 
# save(eligible_w2_phone, file = "eligible_w2_phone.Rdata") # saved w2 phone (as seperate file to take to demographic and paste with messy list)

eligible_w2_paper <- screen_eligible(screener_w2_paper)
# save(eligible_w2_paper, file = "eligible_w2_paper.Rdata") # saved paper (as seperate file to take to demographic and paste with messy list)

# bind J&A list with wave 2 phone and paper
full_list <- 
  bind_rows(
    eligible_w2_phone, 
    eligible_w2_paper,
    editedlist, 
    ) %>%
  # remove unnecessary columns
  select(-("Count")) %>%
  select(-contains("Potential Duplicate")) %>%
  select(-contains("Notes on Duplicate")) %>%
  select(-contains("duplicate_potential")) %>%
  select(-contains("dif group_potential")) %>%
  select(-contains("No change, received mail")) %>%
  select(-contains("Contact Info Changed")) %>%
  select(-contains("New name")) %>% 
  select(-contains("date")) %>%
  select(-contains("tude")) %>%
  select(-("userlanguage")) %>%
  select(-("ipaddress")) %>%
  select(-("progress")) %>%
  select(-contains("duration")) %>%
  select(-("finished")) %>%
  select(-("responseid"))

  

# Create IDs
# Take info from wave to make P100001

set.seed(217)
full_list <- full_list %>%
  mutate(pid = unique_name %>% 
    as.factor() %>% 
    fct_anon(prefix = "p")
  ) %>%
  relocate(pid) %>%
# create ID for recruitment purposes
  mutate(initial_first = toupper(substr(first_name, 1, 1))) %>%
  mutate(initial_last = toupper(substr(last_name, 1, 1))) %>%
  unite("initials", initial_first, initial_last, sep = "-", remove = T) %>%
  unite("recruit_id", initials, dob_mdy, sep = "-", remove = F) %>%
  relocate(recruit_id)

# count <- full_list %>% group_by(pid) %>% tally() 

#stil finding some repeats 
repeated <- full_list %>% 
  group_by(unique_name, dob_mdy) %>% 
  mutate(count = n()) %>%
  filter(count > 1)

#drop repeats
full_list <- full_list %>%
  filter(unique_name != "TOD_PRO"	& address_line1 != "Todd") %>%
  filter(unique_name != "CAT_DAO" & address_city != "AUBURN") %>% # remove assuming older based on Jade list count
  filter(unique_name != "DOR_SAL" & address_line1 != "8805 38th ave s") %>% # remove assuming older based on Jade list count
  filter(unique_name != "JAC_COL" & address_line1 != "720 court st woodland CA") %>% # remove assuming older based on Jade list count
  filter(unique_name != "KEN_RIC" & address_state != "TN") %>% # removing the out-of-state version
  filter(unique_name != "MAR_PAR" & address_city != "KENT") %>% # remove assuming older based on Jade list count
  filter(unique_name != "RIC_MAN" & address_line1 != "1017 s i st")  %>% # remove assuming older based on Jade list count
  filter(unique_name != "TIG_ANB" & address_line1 != "9061seward park Ave S" & is.na(address_line2)) # remove assuming older based on Jade list count
  
# Yeay! Now you can remove unnecessary things from environment ===================
rm(county_eligible,
  county_recoded,
  screener_w1_online,
  screener_w1_phone,
  screener_w2_online,
  screener_w2_paper,
  screener_w2_phone,
  eligible_w2_paper,
  eligible_w2_phone,
  editedlist)
  
# Create contact information list =====================================================

count(full_list, survey_email == "Email me to take an online survey")
count(full_list, survey_text == "Text me to take an online survey")
count(full_list, survey_phone == "Call me to take the survey by phone")
count(full_list, survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")

# create dataframe for contact information (remove survey items)
# clean up contact information
baseline_contact <- full_list %>%
  # drop columns unrelated to contact info
  select(-(
    contains("used_transit") | 
    contains("interested") | 
    contains("disability") | 
    contains("q_url")
    )) %>% 
  select(-(
    starts_with("program")  | 
    starts_with("hh") | 
    starts_with("income") |
    starts_with("gender") |
    starts_with("race")
    )) %>%
  # drop columns added by A&J - most are empty or do not apply to full dataset
  select(-(
   # contains("ID", ignore.case = F) |
    contains("email_additional_2") |
    contains("address_line_additional") |
    contains("source") | # not sure what source var is - mostly NA, assuming added by Jade?
    contains("address_city_add") |
    contains("address_state_add") |
    contains("address_zip_add") |
    contains("household") # assume attempt to find shared households? not sure
    )) %>%
  # make phone numbers clean
  # remove NAs like "none"
  mutate(phone = str_replace_all(phone, "Landline", "")) %>%
  mutate(phone = str_replace_all(phone, "none", "")) %>%
  mutate(phone_additional = str_replace_all(phone, "none", "")) %>%
  # remove punctuation
  mutate(phone1_clean = str_replace_all(phone, "[[:punct:]]", "")) %>% 
  mutate(phone1_clean = str_replace_all(phone1_clean, " ", "")) %>% 
  mutate(phone1_clean = str_trunc(phone1_clean, 10, "left", ellipsis = "")) %>% 
  mutate(phone2_clean = str_replace_all(phone_additional, "[[:punct:]]", "")) %>% 
  mutate(phone2_clean = str_replace_all(phone2_clean, " ", "")) %>%    
  mutate(phone2_clean = str_trunc(phone2_clean, 10, "left", ellipsis = "")) %>%   
  # remove phone_additional (phone 2) if same as phone1
  mutate(phone2_clean = ifelse((phone1_clean == phone2_clean), NA, phone2_clean)) %>%
  # make phone numbers easy to read
  mutate(phone1_pretty = str_replace(phone1_clean,"(\\d{3})(\\d{3})(\\d{4})$","\\1-\\2-\\3")) %>%
  mutate(phone2_pretty = str_replace(phone2_clean,"(\\d{3})(\\d{3})(\\d{4})$","\\1-\\2-\\3")) %>%
  # add 1 to front of clean numbers (to text via Qualtrics)
  mutate(phone1_clean = str_c("1", phone1_clean)) %>%
  mutate(phone2_clean = str_c("1", phone2_clean)) %>%
  # put phone numbers in order
  relocate(phone1_clean, .after = phone_additional) %>%
  relocate(phone2_clean, .after = phone1_clean) %>%
  relocate(phone1_pretty, .after = phone2_clean) %>%
  relocate(phone2_pretty, .after = phone1_pretty) %>%
  # clean address info
  mutate(address_state = toupper(str_trunc(address_state, 2, "right", ellipsis = ""))) %>%   
  # clean contact info added by Jade
  rename(
    phone3 = "New phone",
    phone4 = "New phone_2",
    address2_line1 = "New address",
    address2_city = "City",
    address2_state = "State",
    address2_zip = "Zip",
    email3 = "New email"
  ) %>%
# relocate contact info added by Jade behind existing contact info
  relocate(contains("address2_"), .after = address_zip) %>%
  relocate(email3, .after = email_additional) %>%
  relocate(phone3, .after = phone_additional) %>%
  relocate(phone4, .after = phone3) %>%
  # check if people asked to be contacted a certain way but...
  # did not provide that contact info
  mutate(survey_email = 
           ifelse(
             (survey_email == "Email me to take an online survey" & is.na(email)),
             "no info",
             survey_email
           )
  ) %>%
  mutate(survey_text = 
           ifelse(
             (survey_text == "Text me to take an online survey" & is.na(phone)), 
             "no info", 
             survey_text
           )
  ) %>%
  mutate(survey_phone = 
           ifelse(
             (survey_phone == "Call me to take the survey by phone" & is.na(phone)),
             "no info",
             survey_phone)
  ) %>%
  mutate(survey_mail = 
           ifelse(
             (survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)" & is.na(address_line1)),
             "no info",
             survey_mail)
  ) %>%
  # determine contact methods for each round
  mutate(round1 = 
           case_when(
             survey_email == "Email me to take an online survey" ~ "email",
             survey_text == "Text me to take an online survey" ~ "text",
             survey_phone == "Call me to take the survey by phone" ~ "phone",
             survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)" ~ "mail",
             (!is.na(email) | !is.na(email_additional) | !is.na(email3)) ~ "email", 
             (!is.na(phone) | !is.na(phone_additional) | !is.na(phone3)) ~ "text",
             (!is.na(phone) | !is.na(phone_additional) | !is.na(phone3)) ~ "phone",
             (!is.na(address_line1) | !is.na(address_line2) |  !is.na(address2_line1)) ~ "mail",
             TRUE ~ NA_character_
           )
  ) %>%
  relocate(round1) %>%
  mutate(round2 =
           case_when(
             # when round 1 is email
             (round1 == "email" & survey_text == "Text me to take an online survey")
             ~ "text",
             (round1 == "email" & survey_phone == "Call me to take the survey by phone" )
             ~ "phone",
             (round1 == "email" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             # when round 1 is text
             (round1 == "text" & survey_phone == "Call me to take the survey by phone" )
             ~ "phone",
             (round1 == "text" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             # when round 1 is phone
             (round1 == "phone" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             TRUE ~ NA_character_
           )
  ) %>%
  relocate(round2, .after = round1) %>%
  mutate(round3 =
           case_when(
             # when round 2 is text
             (round2 == "text" & survey_phone == "Call me to take the survey by phone" )
             ~ "phone",
             (round2 == "text" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             # when round 2 is phone
             (round2 == "phone" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             TRUE ~ NA_character_
           )
  ) %>%
  relocate(round3, .after = round2) %>%
  mutate(round4 =
           case_when(
             # when method 3 is phone
             (round3 == "phone" & survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)")
             ~ "mail",
             TRUE ~ NA_character_
           )
  ) %>%
  relocate(round4, .after = round3) %>%
# language - default english
  mutate(lang_selected = 
           case_when(
             lang_english == "English" ~ "English",
             lang_cantonese == "Cantonese" ~ "Cantonese",
             lang_chinesesimp == "Chinese - Simplified" ~ "Chinese - Simplified",
             lang_chinesetrad == "Chinese - Traditional" ~ "Chinese - Traditional",
             lang_mandarin == "Mandarin" ~ "Mandarin",
             lang_somali == "Somali" ~ "Somali",
             lang_spanish == "Spanish" ~ "Spanish",
             lang_vietnamese == "Vietnamese" ~ "Vietnamese",
             TRUE ~ "English"
           )
  ) %>%
  relocate(lang_selected, .after = lang_vietnamese)



# Method numbers for Anne
# table(baseline_contact$method1)
# table(baseline_contact$method2)
# table(baseline_contact$method3)
# table(baseline_contact$method4)
# 
# tabyl(baseline_contact, method1, lang_selected) %>%
#   knitr::kable()
# 
# tabyl(baseline_contact, method2, lang_selected) %>%
#   knitr::kable()
# 
# tabyl(baseline_contact, method3, lang_selected) %>%
#   knitr::kable()
# 
# tabyl(baseline_contact, method4, lang_selected) %>%
#   knitr::kable()



# Check for people who request a method but don't provide info

# nopes <- baseline_contact %>%
#   filter(
#     (survey_email == "Email me to take an online survey" & is.na(email) ) |
#     (survey_text == "Text me to take an online survey" & is.na(phone)) |
#     (survey_phone == "Call me to take the survey by phone" & is.na(phone)) |
#     (survey_mail == "Mail me a paper survey I can mail back (postage will already be paid)" & is.na(address_line1))
#   )


  
  
  
# ALL GOOD TO HERE!
# Next steps:
# Create contact list 
# Create unique ID not connected to personal information (for LEO)
# Create unique household ID - wait on this for when we have 

  
# exported list on Apr 27 for Anne to track contact methods
# write.xlsx(baseline_contact, file = "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\5. Data collection\\baseline+contactmethods.xlsx",
#             colNames = TRUE, rowNames = TRUE, append = FALSE, overwrite = TRUE)

# exported list on May 3 for Anne to track contact methods
# write.xlsx(baseline_contact, file = "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\5. Data collection\\baseline+contactmethods_missing.xlsx",
#            colNames = TRUE, 
#            rowNames = TRUE, 
#            append = FALSE, 
#            overwrite = TRUE,
#            showNA = TRUE,
#            )


# 
# # # exported list on May 4 for Anne to track contact methods
# # baseline_contact <- baseline_contact %>%
# #   select(round1:survey_email)
# write.xlsx(baseline_contact, file = "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\5. Data collection\\Participant Management\\baseline_contactmethods\\baseline_round1_sortafixed.xlsx",
#            colNames = TRUE,
#            rowNames = TRUE,
#            append = FALSE,
#            overwrite = TRUE,
#            showNA = TRUE,
#            )
# 
baseline_r1_email <- baseline_contact %>%
  filter(round1 == "email") %>%
  select(round1:survey_email)
 
# assign emails to days
days <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
set.seed(55)
baseline_r1_email$round1_day <- print(sample(days,nrow(baseline_r1_email), replace = T))
table(baseline_r1_email$round1_day)


# export for Anne (to send to Metro)
write.xlsx(baseline_r1_email, file = "I:\\Projects\\Active\\_KC METRO\\ORCA LIFT\\5. Data collection\\Participant Management\\baseline_contactmethods\\baseline_round1_email.xlsx",
           colNames = TRUE,
           rowNames = TRUE,
           append = FALSE,
           overwrite = TRUE,
           showNA = TRUE,
)

# Household ID =================================================================

# shared contact info - address, phone, email 

# households <- eligible_all %>%
#   group_by(address_line1) %>%
#   nest()

# looking for duplicate addresses - found 760 shared add1, of which 738 are unique rows
# address_dupes <- eligible_all %>%
#   group_by(address_line1, address_line2) %>%
#   mutate(address_dupes = n()) %>%
#   ungroup() %>%
#   filter(address_dupes > 1) %>%
#   unique() # unique rows with shared address  
# 
# households <- address_dupes %>% 
#   group_by(unique_name, address_line1) %>%
#   mutate(name_dupes = n()) %>%
#   ungroup() %>%
#   filter(name_dupes <= 1) # address shared but name is not
  

# verification process - look for duplicates, use most complete info, combined with info from other rows