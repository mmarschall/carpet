#!/bin/sh
#
# Check if a service is enabled or disabled
#
# check_smf <-e | -d> <service name>
#
# Requires Solaris 10
#
# Michael Hocke, Oct 4, 2006

USAGE="$0 < -e | -d > <service name>"

# include Nagios utilities
. /usr/local/nagios/libexec/utils.sh

# parse commandline
set -- `getopt ed $*`
if [ $? -ne 0 ]; then
  echo $USAGE
  exit 2
fi
for i in $*; do
  case $i in
    -e | -d)  if [ -n "$FLAG" ]; then
		echo $USAGE
		exit 2
	      else
		FLAG=$i
		shift
	      fi;;
    --)  shift; break;;
  esac
done
if [ -z "$1" ]; then
  echo $USAGE
  exit 2
else
  SERVICE=$1
  shift
fi
if [ -n "$1" -o -z "$FLAG" ]; then
  echo $USAGE
  exit 2
fi

# check status of service
STATE=`/usr/bin/svcs -o state -H $SERVICE 2>&1`
if [ $? -ne 0 ]; then
  echo "SVCS CRITICAL: service $SERVICE unknown"
  exit $STATE_CRITICAL
fi
if [ "$STATE" = "online" -a "$FLAG" = "-e" ]; then
  echo "SVCS OK: service $SERVICE is online"
  exit $STATE_OK
elif [ "$STATE" = "disabled" -a "$FLAG" = "-d" ]; then
  echo "SVCS OK: service $SERVICE is disabled"
  exit $STATE_OK
else
  echo "SVCS CRITICAL: service $SERVICE is $STATE"
  exit $STATE_CRITICAL
fi
