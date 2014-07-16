#!/bin/bash

DISKSIZE=`/usr/bin/snmpget -v2c -c HQRW 192.168.102.100 HOST-RESOURCES-MIB::hrStorageSize.3 | awk '{print $4}'`
DISKUSED=`/usr/bin/snmpget -v2c -c HQRW 192.168.102.100 HOST-RESOURCES-MIB::hrStorageUsed.3 | awk '{print $4}'`
AVAILABLE=`expr $DISKSIZE - $DISKUSED`
DISKFREE=$(expr $AVAILABLE \* 4096)
GBAVAIL=$(expr $DISKFREE \/ 1073741824)

SENDER=root@cacti.hq.usres.com
RECIPIENT="info.it@usres.com"
SUBJECT="IRVRESFS1 available disk space"
BODY="The available disk space on IRVRESFS1 F: drive is $GBAVAIL GB."
SERVER=mail.usres.com
/usr/local/bin/sendEmail.pl -s $SERVER -f $SENDER -u $SUBJECT -t $RECIPIENT -m $BODY
