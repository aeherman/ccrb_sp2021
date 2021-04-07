# Calculate Numeric Values of Officer Ranks
## libraries
#rm(list=ls())
library(tidyverse)
library(readxl)

## read in relevant data
a <- read_csv("~/sp21dspp/final_project/src/data/allegations_202007271729.csv")
rank <- read_xlsx("~/sp21dspp/final_project/references/CCRBDataLayoutTable.xlsx", sheet = 2)

## confirm that ranks and abbreviations make sense at time of incident...
a %>% left_join(rank, by = c("rank_abbrev_incident" = "Abbreviation")) %>% group_by(rank_incident) %>%
  summarize(ranks = paste(unique(Rank), collapse = ", "))

## View summaries of ranks associated with shorter title:
a %>% left_join(rank, by = c("rank_abbrev_now" = "Abbreviation")) %>% group_by(rank_now) %>%
  summarize(ranks = paste(unique(Rank), collapse = ", "))

## code numbers for ranks
rank$Rank <- str_to_lower(rank$Rank)
rank_dict <- rank %>%
  # record the order of the categories
  mutate(row = row_number()) %>%
  # filter for relevant categories
  filter(Abbreviation %in% c(unique(a$rank_abbrev_incident, a$rank_abbrev_now))) %>%
  # regroup through string matching
  group_by(rank_cat = case_when(
    str_detect(Rank, "chief") ~ "chiefs and other ranks",
    str_detect(Rank, "deputy|police") ~ Rank,
    TRUE ~ word(Rank, 1))) %>%
  # select only first item in each new category
  transmute(rank = row_number()) %>% filter(rank == 1) %>%
  # record rank
  ungroup() %>% mutate(rank = row_number())