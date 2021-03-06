from numpy import array, zeros, argmin, inf
from numpy.linalg import norm
import sys
import os

def dtw(x, y, dist=lambda x, y: norm(x - y, ord=1)):
    """ Computes the DTW of two sequences.

    :param array x: N1*M array
    :param array y: N2*M array
    :param func dist: distance used as cost measure (default L1 norm)

    Returns the minimum distance, the accumulated cost matrix and the wrap path.

    """
    x = array(x)
    if len(x.shape) == 1:
        x = x.reshape(-1, 1)
    y = array(y)
    if len(y.shape) == 1:
        y = y.reshape(-1, 1)

    r, c = len(x), len(y)

    D = zeros((r + 1, c + 1))
    D[0, 1:] = inf
    D[1:, 0] = inf

    for i in range(r):
        for j in range(c):
            D[i+1, j+1] = dist(x[i], y[j])

    for i in range(r):
        for j in range(c):
            D[i+1, j+1] += min(D[i, j], D[i, j+1], D[i+1, j])

    D = D[1:, 1:]

    dist = D[-1, -1] / sum(D.shape)

    return dist, D, _trackeback(D)


def _trackeback(D):
    i, j = array(D.shape) - 1
    p, q = [i], [j]
    while (i > 0 and j > 0):
        tb = argmin((D[i-1, j-1], D[i-1, j], D[i, j-1]))

        if (tb == 0):
            i = i - 1
            j = j - 1
        elif (tb == 1):
            i = i - 1
        elif (tb == 2):
            j = j - 1

        p.insert(0, i)
        q.insert(0, j)

    p.insert(0, 0)
    q.insert(0, 0)
    return (array(p), array(q))
	
x = [0, 0, 1, 1, 2, 4, 2, 1, 2, 0]
y = [1, 1, 1, 2, 2, 2, 2, 3, 2, 0]

if __name__=="__main__":
	
	if len(sys.argv) != 3:
		print("Error : Usage : "+sys.argv[0]+" <nom_fichier_mfcc1> <nom_fichier_mfcc2>")
		quit()
	
	chemin_mfcc1 = sys.argv[1]
	chemin_mfcc2 = sys.argv[2]

	fichier_mfcc1 = open(chemin_mfcc1, "r")
	fichier_mfcc2 = open(chemin_mfcc2, "r")

	mfcc1 = []
	mfcc2 = []

	ligne = fichier_mfcc1.readline()
	while ligne != "":
		tabligne = ligne.split(",")
		for token in tabligne:
			try:
				token = float(token)
				mfcc1.append(token)
			except:
				print("failed to parse : \""+token+"\"")
		ligne = fichier_mfcc1.readline()	


	ligne = fichier_mfcc2.readline()
	while ligne != "":
		tabligne = ligne.split(",")
		for token in tabligne:
			try:
				token = float(token)
				mfcc2.append(token)
			except:
				print("failed to parse : \""+token+"\"")
		ligne = fichier_mfcc2.readline()
	
	dist, cost, path = dtw(mfcc1, mfcc2, dist=lambda mfcc1, mfcc2: norm(mfcc1 - mfcc2, ord=1))
	#dist = 0.3	
	print 'Minimum distance found:', dist

	nom_mfcc1 = os.path.basename(chemin_mfcc1)
	nom_mfcc2 = os.path.basename(chemin_mfcc2)

	#chemin_dtw = chemin_mfcc1.replace("mfccs", "dtw")[0:chemin_mfcc1.rindex("/")-1] + nom_mfcc1 + nom_mfcc2 + "_dtw.dat"
	tab_cheminmfcc1 = chemin_mfcc1.split("/")
	print tab_cheminmfcc1
	chemin_dtw = ""	
	for cpt in range(0, len(tab_cheminmfcc1)-2):
		chemin_dtw += tab_cheminmfcc1[cpt] + "/"
	chemin_dtw += tab_cheminmfcc1[len(tab_cheminmfcc1)-2] + ".dat"
	chemin_dtw = chemin_dtw.replace("mfccs","dtw")
	print chemin_dtw
	fichier_dtw = open(chemin_dtw, "a")
	
	fichier_dtw.write(nom_mfcc1 + ","+ nom_mfcc2 + "," + str(dist) + "\n")
