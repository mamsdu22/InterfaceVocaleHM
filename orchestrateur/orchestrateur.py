import sys
import subprocess
import os
from multiprocessing import Process

def runBashCmd(cmd=""):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return process.communicate()[0]

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
	etatJobSynthetisation = 0
	dossierSentences = dossier_application + "/sentences/"
	dossierSounds = dossier_application + "/sounds/"
	if not os.path.exists(dossierSounds):
		os.makedirs(dossierSounds);
	processes = []	
	for dossier in os.listdir(dossierSentences):
		chemin_dossiertxt = dossierSentences + dossier + "/"
		for fichiertxt in os.listdir(chemin_dossiertxt):
			chemin_fichiertxt = chemin_dossiertxt + fichiertxt
			tab_chemintxt = chemin_fichiertxt.split("/")
			chemin_fichierwav = dossierSounds + tab_chemintxt[len(tab_chemintxt)-2] + "/"
			# Lancement tts1
			cmdTts1 = "python " + chemin_tts1 + " " + chemin_fichiertxt + " " + chemin_fichierwav
			p = Process(target=runBashCmd, args=(cmdTts1,))
			p.start()
			quit()			
			processes.append(p)
			# Lancement tts2
			cmdTts2 = "python " + chemin_tts2 + " " + chemin_fichiertxt + " " + chemin_fichierwav
			p = Process(target=runBashCmd, args=(cmdTts2,))
			p.start()
			processes.append(p)
	# Attente de l'execution de tous les threads
	for process in processes:
		process.join()

	etatJobSynthetisation = 1

