# =======================================================
# Project: HCU CYP
# Purpose: Identify chronic conditions
# Author: Kathryn Dreyer
# Date: 01/11/2019
# =======================================================


##############################################################################################################
#Load Libraries

pth <- "R:/R_repository"

install.packages(c("tidylog"), 
                 repos = file.path("file://", pth),
                 type = "win.binary", dependencies = TRUE)

library(haven)
library(here)
library(tidyverse)
library(naniar)
library(tidylog)

here::here()

##############################################################################################################
#Import SAS data and clean

CYP_SAS <- read_sas(here::here("Data","high_cost_cyp_1516.sas7bdat"))

CYP <- select(CYP_SAS,c(patid, startage, imd, yeardied, yeartrans, died, spells, elects, emergs, others, 
                        elcost, emcost, othcost,apctotcost, los, avlos, prevadm, prevadmchron, prevadmacut, 
                        prevcost, prevcostchron, prevcostacut, aeatts, aetotcost, opatts, optotcost, pcontacts, 
                        ptotcost, therapyrecs, bnfchaps, drugs, drugtotcost, mental, physical, total, finalcost, 
                        sex, age_cat2, fcperc2, c_top5))

CYP <- CYP %>% 
  mutate(age_cat2 = factor(age_cat2)) %>% 
  mutate(age_cat2 = fct_relevel(age_cat2, "5-9", after = 1)) %>% 
  mutate(sex = factor(sex)) %>% 
  mutate(c_top5 = factor(c_top5)) 

# Before exclusions
nrow(CYP)

CYP_clean <- CYP %>% 
  filter(died != 1) %>% #exclude CYP who died
  filter(yeartrans > 2014)

#After exclusions
nrow(CYP_clean)

##############################################################################################################
#Number of patients

sample <- CYP_clean %>% 
  count(c_top5)
sample

##############################################################################################################
#Total costs

CYP_group <- CYP_clean %>% 
  group_by(c_top5)

#Total Costs
total_costs <- summarise(CYP_group, total_cost = round(sum(finalcost)), ip_cost = round(sum(apctotcost)), 
                         ae_cost = round(sum(aetotcost)), op_cost = round(sum(optotcost)), 
                         primary_cost = round(sum(ptotcost)), drug_cost = round(sum(drugtotcost)))

total_costs

#Transform data for graph
total_costs_gg <-  total_costs %>% 
  gather("cost_cat","costs",-c(c_top5))

#Graph
total_cost_graph <- ggplot(data = total_costs_gg, aes(x = cost_cat, y = costs, fill = factor(c_top5))) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_x_discrete(limits = c("total_cost", "ip_cost", "op_cost", "ae_cost", "primary_cost", "drug_cost"), 
                   labels = c("total_cost" = "Total cost", "ip_cost" = "Inpatient care", 
                              "op_cost" = "Outpatient care", "ae_cost" = "ED care", 
                              "primary_cost" = "Primary care", "drug_cost" = "Drug Therapy")) +
  scale_fill_discrete(name = "", labels = c("Bottom 95%", "Top 5%")) +
  ylab("Total summed cost (£)") +
  xlab("") +
  scale_y_continuous(labels = scales::comma) 

ggsave(here::here("Figs","total_cost_graph.png"), plot = total_cost_graph)

##############################################################################################################
#Average costs pp

ave_costs <- summarise(CYP_group, mtotal_cost = mean(finalcost), mip_cost = mean(apctotcost), 
                       mae_cost = mean(aetotcost), mop_cost = mean(optotcost), mprimary_cost = mean(ptotcost), 
                       mdrug_cost = mean(drugtotcost))

ave_costs

#Transform data for graph
ave_costs_gg <-  ave_costs %>% 
  gather("cost_cat","mean_costs",-c(c_top5))

#Graph
ave_cost_graph <- ggplot(data = ave_costs_gg, aes(x = cost_cat, y = mean_costs, fill = factor(c_top5))) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_x_discrete(limits = c("mtotal_cost", "mip_cost", "mop_cost", "mae_cost", "mprimary_cost", "mdrug_cost"), 
                   labels = c("mtotal_cost" = "Total cost", "mip_cost" = "Inpatient care", 
                              "mop_cost" = "Outpatient care", "mae_cost" = "ED care", 
                              "mprimary_cost" = "Primary care", "mdrug_cost" = "Drug Therapy")) +
  scale_fill_discrete(name = "", labels = c("Bottom 95%", "Top 5%")) +
  ylab("Mean cost per patient (£)") +
  xlab("") +
  geom_text(aes(label = round(mean_costs)), position = position_dodge(width = 0.9), vjust = -0.5) +
  scale_y_continuous(labels = scales::comma) 


ggsave(here::here("Figs","ave_cost_graph.png"), plot = ave_cost_graph)

##############################################################################################################
#Average contacts per patient

