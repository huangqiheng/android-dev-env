#!/bin/bash

backup_file=$(pwd)/dump.backup

if [ $(whoami) != 'root' ]; then
	echo "Must be executed as root"
	exit 1
fi

if [ "$1" = "help" ]; then
	cat << EOL
	./backup_dump.sh 		# dump / as $PWD/dump.backup
	./backup_dump.sh /dev/sda1	# restore $PWD/dump.backup to mounted /dev/sda1
EOL
	exit 0
fi

if [ "$1" = "" ]; then
	if [ -f $backup_file ]; then
		back_file="${backup_file%.*}"
		back_file=$back_file.pre.backup
		mv $backup_file $back_file
	fi

	dump -0uan -f $backup_file /
	echo "backup to $backup_file completed"
else 
	if blkid $1 | grep PARTUUID > /dev/null 2>&1; then
		restore -r -f $backup_file
		echo "restore to $1 completed"
	fi
fi

