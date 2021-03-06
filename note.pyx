"""note.py: Class representing a note.

Last modified: Sun Dec 21, 2014  07:37AM

"""
    
__author__           = "Dilawar Singh"
__copyright__        = "Copyright 2013, Dilawar Singh and NCBS Bangalore"
__credits__          = ["NCBS Bangalore"]
__license__          = "GNU GPL"
__version__          = "1.0.0"
__maintainer__       = "Dilawar Singh"
__email__            = "dilawars@ncbs.res.in"
__status__           = "Development"

import scipy
import numpy as np
import cv2
from lxml import etree
import globals as g
from collections import defaultdict
import pyhelper.print_utils as pu

cdef class Note:

    cdef object origin, points, xpoints, ypoints, hull, line
    cdef double energy, height
    cdef int width, computed, geometryComputed
    cdef int startx, starty
    cdef double dt, time
    cdef double timeWidth 

    property points:
        def __get__(self): return self.points
        def __set__(self, points): self.points = points

    property startx:
        def __get__(self): return self.startx 
        def __set__(self, val): self.startx = val

    property starty:
        def __get__(self): return self.starty
        def __set__(self, v): self.starty = v

    property width:
        def __get__(self): return self.width 
        def __set__(self, v): self.width = v

    property height:
        def __get__(self): return self.height
        def __set__(self, v): self.height = v

    property dt:
        def __get__(self): return self.dt 
        def __set__(self, v): self.dt = v

    property time:
        def __get__(self): return self.time
        def __set__(self, v): self.time = v

    property line:
        def __get__(self): return self.line 
        def __set__(self, v): self.line = v
     
    property timeWidth:
        def __get__(self): return self.timeWidth 
        def __set__(self, v): self.timeWidth = v

    def __cinit__(self, x, y):
        self.origin = (x, y)
        self.energy = 0.0
        self.width = 0
        self.height = 0.0
        self.hull = None
        self.points = []
        self.xpoints = []
        self.ypoints = []
        self.computed = 0
        self.geometryComputed = 0
        self.startx = 0
        self.starty = 0
        # Multiply pixel x-index with this number and you get the time.
        self.dt = 1.0
        self.time = 0.0
        self.timeWidth = 0.0
        self.line = []

    cpdef computeAll(self, image):
        if self.computed == 0:
            self.smoothen()
            self.computeGeometry()
            for p in self.points:
                self.energy += image[p[0], p[1]] 
            self.time = g.dt * self.startx
            self.computed = 1

    cdef smoothen(self):
        """Smoothen out a note """
        cdef int i = 0
        vals = np.zeros(len(self.points))
        for i, p in enumerate(self.points):
            vals[i] = g.image_[p[0], p[1]]

        minV, maxV, avgV = vals.min(), vals.max(), np.average(vals)
        validPoints = []
        for p in self.points:
            if g.image_[p[0], p[1]] >  avgV: pass
            else: validPoints.append(p)
        self.points = validPoints 

    cpdef computeLine(self):
        """Construct a line for a note """
        cdef double sums, weights 
        cdef int x
        pu.log("STEP", "Approximating note with a line")
        pointDict = defaultdict(set)
        for x, y in sorted(self.points):
            pointDict[x].add(y)
        lineDict = {}
        for x in sorted(pointDict):
            sums = 0.0
            weights = 0.0
            ps = pointDict[x]
            for y in ps:
                sums += (y * g.image_[x, y])
                weights += g.image_[x, y]
            lineDict[x] = int(sums / weights)
        for k in lineDict:
            self.line.append((k, lineDict[k]))
        self.line.sort()

    cdef computeGeometry(self):
        if self.geometryComputed == 0:
            self.startx = min(self.xpoints)
            self.starty = min(self.ypoints)
            self.width = max(self.xpoints) - self.startx
            self.height = max(self.ypoints) - self.starty
            self.timeWidth = self.width * g.dt 
            self.geometryComputed = 1

    def __repr__(self):
        msg = "start={},energy={},width={},height={}".format(
                self.origin
                , self.energy
                , self.width
                , self.height
                )
        return msg

    cpdef toElementTree(self, xml=True):
        if self.computed == 0:
            raise UserWarning("One or more parameter(s) of your note is not "
                    "computed. Please use self.computeAll(img) function at "
                    " appropriate place"
                    )
        # Else create a xml representation.
        noteExp = etree.Element("note")
        noteExp.set('dt', "%s" % g.dt)
        noteExp.set('yscale',"%s" % g.yscale)

        startxElem = etree.SubElement(noteExp, "startx")
        startxElem.text = "%s" % self.startx
        startyElem = etree.SubElement(noteExp, "starty")
        startyElem.text = "%s" % self.starty

        widthElem = etree.SubElement(noteExp, "width")
        widthElem.text = "%s" % self.width 

        heightElem = etree.SubElement(noteExp, "height")
        heightElem.text = "%s" % self.height

        energyElem = etree.SubElement(noteExp, "energy")
        energyElem.text = "%s" % self.energy

        timeElem = etree.SubElement(noteExp, "time")
        timeElem.text = "%s" % self.time

        pointsElem = etree.SubElement(noteExp, "points")
        for p in self.points:
            pElem = etree.SubElement(pointsElem, "point")
            xElem = etree.SubElement(pElem, "x")
            yElem = etree.SubElement(pElem, "y")
            xElem.text = "%s" % p[0]
            yElem.text = "%s" % p[1]

        lineElem = etree.SubElement(noteExp, "geometry")
        for p in self.line:
            pElem = etree.SubElement(lineElem, "point")
            xElem = etree.SubElement(pElem, "x")
            yElem = etree.SubElement(pElem, "y")
            xElem.text = "%s" % p[0]
            yElem.text = "%s" % p[1]
        return noteExp

    cpdef toXML(self):
        """Convert note to xml string """
        nXml = self.toElementTree()
        return etree.tostring(nXml, pretty_print=True)


    cpdef addPoint(self, point):
        assert point >= [0, 0], "Got %s " % point
        y, x = point
        self.xpoints.append(x)
        self.ypoints.append(y)
        self.points.append(point)
    
    ##
    # fillConvexPoly function.
    #
    # @param img Image onto which points needs to be plotted.
    #
    # @return None.
    
    cpdef drawPoints(self, img):
        #points = [[p[1], p[0]] for p in self.points]
        #points = np.asarray(points)
        #cv2.fillConvexPoly(img, points, 1)
        for p in self.points:
            img[p[0], p[1]] = g.image_[p[0], p[1]]

    cpdef drawGeometry(self, img):
        cdef int i = 0
        #for i, p in enumerate(self.line[:-1]):
        #    startP = self.line[i]
        #    stopP = self.line[i+1]
        #    cv2.line(img, (startP[1], startP[0]), (stopP[1], stopP[0]), (0,0,0))
        for p in self.line:
            img[p[0], p[1]] = 0
    
    # This function is also called from python. Therefore cpdef instead of cdef.
    cpdef isValid(self):
        """Check if a given note is acceptable or note.
        """
        cdef int minPixelsInNote = int(g.config_.get('note', 'min_pixels'))
        cdef int minWidthOfNote = int(g.config_.get('note', 'min_width'))
        cdef double maxWidthOfNote = float(g.config_.get('note', 'max_width'))

        if len(self.points) < minPixelsInNote:
            pu.log("TEST", "Not enough points in this note. Rejecting")
            return False

        self.computeGeometry()
        if(self.width < minWidthOfNote):
            pu.log("TEST"
                    , "Width of this note ({}) is not enough (< {})".format(
                        self.width, minWidthOfNote
                        )
                    )
            return False

        if(self.timeWidth > maxWidthOfNote):
            pu.log("TEST"
                    , "Width of this note {} is larger than max {}".format(
                        self.timeWidth 
                        , maxWidthOfNote
                        )
                    )
            return False

        
        if(self.height >  2 * self.width):
            pu.log("TEST"
                    , "Width of this note is smallar then its 2 * height"
                    )
            return False

        return True

