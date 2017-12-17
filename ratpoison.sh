#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt xinit ratpoison 
	check_apt fonts-wqy-zenhei fcitx-frontend-fbterm fcitx-imlist fcitx-googlepinyin
	check_apt xterm firefox

	echo "
exec fcitx

exec rpws init 6 -k
bind M-1 exec rpws 1
bind M-2 exec rpws 2
bind M-3 exec rpws 3
bind M-4 exec rpws 4
bind M-5 exec rpws 5
bind M-6 exec rpws 6

bind c exec xterm -rv -fa nonaco -fs 13
bind C-f exec firefox
	" > ~/.ratpoisonrc
}

main "$@"; exit $?

