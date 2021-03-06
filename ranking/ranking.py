import sys
import os

class DtwDatas: 
	"""
	Classe definissant les donnees qu'on retrouve dans le fichier de distances Dtw
	- fichier audio 1
	- fichier audio 2
	- valeur de la distance		
	"""
	def __init__(self, audiofilepath1="", audiofilepath2="", valuedistance=0):
		self.audiofilepath1 = audiofilepath1
		self.audiofilepath2 = audiofilepath2
		self.valuedistance = float(valuedistance)
	
	def __str__(self):
		"""
		Representation sous forme de chaine de l'objet DtwData
		"""
		return self.audiofilepath1+","+self.audiofilepath2+","+str(self.valuedistance)

	def __repr__(self):
		"""
		Representation sous forme de chaine de l'objet DtwData
		"""
		return self.audiofilepath1+","+self.audiofilepath2+","+str(self.valuedistance)

def comp(data1, data2):
	"""
	Fonction de comparaison de deux objets de type DtwData
	- data1 et data 2 les deux objets a comparer 
	"""
	if data1.valuedistance>data2.valuedistance:
		return -1
	elif data1.valuedistance<data2.valuedistance:
		return 1
	else:
		return 0

if __name__=='__main__':
	"""
	MAIN
	"""
	#verification du nombre d'arguments
	if len(sys.argv) != 2:
		print("Error : Usage : "+sys.argv[0]+" <fichier_dtw>")
		quit()
	#recuperation du contenu du fichier contenant les dtw
	dtwfilepath = sys.argv[1]
	dtwfile = open(dtwfilepath, "r")
	dtwfilelines = dtwfile.read().split("\n")
	dtwdatas = []
	#mise en forme des donnees afin de pouvoir les manipuler dans le programme
	for line in dtwfilelines:
		dtwlinetoken = line.split(",")
		if len(dtwlinetoken) == 3:
			dtwdatas.append(DtwDatas(dtwlinetoken[0], dtwlinetoken[1], dtwlinetoken[2]))
	#classement des donnees selon leurs distances
	dtwdatas.sort(cmp=comp)
	#ecriture du classement dans un fichier
	print("ranking : "+dtwfilepath+".sorted")
	sorteddtwfile = open(dtwfilepath+".sorted","w")
	for data in dtwdatas:
		print(data)
		sorteddtwfile.write(str(data)+"\n")
	dtwfile.close()
	sorteddtwfile.close()
