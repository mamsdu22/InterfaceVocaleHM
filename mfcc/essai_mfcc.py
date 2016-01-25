import numpy as np
import sys
import os
from scipy.io import wavfile
from scikits.talkbox.features import mfcc

#Verification du nombre d arguments
if len(sys.argv) != 2:
	print("Error : Usage : "+sys.argv[0]+" <nom_du_fichier_audio>.wav")
	quit()
#Verification du format du fichier (.wav)
if sys.argv[1][sys.argv[1].rfind("."):len(sys.argv[1])] != ".wav":
	print("Error");
	quit()
print("Lecture du fichier "+sys.argv[1]+" ...")
#Recuperation du chemin absolue du fichier passe en parametre
audiofilepath = os.path.abspath(sys.argv[1])
sample_rate, X = wavfile.read(audiofilepath)
print("Calcul des mfcc ...")
ceps, mspec, spec = mfcc(X)
mfccfilepath = audiofilepath.replace("sounds","mfccs")+".dat"
print("Ecriture des resultats dans : "+mfccfilepath)
os.makedirs(os.path.dirname(mfccfilepath))
f = open(mfccfilepath, "w");
for vec in ceps:
	for val in vec:
		f.write(str(val)+",")
	f.write("\n");
f.close();
