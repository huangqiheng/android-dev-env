#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_docker

	select_subpath $CACHE_DIR/$EXEC_NAME "$1"
	TargetDir="$CACHE_DIR/$EXEC_NAME/$FUNC_RESULT"
	ContName=$(rm_space "$FUNC_RESULT")

	chownUser $CACHE_DIR

	docker run --rm -it --privileged \
		--hostname="$(hostname)$ContName" \
		-v /etc/localtime:/etc/localtime:ro \
		-p 139:139 -p 445:445 \
		-p 137:137/udp -p 138:138/udp \
		-v $TargetDir:/mount \
		--name "samba-$ContName" dperson/samba -n -p -W \
		-u "$RUN_USER;badpass" \
		-s "public;/mount"

	self_cmdline
}

main_entry $@
