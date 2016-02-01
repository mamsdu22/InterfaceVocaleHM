import sys

def runBashCmd(cmd):	
	process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
	return output = process.communicate()[0]

if __name__=="__main__":
	
	if len(sys.argv) != 2:
		print("Erreur : Usage : "+sys.argv[0]+" <chemin_dossier_application> <chemin_tts1> <chemin_tts2>")

	dossier_application = sys.argv[1]
	chemin_tts1 = sys.argv[2]
	chemin_tts2 = sys.argv[3]

	# Job formalisation
	etatJobFormalisation = 0
	cmdJobFormalisation = "python FormattingText " + dossier_application + "/eval_text_full.txt 100"
	runBashCmd(cmdJobFormalisation)
	etatJobFormalisation = 1
	
	# Job synthetisation
	etatJobSynthetisation = 0
	dossierSentences = dossier_application + "/sentences"
	dossierSounds = dossier_application + "/sounds
	processes = []	
	for dossier in os.listdir(dossierSentences):
		for fichiertxt in os.listdir(dossier):
			chemin_fichiertxt = os.path.abspath(fichiertxt)
			walk_fichiertxt = os.walk(chemin_fichiertxt)
			chemin_fichierwav = dossierSounds + "/" + walk_fichiertxt[len(walk_fichier)-2] + "/" + walk_fichiertxt[len(walk_fichier)-1][0:walk_fichiertxt[len(walk_fichier)-1].rindex('.')]
			cmdTts1 = "python " + chemin_tts1 + " " + chemin_fichiertxt + " " + walk_fichiertxt[len(walk_fichier)-2]
			p = Process(target=executeTts, args=(cmdTts1))
			p.start()
			processes.append(p)
	for process in processes:
		process.join()

	etatJobSynthetisation = 1