contacts <- summarise(CYP_group, mean_primary = mean(pcontacts), mean_out = mean(opatts), 
                      mean_inpatient = mean(spells), mean_ed = mean(aeatts))

contacts

#Transform data for graph
contacts_gg <-  contacts %>% 
  gather("cost_cat","contacts",-c(c_top5))

#Graph
ave_contacts_graph <- ggplot(data = contacts_gg, aes(x = cost_cat, y = contacts, fill = factor(c_top5))) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_x_discrete(limits = c("mean_primary", "mean_out", "mean_inpatient", "mean_ed"), 
                   labels = c("mean_primary" = "Primary care contacts", "mean_out" = "Outpatient attendances", 
                              "mean_inpatient" = "Inpatient admissions", "mean_ed" = "ED attendances")) +
  scale_fill_discrete(name = "", labels = c("Bottom 95%", "Top 5%")) +
  ylab("Mean utilisation") +
  xlab("") +
  geom_text(aes(label = round(contacts,2)), position = position_dodge(width = 0.9), vjust = -0.5) 

ggsave(here::here("Figs","ave_contacts_graph.png"), plot = ave_contacts_graph)

##############################################################################################################
#Average drug utilisation per patient

drugs <- summarise(CYP_group, mean_records = mean(therapyrecs), mean_drugs = mean(drugs), mean_bnf = mean(bnfchaps))

drugs

#Transform data for graph
drugs_gg <-  drugs %>% 
  gather("drug_ut","d_counts",-c(c_top5))

#Graph
drug_use_graph <- ggplot(data = drugs_gg, aes(x = drug_ut, y = d_counts, fill = factor(c_top5))) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_x_discrete(limits = c("mean_records", "mean_drugs", "mean_bnf"), 
                   labels = c("mean_records" = "Prescription recrods", "mean_drugs" = "Drugs prescribed", 
                              "mean_bnf" = "BNF chapters")) +
  scale_fill_discrete(name = "", labels = c("Bottom 95%", "Top 5%")) +
  ylab("Mean counts") +
  xlab("") +
  geom_text(aes(label = round(d_counts,2)), position = position_dodge(width = 0.9), vjust = -0.5) 

ggsave(here::here("Figs","drug_use_graph.png"), plot = drug_use_graph)

##############################################################################################################
#Demographics - Age

age <- CYP_clean %>% 
  count(c_top5, age_cat2, name = "size") %>% 
  group_by(c_top5) %>% 
  mutate(a_percent = size / sum(size) * 100)

age

#Graph
age_graph <- ggplot(data = age, aes(x = age_cat2, y = a_percent, group = c_top5, colour = c_top5)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  ylab("Proportion of group (%)") +
  xlab("Age band") +
  expand_limits(y = 0) +
  scale_colour_discrete(name = "", labels = c("Bottom 95%", "Top 5%"))

ggsave(here::here("Figs","age_graph.png"), plot = age_graph)

##############################################################################################################
#Demographics - Age & Sex

age_sex <- CYP_clean %>% 
  count(c_top5, age_cat2, sex, name = "size") %>% 
  group_by(sex, age_cat2) %>% 
  mutate(percent = size / sum(size) * 100) %>% 
  filter(c_top5 == "top 5%")

age_sex

#Graph
age_sex_graph <- ggplot(data = age_sex, aes(x = age_cat2, y = percent, group = sex, colour = sex)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  ylab("Proportion of group (%)") +
  xlab("Age band") +
  expand_limits(y = 0) +
  scale_colour_discrete(name = "", labels = c("Female", "Male"))

ggsave(here::here("Figs","age_sex_graph.png"), plot = age_sex_graph)


##############################################################################################################
#Demographics - Deprivation

imd <- CYP_clean %>% 
  count(imd, c_top5, name = "dep_size") %>% 
  group_by(imd) %>% 
  mutate(percent = dep_size / sum(dep_size) * 100) %>% 
  filter(c_top5 == "top 5%") %>% 
  filter(imd != "NA")


imd

#Graph
imd_graph <- ggplot(data = imd, aes(x = imd, y = percent, colour = "#F8766D")) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  ylab("Proportion of patients in high cost group (%)") +
  scale_x_continuous(name = "IMD Decile", breaks = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)) +
  expand_limits(y = 0) +
  theme(legend.position = "none", panel.grid.minor.x = element_blank())

ggsave(here::here("Figs","imd_graph.png"), plot = imd_graph)

##############################################################################################################
#Persistency

CYP_SAS_1415 <- read_sas(here::here("Data","high_cost_cyp_1415.sas7bdat"))

CYP_1415 <- select(CYP_SAS_1415,c(patid, c_top5))

persistency <- left_join(CYP_clean, CYP_1415, by = c("patid" = "patid"))

persistency <- select(persistency, c(patid, c_top5.x, c_top5.y))

persist_t5 <- persistency %>% 
  filter(c_top5.x == "top 5%") %>% 
  filter(c_top5.y == "top 5%")
