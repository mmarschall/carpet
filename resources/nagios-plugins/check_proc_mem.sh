#!/usr/bin/bash
# ========================================================================================
# Process Memory plugin for Nagios 
#
# Written by         	: Matthias Marschall (mm@agileweboperations.com)
#
# Usage                 : ./check_proc_mem.sh [-w <warn>] [-c <critical>] -C <command>
# ========================================================================================


# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin default level
WARNING_THRESHOLD=${WARNING_THRESHOLD:="5000"}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:="10000"}

# Plugin variable description
PROGNAME=$(basename $0)
RELEASE="Revision 1.1"
AUTHOR="(c) 2008,2009 Matthias Marschall (mm@agileweboperations.com)"

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
	echo ""
	echo "$PROGNAME $RELEASE - Checks Virtual Memory (VSZ) and Resident Memory (RSS) of a given process for Nagios"
	echo ""
	echo "Usage: check_proc_mem.sh"
	echo ""
	echo "		-C  Command (regular expression) to identify process to check"
	echo "		-w  Warning level for kb VSZ used"
	echo "		-c  Critical level for kb VSZ used"
	echo "		-h  Show this page"
	echo ""
    echo "Usage: $PROGNAME -C <command>"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME -w <warning>"
    echo "Usage: $PROGNAME -c <critical>"
    echo ""
}

print_help() {
		print_usage
        echo ""
        print_release $PROGNAME $RELEASE
        echo ""
        echo "This plugin will check the virtual memory and the resident memory of a given process in kb."
		echo "-C is for regular expression identifying the process (grep it out of the ps listing)"
		echo "-w is for VSZ reporting warning level in kb"
		echo "-c is for VSZ reporting critical level in kb"
        echo ""
		exit 0
}


# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -C | --command)
				shift
                COMMAND=$1
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

# debian
#VSZ=`/bin/ps axwo 'vsz rss comm args' | grep "${COMMAND}" | head -1 | gawk '{print $1}'`
#RSS=`/bin/ps axwo 'vsz rss comm args' | grep "${COMMAND}" | head -1 | gawk '{print $2}'`
#PROC_NAME=`/bin/ps axwo 'vsz rss comm args' | grep "${COMMAND}" | head -1 | gawk '{print $3}'`
#MAX_MEM=`/usr/bin/free -m | head -2 | tail -1 | gawk '{print $2}'`

# OpenSolaris
VSZ=`/usr/bin/ps -eo 'vsz rss comm args' | grep "${COMMAND}" | grep -v "grep" | grep -v "/usr/bin/bash" | awk '{print $1}'`
RSS=`/usr/bin/ps -eo 'vsz rss comm args' | grep "${COMMAND}" | grep -v "grep" | grep -v "/usr/bin/bash" | awk '{print $2}'`
PROC_NAME=`/usr/bin/ps -eo 'vsz rss comm args' | grep "${COMMAND}" | grep -v "grep" | grep -v "/usr/bin/bash" | awk '{print $4}'`
MAX_MEM=$((`/usr/sbin/prtconf 2>/dev/null | grep 'Memory size:' | awk '{print $3}'`*1024))

# Return
	if [ $VSZ -ge $WARNING_THRESHOLD ] && [ $VSZ -lt $CRITICAL_THRESHOLD ]; then
		echo "VSZ WARNING : $PROC_NAME uses ${VSZ} kb virt and ${RSS} kb resident memory | vsz=${VSZ}kb;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM rss=${RSS}kb"
		exit $STATE_WARNING
	elif [ $VSZ -ge $CRITICAL_THRESHOLD ]; then
		echo "VSZ CRITICAL : $PROC_NAME uses ${VSZ} kb virt and ${RSS} kb resident memory | vsz=${VSZ}kb;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM rss=${RSS}kb"
		exit $STATE_CRITICAL
	else
		echo "VSZ OK : $PROC_NAME uses ${VSZ} kb virt and ${RSS} kb resident memory | vsz=${VSZ}kb;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0;$MAX_MEM rss=${RSS}kb"
		exit $STATE_OK
	fi
