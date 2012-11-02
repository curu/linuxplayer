#!/usr/bin/python 
# -*- encoding: gb2312 -*-
#########################################################
#Monitor windows file share disk usage, an example use of pywin32
#Author : Curu Wong
#Date   : 2012-05-04
#License: GPL V2
#########################################################
import logging
import sys, string
import time
import win32api
import win32wnet
from win32netcon import *

#check for free space every checkInterval seconds
checkInterval = 1800 
#send alert when available free space is less than warnFree(GB)
#(单位为GB)小于warnFree时发送告警信息
monitor_config = [
	{
		'path' : r'\\filesvr1\share1',
		'warnFree' : 20.0
	 },
	{
		'path' : r'\\filesvr2\share2',
		'warnFree' : 100.0
	}
]

global logger
logfile = r'mon_disk.log'
loglevel = logging.INFO

def init_logger():
    global logger
    #setup logger
    logger = logging.getLogger(__name__)
    logger.setLevel(loglevel)
    #formatter
    formatter = logging.Formatter('[%(asctime)s] %(levelname)s: %(message)s')
    #console handler
    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    fh = logging.FileHandler(filename = logfile,
                             encoding = 'GBK')
    fh.setFormatter(formatter)
    logger.addHandler(ch)
    logger.addHandler(fh)
    
def getFreeDriveLetter():
	used_letters = win32api.GetLogicalDriveStrings()
	for letter in reversed(string.ascii_uppercase):
		if letter not in used_letters:
			return letter + ":"
	return None

def mapDrive(driveLetter, remotePath):
	netResource = win32wnet.NETRESOURCE()
	netResource.dwType = RESOURCETYPE_DISK
	netResource.lpLocalName = driveLetter
	netResource.lpRemoteName = remotePath
	try:
		win32wnet.WNetAddConnection2(netResource)
		return True
	except win32wnet.error, description:
		errMsg = "Unable to map network drive %s '%s'" % (driveLetter, description[2])
		logger.error(errMsg)
		return False

def unMapDrive(driveLetter):
	try:
		win32wnet.WNetCancelConnection2(driveLetter, 0, 0)
		return True
	except win32wnet.error, description:
		logger.error("Unable to unmap network drive %s %s" % (driveLetter, description[2]))
		return False

def getFreeSpaceGB(driveLetter):
	result = win32api.GetDiskFreeSpaceEx(driveLetter)
	freeGB, totalGB = map(lambda x: x/2**30, result[0:2])
	return (freeGB,totalGB)

def sendAlert(msg):
	#define this method for yourself
	pass

if __name__ == '__main__':
	init_logger()
	try:
		while True:
			for mon in monitor_config:
				driveLetter = getFreeDriveLetter()
				logger.debug("Use driver letter %s" % driveLetter)
				if mapDrive(driveLetter, mon['path']):
					freeGB, totalGB = getFreeSpaceGB(driveLetter)
					if freeGB < mon['warnFree']:
						msg = "[Disk Usage Alert] %s Total size:%.2fG Free size: %.2fG, less than %.2fG。Please take some action" % (mon['path'], totalGB, freeGB, mon['warnFree'])
						sendAlert(msg)
						logger.alert(msg)
					else:
						logger.info("%s Total size:%.2fG Used:%.2fG Free:%.2fG" % (mon['path'], totalGB, totalGB - freeGB, freeGB))
					unMapDrive(driveLetter)
				else:
					#well, just skip....
					pass
			time.sleep(checkInterval)
	except KeyboardInterrupt:
		sys.exit(0)
		
