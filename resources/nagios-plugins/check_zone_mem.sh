#!/bin/sh

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
        -m | --maxmem)
                shift
                MAX_MEM=$1
                ;;
        -h | --host)
                shift
                HOSTED_ON=$1
                ;;
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
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done
RSS=`/usr/bin/prstat -Z 1 1 | /usr/gnu/bin/grep $NODE_NAME | /usr/gnu/bin/awk '{ print $4 }' | /usr/gnu/bin/head -c -2`

# Return
	if [ $RSS -ge $WARNING_THRESHOLD ] && [ $RSS -lt $CRITICAL_THRESHOLD ]; then
		echo "RSS WARNING : $NODE_NAME uses ${RSS} MB resident memory | rss=${RSS}MB;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM"
		exit $STATE_WARNING
	elif [ $RSS -ge $CRITICAL_THRESHOLD ]; then
		echo "RSS CRITICAL : $NODE_NAME uses ${RSS} MB resident memory | rss=${RSS}MB;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM"
		exit $STATE_CRITICAL
	else
		echo "RSS OK : $NODE_NAME uses ${RSS} MB resident memory | rss=${RSS}MB;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM"
		exit $STATE_OK
	fi