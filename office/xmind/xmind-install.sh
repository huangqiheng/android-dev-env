#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo
	cd $CACHE_DIR

	if [ ! -d XMind-Linux-Installer ]; then
		git clone https://github.com/dinos80152/XMind-Linux-Installer.git
	fi

	cd XMind-Linux-Installer

	if [ ! -f xmind-8-update8-linux.zip ]; then
		wget http://dl2.xmind.net/xmind-downloads/xmind-8-update8-linux.zip
	fi

	bash xmind-installer.sh

	mkdir -p XMind_amd64
	cd XMind_amd64
	cp "$DATA_DIR/XMind_amd64.tar.gz" ./
	tar xvf XMind_amd64.tar.gz

	# echo to hosts
	# 127.0.0.1 www.xmind.net
	handle_rc '/etc/hosts' 'www.xmind.net' '127.0.0.1 www.xmind.net'

	XMind

	# Help -> License 
	# XAka34A2rVRYJ4XBIU35UZMUEEF64CMMIYZCK2FZZUQNODEKUHGJLFMSLIQMQUCUBXRENLK6NZL37JXP4PZXQFILMQ2RG5R7G4QNDO3PSOEUBOCDRYSSXZGRARV6MGA33TN2AMUBHEL4FXMWYTTJDEINJXUAV4BAYKBDCZQWVF3LWYXSDCXY546U3NBGOI3ZPAP2SO3CSQFNB7VVIY123456789012345

	log_y 'just try xmind to run'
}

main "$@"; exit $?
