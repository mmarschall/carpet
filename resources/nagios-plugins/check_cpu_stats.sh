#!/bin/bash
# ========================================================================================
# CPU Utilization Statistics plugin for Nagios 
#
# Written by	: Steve Bosek
# Patched by  : Bas van der Doorn
# Release	: 2.2
# Creation date	: 8 September 2007
# Revision date : 23 November 2008
# Package       : DTB Nagios Plugin
# Description   : Nagios plugin (script) to check cpu utilization statistics.
#		This script has been designed and written on Unix plateform (Linux, Aix, Solaris), 
#		requiring iostat as external program. The locations of these can easily 
#		be changed by editing the variables $IOSTAT at the top of the script. 
#		The script is used to query 4 of the key cpu statistics (user,system,iowait,idle)
#		at the same time. Note though that there is only one set of warning 
#		and critical values for iowait percent.
#
# Usage         : ./check_cpu_stats.sh [-w <warn>] [-c <crit] ( [ -i <intervals in second> ] [ -n <report number> ]) 
# ----------------------------------------------------------------------------------------
#
# TODO:  Support for HP-UX
#		      
#
# ========================================================================================
#
# HISTORY :
#     Release	|     Date	|    Authors	| 	Description
# --------------+---------------+---------------+------------------------------------------
# 	2.0	|    16.02.08	|  Steve Bosek	| Solaris support and new parameters 
#               | 		|               | New Parameters : - iostat seconds intervals 
#               |               |               |         	   - iostat report number
#  2.1 |  08.06.08 | Steve Bosek | Bug perfdata and convert comma in point for Linux result
#  2.1.1 | 20.11.08 | Bas van der Doorn | Fixed improperly terminated string
#  2.1.2 | 23.11.08 | Bas van der Doorn | Fixed linux steal reported as idle, comparisons
#  2.2 | 23.11.08 | Bas van der Doorn | Capable systems will output nice and steal data
# -----------------------------------------------------------------------------------------
#	
# =========================================================================================

# Paths to commands used in this script.  These may have to be modified to match your system setup.

IOSTAT=/usr/bin/iostat

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin parameters value if not define
WARNING_THRESHOLD=${WARNING_THRESHOLD:="30"}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:="100"}
INTERVAL_SEC=${INTERVAL_SEC:="1"}
NUM_REPORT=${NUM_REPORT:="3"}

# Plugin variable description
PROGNAME=$(basename $0)
RELEASE="Revision 2.1.1"
AUTHOR="(c) 2008 Steve Bosek (steve.bosek@gmail.com)"

if [ ! -x $IOSTAT ]; then
	echo "UNKNOWN: iostat not found or is not executable by the nagios user."
	exit $STATE_UNKNOWN
fi

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
	echo ""
	echo "$PROGNAME $RELEASE - CPU Utilization check script for Nagios"
	echo ""
	echo "Usage: check_cpu_stats.sh -w -c (-i -n)"
	echo ""
	echo "	-w  Warning level in % for cpu iowait"
	echo "	-c  Crical level in % for cpu iowait"
	echo "  -i  Interval in seconds for iostat (default : 1)"
	echo "  -n  Number report for iostat (default : 3)"
	echo "	-h  Show this page"
	echo ""
    echo "Usage: $PROGNAME"
    echo "Usage: $PROGNAME --help"
    echo ""
}

print_help() {
	print_usage
        echo ""
        echo "This plugin will check cpu utilization (user,system,iowait,idle in %)"
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
        -w | --warning)
                shift
                WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
               shift
                CRITICAL_THRESHOLD=$1
                ;;
        -i | --interval)
               shift
               INTERVAL_SEC=$1
                ;;
        -n | --number)
               shift
               NUM_REPORT=$1
                ;;        
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

# CPU Utilization Statistics Unix Plateform ( Linux,AIX,Solaris are supported )
case `uname` in
	Linux ) CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g' | tr -s ' ' ';' | sed '/^$/d' | tail -1`
			CPU_REPORT_SECTIONS=`echo ${CPU_REPORT} | grep ';' -o | wc -l`
			CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 2`
			CPU_NICE=`echo $CPU_REPORT | cut -d ";" -f 3`
			CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 4`
			CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 5`
			CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
		if [ ${CPU_REPORT_SECTIONS} -ge 6 ]; then
			CPU_STEAL=`echo $CPU_REPORT | cut -d ";" -f 6`
			CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 7`
			NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% nice=${CPU_NICE}% steal=${CPU_STEAL}% | CpuUser=${CPU_USER};CpuSystem=${CPU_SYSTEM};CpuIoWait=${CPU_IOWAIT};CpuIdle=${CPU_IDLE};CpuNice=${CPU_NICE};CpuSteal=${CPU_STEAL};$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
		else
			CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 6`
			NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% nice=${CPU_NICE}% | CpuUser=${CPU_USER};CpuSystem=${CPU_SYSTEM};CpuIoWait=${CPU_IOWAIT};CpuIdle=${CPU_IDLE};CpuNice=${CPU_NICE};$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
		fi		
            ;;
 	AIX ) CPU_REPORT=`iostat -t $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g'|tr -s ' ' ';' | tail -1`
			CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 4`
			CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 5`
			CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 7`
			CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
			CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 6`
			NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% | CpuUser=${CPU_USER};CpuSystem=${CPU_SYSTEM};CpuIoWait=${CPU_IOWAIT};CpuIdle=${CPU_IDLE};$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
            ;;
  	SunOS ) CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | tail -1`
      			CPU_USER=`echo $CPU_REPORT | awk '{ print $1 }'`
			CPU_SYSTEM=`echo $CPU_REPORT | awk '{ print $2 }'`
			CPU_IOWAIT=`echo $CPU_REPORT | awk '{ print $3 }'`
			CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
			CPU_IDLE=`echo $CPU_REPORT | awk '{ print $4 }'`
			NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% | CpuUser=${CPU_USER};CpuSystem=${CPU_SYSTEM};CpuIoWait=${CPU_IOWAIT};CpuIdle=${CPU_IDLE};$WARNING_THRESHOLD;$CRITICAL_THRESHOLD"
            ;;
	*) 		echo "UNKNOWN: `uname` not yet supported by this plugin. Coming soon !"
			exit $STATE_UNKNOWN 
	    ;;
	esac

# Return
	if [ ${CPU_IOWAIT_MAJOR} -ge $WARNING_THRESHOLD ] && [ ${CPU_IOWAIT_MAJOR} -lt $CRITICAL_THRESHOLD ]; then
		echo "CPU STATISTICS WARNING : ${NAGIOS_DATA}"
		exit $STATE_WARNING
	elif [ ${CPU_IOWAIT_MAJOR} -ge $CRITICAL_THRESHOLD ]; then
		echo "CPU STATISTICS CRITICAL : ${NAGIOS_DATA}"
		exit $STATE_CRITICAL
	else
		echo "CPU STATISTICS OK : ${NAGIOS_DATA}"
		exit $STATE_OK
	fi



