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

	if is_devblk "$infile"; then
		if is_devblk "$outfile"; then
			echo "The output must be normal file as mbr.bin"
			exit 1
		fi

		outfile=$(readlink -f $outfile)

		if [ -f $outfile ]; then
			local pre_outfile="${outfile%.*}"
			pre_outfile=$pre_outfile.pre.bin
			mv $outfile $pre_outfile
		fi

		echo Input device: $infile
		echo Backup file: $outfile

		dd if=$infile of=$outfile bs=512 count=1 

	else
		if ! is_devblk "$outfile"; then
			echo "The output must be device like /dev/sda"
			exit 1
		fi

		if [ ! -f $infile ]; then
			echo "The input file must exists"
			exit 1
		fi

		echo Input image file: $infile
		echo Output device: $outfile

		dd if=$infile of=$outfile bs=512 count=1 
	fi
}


print_usage()
{
echo "
  Usage:
    ./backup_mbr.sh /dev/sda mbr.img.gz		# backup sda mbr as $PWD/mbr.img.gz
    ./backup_mbr.sh mbr.img.gz /dev/sda		# restore $PWD/mbr.img/gz to /dev/sda mbr
"
}

main "$@"; exit $?

