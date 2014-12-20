"""birdsong.py: 
    image_ = None

    Process the data in birdsong.

Last modified: Sun Dec 21, 2014  01:32AM

"""
    
__author__           = "Dilawar Singh"
__copyright__        = "Copyright 2013, Dilawar Singh and NCBS Bangalore"
__credits__          = ["NCBS Bangalore"]
__license__          = "GNU GPL"
__version__          = "1.0.0"
__maintainer__       = "Dilawar Singh"
__email__            = "dilawars@ncbs.res.in"
__status__           = "Development"

import globals as g
import logging
import dsp 
import cv2
import scipy
import numpy
from scipy import ndimage
import numpy as np
import pylab
import algorithms
import lxml.etree as etree

import os
import sys
import pyhelper.print_utils as pu

class BirdSong:

    #cdef object data, imageMat,  image, croppedImage, notesImage
    #cdef object Pxx, frequencies, bins
    #cdef object imageH, notes
    #cdef char* filename

    def __init__(self, data):
        self.data = data
        self.imageMat = None
        self.frequencies = None
        self.image = None
        self.croppedImage = None
        self.notesImage = None
        self.imageH = None
        self.filename = os.path.join(g.outdir, "spectogram.png")
        self.notes = []
        self.time = 0.0
        self.start_time = 0.0
        self.start_index = 0
        self.length = 0
        self.algo = algorithms.Algorithms()
        self.isCropped = int(g.config_.get('global', 'autocrop'))

        # Bottom-line of notes, anything near to it are ingnored. These are
        # caused by low-frequencies sound.
        self.bottomline = 250

        # Topline in spectogram. Very high frequency noise
        self.topline = 0

    def filterAndSort(self):
        """Filter notes and then sort all of them
        """
        # This sorting is done according to y position. Lower the startx
        # position better chance of it being a note.
        if self.isCropped:
            pu.log("WARN"
                    , "Image was cropped before processing." 
                    " Not doing the base-line test"
                    , verbosity = 2
                    )
            self.notes = sorted(self.notes, key=lambda note: note.startx)
            return 

        self.notes = sorted(self.notes, key=lambda note: note.starty)
        validNotes = []

        # Calculate the bottomline here
        startys = [ n.starty for n in self.notes ]
        self.bottomline = max(startys)
        pu.log("INFO"
                , "Setting topline to 30% of bottomline"
                , verbosity = 2
                )
        self.topline = 0.3 * self.bottomline

        for i, n in enumerate(self.notes):
            if n.starty > 0.9 * self.bottomline:
                pu.log("REJECTED", "%s" % n 
                        + " Way too close to bottomline " 
                        + " bottomline is %s " % self.bottomline  
                        + " note is at %s " % n.starty
                        , verbosity = 3
                        )
            elif n.starty < self.topline:
                pu.log("REJECTED",  "%s" % n
                        + " Way to close to topline "
                        + "topline is %s " % self.topline 
                        + " note is at %s " % n.starty
                        , verbosity = 3
                        )
            else:
                n.computeLine()
                validNotes.append(n)
        self.notes = sorted(validNotes[:], key = lambda note : note.startx)
        pu.log("INFO", "Total {} notes".format(len(self.notes)))


    def updateBaseline(self, index, note):
        """Update the base line.
        If the given note is below baseline (1.1 factor) then return False,
        else return True.
        """
        totalNotes = len(self.notes)
        self.baseline = (self.baseline * totalNotes + note.starty) / (totalNotes + 1)
        if note.starty > 1.1 * self.baseline:
            pu.log("STEP",
                    "++ Very much away for the baseline: {} ~ {}".format(
                        note.starty, self.baseline)
                    )
            return False
        else:
            #print("++ Note index {} should be inserted".format(index))
            return True


    def extractNotes(self, **kwargs):
        pu.log("STEP", "Processing the speech data")
        self.time = float(g.config_.get('global', 'time'))

        self.start_time = float(g.config_.get('global', 'start_time'))
        self.start_index = int(self.start_time * g.sampling_freq)

        if self.time <= 0.0:
            stop = -1
        else:
            stop = self.start_index + int(self.time * g.sampling_freq)

        data = self.data[self.start_index:stop]
        pu.log("INFO", "Processing index %s to %s" % (self.start_index, stop))
        #data = dsp.filterData(data, g.sampling_freq)
        self.Pxx, self.frequencies, self.bins, self.imageH = dsp.spectogram(
                data
                , g.sampling_freq
                )
        self.imageMat = self.imageH.get_array()

        # Use Wiener filter for noise-removal. Median-filter does not work at
        # all. Don't even think about using it.
        pu.log("INFO", "+ Using wiener filter of size 5 on the image")
        self.imageMat = scipy.signal.wiener(self.imageMat, 5)

        zoom = [float(g.config_.get('global', 'y_zoom'))
                , float(g.config_.get('global', 'x_zoom'))
                ]

        pu.log("INFO", "Zooming in image in both directions: %s " % zoom)
        self.imageMat = ndimage.interpolation.zoom(
                self.imageMat
                , zoom
                , order = 5
                , prefilter = True
                )

        g.dt = 128.0 / (float(g.config_.get('global', 'x_zoom')) * g.sampling_freq)
        g.yscale = 1.0 / float(g.config_.get('global', 'y_zoom')) 
        pu.log("INFO"
                , [ "Scaling spectogram. Computing scales"
                    , "dt = %s " % g.dt 
                    , "yscale = %s " % g.yscale 
                    ]
                )

        # TODO: We should not save the png file rather work directory on numpy
        # array.

        #self.testImage()
        pu.log("STEP", "Saving spectogram to %s " % self.filename, verbosity=0)
        g.image_ = self.imageMat
        pylab.imsave(self.filename, self.imageMat)
        pylab.close()
        self.getNotes()
        self.plotNotes(os.path.join(g.outdir, "notes.png"))
        #self.plotNotes(filename = None)

    def getNotes(self, **kwargs):
        pu.log("STEP", "Read image in GRAYSCALE mode to detect edges")
        self.image = cv2.imread(self.filename, 0)
        assert self.image.max() <= 255, "Expecting <= 255, got %s" % self.image.max()

        if int(g.config_.get('global', 'autocrop')) != 0:
            raise Exception("Developer error: Dont' crop")
            g.logger.warn("++ Autocropping image")
            threshold = self.image.max() * float(g.config_.get('global', 'crop_threshold'))
            self.croppedImage = self.algo.autoCrop(self.image, threshold)
        else:
            self.croppedImage = self.image

        # Create a global copy for further reference.
        g.image_ = np.copy(self.croppedImage)

        img = np.copy(self.croppedImage)
        self.averagePixalVal = img.mean()
        pu.log("DEBUG", "+ Average pixal value is %s " % self.averagePixalVal)
        # Get all the notes in image and insert them into self.notes . Make sure
        # it is sorted.
        self.notes = self.algo.notes(img)
        [ n.computeAll(self.croppedImage) for n in self.notes ]

        assert len(self.notes) > 0, "There must be non-zero notes"
        self.filterAndSort()
        assert len(self.notes) > 0, "There must be non-zero notes"

        if g.args_.note_file is None:
            pu.log("INFO", "Setting note file to %s" % g.args_.note_file)
            g.args_.note_file = os.path.join(g.outdir, "note.dat")

        pu.log("INFO", [ "Writings notes to {}".format(g.args_.note_file)])
        noteXml = etree.Element("notes")
        with open(g.args_.note_file, "wb") as f:
            for n in self.notes:
                noteXml.append(n.toElementTree())

        with open(g.args_.note_file, "w") as xmlFile:
            pu.log("INFO", "Writing notes to %s" % xmlFile.name)
            xmlFile.write(etree.tostring(noteXml, pretty_print=True))
        

    def findSongs(self):
        """Find songs in collection of notes.
        """
        g.logger.debug("+ Finding songs in recording ... ")
        start = []
        for n in self.notes:
            start.append(n.startx)
        #pylab.plot(start, range(len(start)), '*')
        #pylab.show()


    def plotNotes(self, filename = None):
        # Plot the notes.
        fig = pylab.figure()
        ax1 = fig.add_subplot(311)
        ax2 = fig.add_subplot(312)
        ax3 = fig.add_subplot(313)
        self.notesImage = np.empty(shape=self.croppedImage.shape, dtype=np.int8)
        self.geomImage = np.empty(shape=self.croppedImage.shape, dtype=np.int8)
        titleText = [ "{}:{}".format(va[0], va[1]) for va in (g.config_.items('note'))]

        ax1.set_title(" ".join(titleText))
        ax1.set_label("Sampling freq {}".format(g.sampling_freq))
        self.notesImage.fill(255)
        self.geomImage.fill(255)

        for note in self.notes:
            note.plot(self.notesImage)
            note.plotGeom(self.geomImage)
        ax1.imshow(self.notesImage, cmap=pylab.gray())
        ax2.imshow(self.geomImage, cmap=pylab.gray())


        ax3.imshow(self.croppedImage)
        if not filename:
            pylab.show()
        else:
            filename = os.path.join(g.outdir, filename)
            pu.log("STEP", "Saving notes and image to %s" % filename)
            pylab.savefig(filename)

    def testImage(self):
        """Test the given image"""
        g.logger.debug("[TEST] Image created")
        assert self.Pxx.shape == self.imageMat.shape
        self.imageH.write_png("/tmp/temp.png", noscale=True)
        image = pylab.imread('/tmp/temp.png')
        pylab.figure(1)
        pylab.subplot(211)
        pylab.imshow(self.imageMat)
        pylab.subplot(212)
        pylab.imshow(image)
        pylab.show()

    def play(self, notes):
        print("Playing notes")
        import piano
        piano.playNotes(notes)
        
