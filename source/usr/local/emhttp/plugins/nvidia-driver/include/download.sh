#!/bin/bash
export KERNEL_V="$(uname -r)"
export DRIVER_AVAIL="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E 'nvidia-.*.txz' | grep -E -v '\.md5$' | awk -F "-" '{print $2}' | sort -V)"
export NV_DRV_V="$(grep "driver_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)"

#Check Nvidia driver version and set download variable, if Nvidia driver version
#is not found for this kernel fall back to latest, if no Internet connection or parsing of
#release.json failed fall back to local installed version if no local version is found exit.
if [ "${NV_DRV_V}" == "latest" ]; then
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ "$(grep "local_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)" == "none" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    fi
  else
    export DL_DRV="$(echo "$DRIVER_AVAIL" | tail -1)"
    export NV_DRV_V="${DL_DRV}"
  fi
elif [ "${NV_DRV_V}" == "latest_prb" ]; then
  export LAT_PRB_AVAIL="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep 'PRB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ "$(grep "local_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)" == "none" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    fi
  elif [ -z "$(comm -12 <(echo "$DRIVER_AVAIL") <(echo "$LAT_PRB_AVAIL") | sort -V | tail -1)" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get Production Branch version and found no installed local driver-----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
  else
    export DL_DRV="$(comm -12 <(echo "$DRIVER_AVAIL") <(echo "$LAT_PRB_AVAIL") | sort -V | tail -1)"
    export NV_DRV_V="${DL_DRV}"
  fi
elif [ "${NV_DRV_V}" == "latest_nfb" ]; then
  export LAT_NFB_AVAIL="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep 'NFB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ "$(grep "local_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)" == "none" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    fi
  elif [ -z "$(comm -12 <(echo "$DRIVER_AVAIL") <(echo "$LAT_NFB_AVAIL") | sort -V | tail -1)" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "----Can't get New Feature Branch version and found no installed local driver----"
    echo "-----Please wait for an hour and try it again, if it then also fails please-----"
    echo "------go to the Support Thread on the Unraid forums and make a post there!------"
    exit 1
  else
    export DL_DRV="$(comm -12 <(echo "$DRIVER_AVAIL") <(echo "$LAT_NFB_AVAIL") | sort -V | tail -1)"
    export NV_DRV_V="${DL_DRV}"
  fi
else
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ "$(grep "local_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)" == "none" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
        export NV_DRV_V="$(grep "local_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)"
    fi
  else
    export DL_DRV="$(echo "$DRIVER_AVAIL" | grep "$NV_DRV_V")"
    if [ -z "${DL_DRV}" ]; then
      export NV_DRV_OLD=${NV_DRV_V}
      export DL_DRV="$(echo "$DRIVER_AVAIL" | tail -1)"
      export NV_DRV_V="$(echo "$DL_DRV")"
      echo
      echo "---Can't find Nvidia Driver v${NV_DRV_OLD} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v${NV_DRV_V}---"
      sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
    fi
  fi
fi

if [ ! -d "/boot/config/plugins/nvidia-driver/packages" ]; then
  mkdir -p "/boot/config/plugins/nvidia-driver/packages"
fi

#Download Nvidia Driver Package
download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/nvidia-${NV_DRV_V}-${KERNEL_V}-1.txz" "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${DL_DRV}-${KERNEL_V}-1.txz" ; then
  if [ "$(md5sum "/boot/config/plugins/nvidia-driver/packages/nvidia-${NV_DRV_V}-${KERNEL_V}-1.txz" | cut -d ' ' -f1)" != "$(wget -qO- "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${DL_DRV}-${KERNEL_V}-1.txz.md5" | cut -d ' ' -f1)" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "--------------------------------CHECKSUM ERROR!---------------------------------"
    exit 1
  fi
  sed -i '/local_version=/c\local_version='${NV_DRV_V}'' "/boot/config/plugins/nvidia-driver/settings.cfg"
  echo
  echo "-----------Successfully downloaded Nvidia Driver Package v${NV_DRV_V}-----------"
else
  echo
  echo "---------------Can't download Nvidia Driver Package v${NV_DRV_V}----------------"
  exit 1
fi
}

#Check if driver is already downloaded
check() {
if [ ! -f /boot/config/plugins/nvidia-driver/packages/nvidia-${NV_DRV_V}-${KERNEL_V}-1.txz ]; then
  echo
  echo "+=============================================================================="
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "|"
  echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
  echo "|"
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "+=============================================================================="
  echo
  echo "----------------Downloading Nvidia Driver Package v${NV_DRV_V}-----------------"
  echo "---------This could take some time, please don't close this window!------------"
  download
else
  echo
  echo "---------Noting to do, Nvidia Drivers v${NV_DRV_V} already downloaded!---------"
  echo
  echo "------------------------------Verifying CHECKSUM!------------------------------"
  if [ "$(md5sum "/boot/config/plugins/nvidia-driver/packages/nvidia-${NV_DRV_V}-${KERNEL_V}-1.txz" | cut -d ' ' -f1)" != "$(wget -qO- "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${DL_DRV}-${KERNEL_V}-1.txz.md5" | cut -d ' ' -f1)" ]; then
    rm -rf /boot/config/plugins/nvidia-driver/packages/nvidia-${NV_DRV_V}-${KERNEL_V}-1.txz
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR-----"
    echo "--------------------------------CHECKSUM ERROR!--------------------------------"
    echo
    echo "---------------Trying to redownload the Nvidia Driver v${NV_DRV_V}-------------"
    echo
    echo "+=============================================================================="
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "|"
    echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
    echo "|"
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "+=============================================================================="
    download
  else
    echo
    echo "----------------------------------CHECKSUM OK!---------------------------------"
  fi
  exit 0
fi
}

#Begin Check
check

#Display message to reboot server both in Plugin and WebUI
echo
echo "----To install the new Nvidia Driver v${NV_DRV_V} please reboot your Server!----"
/usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "To install the new Nvidia Driver v${NV_DRV_V} please reboot your Server!" -i "alert" -l "/Main"
