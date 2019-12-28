#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	if ! cmd_exists pip3; then
		check_apt python3-pip
	fi

	if ! cmd_exists opendrop; then
		check_sudo
		pip3 install opendrop
	fi

	if ! cmd_exists owl; then
		check_sudo
		check_apt libpcap-dev libev-dev libnl-3-dev libnl-genl-3-dev libnl-route-3-dev
		check_apt cmake

		cd $CACHE_DIR
		if [ ! -f owl/README.md ]; then
			git clone https://github.com/seemoo-lab/owl.git
		fi
		cd owl
		git submodule update --init
		mkdir build
		cd build
		cmake ..
		make
		make install
	fi

	cat << EOF
    Trys: 
	opendrop find
	  Looking for receivers. Press enter to stop ...
	  Found  index 0  ID eccb2f2dcfe7  name John’s iPhone
	  Found  index 1  ID e63138ac6ba8  name Jane’s MacBook Pro
	opendrop send -r 0 -f /path/to/some/file
	  Asking receiver to accept ...
	  Receiver accepted
	  Uploading file ...
	  Uploading has been successful
	opendrop receive
EOF


}

main "$@"; exit $?
