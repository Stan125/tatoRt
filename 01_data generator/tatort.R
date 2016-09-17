#### Tatort data
library(XML)
library(dplyr)
library(ggplot2)
library(rvest)
library(lubridate)

imdb_id <- omdbapi::find_by_title("Tatort")$imdbID
page <- paste0("http://www.imdb.com/title/", imdb_id, "epdate?ref_=ttep_ql_4")
imdb_table <- readHTMLTable(page, header = TRUE)
series_table <- imdb_table[[1]][, 1:4]
colnames(series_table) <- c("number", "ep_name", "rating", "numvotes")
series_table <- series_table %>%
  mutate(number = gsub("Â", "", number)) %>%
  mutate(rating = as.numeric(as.character(rating)),
         numvotes = as.numeric(as.character(gsub(",", "", numvotes))),
         number = as.numeric(number),
         ep_name = iconv(ep_name, from = "UTF-8", to = "latin1")) %>%
  select(-number) %>%
  na.omit()

# find out if ratings are better with 

### Wikipedia

# Link
wiki <- "https://de.wikipedia.org/wiki/Liste_der_Tatort-Folgen"

# Get Nodes
wiki_nodes <- wiki %>%
  read_html() %>%
  html_nodes("table")

# Get table from second node
wiki_table <- html_table(wiki_nodes[2]) %>%
  as.data.frame()

# Set German locale to convert dates
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

# Boxplot: IMDB Ratings broken-down in countries
ggplot(wiki_table, aes(x = factor(Land), y = rating)) +
  geom_boxplot() +
  ggtitle("Average IMDB Ratings of Tatort episodes per country")

# Ratings over time in countries
ggplot(wiki_table, aes(x = Erstausstrahlung, y = rating, col = Land)) +
  geom_point(alpha = 0.3) +
  geom_smooth() +
  ggtitle("Average IMDB Ratings of Tatort episodes per country")

# Best 10 episodes
wiki_table %>%
  top_n(10, rating) %>%
  arrange(desc(rating)) %>%
  select(ep_name, rating)

# Average rating per producer
wiki_table %>%
  group_by(Sender) %>%
  summarise(mean = mean(rating, na.rm = TRUE)) %>%
  arrange(desc(mean))

# Best kommisars
wiki_table %>%
  group_by(Ermittler) %>%
  summarise(mean = mean(rating, na.rm = TRUE),
            count = n()) %>%
  arrange(desc(mean)) %>%
  filter(count > 10)





