#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main () 
{
	check_apt rar unrar p7zip-full
	show_help_exit
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	echo "${Yellow}"
	cat << EOL
zip:
  zip -r file.zip ./path/to/dir
  unzip file.zip

tar gz:
  tar -zxvf xx.tar.gz

tar bz:
  tar -jxvf xx.tar.bz2

rar:
  rar a -r file.rar /path/to/dir   	// zip file
  rar l file.rar		     	// list file
  rar x file.rar		     	// unzip file

unrar:
  unrar e -r file.rar			// all file unpack in same dir
  unrar x -r file.rar			// with full path

7z:
  7z a file.7z /path/to/dir	    	// zip file
  7z l file.7z				// list file
  7z x file.7z			   	// unzip file

xz-utils
  unxz file.xz
  xz --decompress file.xz

EOL
	echo "${Color_Off}"
	exit 0
}

#---------------------------------------------------------------------------------#
main_entry $@
