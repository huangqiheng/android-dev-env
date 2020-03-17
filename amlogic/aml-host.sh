#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main () 
{
	check_apt nmap

	if [ -z "$1" ]; then
		for subnet in $(ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'); do
			nmap -sP $subnet | grep "Nmap scan report for aml" 
		done
	else 
		nmap -sP "$1" | grep "Nmap scan report for aml" 
	fi
	
}

#--------------------------------------------------------#
main_entry $@
