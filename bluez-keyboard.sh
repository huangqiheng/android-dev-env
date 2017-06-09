#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	check_update
	apt_ensure bluez		

	cat << EOL
bluetoothctl executes:
  power on
  agent KeyboardOnly
  default-agent
  pairable on
  scan on
  pair xx:xx:xx:xx:xx:xx
  trust xx:xx:xx:xx:xx:xx
  connect xx:xx:xx:xx:xx:xx
  quit
EOL
	echo $help

	bluetoothctl
}

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

apt_ensure()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			echo "${package} has been installed"
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
