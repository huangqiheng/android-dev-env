#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	cd $CACHE_DIR
	git clone https://github.com/udalov/kotlin-vim.git
	cd kotlin-vim

	mkdir -p ~/.vim/{syntax,indent,ftdetect}
	cp syntax/kotlin.vim ~/.vim/syntax/kotlin.vim
	cp indent/kotlin.vim ~/.vim/indent/kotlin.vim
	cp ftdetect/kotlin.vim ~/.vim/ftdetect/kotlin.vim
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
