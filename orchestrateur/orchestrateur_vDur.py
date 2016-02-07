import sys
import subprocess
import os
from multiprocessing import Process

def runBashCmd(cmd=""):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return process.communicate()[0]

def jobSynthesation(chemin_fichiertxt="", chemin_tts1="", chemin_tts2="", chemin_fichierwav=""):
	# Lancement tts1
	cmdTts1 = "python " + chemin_tts1 + " " + chemin_fichiertxt + " " + chemin_fichierwav
	runBashCmd(cmdTts1)
	# Lancement tts2
	cmdTts2 = "python " + chemin_tts2 + " " + chemin_fichiertxt + " " + chemin_fichierwav
	runBashCmd(cmdTts2)
	return pathFichierTxt

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
	with Pool(processes == 20) as poolJobTts:
		
		for dossier in os.listdir(dossierSentences):
			chemin_dossiertxt = dossierSentences + dossier + "/"
			for fichiertxt in os.listdir(chemin_dossiertxt):
				chemin_fichiertxt = chemin_dossiertxt + fichiertxt
				tab_chemintxt = chemin_fichiertxt.split("/")
				chemin_fichierwav = dossierSounds + tab_chemintxt[len(tab_chemintxt)-2] + "/"
				pool.apply_async(jobSynthetisation, (chemin_fichiertxt, chemin_tts1, chemin_tts2, chemin_fichierwav,)
	etatJobSynthetisation = 1






