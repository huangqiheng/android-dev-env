#!/bin/bash

get_phy_device() {
    local x
    for x in /sys/class/ieee80211/*; do
        [[ ! -e "$x" ]] && continue
        if [[ "${x##*/}" = "$1" ]]; then
            echo $1
            return 0
        elif [[ -e "$x/device/net/$1" ]]; then
            echo ${x##*/}
            return 0
        elif [[ -e "$x/device/net:$1" ]]; then
            echo ${x##*/}
            return 0
        fi
    done
    echo "Failed to get phy interface" >&2
    return 1
}

get_adapter_info() {
    local PHY
    PHY=$(get_phy_device "$1")
    [[ $? -ne 0 ]] && return 1
    iw phy $PHY info
}
get_adapter_kernel_module() {
    local MODULE
    MODULE=$(readlink -f "/sys/class/net/$1/device/driver/module")
    echo ${MODULE##*/}
}

can_be_sta_and_ap() {
    if [[ "$(get_adapter_kernel_module "$1")" == "brcmfmac" ]]; then
        echo "WARN: brmfmac driver doesn't work properly with virtual interfaces and" >&2
        echo "      it can cause kernel panic. For this reason we disallow virtual" >&2
        echo "      interfaces for your adapter." >&2
        echo "      For more info: https://github.com/oblique/create_ap/issues/203" >&2
        return 1
    fi
    get_adapter_info "$1" | grep -E '{.* managed.* AP.*}' > /dev/null 2>&1 && return 0
    get_adapter_info "$1" | grep -E '{.* AP.* managed.*}' > /dev/null 2>&1 && return 0
    return 1
}

is_wifi_connected() {
    iw dev "$1" link 2>&1 | grep -E '^Connected to' > /dev/null 2>&1 && return 0
    return 1
}

if [[ -z $1 ]]; then
	echo "ERROR: Please input wlan interface" >&2
	exit 1
fi

if ! can_be_sta_and_ap ${1}; then
	echo "ERROR: Your adapter can not be a station (i.e. be connected) and an AP at the same time" >&2
	exit 1
fi

echo 'Your adapter is good'
