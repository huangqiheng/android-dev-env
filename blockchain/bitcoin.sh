#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt software-properties-common
	check_update ppa:bitcoin/bitcoin
	check_apt bitcoind bitcoin-qt

	cat << EOL
start:
	bitcoind -daemon -txindex

getinfo:
	bitcoin-cli getinfo 

get first block:
	bitcoin-cli getblockhash 0

view block content:
	bitcoin-cli getblock
EOL
}

main "$@"; exit $?
