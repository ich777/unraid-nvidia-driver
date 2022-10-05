#!/bin/bash

# Define Variables
export KERNEL_V="$(uname -r)"
export SET_DRV_V="$(grep "driver_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)"
if [ "${SET_DRV_V}" == "latest_nos" ]; then
  export PACKAGE="nvos"
  export OS="Open Source "
  LAT_NOS_AVAIL="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E -v '\.md5$' | grep "${PACKAGE}" | awk -F "-" '{print $2}' | sort -V | tail -1)"
else
  export PACKAGE="nvidia"
  export DRIVER_AVAIL="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E ${PACKAGE} | grep -E -v '\.md5$' | sort -V)"
  export BRANCHES="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep -v "UPDATED")"
fi
export DL_URL="https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}"
export CUR_V="$(nvidia-smi | grep NVIDIA-SMI | cut -d ' ' -f3)"

#Download Nvidia Driver Package
download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}" "${DL_URL}/${LAT_PACKAGE}" ; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5" "${DL_URL}/${LAT_PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "--------------------------------CHECKSUM ERROR!---------------------------------"
    rm -rf /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}*
    exit 1
  fi
  echo
  echo "-----------Successfully downloaded Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)-----------"
else
  echo
  echo "---------------Can't download Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)----------------"
  exit 1
fi
}

#Check if driver is already downloaded
check() {
if ! ls -1 /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/ | grep -q "${PACKAGE}-$(echo $LAT_PACKAGE | cut -d '-' -f2)" ; then
  echo
  echo "+=============================================================================="
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "|"
  echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
  echo "|"
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "+=============================================================================="
  echo
  echo "----------------Downloading Nvidia ${OS}Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)-----------------"
  echo "---------This could take some time, please don't close this window!------------"
  download
else
  echo
  echo "--------Nothing to do, Nvidia ${OS}Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) already downloaded!---------"
  echo
  echo "------------------------------Verifying CHECKSUM!------------------------------"
  if [ "$(md5sum /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    rm -rf /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}*
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR-----"
    echo "--------------------------------CHECKSUM ERROR!--------------------------------"
    echo
    echo "---------------Trying to redownload the Nvidia ${OS}Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)-------------"
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
    exit 0
  fi
fi
}

if [ ! -d "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}" ]; then
  mkdir -p "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}"
fi

if [ "${SET_DRV_V}" == "latest" ]; then
  export LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
  if [ -z "$LAT_PACKAGE" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  fi
elif [ "${SET_DRV_V}" == "latest_prb" ]; then
  LAT_PRB_AVAIL="$(echo "$BRANCHES" | grep 'PRB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$LAT_PRB_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get Production Branch version and found no installed local driver-----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  elif [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "------Can't get Nvidia driver versions and found no installed local driver------"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  else
    LAT_PRB_V="$(comm -12 <(echo "$DRIVER_AVAIL" | cut -d '-' -f2) <(echo "$LAT_PRB_AVAIL") | sort -V | tail -1)"
    if [ -z "${LAT_PRB_V}" ]; then
      if [ -z "${CUR_V}" ]; then
        echo
        echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
        echo "---Can't get latest Nvidia driver version and found no installed local driver---"
        echo "-----Please wait for an hour and try it again, if it then also fails please-----"
        echo "------go to the Support Thread on the Unraid forums and make a post there!------"
        exit 1
      else
        LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
        echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
        sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
      fi
    else
      LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$LAT_PRB_V")"
    fi
  fi
elif [ "${SET_DRV_V}" == "latest_nfb" ]; then
  LAT_NFB_AVAIL="$(echo "$BRANCHES" | grep 'NFB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$LAT_NFB_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get New Feature Branch version and found no installed local driver----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  elif [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "------Can't get Nvidia driver versions and found no installed local driver------"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  else
    LAT_NFB_V="$(comm -12 <(echo "$DRIVER_AVAIL" | cut -d '-' -f2) <(echo "$LAT_NFB_AVAIL") | sort -V | tail -1)"
    if [ -z "${LAT_NFB_V}" ]; then
      if [ -z "${CUR_V}" ]; then
        echo
        echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
        echo "------Can't get Nvidia driver versions and found no installed local driver------"
        echo "-----Please wait for an hour and try it again, if it then also fails please-----"
        echo "------go to the Support Thread on the Unraid forums and make a post there!------"
        exit 1
      else
        LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
        echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
        sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
      fi
    else
      LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$LAT_NFB_V")"
    fi
  fi
elif [ "${SET_DRV_V}" == "latest_nos" ]; then
  if [ -z "$LAT_NOS_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get Nvidia Open Source version and found no installed local driver----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      export PACKAGE="nvidia"
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  else
    LAT_PACKAGE=$PACKAGE-$LAT_NOS_AVAIL-$KERNEL_V-1.txz
  fi
else
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$PACKAGE-$CUR_V-$KERNEL_V-1.txz
    fi
  else
    LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$SET_DRV_V")"
    if [ -z "${LAT_PACKAGE}" ]; then
      export LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
      echo
      echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
      sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
    fi
  fi
fi

#Begin Check
check

#Check for old packages that are not suitable for this Kernel and not suitable for the current Nvidia driver version
rm -rf $(ls -d /boot/config/plugins/nvidia-driver/packages/* 2>/dev/null | grep -v "${KERNEL_V%%-*}")
rm -f $(ls /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "$LAT_PACKAGE")

#Display message to reboot server both in Plugin and WebUI
echo
echo "----To install the new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) please reboot your Server!----"
/usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "To install the new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) please reboot your Server!" -i "alert" -l "/Main"
