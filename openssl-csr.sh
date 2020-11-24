#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo

	if [ "$1" = "" ]; then
		log 'must input domain name as parmameter'
		exit 0
	fi

	sslpath=$CACHE_DIR/ssl
	mkdir -p $sslpath

	keyFile=$sslpath/$1.key
	csrFile=$sslpath/$1.csr

	if [ ! -f $keyFile]; then
		openssl genrsa –des3 –out "$keyFile" 2048
	fi

	openssl req –new –key $keyFile –out $csrFile
	# https://www.thesslstore.com/blog/generate-2048-bit-csr/ 
}

main "$@"; exit $?

