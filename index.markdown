---
layout: page
title: Home
comments: true
repository_url: http://github.com/dilawar/chidiya
---

## What `chidiya` does?

This cython application __chidiya__ (चिड़िया) -- Hindustani for bird -- is a work in
progress. For now, it claims to do the following:

- _Read recorded bird-songs_ (`aiff` file format) and create a spectogram like the one show below.

![spectogram]({{ site.url }}/_data/spectogram.png)

- _Extract `notes`_ and approximate them with simple lines. A small section of
  the spectogram is shown below. Lower pane is raw spectogram, the upper pane
  shows extracted notes, the middle one is their approximation using simple
  lines.

![Extracted notes]( {{ site.url }}/_data/notes.png )

The parameters in _config_ file determines the detected notes. The lighter notes
are ignored by the parameters.

- _Serialize notes_ in XML format.

- Process stored notes in an XML file and cluster them according to temporal
  variation. It calls them song. Serialize the song into XML. [In progress]

## How to use this program 

### Build the application

Since it is a cython program, you need to build the application using `setup.py`
file. You would need cython installed on your system.


    $ python setup.py build_ext --inplace

If this step was successful, then you can now start using this application.

### Run the application 

The entry point of chidiya is `main.py` file. You will get a detailed
description if you execute the following:

    $ python main.py --help

    usage: main.py [-h] --input_song INPUT_SONG
                   (--extract_notes | --process_notes) [--note_file NOTE_FILE]
                   --config config file [--verbose VERBOSE]

    Process bird songs

    optional arguments:
      -h, --help            show this help message and exit
      --input_song INPUT_SONG, -in INPUT_SONG
                            Recorded song (aiff format)
      --extract_notes, -e   Input song file in aifc format to extract notes.
      --process_notes, -pn  Process notes stored in this file
      --note_file NOTE_FILE, -nf NOTE_FILE
                            File where notes are stored and read from
      --config config file, -c config file
                            Configuration file to fine tune the processing
      --verbose VERBOSE, -v VERBOSE
                            Verbosity level. Default 0

Since this application is a work in progress, this help message might be
different then what you see on the terminal.

## The configuration file 

The configuration file keeps all the parameters which this program uses to do
what it does. The performance of this program is very sensitive to what is
described in configuration file. You must pass the location of configuration
file. The default location is `chidiya.conf` located in the same directory in
which you run this application. You need to modify the parameters as suggested
in [configuration]({% post_url chidiya/2014-12-10-Configuration %}) section.

