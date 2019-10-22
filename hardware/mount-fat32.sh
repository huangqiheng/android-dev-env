#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	mount -t vfat -o iocharset=cp936 $1 $2
	cat <<EOL
for new device: 
	mkfs.vfat -o iocharset=cp936 $1 $2
EOL
}

main "$@"; exit $?

