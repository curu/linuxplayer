#!/usr/bin/python
##########################################
# a very simple console progress bar
# Author: Curu Wong
# Date:   2012-11-08
# License: GPL V2
##########################################
import sys
import time

class ProcessBar:
    def __init__(self, bar_width):
	    self.bar_width = bar_width

    def show_progress(self, progress):
	    prog_width = int(progress*self.bar_width)
	    prog_format = "%3d%% [%-" + str(self.bar_width) + "s]"
	    sys.stdout.write(chr(0x0d))
	    sys.stdout.write(prog_format % (int(progress*100), prog_width *'='))
	    sys.stdout.flush()

bar = ProcessBar(30);

if __name__ == "__main__":
	print "caculating, please wait..."
	for i in range(100):
	    progress = i / (100 - 1.0) 
	    bar.show_progress(progress)
	    time.sleep(0.01)
	print 
