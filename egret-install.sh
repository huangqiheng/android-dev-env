#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	setup_typescript

	cd $CACHE_DIR
	git clone https://github.com/egret-labs/egret-core.git

	cd egret-core
	npm install -g

	set_comt $CACHE_DIR/egret-core
	set_comt off 'toolsList = project_1.launcher.getLauncherLibrary().getInstalledTools();' '//'

	mkdir -p $HOME/egret-src

	if [ ! -d $HOME/egret-src/helloWorld ]; then
		cd $HOME/egret-src
		egret create helloWorld

		insert_line $HOME/egret-src/helloWorld/src/Main.ts
		insert_line 'private createGameScene' 'console.log("hello egret world");'

		cd helloWorld
		egret run
	fi
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
