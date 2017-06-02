#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update
	apt_prepare_tools
	build_srs
}

build_srs()
{
	cd $THIS_DIR
	mkdir -p temp && cd temp

	if [ ! -d "srs" ]; then
		git clone https://github.com/ossrs/srs
	fi

	cd srs/trunk
	./configure --prefix=/opt/srs --full
	make
	cp -fv /opt/srs/etc/init.d/srs /etc/init.d/srs

	/etc/init.d/srs start
}

apt_update ()
{
	if [ -z "$1" ]; then
		input=864000
	else 
		input=$1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y 
	fi 
}

apt_prepare_tools () 
{
	apt install -y build-essential git python
}

main "$@"; exit $?
