import sys
import subprocess
import os
from multiprocessing import Process, Pool, Pipe
from contextlib import closing
import multiprocessing, logging

chemin_tts1=""
chemin_tts2=""

def runBashCmd(cmd=""):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return process.communicate()[0]

#def jobSynthesation(chemin_fichiertxt="", chemin_tts1="", chemin_tts2="", chemin_fichierwav=""):
#def jobSynthetisation(chemins_txtwav):
	# Lancement tts1
#	cmdTts1 = "python " + chemin_tts1 + " " + chemins_txtwav[0] + " " + chemins_txtwav[1]
#	print(cmdTts1)
#	runBashCmd(cmdTts1)
	# Lancement tts2
#	cmdTts2 = "python " + chemin_tts2 + " " + chemins_txtwav[0] + " " + chemins_txtwav[1]
#	runBashCmd(cmdTts2)
#	return chemins_txtwav[0]
def jobSynthetisation(conn):
	recv = conn.recv()
	while recv != -1:
		chemintxt = recv[0]
		cheminwav = recv[1]
		print("Fichier traiter : "+chemintxt)
		#Lancement tts1
		cmdTts1 = "python " + chemin_tts1 + " " + chemintxt + " " + cheminwav + " > tts1.log"
		runBashCmd(cmdTts1)
		# Lancement tts2
		cmdTts2 = "python " + chemin_tts2 + " " + chemintxt + " " + cheminwav + " > tts2.log"
		runBashCmd(cmdTts2)
		conn.send(1)
		recv = conn.recv()

def jobMfcc(conn):
	recv = conn.recv()
	while recv != -1:
		cheminwav = recv
		#Lancement mfcc
		cmdMfcc = "python mfcc.py " + cheminwav + " >> mfcc.log"
		runBashCmd(cmdMfcc)
		conn.send(1)
		recv = conn.recv()

if __name__=="__main__":

	if len(sys.argv) != 4:
		print("Erreur : Usage : "+sys.argv[0]+" <chemin_dossier_application> <chemin_tts1> <chemin_tts2>")
		quit()

	# Init chemins
	dossier_application = sys.argv[1]
	chemin_tts1 = sys.argv[2]
	chemin_tts2 = sys.argv[3]
	
	dossierSentences = dossier_application + "/sentences/"
	dossierSounds = dossier_application + "/sounds/"
	dossierMfccs = dossier_application + "/mfccs/"
	
	# Job formalisation
	etatJobFormalisation = 0
	cmdJobFormalisation = "python FormatingText.py " + dossier_application + "/eval_text_partial.txt 100"
	runBashCmd(cmdJobFormalisation)
	etatJobFormalisation = 1
	
	# Job synthetisation
	etatJobSynthesitation = 0
	if not os.path.exists(dossierSounds):
		os.makedirs(dossierSounds);
		
	processes = []
	for i in range(0,20):
		parent_conn, child_conn = Pipe()
		process = Process(target=jobSynthetisation, args=(child_conn,))
		processes.append([process, parent_conn])
	i=0
	for dossier in os.listdir(dossierSentences):
		chemin_dossiertxt = dossierSentences + dossier + "/"
		for fichiertxt in os.listdir(chemin_dossiertxt):
			chemin_fichiertxt = chemin_dossiertxt + fichiertxt
			tab_chemintxt = chemin_fichiertxt.split("/")
			chemin_fichierwav = dossierSounds + tab_chemintxt[len(tab_chemintxt)-2] + "/"
			if not os.path.exists(chemin_fichierwav):
				os.makedirs(chemin_fichierwav)
			# Envoie des donnees aux processus fils
			if i<len(processes):
				#print(chemin_fichiertxt)
				process_info = processes[i]
				process = process_info[0]
				conn = process_info[1]
				process.start()
				conn.send([chemin_fichiertxt, chemin_fichierwav])
			else:				
				for process_info in processes: 
					conn = process_info[1]
					if conn.recv() == 1: # TODO optimiser
						conn.send([chemin_fichiertxt, chemin_fichierwav])
						break
			i+=1
	for process_info in processes:
		process_info[1].send(-1)	
	etatJobSynthetisation = 1

	# Job MFCC
	etatJobMfcc = 0
	processes = []
	if not os.path.exists(dossierMfccs):
		os.makedirs(dossierMfccs);
	for i in range(0,20):
		parent_conn, child_conn = Pipe()
		process = Process(target=jobMfcc, args=(child_conn,))
		processes.append([process, parent_conn])
	i=0
	for dossier in os.listdir(dossierMfccs):
		chemin_dossierwav = dossierSounds + dossier + "/"
		for fichierwav in os.listdir(chemin_fichierwav):
			chemin_fichierwav = chemin_dossierwav + fichierwav
			tab_cheminwav = chemin_fichierwav.split("/")
			chemin_fichiermfcc = dossierMfccs + tab_cheminwav[len(tab_cheminwav)-2] + "/"
			if not os.path.exists(chemin_fichiermfcc):
				os.makedirs(chemin_fichiermfcc)
			if i<len(processes):
				process_info = processes[i]
				process = process_info[0]
				conn = process_info[1]
				process.start()
				conn.send(chemin_fichierwav)
			else:
				for process_info in processes: 
					conn = process_info[1]
					if conn.recv() == 1: # TODO optimiser
						conn.send(chemin_fichierwav)
						break
	for process_info in processes:
		process_info[1].send(-1)	
			
	etatJobMfcc = 1
