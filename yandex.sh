#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	echo "deb http://repo.yandex.ru/yandex-disk/deb/ stable main" | \
		tee -a /etc/apt/sources.list.d/yandex-disk.list > /dev/null
	wget http://repo.yandex.ru/yandex-disk/YANDEX-DISK-KEY.GPG -O- | apt-key add -

	check_update ppa:slytomcat/ppa

	check_aptyandex-disk 
	check_apt yd-tools 
	echo 'yd-tools is ready'
}

init()
{
	check_update
}

main_entry $@
