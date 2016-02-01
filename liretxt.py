#!/usr/bin/python
# -*- coding: latin-1 -*-
import os
import sys
txtfilepath = sys.argv[1]
path = sys.argv[2]
wavfilepath = "file"+"tts1"+".wav"
print(wavfilepath)
cmd="../script/spc/tts.pl --config ../../data/podalydes/corpus_config.json --add-filter IS_LAST_SYL_OF_SENTENCE --add-filter IS_LAST_SYL_OF_BG --length 2 " + txtfilepath + " "+ path+wavfilepath
print(cmd)
os.system(cmd)
