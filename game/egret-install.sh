#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	setup_typescript

	cd $CACHE_DIR
	if [ ! -d egret-core ]; then
		git clone https://github.com/egret-labs/egret-core.git
	fi

	cd egret-core
	npm install -g

	set_comt $CACHE_DIR/egret-core/tools/commands/run.js
	set_comt off 'toolsList = project_1.launcher.getLauncherLibrary().getInstalledTools();' '//'

	mkdir -p $UHOME/egret-src

	if [ ! -d $UHOME/egret-src/helloWorld ]; then
		cd $UHOME/egret-src
		egret create helloWorld

		insert_line $UHOME/egret-src/helloWorld/src/Main.ts
		insert_line 'private createGameScene' 'console.log("hello egret world");'

		cd helloWorld
		egret run
	fi

	chownUser $UHOME/egret-src
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
