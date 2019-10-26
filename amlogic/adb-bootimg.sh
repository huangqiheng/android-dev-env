#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	targetDev=$(get_partition_path 'boot')
	pull_partition $targetDev
	log_y "Got it: $PULLED_IMG"

	check_split_bootimg $PULLED_IMG
}


main "$@"; exit $?
