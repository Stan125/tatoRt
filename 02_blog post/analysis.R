### --- Analyze the data --- ####

# Remove everything
rm(list = ls())

# Libraries
library(ggplot2)
library(dplyr)

# Load data
load("01_data generator/wiki_table.RData")

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
