remove(list =ls())
options(stringsAsFactors = FALSE)
options(scipen = 999)

library(tidyverse);library(tidytext);library(tm);library(viridis)

##From wide to long and filter out empty titles
x <- read_csv("medium_datasci.csv") %>% select(-x1)%>%
    gather(tag, value, -(title:author_url)) %>%
    filter(value == 1) %>%
    filter(!is.na(title)) %>%
    mutate(tag = str_to_title(str_replace_all(str_replace_all(tag,"tag\\_", ""), "_"," "))) #%>%
    #mutate(tag = ifelse(tag == "Artificial Intelligence", "Ai", tag))


##
words_by_tag <- x %>% select(title, tag) %>% mutate(dupe = duplicated(title)) %>%
    filter(dupe == FALSE) %>%
    mutate(title = tm::removePunctuation(tm::removeNumbers(title))) %>%
    unnest_tokens(word, title) %>%
    count(tag, word, sort = TRUE) %>%
    ungroup() %>% anti_join(stop_words)

total_words <- words_by_tag %>% 
    group_by(tag) %>% 
    summarise(total = sum(n))

words_by_tag <- words_by_tag %>%
    inner_join(total_words) %>% 
    bind_tf_idf(word, tag, n)

#Need to do some word changing
words_by_tag %>%
    arrange(desc(tf_idf)) %>%
    select(tag, word, tf_idf) %>% group_by(tag) %>%
    top_n(10,tf_idf) %>%
    mutate(word = case_when(
        tag == "Deep Learning" ~ paste0(" ", str_to_title(word)),
        tag == "Machine Learning" ~paste0(str_to_title(word), " "),
        TRUE~str_to_title(word)
    )) %>%
    ggplot(aes(x = reorder(word, tf_idf), y= tf_idf,fill = tag)) + 
    geom_col(show.legend = FALSE) + 
    facet_wrap(~tag, scales = "free", nrow = 2) + coord_flip() + 
    theme_minimal() + 
    theme(
        text = element_text(family = "Roboto"),
        axis.text.x = element_blank(),
        panel.grid = element_blank(),
        axis.line.x = element_line(size = 0.25),
        strip.background = element_rect(fill = "gray90", color = "gray90"),
        plot.title = element_text(size = 14,face = "bold"),
        plot.subtitle = element_text(size = 13,face = "bold")
    ) + 
  scale_fill_viridis(discrete = TRUE, option = "D") + 
  labs(x = "TF-IDF scores",
       y = "Word",
       title = "TF-IDF scores of words in the titles of Medium data science articles",
       subtitle = "Duplicates were removed",
       caption = "Tidy tuesday week 36\nMedium data science articles metadata")

test <- x %>% select(title) %>% mutate(doc_id = row_number()) %>%
    unnest_tokens(word, title) 