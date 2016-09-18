### --- Get the data --- ####

# Delete everything
rm(list = ls())

# Libraries
library(XML)
library(dplyr)
library(ggplot2)
library(rvest)

### IMDB Table ###

# Get link for imdb ratings page
page <- "http://www.imdb.com/title/tt0806910epdate?ref_=ttep_ql_4"

# Obtain table
imdb_table <- readHTMLTable(page, header = TRUE)
series_table <- imdb_table[[1]][, 1:4]

# Modify table
colnames(series_table) <- c("number", "ep_name", "rating", "numvotes")
series_table <- series_table %>%
  mutate(number = gsub("Â", "", number)) %>%
  mutate(rating = as.numeric(as.character(rating)),
         numvotes = as.numeric(as.character(gsub(",", "", numvotes))),
         number = as.numeric(number),
         ep_name = iconv(ep_name, from = "UTF-8", to = "latin1")) %>%
  select(-number) %>%
  na.omit()

### Wikipedia Table ###

# Link
wiki <- "https://de.wikipedia.org/wiki/Liste_der_Tatort-Folgen"

# Get Nodes
wiki_nodes <- wiki %>%
  read_html() %>%
  html_nodes("table")

# Get table from second node
wiki_table <- html_table(wiki_nodes[2]) %>%
  as.data.frame()

# Set German locale to convert dates, works only on macOS
Sys.setlocale("LC_TIME", "de_DE")
wiki_table <- wiki_table %>%
  mutate(Erstausstrahlung = gsub("[.]", "", Erstausstrahlung)) %>%
  mutate(Erstausstrahlung = as.Date(Erstausstrahlung, "%d %b %Y")) %>%
  rename(ep_name = Titel)

# Join ratings and wiki table
wiki_table <- left_join(wiki_table, series_table)

# Omit collaboration Tatorts
wiki_table <- wiki_table %>%
  filter(!grepl("/", Sender))

# Make countries
wiki_table$Land <- ifelse(wiki_table$Sender == "ORF", "Oesterreich", 
                          ifelse(wiki_table$Sender == "SRF", "Schweiz",
                                 "Deutschland"))

# Save data
save(list = "wiki_table", file = "01_data generator/wiki_table.RData")
