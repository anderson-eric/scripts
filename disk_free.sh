#################################################################################
# ActiveXperts Network Monitor  - shell script checks
# © 1999-2009, ActiveXperts Software B.V.
#
# For more information about ActiveXperts Network Monitor and SSH, please
# visit the online ActiveXperts Network Monitor Shell Script Guidelines at:
#   http://www.activexperts.com/support/activmonitor/online/linux/
#################################################################################
# disk_free.sh
# Description:
#     Checks the available free space on a disk
# Parameters:
#     1) $1 (string)  - Path to disk
#     2) $2 (string)  - Max size of disk
# Usage:
#     disk_free.sh <disk> <max_size_MB>
# Sample:
#     disk_free.sh /dev/hda1 60
#################################################################################

#!/bin/sh

# Macro definitiions
PART=$1
MSIZE=$2
DISKS=`df -T | awk ' NR!=1 { print $0; }'`

# Validate number of arguments
if [ $# -ne 2 ] ; then
    echo "UNCERTAIN: Invalid number of arguments - Usage: disk_free <disk> <max_size_MB>"
    exit 1
fi

# Try to get disk information
if [[ -z $DISKS ]]; then
    echo "UNCERTAIN: Unable to get disk information."
    exit 1
fi

set -- $DISKS
i=1

# Check for the free space on the partition specified
while [[ -n ${!i} ]]
do
    if [ ${!i} == $PART ] ; then
        size=`expr $i + 2`
        used=`expr $i + 3`
        free=`expr $i + 4`
	
        if [[ ${!free} -ge $MSIZE ]] ; then
            echo "SUCCESS: Free disk space on drive $PART=[${!free} MB], minimum required=[$MSIZE MB]"
        else
            echo "ERROR: Free disk space on drive $PART=[${!free} MB], minimum required=[$MSIZE MB]"
        fi	
    fi
    i=`expr $i + 7`
done

# Give a warning if the partition does not exist
if [ -z $size ] ; then
    echo "UNCERTAIN: Partition $PART does not exist"
fi
