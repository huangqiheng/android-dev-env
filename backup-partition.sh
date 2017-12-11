#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
check_bash $@
check_sudo

main () 
{
	if [ "$1" = "" ] || [ "$1" = "help" ] || [ "$2" = "" ]; then
		print_usage
		exit 1
	fi

	local infile=$1
	local outfile=$2

	if is_device "$infile"; then
		if is_device "$outfile"; then
			echo "The output file must be normal file as *.img.gz"
			exit 1
		fi

		outfile=$(readlink -f $outfile)

		if [ $(echo $outfile | grep -c "img.gz") -eq 0 ]; then
			echo "The output file must be *.img.gz ($2)"
			exit 1
		fi

		if [ -f $outfile ]; then
			local pre_outfile="${outfile%.*}"
			pre_outfile=$pre_outfile.pre.img.gz
			mv $outfile $pre_outfile
		fi

		echo Input device: $infile
		echo Backup gzip file: $outfile

		dd if=$infile | gzip -c > $outfile bs=1024K conv=noerror,sync status=progress

	else
		if ! is_device "$outfile"; then
			echo "The output must be device like /dev/sda1"
			exit 1
		fi

		if [ ! -f $infile ]; then
			echo "The input file must exists"
			exit 1
		fi

		if [ $(echo $infile | grep -c "img.gz") -eq 0 ]; then
			echo "The output file must be *.img.gz ($infile)"
			exit 1
		fi

		echo Input image file: $infile
		echo Output device: $outfile

		gzip -dc $infile | dd of=$outfile bs=1024K conv=noerror,sync status=progress
	fi
}


print_usage()
{
echo "
  Usage:
    ./backup_dd.sh /dev/sda2 sda2.img.gz	# backup sda2 as $PWD/sda2.img.gz
    ./backup_dd.sh sda2.img.gz /dev/sda1	# restore $PWD/dump.backup to mounted /dev/sda1
"
}

is_device()
{
	[ $(lsblk -np --output KNAME | grep -c "$1") -gt 0 ]
}

main "$@"; exit $?
