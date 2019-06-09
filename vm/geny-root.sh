#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	cd $CACHE_DIR
	if [ ! -f 'rootcheck-5.6.8-APK.rar' ]; then
		wget http://root-checker.org/download/rootcheck-5.6.8-APK.rar
		unrar rootcheck-5.6.8-APK.rar
	fi

	if [ ! -f 'UPDATE-SuperSU-v2.46.zip' ]; then
		wget https://download.chainfire.eu/696/SuperSU/UPDATE-SuperSU-v2.46.zip?retrieve_file=1 -O UPDATE-SuperSU-v2.46.zip
	fi

	adb push --sync rootcheck-5.6.8-APK.apk /sdcard/Download/
	adb install rootcheck-5.6.8-APK.apk

	adb push --sync UPDATE-SuperSU-v2.46.zip /sdcard/Download/
	adb shell flash-archive.sh /sdcard/Download/UPDATE-SuperSU-v2.46.zip
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
