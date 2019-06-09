#!/bin/bash

if [ $(whoami) != 'root' ]; then
	echo "Must be executed as root"
	exit 1
fi

cd /home

if [ "$1" = 'restore' ]; then
	echo 'RESTORE the os, Ctrl-C for Exit, Enter for continue.'
	read input 
	echo 'Waiting for "DONE" ......'

	tar -xpzf backup.tar.gz -C / --numeric-owner

	echo 'DONE'

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
	echo 'BACKUP the os, Ctrl-C for Exit, Enter for continue.'
	read input 
	echo 'Waiting for "DONE" ......'

	excludeStr="--exclude=/home"

	if [ -f /swap.img ]; then
		excludeStr="$excludeStr ----exclude=/swap.img"
	fi

	tar -cpzf __backup.tar.gz $excludeStr --one-file-system / 
	ret=$?

	echo "tar return: ${ret}"
	echo 'DONE'

	if [ "$ret" -ne 2 ]; then
		mv __backup.tar.gz backup.tar.gz
	else
		unlink __backup.tar.gz
		echo 'backup error'
		exit 1
	fi
fi

