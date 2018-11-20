#!/bin/bash

if [ $(whoami) != 'root' ]; then
	echo "Must be executed as root"
	exit 1
fi

cd /

if [ "$1" = 'restore' ]; then
	read -p 'RESTORE the os, Ctrl-C for Exit, Enter for continue.'

	tar -xvpzf backup.tar.gz -C / --numeric-owner

	if [ "$?" -ne 0 ]; then
		echo 'restore error'
		exit 1
	fi
	
	for item in /proc /sys /mnt /media; do 
		if [ ! -d $item ]; then
			mkdir $item
		fi
	done

else 
	tar -cvpzf __backup.tar.gz --exclude=/backup.tar.gz --one-file-system / 
	ret=$?

	echo "tar return: ${ret}"

	if [ "$ret" -ne 2 ]; then
		mv __backup.tar.gz backup.tar.gz
	else
		unlink __backup.tar.gz
		echo 'backup error'
		exit 1
	fi
fi

