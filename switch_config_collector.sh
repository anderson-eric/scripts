#!/bin/bash

# Usage
# switch_config_collector [report] [report_on_success]
#	without parameters produces debug output and does not email the report
#	report - email report on warnings and errors
#	report_on_success - email report on success, warnings and errors

SCC_HOME=/data/switch_config_collector
SCC_BIN=$SCC_HOME/bin
SCC_ETC=$SCC_HOME/etc
SCC_LOGS=$SCC_HOME/logs
SCC_LAST=$SCC_HOME/switch_configs/last
SCC_PREVIOUS=$SCC_HOME/switch_configs/previous
SCC_PORTSTATUS=$SCC_HOME/switch_configs/last_port_status
SCC_BYDEVICE=$SCC_HOME/switch_configs/by_device

TS=`date "+%Y%m%d_%H%M%S"`
ID=$SCC_ETC/private_openssh.key
LOG=$SCC_LOGS/scc_log_${TS}.txt
SHORTLOG=$SCC_LOGS/scc_short_log.txt
cat /dev/null > $SHORTLOG
COMMUNITY=HQRW
STATUS=0
SERVER=mailserver.yourdomain.com
SENDER=root@sendingserver.com
RECIPIENT="<emailaddress1> <emailaddress2>"
DEBUG=0
if [ "$1" == "" ]; then DEBUG=1; fi
echo Script started with parameters \"$1\" >> $LOG
if [ $DEBUG == 1 ]; then
    echo Script started with parameters \"$1\"
fi
for switch in       \
	<switchname1>
	<switchname2>
	<switchname3>
	...
	<switchnameN>
	; do

    echo "" >> $LOG
    echo "========================================================" >> $LOG
    echo `date "+%Y/%m/%d %H:%M:%S"` Processing switch $switch ...  >> $LOG
    if [ $DEBUG == 1 ]; then
        echo `date "+%Y/%m/%d %H:%M:%S"` Processing switch $switch ...
    fi
    CURSTATUS=0

    /bin/mkdir -p $SCC_BYDEVICE/$switch

    /usr/bin/scp -i $ID admin@${switch}:/cfg/startup-config $SCC_BYDEVICE/$switch/${TS}_startup.txt >> $LOG 2>&1
    RC=$?
    # sometimes switch closes scp connection which results in non-zero return code
    # if downloaded file is complete (last line "password operator") we reset RC to 0
    TEST_STRING=`tail -2 $SCC_BYDEVICE/$switch/${TS}_startup.txt 2> /dev/null | head -1`
    if [ $RC != 0 ]  &&  
       [ -e $SCC_BYDEVICE/$switch/${TS}_startup.txt ] &&
       [ "$TEST_STRING" == "password operator" ] ; then
	RC=0
    fi
    if [ $RC != 0 ]; then
	echo "!!! Error $RC collecting startup-config from switch $switch." >> $LOG
	echo "!!! Error $RC collecting startup-config from switch $switch." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Error $RC collecting startup-config from switch $switch."
        fi
        CURSTATUS=2
	continue
    fi

    /usr/bin/scp -i $ID admin@${switch}:/cfg/running-config $SCC_BYDEVICE/$switch/${TS}_running.txt >> $LOG 2>&1
    RC=$?
    # sometimes switch closes scp connection which results in non-zero return code
    # if downloaded file is complete (last line "password operator") we reset RC to 0
    TEST_STRING=`tail -2 $SCC_BYDEVICE/$switch/${TS}_running.txt 2> /dev/null | head -1`
    if [ $RC != 0 ]  &&  
       [ -e $SCC_BYDEVICE/$switch/${TS}_running.txt ] &&
       [ "$TEST_STRING" == "password operator" ] ; then
	RC=0
    fi
    if [ $RC != 0 ]; then
	echo "!!! Error $RC collecting startup-config from switch $switch." >> $LOG
	echo "!!! Error $RC collecting startup-config from switch $switch." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Error $RC collecting startup-config from switch $switch."
        fi
        CURSTATUS=2
	continue
    fi

    /usr/bin/diff -u $SCC_BYDEVICE/$switch/${TS}_startup.txt $SCC_BYDEVICE/$switch/${TS}_running.txt >> $LOG 2>&1
    if [ $? != 0 ]; then
	echo "!!! Warning: uncommitted configuration changes on switch $switch." >> $LOG
	echo "!!! Warning: uncommitted configuration changes on switch $switch." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Warning: uncommitted configuration changes on switch $switch."
        fi
        if [ $CURSTATUS == 0 ]; then 
	    CURSTATUS=1
	fi
    fi

    if [ ! -e $SCC_LAST/${switch}.txt ]; then
	/bin/cp $SCC_BYDEVICE/$switch/${TS}_running.txt $SCC_LAST/${switch}.txt >> $LOG 2>&1
    fi

    /usr/bin/diff -u $SCC_LAST/${switch}.txt $SCC_BYDEVICE/$switch/${TS}_running.txt >> $LOG 2>&1
    if [ $? != 0 ]; then
	echo "!!! Warning: switch $switch configuration has changed." >> $LOG
	echo "!!! Warning: switch $switch configuration has changed." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Warning: switch $switch configuration has changed."
        fi
        if [ $CURSTATUS == 0 ]; then 
	    CURSTATUS=1
	fi
	/bin/cp $SCC_LAST/${switch}.txt                 $SCC_PREVIOUS/${switch}.txt >> $LOG 2>&1
	/bin/cp $SCC_BYDEVICE/$switch/${TS}_running.txt $SCC_LAST/${switch}.txt     >> $LOG 2>&1
    fi


    TMPFILE=`mktemp`
    RC=0
    /usr/bin/snmpwalk -v2c -c $COMMUNITY $switch IF-MIB::ifOperStatus >> $TMPFILE 2>> $LOG
    RC2=$?
    if [ $RC -lt $RC2 ]; then RC=$RC2; fi
    /usr/bin/snmpwalk -v2c -c $COMMUNITY $switch IF-MIB::ifType       >> $TMPFILE 2>> $LOG
    RC2=$?
    if [ $RC -lt $RC2 ]; then RC=$RC2; fi
    /usr/bin/snmpwalk -v2c -c $COMMUNITY $switch IF-MIB::ifAlias      >> $TMPFILE 2>> $LOG
    RC2=$?
    if [ $RC -lt $RC2 ]; then RC=$RC2; fi
    sort -k 2 -t . -n $TMPFILE > $SCC_BYDEVICE/$switch/${TS}_port_status.txt 2>> $LOG
    rm -f $TMPFILE
    if [ $RC != 0 ]; then
	echo "!!! Error $RC collecting port status from switch $switch." >> $LOG
	echo "!!! Error $RC collecting port status from switch $switch." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Error $RC collecting port status from switch $switch."
        fi
        CURSTATUS=2
	continue
    fi

    if [ ! -e $SCC_PORTSTATUS/${switch}.txt ]; then
	/bin/cp $SCC_BYDEVICE/$switch/${TS}_port_status.txt $SCC_PORTSTATUS/${switch}.txt >> $LOG 2>&1
    fi

    /usr/bin/diff -u $SCC_PORTSTATUS/${switch}.txt $SCC_BYDEVICE/$switch/${TS}_port_status.txt >> $LOG 2>&1
    if [ $? != 0 ]; then
	echo "!!! Warning: port status has changed on switch $switch." >> $LOG
	echo "!!! Warning: port status has changed on switch $switch." >> $SHORTLOG
        if [ $DEBUG == 1 ]; then
	    echo "!!! Warning: port status has changed on switch $switch."
        fi
        if [ $CURSTATUS == 0 ]; then 
	    CURSTATUS=1
	fi
	/bin/cp $SCC_BYDEVICE/$switch/${TS}_port_status.txt $SCC_PORTSTATUS/${switch}.txt >> $LOG 2>&1
    fi

    if [ $CURSTATUS -gt $STATUS ] ; then STATUS=$CURSTATUS; fi
    echo `date "+%Y/%m/%d %H:%M:%S"` ... done. Current status $CURSTATUS. Overall status $STATUS. >> $LOG
    if [ $DEBUG == 1 ]; then
        echo `date "+%Y/%m/%d %H:%M:%S"` ... $switch done. Current status $CURSTATUS. Overall status $STATUS.
    fi

