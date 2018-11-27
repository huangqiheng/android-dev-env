#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if cmd_exists amap; then
		echo "amap has been installded"
		exit 0
	fi

	amapFile="amap-5.4.tar.gz"

	cd $DATA_DIR

	if [ ! -f "$amapFile" ]; then
		wget https://raw.githubusercontent.com/vanhauser-thc/THC-Archive/master/Tools/${$amapFile}
	fi

	tar xzvf $amapFile
	amapDir=$(dirname $amapFile)
	amapDir=$(dirname $amapDir)
	cd $amapDir

	./configure
	make 
	make install

	amap --help
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
