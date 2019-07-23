#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

# https://www.jianshu.com/p/9d93b1754549

main () 
{
	check_sudo
	check_apt openjdk-8-jdk

	cd $CACHE_DIR

	mkdir -p xmind
	cd xmind

	if [ ! -f xmind-8-update8-linux.zip ]; then
		wget http://dl2.xmind.net/xmind-downloads/xmind-8-update8-linux.zip
	fi

	if [ ! -d XMind_amd64 ]; then
		unzip xmind-8-update8-linux.zip
	fi

	cd XMind_amd64

	if [ -f XMindCrack.jar ]; then
		cp "$DATA_DIR/XMind_amd64.tar" ./
		tar xvf XMind_amd64.tar
	fi

	# echo to XMind.ini
	handle_rc './XMind.ini' 'java-8-openjdk-amd64' "-vm\n/usr/lib/jvm/java-8-openjdk-amd64/bin"

	# echo to hosts
	# 127.0.0.1 www.xmind.net
	handle_rc '/etc/hosts' 'www.xmind.net' '127.0.0.1 www.xmind.net'

	rm /usr/local/bin/xmind
	ln -sf $CACHE_DIR/xmind/XMind_amd64/XMind /usr/local/bin/xmind

	log_y "Help -> License 
XAka34A2rVRYJ4XBIU35UZMUEEF64CMMIYZCK2FZZUQNODEKUHGJLFMSLIQMQUCUBXRENLK6NZL37JXP4PZXQFILMQ2RG5R7G4QNDO3PSOEUBOCDRYSSXZGRARV6MGA33TN2AMUBHEL4FXMWYTTJDEINJXUAV4BAYKBDCZQWVF3LWYXSDCXY546U3NBGOI3ZPAP2SO3CSQFNB7VVIY123456789012345
"
	log_y 'just try xmind to run'
}

main "$@"; exit $?
