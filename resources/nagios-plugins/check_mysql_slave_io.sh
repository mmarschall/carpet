#!/bin/sh

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -p | --password)
                shift
                PASSWORD=$1
                ;;
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done


IO_RUNNING=`/usr/mysql/bin/mysql -u root --password=$PASSWORD --execute 'SHOW SLAVE STATUS\G' | grep Slave_IO_Running | awk '{print $2}'`

# Return
  if [ '$IO_RUNNING' = 'No' ]; then
		echo "Slave IO CRITICAL : Slave IO not running"
		exit $STATE_CRITICAL
	else
		echo "Slave IO OK : Slave IO running"
		exit $STATE_OK
	fi