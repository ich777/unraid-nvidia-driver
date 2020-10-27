#!/bin/bash

function update(){
KERNEL_V="$(uname -r)"
echo "$(wget -qO- -T10 https://s3.amazonaws.com/dnld.lime-technology.com/drivers/releases.json | jq -r '.[] | "\(.kernel) \(.version) \(.url) \(.md5) \(.size)" | select( index("'${KERNEL_V}'"))')" > /tmp/nvidia_driver
}

function update_version(){
sed -i "/driver_version=/c\driver_version=${1}" "/boot/config/plugins/nvidia-driver/settings.cfg"
}

function get_latest_version(){
KERNEL_V="$(uname -r)"
echo "$(cat /tmp/nvidia_driver | head -1 | cut -d ' ' -f2)"
}

$@
