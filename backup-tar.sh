#!/bin/bash

if [ $(whoami) != 'root' ]; then
	echo "Must be executed as root"
	exit 1
fi

cd /

if [ "$1" = 'restore' ]; then
	echo 'RESTORE the os, Ctrl-C for Exit, Enter for continue.'
	read input 

	tar -xpzf backup.tar.gz -C / --numeric-owner

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

	tar -cpzf __backup.tar.gz \ 
		--exclude=/swap.img \
		--exclude=/backup.tar.gz \
		--exclude=/__backup.tar.gz \ 
		--one-file-system / 
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

