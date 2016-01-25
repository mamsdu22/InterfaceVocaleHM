#!/usr/bin/python
# -*- coding: latin-1 -*-
import os
import sys
txtfilepath = sys.argv[0]
wavfilepath = "file"+"tts1"+".wav"
print(wavfilepath)
os.system("../script/spc/tts.pl --config ../../data/podalydes/corpus_config.json --add -filter IS_LAST_SYL_OF_SENTENCE --add-filter IS_LAST_SYL_OF_BG --length 2 " + txtfilepath + wavfilepath)
