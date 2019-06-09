#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`
url_driver_runfile=http://us.download.nvidia.com/XFree86/Linux-x86_64/384.59/NVIDIA-Linux-x86_64-384.59.run
url_cuda_runfile=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run
url_cuda_patch_runfile=https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda_8.0.61.2_linux-run

main () 
{
	check_bash
	check_update ppa:graphics-drivers/ppa
	check_apt build-essential autoconf automake pkg-config
	check_apt freeglut3-dev libx11-dev libxmu-dev libxi-dev libgl1-mesa-glx libglu1-mesa libglu1-mesa-dev libglfw3-dev libgles2-mesa-dev
	check_apt linux-headers-$(uname -r)

	export GLPATH=/usr/lib
	cd $ROOT_DIR && mkdir -p temp && cd temp

	if ! apt_exists lubuntu-core; then
		apt install -y lubuntu-core --no-install-recommend
		systemctl set-default multi-user.target
	fi

	if ! apt_exists nvidia-384; then
		check_apt nvidia-384 nvidia-384-dev nvidia-modprobe
		log 'NEED TO REBOOT THE SYSTEM, TO MAKE THE DRIVER EFFECT.'
		log 'THEN RUN THIS SCRIPT AGAIN.'
		exit 0
	fi


	for url in $url_driver_runfile $url_cuda_runfile $url_cuda_patch_runfile; do
		if [ ! -f $(basename $url) ]; then
			wget --no-check-certificate $url
		fi
	done

	if ! cmd_exists /usr/local/cuda/bin/nvcc; then
		echo 'DO NOT INSTALL THE DISPLAY DRIVER 375'
		read -p 'Press Enter to continue'
		torun=$(basename $url_cuda_runfile)
		chmod a+x ./$torun && ./$torun

		echo 'NOW INSTALL THE PATCH'
		read -p 'Press Enter to continue'
		torun=$(basename $url_cuda_patch_runfile)
		chmod a+x ./$torun && ./$torun

		echo_to=/root/.bashrc
		if ! grep -q "cuda-8.0" $echo_to; then
			echo 'export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}' >> $echo_to 
			echo 'export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> $echo_to
			source $echo_to
		fi
	fi

	deviceQuery=/root/NVIDIA_CUDA-8.0_Samples/bin/x86_64/linux/release/deviceQuery

	if [ ! -d /root/NVIDIA_CUDA-8.0_Samples/bin ]; then
		cd /root/NVIDIA_CUDA-8.0_Samples
		make -j 4
	fi

	if [ -f $deviceQuery ]; then
		if [ $($deviceQuery | grep -c 'Result = PASS') -gt 0 ]; then
			log 'Cuda environment is OK'
			log 'ALL DONE'
			exit 0
		else 
			log 'Cuda compiler environment has errors'
			exit 1
		fi 
	else 
		log "ERROR: Not found $deviceQuery"
		exit 1
	fi
}


#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_bash()
{
	[ -z "$BASH_VERSION" ] && echo "Change to: bash $0" && setsid bash $0 && exit
}

check_sudo()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	sudo $0"
	    exit 1
	fi
}

check_update()
{
	check_sudo

	if [ "$1" = 'f' ]; then
		apt update -y
		apt upgrade -y
		return 0
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

apt_exists()
{
	[ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]
}

check_apt()
{
	for package in "$@"; do
		if apt_exists $package; then
			log "${package} has been installed"
		else
			apt install -y "$package"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

cmd_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?