done


echo "" >> $LOG
echo "========================================================" >> $LOG
pushd $SCC_LAST > /dev/null
pwd >> $LOG
/bin/rm -f last_config.zip >> $LOG 2>&1
/usr/bin/zip last_config.zip *.txt >> $LOG 2>&1
popd > /dev/null

if [ $CURSTATUS -gt $STATUS ] ; then $STATUS=$CURSTATUS; fi
echo Script completed with STATUS=$STATUS. See log file for details: $LOG >> $LOG
if [ $DEBUG == 1 ]; then
    echo Script completed with STATUS=$STATUS. See log file for details: $LOG
fi

if [ $STATUS == 0 ]; then  SUBJECT="Switch Config Collector: SUCCESS"; fi
if [ $STATUS == 1 ]; then  SUBJECT="Switch Config Collector: WARNING"; fi
if [ $STATUS == 2 ]; then  SUBJECT="Switch Config Collector: ERROR";   fi

if [ "$1" == "report_on_success" ] ||
   ( [ "$1" == "report" ] && [ $STATUS -gt 0 ] ) ; then
    echo Emailing report to $RECIPIENT >> $LOG
    if [ $DEBUG == 1 ] ; then
        echo Emailing report to $RECIPIENT
    fi
    /bin/cat $SHORTLOG | $SCC_BIN/sendEmail.pl -s $SERVER -f $SENDER -u $SUBJECT \
		-a $LOG -a $SCC_LAST/last_config.zip -t $RECIPIENT >> $LOG 2>&1
fi

