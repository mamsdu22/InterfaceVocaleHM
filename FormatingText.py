from sys import argv
import string
import os
import fileinput
#script, filename = argv
script = argv[0]
filename = argv[1]
number_line = int(argv[2])

#txt = open(filename)
#channel_values = open(filename).read().split("\n")

#print "Here's your file %r:" % filename
#print txt.read()
#print channel_values



curDir = os.path.dirname(os.path.realpath(__file__))
print curDir

dirname = "folder"
sentencedirname = "sentences"


#Creation du 1er dossier
folderPath = curDir+"/"+dirname+"%i"%(0)
if not os.path.exists(folderPath):
    os.makedirs(folderPath)

sentencesPath =  folderPath +"/sentences"
if not os.path.exists(sentencesPath):
    os.makedirs(sentencesPath)
    
soundsPath =  folderPath +"/sounds"
if not os.path.exists(soundsPath):
    os.makedirs(soundsPath)
    
mfccsPath =  folderPath +"/mfccs"
if not os.path.exists(mfccsPath):
    os.makedirs(mfccsPath)
    
    
i = 1
fout = open(sentencesPath +"/output0.txt","wb")
for line in fileinput.FileInput(filename):
  fout.write(line)
  i+=1
  if i%number_line == 0:
    fout.close()
    folderPath = curDir+"/"+dirname+"%i"%(i/number_line)
    if not os.path.exists(folderPath):
        os.makedirs(folderPath)

    sentencesPath =  folderPath +"/sentences"
    if not os.path.exists(sentencesPath):
        os.makedirs(sentencesPath)
    soundsPath =  folderPath +"/sounds"
    if not os.path.exists(soundsPath):
        os.makedirs(soundsPath)
    
    mfccsPath =  folderPath +"/mfccs"
    if not os.path.exists(mfccsPath):
        os.makedirs(mfccsPath)
        
    fout = open(sentencesPath+"/output%d.txt"%(i/number_line),"wb")
    
    
    
    

fout.close()  


#print "Type the filename again:"
#file_again = raw_input("> ")

#txt_again = open(file_again)

#print txt_again.read()