#!/bin/sh

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -p | --password)
                shift
                PASSWORD=$1
                ;;
        -m | --mode)
                shift
                MODE=$1
                ;;
        *)  echo "Unknown argument: $1"
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done


SLAVE_STATUS=`/usr/mysql/bin/mysql -u root --password=$PASSWORD --execute 'SHOW SLAVE STATUS\G' | grep $MODE | awk '{print $2}'`

# Return
  if [ "$SLAVE_STATUS" == "No" ]; then
		echo "$MODE CRITICAL : $MODE reports 'No'"
		exit $STATE_CRITICAL
	elif [ "$SLAVE_STATUS" == "Yes" ]; then
		echo "$MODE OK : $MODE reports 'Yes'"
		exit $STATE_OK
	else
		echo "$MODE UNKNOWN : $MODE reports nothing"
		exit $STATE_UNKNOWN
	fi