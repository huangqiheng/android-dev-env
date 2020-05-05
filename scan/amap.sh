#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	if cmd_exists amap; then
		echo "amap has been installded"
		exit 0
	fi

	amapFile="amap-5.4.tar.gz"

	cd $CACHE_DIR

	if [ ! -f "$amapFile" ]; then
		wget "https://raw.githubusercontent.com/vanhauser-thc/THC-Archive/master/Tools/${amapFile}"
	fi

	tar xzvf $amapFile
	cd 'amap-5.4'

	./configure
	make 
	make install

	amap --help
}

#---------------------------------------------------------------------------------#
main_entry $@
