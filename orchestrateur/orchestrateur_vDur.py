import sys
import subprocess
import os
from multiprocessing import Process, Pool
from contextlib import closing
import multiprocessing, logging

chemin_tts1=""
chemin_tts2=""

def runBashCmd(cmd=""):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return process.communicate()[0]

#def jobSynthesation(chemin_fichiertxt="", chemin_tts1="", chemin_tts2="", chemin_fichierwav=""):
def jobSynthetisation(chemins_txtwav):
	# Lancement tts1
	cmdTts1 = "python " + chemin_tts1 + " " + chemins_txtwav[0] + " " + chemins_txtwav[1]
	print(cmdTts1)
	runBashCmd(cmdTts1)
	# Lancement tts2
	cmdTts2 = "python " + chemin_tts2 + " " + chemins_txtwav[0] + " " + chemins_txtwav[1]
	runBashCmd(cmdTts2)
	return chemins_txtwav[0]

if __name__=="__main__":

	if len(sys.argv) != 4:
		print("Erreur : Usage : "+sys.argv[0]+" <chemin_dossier_application> <chemin_tts1> <chemin_tts2>")
		quit()

	dossier_application = sys.argv[1]
	chemin_tts1 = sys.argv[2]
	chemin_tts2 = sys.argv[3]
	
	# Job formalisation
	etatJobFormalisation = 0
	cmdJobFormalisation = "python FormatingText.py " + dossier_application + "/eval_text_full.txt 100"
	runBashCmd(cmdJobFormalisation)
	etatJobFormalisation = 1
	
	# Job synthetisation
	etatJobSynthesitation = 0
	dossierSentences = dossier_application + "/sentences/"
	dossierSounds = dossier_application + "/sounds/"
	if not os.path.exists(dossierSounds):
		os.makedirs(dossierSounds);
	lst_jobsynthetisation = []
	
	for dossier in os.listdir(dossierSentences):
		chemin_dossiertxt = dossierSentences + dossier + "/"
		for fichiertxt in os.listdir(chemin_dossiertxt):
			chemin_fichiertxt = chemin_dossiertxt + fichiertxt
			tab_chemintxt = chemin_fichiertxt.split("/")
			chemin_fichierwav = dossierSounds + tab_chemintxt[len(tab_chemintxt)-2] + "/"
			print(chemin_fichierwav)
			if not os.path.exists(chemin_fichierwav):
				os.makedirs(chemin_fichierwav)
			lst_jobsynthetisation.append([chemin_fichiertxt, chemin_fichierwav])
			#poolJobTts.apply_async(jobSynthetisation, (chemin_fichiertxt, chemin_tts1, chemin_tts2, chemin_fichierwav,)
	#poolJobTts = Pool(processes=20)
	#print(poolJobTts.map(jobSynthetisation, lst_jobsynthetisation))
	#poolJobTts.terminate()
	for arg in lst_jobsynthetisation:
		jobSynthetisation(arg) 
	etatJobSynthetisation = 1
		

	# Job MFCC
	#with Pool(processes = 10) as poolJobMfcc:
