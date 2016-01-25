
from math import *
import matplotlib.pyplot as plt
from numpy import array, zeros, argmin, inf

def print_Matrice(mat) :
    print '[Matrice] width : %d height : %d' % (len(mat[0]), len(mat))
    print '-----------------------------------'
    for i in range(len(mat)) :
        print mat[i]#[v[:2] for v in mat[i]]


def dtw(x, y, dist):
    """
    Computes Dynamic Time Warping (DTW) of two sequences.
    :param array x: N1*M array
    :param array y: N2*M array
    :param func dist: distance used as cost measure
    Returns the minimum distance, the cost matrix, the accumulated cost matrix, and the wrap path.
    """
    assert len(x)
    assert len(y)
    lenX, lenY = len(x), len(y)
    Matrice0 = zeros((lenX + 1, lenY + 1))

    Matrice0[0, 1:] = inf
    Matrice0[1:, 0] = inf
    Matrice1 = Matrice0[1:, 1:] # view
    for i in range(lenX):
        for j in range(lenY):
            Matrice1[i, j] = dist(x[i], y[j])

    C = Matrice1.copy()
    for i in range(lenX):
        for j in range(lenY):
            Matrice1[i, j] += min(Matrice0[i, j], Matrice0[i, j+1], Matrice0[i+1, j])
    print_Matrice(Matrice1)

    if len(x)==1:
        path = zeros(len(y)), range(len(y))

    elif len(y) == 1:
        path = range(len(x)), zeros(len(x))

    else:
        path = _traceback(Matrice0)
    return Matrice1[-1, -1] / sum(Matrice1.shape), C, Matrice1, path


def _traceback(D):
    i, j = array(D.shape) - 2
    p, q = [i], [j]
    while ((i > 0) or (j > 0)):
        tb = argmin((D[i, j], D[i, j+1], D[i+1, j]))
        if (tb == 0):
            i -= 1
            j -= 1
        elif (tb == 1):
            i -= 1
        else: # (tb == 2):
            j -= 1
        p.insert(0, i)
        q.insert(0, j)
    return array(p), array(q)

if __name__ == '__main__':

    if 0: # 1-D numeric
        from sklearn.metrics.pairwise import manhattan_distances
        x = [0, 0, 1, 1, 2, 4, 2, 1, 2, 0]
        y = [1, 1, 1, 2, 2, 2, 2, 3, 2, 0]
        dist_fun = manhattan_distances
    if 0: # 2-D numeric
        from sklearn.metrics.pairwise import euclidean_distances
        x = [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2], [4, 3], [2, 3], [1, 1], [2, 2], [0, 1]]
        y = [[1, 0], [1, 1], [1, 1], [2, 1], [4, 3], [4, 3], [2, 3], [3, 1], [1, 2], [1, 0]]
        dist_fun = euclidean_distances
    else: # 1-D list of strings
        from nltk.metrics.distance import edit_distance
        x = ['we', 'shelled', 'clams', 'for', 'the', 'chowder']
        y = ['class', 'too']
        #x = ['i', 'soon', 'found', 'myself', 'muttering', 'to', 'the', 'walls']
        #y = ['see', 'drown', 'himself']
        #x = 'we talked about the situation'.split()
        #y = 'we talked about the situation'.split()
        dist_fun = edit_distance

        from sklearn.metrics.pairwise import manhattan_distances
        x = [1, 2, 3, 4, 5, 5, 5, 4]
        y = [2, 3, 4, 5, 5, 5]
        dist_fun = manhattan_distances

    dist, cost, acc, path = dtw(x, y, dist_fun)

    # vizualize

    plt.subplot(2, 2, 1)
    plt.plot(range(len(x)), x, 'g')
    plt.plot(y, range(len(y)), 'r')
    plt.title('x->g et y->r')

    plt.subplot(2, 2, 2)
    #plt.imshow(cost.T, origin='lower', cmap=plt.cm.Reds, interpolation='nearest')
    plt.plot(path[0], path[1], '-o') # relation
    plt.xticks(range(len(x)), x)
    plt.yticks(range(len(y)), y)
    plt.xlabel('x')
    plt.ylabel('y')
    plt.axis('tight')
    plt.title('Minimum distance: {}'.format(dist))

    plt.show()