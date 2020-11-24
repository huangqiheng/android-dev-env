#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`
nvenc_sdk=https://developer.nvidia.com/nvidia-video-codec-sdk#Download

main () 
{
	check_bash

	#----------------------------------------#
	# fuck nvidia! need manual download sdk
	#----------------------------------------#

	cd $ROOT_DIR && mkdir -p temp && cd temp

	if ! ls Video_Codec_SDK_*.zip > /dev/null 2>&1; then
		log 'please manual download nvenc sdk on nvidia official site'
		log "url: $nvenc_sdk"
		log "save to: $ROOT_DIR/temp"
		exit 1
	fi

	#----------------------------------------#
	# install nvidia display drivers
	#----------------------------------------#

	check_update ppa:graphics-drivers/ppa
	check_enviroment
	check_dependance
	systemctl stop lightdm

	if ! apt_exists nvidia-384; then
		check_apt nvidia-384 nvidia-384-dev nvidia-modprobe

		log 'NEED TO REBOOT THE SYSTEM, TO MAKE THE DRIVER EFFECT.'
		log 'THEN RUN THIS SCRIPT AGAIN.'
		exit 0
	fi


	#----------------------------------------#
	# install cuda 
	#----------------------------------------#

	cd $ROOT_DIR/temp
	deviceQuery=/root/NVIDIA_CUDA-8.0_Samples/bin/x86_64/linux/release/deviceQuery

	# install cuda with deb file
	if [ "$1" = "deb" ]; then
		# still has problem, because of version 375 is too low
		# fixme
		cuda_base=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb
		cuda_patch=https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda-repo-ubuntu1604-8-0-local-cublas-performance-update_8.0.61-1_amd64-deb

		if apt_exists cuda; then
			log 'cuda has been installed'
		else
			cuda_base_file=$(basename "$cuda_base")
			if [ ! -f $cuda_base_file ]; then
				wget --no-check-certificate $cuda_base
			fi

			cuda_patch_file=$(basename "$cuda_patch")
			if [ ! -f $cuda_patch_file ]; then
				wget --no-check-certificate $cuda_patch
			fi

			dpkg -i $cuda_base_file
			dpkg -i $cuda_patch_file
			apt update -y

			check_apt cuda

		fi

		install_sample=/usr/local/cuda-8.0/bin/cuda-install-samples-8.0.sh
		if cmd_exists $install_sample; then
			$install_sample /root
			log 'copying cuda sample codes'
		else 
			log 'you cuda environment not correct'
			exit 0
		fi

	# install cuda with run files
	else
		url_cuda_runfile=https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux.run
		url_cuda_patch_runfile=https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda_8.0.61.2_linux.run

		for url in $url_cuda_runfile $url_cuda_patch_runfile; do
			if [ ! -f $(basename $url) ]; then
				wget --no-check-certificate $url
			fi
		done

		# DO NOT INSTALL THE DISPLAY DRIVER HERE
		if ! cmd_exists nvcc; then
			bash $(basename $url_cuda_runfile)
			bash $(basename $url_cuda_patch_runfile)
		fi
	fi

	# add shell environment

	echo_to=/root/.bashrc
	if ! grep -q "cuda-8.0" $echo_to; then
		echo 'export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}' >> $echo_to 
		echo 'export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> $echo_to
		source $echo_to

		log 'NEED TO REBOOT THE SYSTEM, TO MAKE THE DRIVER EFFECT.'
		log 'THEN RUN THIS SCRIPT AGAIN.'
		exit 0
	fi

	# test cuda environment

	if [ ! -f $deviceQuery ]; then
		log 'please install sample code to test'
		exit 1
	fi

	if [ ! $($deviceQuery | grep -c 'Result = PASS') -gt 0 ]; then
		log 'cuda environment has errors'
		exit 1
	fi 

	log 'cuda environment is OK'


	#----------------------------------------#
	# prepare nvenc sdk
	#----------------------------------------#

	# nvenc dependance
	check_apt glew-utils libglew-dbg libglew-dev libglew1.13 libglewmx-dev libglewmx-dbg freeglut3 freeglut3-dev freeglut3-dbg libghc-glut-dev libghc-glut-doc libghc-glut-prof libalut-dev libxmu-dev libxmu-headers libxmu6 libxmu6-dbg libxmuu-dev libxmuu1 libxmuu1-dbg

	cd $ROOT_DIR/temp

	nvenc_zip=$(ls -pt | egrep -m 1 "Video_Codec_SDK_.*.zip")
	nvenc_dir="${nvenc_zip%.*}"

	nvenc_inc=nv_sdk/Samples/common/inc

	if [ -f $nvenc_inc/nvUtils.h ]; then
		log 'nvenc sdk files is ready'
	else
		unzip -o $nvenc_zip
		mv  $nvenc_dir nv_sdk
		cp $nvenc_inc/*.h /usr/local/include
		log 'nvenc sdk files has been copied'
	fi

	#----------------------------------------#
	# compile ffmpeg
	#----------------------------------------#

	# base dependance
	check_apt libass-dev libfreetype6-dev libtheora-dev libtool libvorbis-dev pkg-config texinfo zlib1g-dev

	# functional options
	check_apt libchromaprint-dev frei0r-plugins-dev ladspa-sdk libass-dev libiec61883-dev libraw1394-dev libavc1394-dev libass-dev libbluray-dev  libbs2b-dev libcaca-dev libcdio-dev  libfontconfig1-dev libfribidi-dev libgme-dev libgsm1-dev libmodplug-dev libmp3lame-dev libopenjpeg-dev libopus-dev libpulse-dev librubberband-dev libshine-dev libsnappy-dev flite1-dev libopencv-dev libsoxr-dev libssh-dev libspeex-dev libtheora-dev libtwolame-dev libvorbis-dev libvpx-dev libwavpack-dev libwebp-dev libx264-dev libx265-dev libzmq3-dev libzvbi-dev libxvidcore-dev libopenal-dev libcdio-paranoia-dev libgnutls-dev libssl-dev libfdk-aac-dev 

	cd $ROOT_DIR/temp

	if [ ! -d ffmpeg ]; then
		# git clone https://github.com/FFmpeg/FFmpeg ffmpeg -b master
		wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
		tar xjvf ffmpeg-snapshot.tar.bz2
	fi

	mkdir -p ffmpeg_build
	cd ffmpeg_build

	../ffmpeg/configure --prefix=/usr --toolchain=hardened --cc=cc --cxx=g++ --libdir=/usr/lib/x86_64-linux-gnu --incdir=/usr/include/x86_64-linux-gnu --enable-gpl --disable-stripping --enable-avresample --enable-avisynth --enable-gnutls --enable-openssl --enable-ladspa --enable-libass --enable-libbluray --enable-libbs2b --enable-libcaca --enable-libcdio --enable-libflite --enable-libfontconfig --enable-libfreetype --enable-libfribidi --enable-libgme --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopenjpeg --enable-libopus --enable-libpulse --enable-librubberband --enable-libshine --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libssh --enable-libtheora --enable-libtwolame --enable-libvorbis --enable-libvpx --enable-libwavpack --enable-libwebp --enable-libx265 --enable-libxvid --enable-libzmq --enable-libzvbi --enable-openal --enable-opengl --enable-libdc1394 --enable-libiec61883 --enable-libopencv --enable-frei0r --enable-libx264 --enable-chromaprint --enable-nonfree --extra-cflags=-I../nv_sdk --extra-ldflags=-L../nv_sdk --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --enable-nvenc --enable-shared --enable-cuda --enable-cuvid --enable-libnpp

	make -j 4
	make install

	err_count=0
	for i in encoders decoders filters; do
		echo ${i}:
		ffmpeg -hide_banner -${i} | egrep -i "npp|cuvid|nvenc|cuda"
		err_count=$[ $err_count + $? ]
	done

	if [ $err_count -gt 0 ]; then
		echo 'build ffmpeg error'
	fi
}

check_dependance()
{
	check_apt git unzip wget sysstat
	check_apt gcc g++ linux-headers-$(uname -r) build-essential autoconf automake
	check_apt yasm 
}

check_enviroment()
{

	if ! lspci | grep -i nvidia > /dev/null; then
		log 'you dont have a nvidia displaycard'
		exit 1
	fi

	if ! uname -m  | grep x86_64 > /dev/null; then
		log 'must be x86_64 architecture'
		exit 1
	fi

	if ! cat /etc/*release | grep -i "ubuntu 16.04" > /dev/null; then
		log 'please make sure the distrib is ubuntu 1604'
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

