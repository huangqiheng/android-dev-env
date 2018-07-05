#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt build-essential

	goCmd=/usr/local/go/bin/go
	userName="$1"

	if ! cmd_exists "$goCmd" ; then
		cd $CACHE_DIR
		wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
		tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
		echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
		echo 'export PATH=$PATH:$HOME/go/bin' >> /etc/profile
	fi

	if [ "$userName" = "" ]; then
		echo "please input user name"
		exit 1
	fi

	su $userName -c "

	source /etc/profile;

	go get -u -d github.com/ipfs/go-ipfs;
	cd $HOME/go/src/github.com/ipfs/go-ipfs;
	make install;

	go get github.com/Kubuxu/go-ipfs-swarm-key-gen/ipfs-swarm-key-gen;
	ipfs-swarm-key-gen > ~/.ipfs/swarm.key;
"

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
