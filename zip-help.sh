#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

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

EOL
	echo "${Color_Off}"
	exit 0
}

maintain "$@"; main "$@"; exit $?
