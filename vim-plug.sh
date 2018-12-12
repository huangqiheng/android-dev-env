#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	plugfile=$UHOME/.vim/autoload/plug.vim

	if [ ! -f $plugfile ]; then
		curl -fLo $plugfile --create-dirs \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	fi

	tsvim_file=$UHOME/.vim/bundle/typescript-vim

	if [ ! -d $tsvim_file ]; then
		git clone https://github.com/leafgarland/typescript-vim.git $tsvim_file
	fi

	rccontent=$(cat <<-END
call plug#begin('~/.vim/plugged')
Plug 'leafgarland/typescript-vim'
call plug#end()
END
)
	vimrc 'typescript-vim' "$rccontent"

	echo 'Now, open vim, and type ":PlugInstall"'
}

vimrc()
{
	echo_file=$UHOME/.vimrc

	if [ -f $echo_file ]; then
		if grep -iq "$1" $echo_file; then
			return 1
		fi

		echo "$2" >> $echo_file
	else 
		echo "$2" > $echo_file
	fi
	return 0
}


main "$@"; exit $?

