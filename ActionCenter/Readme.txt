ActionCenter
let non-technical user take the action, set sys administrators from trivia

by Curu Wong, originally wrote for Pineapple Design Limited<http://www.pineapple.com.hk>

system structure:
* A web interface, enable user to submit action task to the database
* A daemon running in the background, query the database frequently to fetch new task.

files:
actiond: the daemon
actiond.init: sys-v init script to start/stop the daemon
ActionCenter.sql: database structure
web/actioncenter: frontend web interface

Install:
1. install the daemon
mkdir /usr/local/actioncenter
chmod +x actiond
cp actiond* /usr/local/actioncenter
chmod +x actiond.init
cp actiond.init /etc/init.d/actiond

2. install the interface
cp -a web/actioncenter /var/www/html/actioncenter

3. create database and user
then import ActionCenter.sql to the db

Configuration:
for daemon, edit actiond.cfg
for web interface, edit config.php

