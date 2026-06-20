# Kartochky
vibe-coding a ukrainian flashcards app with my preferred structure


Initial data from the closed-caption frequency dataset here:
https://github.com/hermitdave/FrequencyWords/blob/master/content/2018/uk/uk_50k.txt

We used this dictionary to verify the words in the closed caption (i.e. to get rid of weird artifacts, english words, russian words):
https://raw.githubusercontent.com/titoBouzout/Dictionaries/master/Ukrainian_uk_UA.dic

Target words are chosen randomly with a bias to the original frequency of useage in the closed-caption dataset, so the flashcards will test more common words first. 

Distractor choices are chosen via levenshtein distance, so the distractor words should "feel" very close to the target word, making them more distracting. for example:
```r

[EN -> UA]  yet

  1. де
  2. ме
  3. ее
  4. ще
  5. фе

Answer (1-5, or q): 4
Correct! (3366 ms)
```

the closest 15 distractor words are chosen, then randomly sample 5 distractors alongside the target. 

the cooldown period for words is based on implicit difficulty, as a function of how long the user needed to choose the right word. Words with more automaticity are given a longer cooldown. 

Users should in principle be able to add their own dictionary words with an explicit frequency if they wish to test them more often. 
