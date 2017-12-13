#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt xinit ratpoison 
	check_apt fonts-wqy-zenhei fcitx-frontend-fbterm fcitx-imlist fcitx-googlepinyin
	check_apt xterm

}

main "$@"; exit $?

