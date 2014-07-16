#################################################################################
# ActiveXperts Network Monitor  - shell script checks
# © 1999-2009, ActiveXperts Software B.V.
#
# For more information about ActiveXperts Network Monitor and SSH, please
# visit the online ActiveXperts Network Monitor Shell Script Guidelines at:
#   http://www.activexperts.com/support/activmonitor/online/linux/
#################################################################################
# cpu_load.sh
# Description:
#     Checks the cpu load on a computer
# Parameters:
#     1) size (string)  - Max size of the CPU load in %
# Usage:
#     cpu_load.sh <max_load_pct>
# Sample:
#     cpu_load.sh 70
#################################################################################

#!/bin/sh

# Macro definitiions
Max=$1
TotalPS=0

# Validate number of arguments
if [ $# -ne 1 ] ; then
    echo "UNCERTAIN: Invalid number of arguments - Usage: cpu_load <max_load_pct>"
    exit 1
fi

# Check the CPU usage
for PSID in `ps uax | awk '{if ($3 > 0) {print $3} }'`
do
    TotalPS=`echo "$TotalPS $PSID" | awk '{ print $1 + $2 }'`
done

# Check if the CPU usage good or bad is
st=$(echo "$TotalPS < $Max" | bc)
if [ $st -eq 1 ] ; then
    echo "SUCCESS: CPU usage is [$TotalPS%], maximum allowed=[$1%] DATA:$TotalPS%   $loaddelta"
else
    echo "ERROR: CPU usage is [$TotalPS%], maximum allowed=[$1%] DATA:$TotalPS%   $loaddelta"
fi
 