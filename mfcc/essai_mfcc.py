import numpy as np
import sys
from scipy.io import wavfile
from scikits.talkbox.features import mfcc

#Vérification du nombre d'arguments
if len(sys.argv) != 2:
	print("Error : Usage : "+sys.argv[0]+" <nom_du_fichier_audio>.wav")
	quit()
#Vérification du format du fichier (.wav)
if sys.argv[1][sys.argv[1].rfind("."):len(sys.argv[1])] != ".wav":
	print("Error");
	quit()
print("Lecture du fichier "+sys.argv[1]+" ...")
sample_rate, X = wavfile.read("/home/thomas/Documents/ivhm/space_oddity.wav")
print("Calcul des mfcc ...")
ceps, mspec, spec = mfcc(X)
filename = sys.argv[1]+"_mfcc.dat"
print("Ecriture des resultats dans : "+filename)
f = open(filename, "w");
for vec in ceps:
	for val in vec:
		f.write(str(val)+",")
	f.write("\n");
f.close();
