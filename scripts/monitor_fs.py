#!/usr/bin/python
############################################################################
#monitor_fs.py: a simple script to monitor directory for file change events.
############################################################################
import os, sys, time
import pyinotify
 
def log_msg(msg):
    now = time.strftime("%F %T")
    print "[%s]: %s" %( now, msg)
    sys.stdout.flush()
 
def stat(path):
    stat = os.stat(path)
    print path
    print "Acess Time:\t%s" % time.strftime("%F %T %z", time.localtime(stat.st_atime)) 
    print "Change Time:\t%s" % time.strftime("%F %T %z", time.localtime(stat.st_ctime))
    print "Modify Time:\t%s" % time.strftime("%F %T %z", time.localtime(stat.st_mtime))
    print
    sys.stdout.flush()
 
 
 
class EventHandler(pyinotify.ProcessEvent):
    def __init__(self, watchManager, mask):
       self.wm = watchManager
       self.mask = mask
 
    def process_default(self, event):
        log_msg("event: %s"  % event.maskname)
        filename = event.pathname
        if event.mask & pyinotify.IN_ISDIR:
            #add watch on new directory
            if event.mask & pyinotify.IN_CREATE:
                log_msg("created new dir:'%s'" % filename)
                self.wm.add_watch(filename, mask, rec=True)
            #remove watch on deleted directory
            elif event.mask & pyinotify.IN_DELETE:
                log_msg("deleted dir:'%s'" % filename)
                self.wm.del_watch(self.wm.get_wd(event.pathname))
        else:
            if not (event.mask & pyinotify.IN_DELETE):
                try:
                    stat(filename)
                except OSError,e:
                    log_msg(e)
 
if __name__ == '__main__':
    wm = pyinotify.WatchManager() # Watch Manager
    mask = pyinotify.IN_CREATE | pyinotify.IN_CLOSE_WRITE | \
        pyinotify.IN_MOVED_TO | pyinotify.IN_DELETE | pyinotify.IN_ONLYDIR
    handler = EventHandler(wm, mask)
    notifier = pyinotify.Notifier(wm, handler)
    d = '/release/special'
    log_msg("watching %s" % d)
    wdd = wm.add_watch(d, mask, rec=True)
 
    notifier.loop()
