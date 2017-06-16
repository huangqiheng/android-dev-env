#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	check_update
	check_apt git autoconf libreadline6-dev protobuf-compiler 


}

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "
	This script should be executed as root or with sudo:
	    sudo $0
	"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	if [ $diff_time -gt 604800 ]; then
		apt update -y
	fi 

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

check_apt()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			log "${package} has been installed"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

command_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
