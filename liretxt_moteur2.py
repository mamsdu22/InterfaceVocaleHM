#!/usr/bin/python
# -*- coding: latin-1 -*-
import os
import sys
txtfilepath = sys.argv[1]
path = sys.argv[2]
wavfilepath = "file"+"tts2"+".wav"
print(wavfilepath)
cmd="../script/spc/tts.pl --config ../../data/podalydes/corpus_config.json --add-filter IS_LAST_SYL_OF_SENTENCE --add-filter IS_LAST_SYL_OF_BG --add-filter IS_IN_WORD_END --add-filter IS_SYLLABLE_DESCENDING --add-filter IS_SYLLABLE_RISING --add-filter HAS_CODA --add-filter IS_IN_CODA --add-filter IS_SYLLABLE_END  --candidates-threshold=10 --fuzzy-sandwich --length 2"+ txtfilepath+ " "+ path+wavfilepath
print(cmd)
os.system(cmd)