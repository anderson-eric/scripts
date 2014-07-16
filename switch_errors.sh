#!/bin/bash

# Usage:
# switch_error_collector [report] [report_on_success]
#	no parameters     : produces debug output; does not email the report
#	report            : emails report on warnings and errors
#	report_on_success : emails report on success, warnings and errors

TS=`date "+%Y%m%d_%H%M%S"`
ID=$ETC/private_openssh.key
HOME=/data/switch_error_collector
BIN=$HOME/bin
ETC=$HOME/etc
LOGS=$HOME/logs
LOGFILE=$LOGS/${TS}.log
COMMUNITY=HQRW
STATUS=0
SERVER=mail.usres.com
SENDER=root@cacti.hq.usres.com
RECIPIENT="eric.anderson@usres.com"
#RECIPIENT="info.it@usres.com"
DEBUG=0

echo Script started with parameters \"$1\" >> $LOGFILE

for SWITCH in       \
	LFUSRSW80   \
	LFUSRSW81   \
	LFUSRSW82   \
	LFUSRSW90   \
	LFUSRSW91   \
	LFUSRSW92   \
	LFCORESW06  \
	LFCORESW07  \
	DRSRVSW02   \
	DRCORESW01  \
	IRVEXTSW05  \
	IRVEXTSW06  \
	IRVCORESW01 \
	IRVCORESW02 \
	IRVSRVSW48  \
	IRVSRVSW49  \
	IRVSRVSW50  \
	IRVSRVSW51  
do

    STATUS=0
    RC=0

    echo `date "+%Y/%m/%d %H:%M:%S"` Processing switch $SWITCH ...  >> $LOGFILE

    # Header info
    printf  "\n$SWITCH"     >> ${TS}_int_error.txt 2>> $LOGFILE
    printf  "\n=========\n" >> ${TS}_int_error.txt 2>> $LOGFILE
    
    # Receive errors
    ERRIN=$(/usr/bin/snmpwalk -v2c -c $COMMUNITY $SWITCH IF-MIB::ifInErrors | /bin/awk '{ print $4 }') 

    # Transmit errors
    ERROUT=$(/usr/bin/snmpwalk -v2c -c $COMMUNITY $SWITCH IF-MIB::ifOutErrors | /bin/awk '{ print $4 }') 

    if [ $RC != 0 ]; then
	echo "!!! Error $RC collecting error status from switch $SWITCH." >> $LOGFILE
    fi

    count=1
    for i in $ERRIN; 
    do 
      if [ "$i" != "0" ]; then
         echo -e "   INT-$count RX errors: $i" >> ${TS}_int_error.txt 2>> $LOGFILE
      fi
      count=$[count + 1];
    done
    count=1
    echo "" >> ${TS}_int_error.txt 2>> $LOGFILE
    for j in $ERROUT; 
    do
      if [ "$j" != "0" ]; then
         echo -e "   INT-$count TX errors: $j" >> ${TS}_int_error.txt 2>> $LOGFILE
      fi
      count=$[count + 1];
    done

    echo `date "+%Y/%m/%d %H:%M:%S"` ... done. Overall status $STATUS. >> $LOGFILE 
    echo "$'\r'" >> $LOGFILE
done

# Mail the configuration and status report.
SUBJECT="Switch Interface Error Status"
 
echo "Emailing report to $RECIPIENT" >> $LOGFILE #/bin/cat ${TS}_int_error.txt | $BIN/sendEmail.pl -s $SERVER -f $SENDER -u $SUBJECT -t $RECIPIENT >> $LOGFILE 2>&1
