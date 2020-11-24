#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IMG_NAME=telegram-chinese

main () 
{
	check_docker

	select_subpath $CACHE_DIR/TelegramDesktop "$1"
	TelegramHome="$CACHE_DIR/TelegramDesktop/$FUNC_RESULT"
	TeleName=$(rm_space "telegram-$FUNC_RESULT")
	chownUser $CACHE_DIR

	build_image $IMG_NAME <<-EOL
	FROM debian:jessie-slim as downloader

	RUN apt-get update && apt-get install -y \
	    apt-utils \
	    software-properties-common \
	    wget \
	    --no-install-recommends && \
	    apt-get clean && \
	    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

	RUN wget https://updates.tdesktop.com/tlinux/tsetup.1.9.8.tar.xz -O /tmp/telegram.tar.xz \
	    && cd /tmp/ \
	    && tar xvfJ /tmp/telegram.tar.xz \
	    && mv /tmp/Telegram/Telegram /usr/bin/Telegram \
	    && rm -rf /tmp/{telegram.tar.xz,Telegram}

	FROM debian:stretch
	LABEL maintainer "Christophe Boucharlat <christophe.boucharlat@gmail.com>"

	# Make a user
	ENV HOME /home/user
	RUN useradd --create-home --home-dir \$HOME user \
		&& chown -R user:user \$HOME \
		&& usermod -a -G audio,video user

	ENV LANG zh_CN.UTF-8
	ENV LANGUAGE zh_CN:zh
	ENV LC_ALL zh_CN.UTF-8
	ENV DEBIAN_FRONTEND noninteractive

	# Install required deps
	RUN apt-get update && apt-get install -y \
		apt-utils \
		locales-all \
		dbus-x11 \
		libpulse0 \
		dunst \
		hunspell-en-us \
		python3-dbus \
		software-properties-common \
		libx11-xcb1 \
		libasound2 \
		ttf-wqy-zenhei \
		ttf-wqy-microhei \
		fonts-wqy-zenhei \
		fonts-wqy-microhei \
		gconf2 \
		--no-install-recommends \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

	COPY --from=downloader /usr/bin/Telegram /usr/bin/Telegram

	WORKDIR \$HOME
	USER user

	ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb

	# Autorun Telegram
	CMD ["/usr/bin/Telegram"]
EOL

	docker run -it --rm \
		--hostname=$(hostname) \
		-e DISPLAY=unix$DISPLAY \
		--device /dev/snd \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v "/home/$(whoami)/.Xauthority:/home/user/.Xauthority" \
		-v /etc/localtime:/etc/localtime:ro \
		-v $TelegramHome:/home/user/.local/share/TelegramDesktop/ \
		-e GTK_IM_MODULE=fcitx \
		-e XMODIFIERS=@im=fcitx \
		-e QT_IM_MODULE=fcitx \
		--name $TeleName $IMG_NAME

	self_cmdline tg
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
