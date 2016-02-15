import sys
import subprocess
import os
from multiprocessing import Process

def runBashCmd(cmd=""):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return process.communicate()[0]

if __name__=="__main__":
	
	if len(sys.argv) != 5:
		print("Erreur : Usage : "+sys.argv[0]+" <chemin_dossier_application> <chemin_tts1> <chemin_tts2> <etape>")
		quit()

	dossier_application = sys.argv[1]
	chemin_tts1 = sys.argv[2]
	chemin_tts2 = sys.argv[3]
	etape = sys.argv[4]

	dossierSentences = dossier_application + "/sentences/"
	dossierSounds = dossier_application + "/sounds/"
	dossierMfccs = dossier_application + "/mfccs/"
	dossierDtw = dossier_application + "/dtw/"	

	cheminFichierEtat = dossier_application + "/orchestrateur_state.log"

	print("formalisation")	
	if etape == "formalisation":
		# Job formalisation
		etatJobFormalisation = 0
		cmdJobFormalisation = "python FormatingText.py " + dossier_application + "/eval_text_partial.txt 100"
		runBashCmd(cmdJobFormalisation)
		etatJobFormalisation = 1

	print("synthetisation")
	if etape == "synthetisation" or etape == "formalisation":
		# Job synthetisation.
		etatJobSynthetisation = 0
		if not os.path.exists(dossierSounds):
			os.makedirs(dossierSounds);
		processes = []	
		for dossier in os.listdir(dossierSentences):
			chemin_dossiertxt = dossierSentences + dossier + "/"
			print("chemin_dossiertxt : "+chemin_dossiertxt)
			for fichiertxt in os.listdir(chemin_dossiertxt):
				chemin_fichiertxt = chemin_dossiertxt + fichiertxt
				print("chemin_fichiertxt : "+chemin_fichiertxt)
				tab_chemintxt = chemin_fichiertxt.split("/")
				print("tab_chemintxt : "+str(tab_chemintxt))
				chemin_fichierwav = dossierSounds + tab_chemintxt[len(tab_chemintxt)-2] + "/"
				print("chemin_fichierwav : "+chemin_fichierwav)
				if not os.path.exists(chemin_fichierwav):
					os.makedirs(chemin_fichierwav)
				# Lancement tts1
				cmdTts1 = "python " + chemin_tts1 + " " + chemin_fichiertxt + " " + chemin_fichierwav
				print(cmdTts1)
				p = Process(target=runBashCmd, args=(cmdTts1,))	
				p.start()			
				processes.append(p)
				# Lancement tts2
				cmdTts2 = "python " + chemin_tts2 + " " + chemin_fichiertxt + " " + chemin_fichierwav
				print(cmdTts2)
				p = Process(target=runBashCmd, args=(cmdTts2,))
				p.start()
				processes.append(p)
		# Attente de l'execution de tous les threads
		for process in processes:
			process.join()

		etatJobSynthetisation = 1
		
	print("mfcc")
	if etape == "mfcc" or etape == "formalisation" or etape == "synthetisation":
		# Job Mfcc
		etatJobMfcc = 0
		processes = []
		if not os.path.exists(dossierMfccs):
			os.makedirs(dossierMfccs)
		for dossier in os.listdir(dossierSounds):
			chemin_dossierwav = dossierSounds + dossier + "/"
			for fichierwav in os.listdir(chemin_dossierwav):
				chemin_fichierwav = chemin_dossierwav + fichierwav
				tab_cheminwav = chemin_fichierwav.split("/")
				chemin_fichiermfcc = dossierMfccs + tab_cheminwav[len(tab_cheminwav)-2] + "/"
				if not os.path.exists(chemin_fichiermfcc):
					os.makedirs(chemin_fichiermfcc)
				# Lancement Mfcc
				cmdMfcc = "python mfcc.py " + chemin_fichierwav
				print(cmdMfcc)
				p = Process(target=runBashCmd, args=(cmdMfcc,))
				p.start()
				processes.append(p)
		# Attente de l'execution de tous les threads
		for process in processes:
			process.join()
				
		etatJobMfcc = 1

	print("dtw")
	if etape == "dtw" or etape == "mfcc" or etape == "formalisation" or etape == "synthetisation":
		# Job dtw
		etatJobDtw = 0
		processes = []
		if not os.path.exists(dossierDtw):
			os.makedirs(dossierDtw)
		for dossier in os.listdir(dossierMfccs):
			chemin_dossiermfccs = dossierMfccs + dossier + "/"
			listFichiersMfcc = os.listdir(chemin_dossiermfccs)
			cpt=0
			# on parcourt les fichiers mfcc deux a deux
			while cpt < len(listFichiersMfcc):
				chemin_mfcc1 = chemin_dossiermfccs + listFichiersMfcc[cpt]
				chemin_mfcc2 = chemin_dossiermfccs + listFichiersMfcc[cpt+1]
				chemin_dtw = chemin_mfcc1.replace("mfccs","dtw")[0:chemin_mfcc1.rindex("/")-1]
				if not os.path.exists(chemin_dtw):
					os.makedirs(chemin_dtw)
				cmdDtw = "python dtw.py " + chemin_mfcc1 + " " + chemin_mfcc2
				p = Process(target=runBashCmd, args=(cmdDtw,))
				p.start()
				processes.append(p)
				cpt += 2
		# Attente de l'execution de tous les threads	
		for process in processes:
			process.join()
