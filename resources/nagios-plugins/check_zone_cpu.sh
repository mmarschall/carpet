#!/bin/sh

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# prstat -Z
# PID USERNAME  SIZE   RSS STATE  PRI NICE      TIME  CPU PROCESS/NLWP
# 173 daemon     17M   11M sleep   59    0   3:18:42 0.2% rcapd/1
# 17676 apl    6916K 3468K cpu4    59    0   0:00:00 0.1% prstat/1
# ...
# ZONEID    NPROC  SWAP   RSS MEMORY      TIME  CPU ZONE                        $
#      0       48  470M  482M   1.5%   4:05:57 0.0% global                      $
#      3       85 2295M 2369M   7.2%   0:36:36 0.0% refapp1                     $
#      6       74   13G 3273M    10%  16:51:18 0.0% refdb1                      $
# Total: 207 processes, 709 lwps, load averages: 0.05, 0.06, 0.11$

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -n | --node)
				        shift
                NODE_NAME=$1
                ;;
        -w | --warning)
                shift
                WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
                shift
                CRITICAL_THRESHOLD=$1
                ;;
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done
CPU=`/usr/bin/prstat -Z 1 1 | grep $NODE_NAME | awk '{ print $7 }' | head -c -2`

# Return
	if [ $CPU -ge $WARNING_THRESHOLD ] && [ $CPU -lt $CRITICAL_THRESHOLD ]; then
		echo "CPU WARNING : $NODE_NAME uses ${CPU} % CPU | cpu=${CPU}%;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
		exit $STATE_WARNING
	elif [ $CPU -ge $CRITICAL_THRESHOLD ]; then
		echo "CPU CRITICAL : $NODE_NAME uses ${CPU} % CPU | cpu=${CPU}%;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
		exit $STATE_CRITICAL
	else
		echo "CPU OK : $NODE_NAME uses ${CPU} % CPU | cpu=${CPU}%;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
		exit $STATE_OK
	fi