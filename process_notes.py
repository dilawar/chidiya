"""process_notes.py: 

    Class to process notes.

Last modified: Fri Dec 19, 2014  07:26AM

"""
    
__author__           = "Dilawar Singh"
__copyright__        = "Copyright 2013, Dilawar Singh and NCBS Bangalore"
__credits__          = ["NCBS Bangalore"]
__license__          = "GNU GPL"
__version__          = "1.0.0"
__maintainer__       = "Dilawar Singh"
__email__            = "dilawars@ncbs.res.in"
__status__           = "Development"

import note
import globals as g
import pyhelper.print_utils as pu
import lxml.objectify as objectify
import numpy as np
import pylab


class ProcessNotes():

    def __init__(self):

        self.noteFile = g.args_.note_file 
        self.notes = []
        self.noteXml = None
        self.songs = []
        # Its the delay between this note and its predecessor.
        self.delay = 0.0
        self.delayList = []
        self.avgNoteSep = 0.25 


    def analyze(self, **kwargs):
        pu.dump("STEP", "Processing notes stored in %s " % self.noteFile)
        self.readNoteFile()
        self.getSongs()

    def readNoteFile(self):
        with open(self.noteFile, "r") as nF:
            noteXml = objectify.parse(nF)
        self.notes = noteXml.findall('note')

    def getSongs(self):
        pu.dump("INFO", "Searching for songs in note")
        startTime = np.zeros(len(self.notes))
        energy = np.zeros(len(self.notes))
        for i, n in enumerate(self.notes):
            index = n.startx
            time = float(n.attrib['xscale']) * n.startx
            startTime[i] = time 
            energy[i] = n.energy


        # Algorithm to check the separation between songs:
        # 1. Sort the time difference array.
        # 2. Take the diff of sorted array.
        # 3. Find the index at which max-transition occurs.
    
        sortedTime = np.diff(np.sort(np.diff(startTime)))
        transTime = np.argmax(sortedTime)
        self.minSongSep = 1.01 *  sortedTime[transTime]

        currTime = 0.0
        for n in self.notes:
            nt = n.time
            if nt - currTime >= self.minSongSep:
                print("+ This is a song at time %s" % currTime)
            currTime = nt

        #pylab.vlines(startTime, [0], energy)
        #pylab.ylabel("Energy in note")
        #pylab.xlabel("Time of note in sec")
        #pylab.show()
        


            


