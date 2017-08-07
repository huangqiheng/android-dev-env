#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

cuda_base=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb
cuda_patch=https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda-repo-ubuntu1604-8-0-local-cublas-performance-update_8.0.61-1_amd64-deb
nvenc_sdk=http://developer.download.nvidia.com/compute/nvenc/v5.0/nvenc_5.0.1_sdk.zip
cuda_utils=http://developer.download.nvidia.com/compute/redist/ffmpeg/1511-patch/cudautils.zip
gpu_acce=http://developer.download.nvidia.com/compute/redist/ffmpeg/1511-patch/ffmpeg_NVIDIA_gpu_acceleration.patch

main () 
{
	check_bash
	check_update ppa:graphics-drivers/ppa

	check_apt build-essential git yasm unzip wget sysstat
	check_apt freeglut3-dev libx11-dev libxmu-dev libxi-dev libgl1-mesa-glx libglu1-mesa libglu1-mesa-dev libglfw3-dev libgles2-mesa-dev
	check_apt linux-headers-$(uname -r)

	#----------------------------------------#
	# install display driver
	#----------------------------------------#

	systemctl stop lightdm
	rmmod nvidia_drm
	rmmod nvidia_uvm
	rmmod nvidia_modeset
	rmmod nvidia
	apt remove -y nvidia*

	check_apt nvidia-375 nvidia-modprobe

	apt install --reinstall ubuntu-desktop
	systemctl set-default multi-user.target

	# need to restart ubuntu


	#----------------------------------------#
	# install nvenc sdk
	#----------------------------------------#

	cd $THIS_DIR && mkdir -p temp && cd temp

	nvenc_zip=$(basename "$nvenc_sdk")

	if [ ! -f $nvenc_zip ]; then
		wget $nvenc_sdk
	fi

	unzip $nvenc_zip

	nvenc_dir="${nvenc_zip%.*}"
	cp $nvenc_dir/Samples/common/inc/*.h /usr/local/include


	#----------------------------------------#
	# install cuda utility
	#----------------------------------------#

	cd $THIS_DIR/temp

	utils_zip=$(basename "$cuda_utils")

	if [ ! -f $utils_zip ]; then
		wget $cuda_utils
	fi

	unzip $utils_zip

	nvenc_dir="${utils_zip%.*}"
	cd $nvenc_dir
	make

	#----------------------------------------#
	# build nasm-2.13 for x264
	#----------------------------------------#

	cd $THIS_DIR/temp
	if [ ! -f "nasm-2.13.01.tar.xz" ]; then
		wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz
	fi

	tar -xf nasm-2.13.01.tar.xz
	cd nasm-2.13.01
	./configure --prefix=/usr
	make
	make install

	#----------------------------------------#
	# build x264
	#----------------------------------------#

	apt -y remove x264 libx264-dev

	cd $THIS_DIR/temp
	if [ ! -d x264 ]; then
		git clone git://git.videolan.org/x264.git
	fi

	cd x264
	./configure --disable-cli --enable-static --enable-shared --enable-strip
	make -j 4
	make install
	ldconfig

	#----------------------------------------#
	# build ffmpeg with cuda
	#----------------------------------------#

	apt -y remove ffmpeg

	cd $THIS_DIR/temp
	if [ ! -d ffmpeg ]; then
		git clone git://source.ffmpeg.org/ffmpeg.git
	fi

	gpu_patch=$(basename "$gpu_acce")
	if [ ! -f $gpu_patch ]; then
		wget $gpu_acce
	fi

	cd ffmpeg
	git reset --hard b83c849e8797fbb972ebd7f2919e0f085061f37f
	git apply ../$gpu_patch

	cd $THIS_DIR/temp
	mkdir ffmpeg_build
	cd ffmpeg_build
	../ffmpeg/configure
		--enable-nonfree \
		--enable-nvenc \
		--enable-nvresize \
		--extra-cflags=-I../cudautils \
		--extra-ldflags=-L../cudautils \
		--enable-gpl \
		--enable-libx264
	make -j 4

	./ffmpeg -encoders 2>/dev/null | grep nvenc_h264
	res_encoder=$?

	./ffmpeg -filters 2>/dev/null | grep nvresize
	res_filter=$?

	res=$res_encoder + $res_filter

	if [ $res -eq 0 ]; then
		make install
		ldconfig
	else
		echo 'build ffmpeg error'
	fi
}

need_ffmpeg()
{
	local current_version=$(ffmpeg_version)
	[ ! $? ] && return 0
	version_compare $current_version $1
	[ ! $? -eq 1 ] && return 0
	return 1
}


version_compare () 
{
	if [[ $1 == $2 ]]; then
		return 0
	fi

	local IFS=.
	local i ver1=($1) ver2=($2)
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
		ver1[i]=0
	done

	for ((i=0; i<${#ver1[@]}; i++)); do
		if [[ -z ${ver2[i]} ]]; then
			ver2[i]=0
		fi
		if ((10#${ver1[i]} > 10#${ver2[i]})); then
			return 1
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]})); then
			return 2
		fi
	done
	return 0
}

ffmpeg_version()
{
	! cmd_exists ffmpeg && return 1
	IFS=' -'; set -- $(ffmpeg -version | grep "ffmpeg version"); echo $3
	[ ! -z $3 ]
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

check_apt()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			log "${package} has been installed"
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

