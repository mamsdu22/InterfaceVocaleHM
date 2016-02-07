#!/usr/bin/python
# -*- coding: latin-1 -*-
import os
import sys
txtfilepath = sys.argv[1]
path = sys.argv[2]
tab = txtfilepath.split("/")
print(tab)
wavfilepath = tab[len(tab)-1]+"tts1"+".wav"
print(wavfilepath)
cmd="/vrac/ivhm/speech/script/spc/tts.pl --config /vrac/ivhm/data/podalydes/corpus_config.json --add-filter IS_LAST_SYL_OF_SENTENCE --add-filter IS_LAST_SYL_OF_BG --length 2 " + txtfilepath + " "+ path+wavfilepath
print(cmd)
os.system(cmd)
