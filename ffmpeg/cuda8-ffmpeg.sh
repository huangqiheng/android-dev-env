#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`
nvenc_sdk=https://developer.nvidia.com/nvidia-video-codec-sdk#Download

main () 
{
	check_bash
	check_update 
	check_enviroment
	check_dependance

	#----------------------------------------#
	# fuck nvidia! need download sdk manually 
	#----------------------------------------#

	cd $ROOT_DIR && mkdir -p temp && cd temp

	if ! ls Video_Codec_SDK_*.zip > /dev/null 2>&1; then
		log 'please manually download nvenc sdk on nvidia official site'
		log "url: $nvenc_sdk"
		log "save as: $ROOT_DIR/temp/Video_Codec_SDK_*.zip"
		exit 1
	fi

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
		git clone https://github.com/FFmpeg/FFmpeg ffmpeg -b master
	fi

	mkdir -p ffmpeg_build
	cd ffmpeg_build

	../ffmpeg/configure --prefix=/usr --toolchain=hardened --cc=cc --cxx=g++ --libdir=/usr/lib/x86_64-linux-gnu --incdir=/usr/include/x86_64-linux-gnu --enable-gpl --disable-stripping --enable-avresample --enable-avisynth --enable-gnutls --enable-openssl --enable-ladspa --enable-libass --enable-libbluray --enable-libbs2b --enable-libcaca --enable-libcdio --enable-libflite --enable-libfontconfig --enable-libfreetype --enable-libfribidi --enable-libgme --enable-libgsm --enable-libmodplug --enable-libmp3lame --enable-libopenjpeg --enable-libopus --enable-libpulse --enable-librubberband --enable-libshine --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libssh --enable-libtheora --enable-libtwolame --enable-libvorbis --enable-libvpx --enable-libwavpack --enable-libwebp --enable-libx265 --enable-libxvid --enable-libzmq --enable-libzvbi --enable-openal --disable-opengl --enable-libdc1394 --enable-libiec61883 --enable-libopencv --enable-frei0r --enable-libx264 --enable-chromaprint --enable-nonfree --extra-cflags=-I../nv_sdk --extra-ldflags=-L../nv_sdk --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --enable-nvenc --enable-shared --enable-cuda --enable-cuvid --enable-libnpp

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
		exit 1
	fi

	if [ -f /dev/video0 ]; then
		cd $ROOT_DIR/temp
		if ! ffmpeg -y -f v4l2 -i /dev/video0 -fs 100 -c:v h264_nvenc test.mkv; then 
			echo 'ffmpeg cuda has error'
			exit 1
		fi
		unlink ./test.mkv
	fi

	echo 'ffmpeg cuda is ready'
	exit 0
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

