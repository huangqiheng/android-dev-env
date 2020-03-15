#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS="$EXEC_NAME-apps"

docker_entry()
{
	gen_entrycode '###DOCKER_BEGIN###' '###DOCKER_END###'; return
	###DOCKER_BEGIN###

	###DOCKER_END###
}

main() 
{
	check_sudo
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
EOL

	docker run -it --rm \
		--net host --privileged \
		-v $SubHome:/home/user \
		-v $(docker_entry):/root/entrypoint \
		-v /etc/localtime:/etc/localtime:ro \
		--name "$EXEC_NAME-$SubName" $IMG_APPS

	self_cmdline
}

main_entry $@
