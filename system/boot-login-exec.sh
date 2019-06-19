#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	login_root_exec "$@" 
}

main "$@"; exit $?



