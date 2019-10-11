#!/bin/dash

. $(dirname $(dirname $(dirname $(readlink -f $0))))/basic_functions.sh

#https://www.dlaube.de/2019/06/26/cross-compiling-u-boot-for-aarch64-on-arch-linux/

main () 
{
	check_apt build-essential
	check_apt bison flex 
	check_apt gcc-aarch64-linux-gnu

	cd $CACHE_DIR

	if [ ! -f u-boot ]; then
		git clone https://github.com/u-boot/u-boot.git
	fi

	if ! cd u-boot; then
		log_r 'clone u-boot error'
		exit 1
	fi

	git clean -fdx
	export CROSS_COMPILE=aarch64-linux-gnu-
	make u200_defconfig
	make -j $(nproc)

	log_y "see $CACHE_DIR" 
}

main "$@"; exit $?
