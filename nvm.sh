#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	cd $CACHE_DIR

	if [ ! -f nvm-install.sh ]; then
		wget https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh
		mv install.sh nvm-install.sh
	fi

	bash nvm-install.sh
}

#---------------------------------------------------------------------------------#
main_entry $@
