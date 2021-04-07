# Merge in rank_dict and reshape CCRB data to calcualte change in ranks
# associated with the resolution of complaints

## libraries
library(tidyverse)

## read in relevant data
a <- read_csv("~/sp21dspp/final_project/src/data/allegations_202007271729.csv")

# str_to_lower
cols <- c("rank_incident", "rank_now")
a[cols] <- sapply(a[cols], str_to_lower)

# do they always get closed at the same time?
## all complaints are resolved at the same time
a %>% group_by(complaint_id, date = zoo::as.yearmon(paste(year_closed, month_closed, sep = "-"))) %>%
  summarize(count = n()) %>% group_by(complaint_id) %>%
  summarize(count = n()) %>% group_by(count) %>% summarize(test = n())

reshaped <- a %>%
  ## convert received and closed dates to yearmon
  mutate(date_r = zoo::as.yearmon(paste(year_received, month_received, sep = "-")),
         date_c = zoo::as.yearmon(paste(year_closed, month_closed, sep = "-"))) %>%
  ## join rank information for time of incident and for rank_now (as of july 2020)
  left_join(rank_dict, by = c("rank_incident" = "rank_cat")) %>% rename(rank_incident_no = rank) %>%
  left_join(rank_dict, by = c("rank_now" = "rank_cat")) %>% rename(rank_now_no = rank) %>%
  
  ## use this line deferentially to confirm output looks right for the included officer IDs:
  #filter(unique_mos_id %in% c(25814, 18589, 25861)) %>%
  
  ## group board resolution by upper category indicated by first word
  ## and arrange it by most interesting category
  mutate(board_disposition =
           factor(word(board_disposition, 1),
                  levels = c("Substantiated", "Exonerated", "Unsubstantiated"))) %>%
  ## filter for the most interesting CCRB conclusion per complaint per officer
  group_by(unique_mos_id, complaint_id) %>% arrange(board_disposition) %>%
  mutate(row = row_number()) %>% filter(row == 1) %>%
  ## add some metadata (order and final?) to each officer's complaint
  group_by(unique_mos_id) %>% arrange(date_r) %>%
  mutate(complaint = row_number(), final = ifelse(complaint == max(complaint), 1, 0),
         rank_change = ifelse(final == 1, rank_now_no - rank_incident_no, diff(rank_incident_no)),
         rank_diff_scale = ifelse(final == 0, rank_incident_no - first(rank_incident_no),
                                  rank_now_no - rank_incident_no))

# calcualte rank at time of complaint resolution
## define empty columns for the for loop
### any old values for both to preserve the format for the for loop
reshaped$rank_closed_change <- 0
reshaped$rank_date_check <- zoo::as.yearmon("1000-01")

## for loop that looks for the location in time of the resolution within the
## the dates of lodged complaints in order to transfer the correct ranking at the
## time of resolution (this is important when resolutions occur after newer allegations
## are lodged)
for (i in 1:nrow(reshaped)) {
  # don't do anything if the month and year of the complaint and resolution are the same
  if (reshaped$date_c[i] == reshaped$date_r[i]) {
    reshaped$rank_closed_change[i] <- reshaped$rank_incident_no[i]
    reshaped$rank_date_check[i] <- reshaped$date_r[i]
  } else {
    # find the value most recent incident date from before the complaint resolution
    value <- max(reshaped$date_r[which(reshaped$date_c[i] > reshaped$date_r)])
    # locate this value in the lodge dates of the complaint
    index <- last(which(reshaped$date_r == value))
    # define the rank close date as the the rank at the date that the most recent
    # complaint had been lodged
    reshaped$rank_closed_change[i] <- reshaped$rank_change[index]
    # keep the date from that observation to track results visually
    reshaped$rank_date_check[i] <- zoo::as.yearmon(reshaped$date_r[index])
  }
}

# reshape data
## select relevant columns
#cols <- c("unique_mos_id", "rank_now_no", "board_disposition", "final",
#          "date_r", "rank_incident_no", "date_c", "rank_closed_no", "rank_date_check",
#          "complaint", "complaint_id", "year_received", "year_closed", "precinct")
# complainant ethnicity and most ethnicity?, complaint_id
#a_dict <- reshaped %>% select(cols) %>% arrange(unique_mos_id, date_c) %>%
  # add measures of rank change
#  mutate()
a_dict <- reshaped %>% mutate(result = case_when(rank_closed_change < 0 ~ "demoted",
                                                 rank_closed_change == 0 ~ "unchanged",
                                                 rank_closed_change > 0 ~ "promoted"),)