
"""reader.py: Read audio file

Last modified: Tue Dec 23, 2014  12:29AM

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
import numpy as np
import pyhelper.print_utils as pu
import os 

class AudioFile(object):

    def __init__(self, filepath):
        self.filepath = filepath
        self.data = None
        self.spectogram = None
        self.samplingFreq = 0.0

    def readData(self):
        g.logger.info("Reading %s " % file)
        try:
            import aifc as aud
            f = aud.open(self.filepath, "r") 
        except Exception as e:
            try:
                import wave  as aud
                f = aud.open(self.filepath, "r")
            except:
                raise RuntimeError("Only WAVE and AIFC format are supported")

        self.samplingFreq = f.getframerate()
        g.sampling_freq = self.samplingFreq
        nframes = f.getnframes()
        strData = f.readframes(nframes)
        data = np.fromstring(strData, np.short).byteswap()
        self.data = data[~np.isnan(data)]
        g.logger.debug("Reading audio file is over. Got %s samples" % len(data))


