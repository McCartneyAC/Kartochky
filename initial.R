library(tidyverse)
library(readr)

words <- readxl::read_xlsx("C:\\Users\\a.mccartney\\Desktop\\flashcards\\words.xlsx")

download.file(
  "https://raw.githubusercontent.com/titoBouzout/Dictionaries/master/Ukrainian_uk_UA.dic",
  destfile = "uk_dict.dic",
  mode = "wb"
)

lemmas <- readr::read_lines("uk_dict.dic", locale = readr::locale(encoding = "UTF-8")) %>%
  .[-1] %>%                    # drop word count on first line
  stringr::str_remove("/.*$") %>%   # strip hunspell flags
  tibble::tibble(word = .) %>%
  dplyr::distinct()
lemmas

words
v1_words <- words %>% 
  semi_join(lemmas, by = "word")
v1_words %>% 
  arrange(desc(value))
v1_words %>% 
  mutate(len = nchar(word)) %>% 
  arrange(desc(len)) -> v1_words
readr::write_excel_csv(v1_words, "C:\\Users\\a.mccartney\\Desktop\\flashcards\\v1words.csv")








library(dplyr)
library(readr)
library(stringdist)
save_results <- function(session, path = "C:\\Users\\a.mccartney\\Desktop\\flashcards\\session_results.csv") {
  if (file.exists(path)) {
    readr::write_excel_csv(session, path, append = TRUE, col_names = FALSE)
  } else {
    readr::write_excel_csv(session, path)
  }
}
pick_distractors <- function(deck, target_idx, n = 4, candidate_pool = 15) {
  target <- deck[target_idx, ]
  pool   <- deck[-target_idx, ] %>%
    filter(word_en != target$word_en) %>%          # no synonym collisions
    mutate(dist = stringdist(target$word_uk, word_uk, method = "lv")) %>%
    arrange(dist) %>%
    slice_head(n = candidate_pool) %>%             # top N closest neighbors
    slice_sample(n = n)                            # uniform sample from pool
  pool
}

run_quiz <- function(deck, cooldown_rounds = 10) {
  # deck expects columns: word_uk, word_en, value
  
  results <- tibble(
    timestamp      = as.POSIXct(character()),
    word_uk        = character(),
    word_en        = character(),
    direction      = character(),
    correct_answer = character(),
    chosen_answer  = character(),
    is_correct     = logical(),
    response_ms    = numeric()
  )
  
  cooldown <- c()  # named vector: word_uk -> rounds_remaining
  
  cat("Ukrainian vocab quiz. Type q to quit.\n\n")
  
  repeat {
    
    # decrement and expire cooldowns
    if (length(cooldown) > 0) {
      cooldown <- cooldown - 1
      cooldown <- cooldown[cooldown > 0]
    }
    
    # build sample weights: zero out cooled-down words
    sample_weights <- deck$value
    sample_weights[deck$word_uk %in% names(cooldown)] <- 0
    
    # safety valve: if everything is on cooldown somehow, reset
    if (all(sample_weights == 0)) {
      cat("(all words on cooldown — resetting)\n")
      cooldown <- c()
      sample_weights <- deck$value
    }
    
    # 1. select word biased toward high frequency
    idx    <- sample(nrow(deck), size = 1, prob = sample_weights)
    target <- deck[idx, ]
    
    # 2. random direction
    direction <- sample(c("uk_to_en", "en_to_uk"), size = 1)
    
    # 3. levenshtein distractors
    distractors <- pick_distractors(deck, idx)
    
    # 4. build and shuffle answer set
    if (direction == "uk_to_en") {
      prompt         <- target$word_uk
      correct        <- target$word_en
      answer_choices <- c(correct, distractors$word_en)
    } else {
      prompt         <- target$word_en
      correct        <- target$word_uk
      answer_choices <- c(correct, distractors$word_uk)
    }
    
    answer_choices <- sample(answer_choices)
    correct_pos    <- which(answer_choices == correct)
    
    # 5. display question
    dir_label <- if (direction == "uk_to_en") "UA -> EN" else "EN -> UA"
    cat(sprintf("[%s]  %s\n\n", dir_label, prompt))
    for (i in seq_along(answer_choices)) {
      cat(sprintf("  %d. %s\n", i, answer_choices[i]))
    }
    cat("\n")
    
    # 6. get input and time it
    t_start <- Sys.time()
    input   <- readline("Answer (1-5, or q): ")
    t_end   <- Sys.time()
    
    if (tolower(input) == "q") {
      cat("Quitting. Saving results...\n")
      break
    }
    
    chosen_num <- suppressWarnings(as.integer(input))
    
    if (is.na(chosen_num) || chosen_num < 1 || chosen_num > 5) {
      cat("Invalid input, skipping.\n\n")
      next
    }
    
    chosen       <- answer_choices[chosen_num]
    correct_flag <- chosen_num == correct_pos
    resp_ms      <- as.numeric(t_end - t_start) * 1000
    
    # 7. feedback and cooldown update
    if (correct_flag) {
      cat(sprintf("Correct! (%d ms)\n\n", round(resp_ms)))
      cooldown[target$word_uk] <- cooldown_rounds
    } else {
      cat(sprintf("Wrong. Answer was: %d. %s (%d ms)\n\n",
                  correct_pos, correct, round(resp_ms)))
      # wrong answers do NOT trigger cooldown — see them again soon
    }
    
    # 8. accumulate results
    results <- results %>% add_row(
      timestamp      = Sys.time(),
      word_uk        = target$word_uk,
      word_en        = target$word_en,
      direction      = direction,
      correct_answer = correct,
      chosen_answer  = chosen,
      is_correct     = correct_flag,
      response_ms    = resp_ms
    )
  }
  
  return(results)
}







deck    <- readr::read_csv("C:\\Users\\a.mccartney\\Desktop\\flashcards\\v1words.csv")  # word_uk, word_en, value
session <- run_quiz(deck, cooldown_rounds = 10)
#readr::write_excel_csv(session, "C:\\Users\\a.mccartney\\Desktop\\flashcards\\session_results.csv")
save_results(session)