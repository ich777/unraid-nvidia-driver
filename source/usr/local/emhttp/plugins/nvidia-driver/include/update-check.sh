#!/bin/bash
KERNEL_V="$(uname -r)"
SET_DRV_V="$(cat /boot/config/plugins/nvidia-driver/settings.cfg | grep "driver_version" | cut -d '=' -f2)"
if [ "${SET_DRV_V}" == "latest_nos" ]; then
  export PACKAGE="nvos"
else
  export PACKAGE="nvidia"
fi
DL_URL="https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}"
INSTALLED_V="$(nvidia-smi | grep NVIDIA-SMI | cut -d ' ' -f3)"

download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}" "${DL_URL}/${LAT_PACKAGE}" ; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5" "${DL_URL}/${LAT_PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "--------------------------------CHECKSUM ERROR!---------------------------------"
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) but a checksum error occurred! Please try to install the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
    crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
    rm -rf /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}*
    exit 1
  fi
  echo
  echo "-----------Successfully downloaded Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)-----------"
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "New Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) found and downloaded! Please reboot your Server to install the new version!" -l "/Main"
  crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
else
  echo
  echo "---------------Can't download Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)----------------"
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) but a download error occurred! Please try to download the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
  crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
  exit 1
fi
}

#Check if one of latest, latest_prb or latest_nfb is checked otherwise exit
if [[ "${SET_DRV_V}" != "latest" && "${SET_DRV_V}" != "latest_prb" && "${SET_DRV_V}" != "latest_nfb" ]]; then
  exit 0
elif [ "${SET_DRV_V}" == "latest" ]; then
  LAT_PACKAGE="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "$PACKAGE" | grep -E -v '\.md5$' | sort -V | tail -1)"
  if [ -z ${LAT_PACKAGE} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest version number!"
    exit 1
  elif [ "$(echo "$LAT_PACKAGE" | cut -d '-' -f2)" != "${INSTALLED_V}" ]; then
    download
  fi
elif [ "${SET_DRV_V}" == "latest_prb" ]; then
  AVAIL_V="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "$PACKAGE" | grep -E -v '\.md5$' | sort -V)"
  PRB_V="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep "PRB" | cut -d '=' -f2 | sort -V)"
  LAT_PRB_V="$(comm -12 <(echo "$(echo "$AVAIL_V" | cut -d '-' -f2 | awk -F '.' '{printf "%d.%03d.%d\n", $1,$2,$3}' | awk -F '.' '{printf "%d.%03d.%02d\n", $1,$2,$3}')") <(echo "${PRB_V}" | awk -F '.' '{printf "%d.%03d.%d\n", $1,$2,$3}' | awk -F '.' '{printf "%d.%03d.%02d\n", $1,$2,$3}') | tail -1 | awk -F '.' '{printf "%d.%02d.%02d\n", $1,$2,$3}' | awk '{sub(/\.0+$/,"")}1')"
  LAT_PACKAGE="$(echo "${AVAIL_V}" | grep "\-${LAT_PRB_V}-")"
  if [ -z ${LAT_PACKAGE} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest Production Branch version number!"
    exit 1
  elif [ "$(echo "$LAT_PACKAGE" | cut -d '-' -f2)" != "${INSTALLED_V}" ]; then
    download
  fi
elif [ "${SET_DRV_V}" == "latest_nfb" ]; then
  AVAIL_V="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "$PACKAGE" | grep -E -v '\.md5$' | sort -V)"
  NFB_V="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep "NFB" | cut -d '=' -f2 | sort -V)"
  LAT_NFB_V="$(comm -12 <(echo "$(echo "$AVAIL_V" | cut -d '-' -f2 | awk -F '.' '{printf "%d.%03d.%d\n", $1,$2,$3}' | awk -F '.' '{printf "%d.%03d.%02d\n", $1,$2,$3}')") <(echo "${NFB_V}" | awk -F '.' '{printf "%d.%03d.%d\n", $1,$2,$3}' | awk -F '.' '{printf "%d.%03d.%02d\n", $1,$2,$3}') | tail -1 | awk -F '.' '{printf "%d.%02d.%02d\n", $1,$2,$3}' | awk '{sub(/\.0+$/,"")}1')"
  LAT_PACKAGE="$(echo "${AVAIL_V}" | grep "\-${LAT_NFB_V}-")"
  if [ -z ${LAT_PACKAGE} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest New Feature Branch version number!"
    exit 1
  elif [ "$(echo "$LAT_PACKAGE" | cut -d '-' -f2)" != "${INSTALLED_V}" ]; then
    download
  fi
elif [ "${SET_DRV_V}" == "latest_nos" ]; then
  LAT_PACKAGE="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E -v '\.md5$' | grep "${PACKAGE}" | sort -V | tail -1)"
  if [ -z ${LAT_PACKAGE} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest Open Source Driver version number!"
    exit 1
  elif [ "$(echo "$LAT_PACKAGE" | cut -d '-' -f2 )" != "${INSTALLED_V}" ]; then
    download
  fi
fi

#Check for old packages that are not suitable for this Kernel and not suitable for the current Nvidia driver version
rm -rf $(ls -d /boot/config/plugins/nvidia-driver/packages/* 2>/dev/null | grep -v "${KERNEL_V%%-*}")
rm -f $(ls /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "$LAT_PACKAGE")
