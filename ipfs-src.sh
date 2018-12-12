#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt build-essential

	goCmd=/usr/local/go/bin/go
	userName="$LOGNAME"

	if ! cmd_exists "$goCmd" ; then
		cd $CACHE_DIR
		wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
		tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
		echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
		echo 'export PATH=$PATH:$UHOME/go/bin' >> /etc/profile
	fi

	su $userName -c "

	source /etc/profile;

	go get -u -d github.com/ipfs/go-ipfs;
	go get github.com/Kubuxu/go-ipfs-swarm-key-gen/ipfs-swarm-key-gen;

	cd /home/$userName/go/src/github.com/ipfs/go-ipfs;
	make install;

	ipfs init;
"

	cat << EOL
set private ipfs:
	ipfs-swarm-key-gen > ~/.ipfs/swarm.key;
	ipfs bootstrap rm --all
	ipfs add /ip4/10.0.2.7/tcp/4001/ipfs/QmSoLV....
	export LIBP2P_FORCE_PNET=1
	ipfs daemon
EOL

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
