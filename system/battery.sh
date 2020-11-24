#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_apt acpi
	acpi
}

main "$@"; exit $?


