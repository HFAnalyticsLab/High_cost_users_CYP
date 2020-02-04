# =======================================================
# Project: HCU CYP
# Purpose: Identify chronic conditions
# Author: Kathryn Dreyer
# Date: 01/11/2019
# =======================================================

library(here)
library(tidyverse)
library(tidylog)


##############################################################################################################
#Import data and identify CYP

#Extract patids
pat_list <- select(CYP_clean, c(patid, startage))

#Import raw diagnosis data
SAS_diag <- read_sas(".../SAS/Data/raw/hes_diagnosis_epi_17_150r.sas7bdat")
nrow(SAS_diag)

#Identify CYP patients
CYP_SAS_diag <- SAS_diag %>% 
  mutate(CYP = ifelse(patid %in% pat_list$patid, 1, 0)) %>% #identify CYP in data
  filter(CYP == 1) #select CYP only

nrow(CYP_SAS_diag)

#Import date of death data
CYP_SAS_dod <- read_sas(".../SAS/Data/raw/death_patient_17_150r.sas7bdat")

#Import comorbidity code lists
CYP_cancer <- read.csv(here::here("Data","CM_cancer.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'cancer')

CYP_cardiovascular <- read.csv(here::here("Data","CM_cardiovascular.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'cardiovascular')

CYP_infection <- read.csv(here::here("Data","CM_infection.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'infection')

CYP_mentalhealth <- read.csv(here::here("Data","CM_mentalhealth.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'mentalhealth')

CYP_metabolic <- read.csv(here::here("Data","CM_metabolic.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'metabolic')

CYP_musculoskeletal <- read.csv(here::here("Data","CM_musculoskeletal.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'musculoskeletal')

CYP_neurological <- read.csv(here::here("Data","CM_neurological.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'neurological')

CYP_nonspecific <- read.csv(here::here("Data","CM_nonspecific.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'nonspecific')

CYP_respiratory <- read.csv(here::here("Data","CM_respiratory.csv")) %>% 
  gather(key = 'crit', value = 'icd') %>% 
  filter(!is.na(icd) & icd != '') %>% 
  mutate(type = 'respiratory')

CYP_combined <- rbind(CYP_cancer, CYP_cardiovascular, CYP_infection, CYP_mentalhealth, CYP_metabolic, CYP_musculoskeletal,
                      CYP_neurological, CYP_nonspecific, CYP_respiratory)

##############################################################################################################
#Create severity flag: LOS > 3 days and date of death more than 30 days after the discharge date of the admission for the code

#Calculate spell LOS
CYP_spell <- select(CYP_SAS_diag, c(spno, epistart, epiend))

CYP_spell <- CYP_spell %>% 
  group_by(spno) %>% 
  mutate(spstart = min(epistart)) %>% 
  mutate(spend = max(epiend))

CYP_spell_calc <- select(CYP_spell, c(spno,spstart,spend))

CYP_spell_calc <- CYP_spell_calc %>% 
  distinct(spno,spstart,spend) %>% #get distinct spells
  mutate(spell_LOS = spend - spstart + 1) %>% #count day admissions as 1 day
  mutate(LOS_critera = ifelse(spell_LOS > 3, 1, 0)) #Flag for LOS severity criteria

#Join LOS back on
CYP_diag <- left_join(CYP_SAS_diag, CYP_spell_calc, by = c("spno" = "spno"))

#Get date of death
CYP_dod <- select(CYP_SAS_dod, c(patid, dod))

#Link on dod
CYP_diag <- left_join(CYP_diag, CYP_dod, by = c("patid" = "patid"))

#Calculate time between spell and dod 
CYP_diag <- CYP_diag %>% 
  mutate(t_death = dod - spend) %>% #calculate time between discharge and death
  mutate(t_death = replace_na(t_death, 999)) %>% #replace NAs with a high number to create a flag
  mutate(dod_critera = ifelse(t_death > 30, 1, 0)) #Flag for admissions where discharge is more than 30 days before dod

#Create severity flag
CYP_diag <- CYP_diag %>% 
  mutate(sev_crit = ifelse(dod_critera == 1 & LOS_critera == 1, 1, 0))

##############################################################################################################
#Create age flag

#Create age flag: age > 10
pat_age <-  pat_list %>% 
  mutate(age_crit = ifelse(startage > 10, 1, 0))

#Link on age flag
CYP_diag <- left_join(CYP_diag, pat_age, by = c("patid" = "patid"))

#Select relevant variables
CYP_diag_final <- select(CYP_diag, c(patid, ICD, age_crit, sev_crit))

##############################################################################################################
#Clean ICD10 codes

CYP_diag_final <- CYP_diag_final %>% 
  mutate(ICD1 = str_replace_all(ICD, "[[:punct:]]", "")) %>% #remove all punctuation
  mutate(ICD2 = str_pad(ICD1, 4, "right", pad = "0")) #add a zero to ensure all codes are 4 digits

CYP_diag_final <- select(CYP_diag_final,c(patid, ICD2, age_crit, sev_crit))

CYP_diag_final <- CYP_diag_final %>% 
  distinct(patid, ICD2, age_crit, sev_crit) #remove any duplicates

#check frequency
#ICD_freq <- ftable(CYP_diag_crit$ICD2)
#view(ICD_freq)

##############################################################################################################
#Create comorbidity flags

#Function to create flags based on criteria
checkCondition <- function(data, ICD_table, condition){
  
  condition_sym <- sym(condition)
  
  codes <- ICD_table %>% 
    filter(type == condition)
  
  data <- data %>% 
    mutate(!!condition_sym := case_when(ICD2 %in% codes$icd[codes$crit == 'no_crit'] ~ 1,
                            ICD2 %in% codes$icd[codes$crit == 'age_crit'] & age_crit == 1 ~ 1,
                            ICD2 %in% codes$icd[codes$crit == 'sev_crit'] & sev_crit == 1 ~ 1,
                            TRUE ~ 0))
    
  
  return(data)
}


CYP_MM <- checkCondition(data = CYP_diag_final, ICD_table = CYP_combined, condition = 'cancer')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'cardiovascular')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'infection')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'mentalhealth')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'metabolic')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'musculoskeletal')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'neurological')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'nonspecific')
CYP_MM <- checkCondition(data = CYP_MM, ICD_table = CYP_combined, condition = 'respiratory')


#Summarise file
CYP_MM_final <- select(CYP_MM, c(patid, cancer, cardiovascular, infection, mentalhealth, metabolic,
                                 musculoskeletal, neurological, nonspecific, respiratory))

CYP_MM_final <- CYP_MM_final %>% 
  group_by(patid) %>% 
  summarise(S_cancer = sum(cancer), 
            S_cardiovascular = sum(cardiovascular), 
            S_infection = sum(infection),
            S_mentalhealth = sum(mentalhealth), 
            S_metabolic = sum(metabolic), 
            S_musculoskeletal = sum(musculoskeletal),
            S_neurological = sum(neurological),
            S_nonspecific = sum(nonspecific),
            S_respiratory = sum(respiratory))

#Create patient level flags
CYP_MM_final <- CYP_MM_final %>% 
  mutate(F_cancer = ifelse(S_cancer > 0, 1, 0)) %>% 
  mutate(F_cardiovascular = ifelse(S_cardiovascular > 0, 1, 0)) %>% 
  mutate(F_infection = ifelse(S_infection > 0, 1, 0)) %>% 
  mutate(F_mentalhealth = ifelse(S_mentalhealth > 0, 1, 0)) %>% 
  mutate(F_metabolic = ifelse(S_metabolic > 0, 1, 0)) %>% 
  mutate(F_musculoskeletal = ifelse(S_musculoskeletal > 0, 1, 0)) %>% 
  mutate(F_neurological = ifelse(S_neurological > 0, 1, 0)) %>% 
  mutate(F_nonspecific = ifelse(S_nonspecific > 0, 1, 0)) %>% 
  mutate(F_respiratory = ifelse(S_respiratory > 0, 1, 0)) %>% 
  mutate(mm_total = F_cancer + F_cardiovascular + F_infection + F_mentalhealth + F_metabolic +
                        F_musculoskeletal + F_neurological + F_nonspecific + F_respiratory)
  
CYP_MM_final <- select(CYP_MM_final, c(patid, F_cancer, F_cardiovascular, F_infection, F_mentalhealth, F_metabolic,
                                 F_musculoskeletal, F_neurological, F_nonspecific, F_respiratory, mm_total))


#Join onto patient spine
CYP_MM_clean <- left_join(CYP_clean, CYP_MM_final, by = c("patid" = "patid"))

#Replace NA with 0s
CYP_MM_clean <- CYP_MM_clean %>% 
  mutate(F_cancer = replace_na(F_cancer, 0)) %>% 
  mutate(F_cardiovascular = replace_na(F_cardiovascular, 0)) %>% 
  mutate(F_infection = replace_na(F_infection, 0)) %>%
  mutate(F_mentalhealth = replace_na(F_mentalhealth, 0)) %>% 
  mutate(F_metabolic = replace_na(F_metabolic, 0)) %>% 
  mutate(F_musculoskeletal = replace_na(F_musculoskeletal, 0)) %>% 
  mutate(F_neurological = replace_na(F_neurological, 0)) %>% 
  mutate(F_nonspecific = replace_na(F_nonspecific, 0)) %>% 
  mutate(F_respiratory = replace_na(F_respiratory, 0)) %>% 
  mutate(mm_total = replace_na(mm_total, 0))


##############################################################################################################
#Descriptive analysis of comorbidities

CYP_MM_group <- CYP_MM_clean %>% 
  group_by(c_top5)

CYP_MM_sum <- summarise(CYP_MM_group, 
                        cyp_count = n(), 
                        cancer = sum(F_cancer),
                        cardiovascular = sum(F_cardiovascular),
                        infection = sum(F_infection),
                        mentalhealth = sum(F_mentalhealth),
                        metabolic = sum(F_metabolic),
                        musculoskeletal = sum(F_musculoskeletal),
                        neurological = sum(F_neurological),
                        non_specific = sum(F_nonspecific),
                        respiratory = sum(F_respiratory))

CYP_MM_sum_t5 <- CYP_MM_sum %>% 
  filter(c_top5 == "top 5%") %>% 
  gather("conditions", "t5_count", -c(c_top5)) %>%   
  select(-c(c_top5)) 

CYP_MM_sum_b95 <- CYP_MM_sum %>% 
  filter(c_top5 == "bottom 95%") %>% 
  gather("conditions", "b95_count", -c(c_top5)) %>% 
  select(-c(c_top5)) 

CYP_MM_sum_final <- merge(CYP_MM_sum_t5, CYP_MM_sum_b95, by = "conditions")

CYP_MM_sum_final







