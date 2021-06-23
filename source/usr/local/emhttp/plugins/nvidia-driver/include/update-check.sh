#!/bin/bash
KERNEL_V="$(uname -r)"
SELECTED_V="$(cat /boot/config/plugins/nvidia-driver/settings.cfg | grep "driver_version" | cut -d '=' -f2)"
INSTALLED_V="$(nvidia-smi | grep NVIDIA-SMI | cut -d ' ' -f3)"

#Check if one of latest, latest_prb or latest_nfb is checked otherwise exit
if [[ "${SELECTED_V}" != "latest" && "${SELECTED_V}" != "latest_prb" && "${SELECTED_V}" != "latest_nfb" ]]; then
  exit 0
elif [ "${SELECTED_V}" == "latest" ]; then
  LATEST_V="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E 'nvidia-.*.txz' | grep -E -v '\.md5$' | awk -F "-" '{print $2}' | sort -V | tail -1)"
  if [ -z ${LATEST_V} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest version number!"
    exit 1
  elif [ "${LATEST_V}" != "${INSTALLED_V}" ]; then
    if wget -q -O "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_V}-${KERNEL_V}-1.txz" "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_V}-${KERNEL_V}-1.txz" ; then
      if [ "$(md5sum "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_V}-${KERNEL_V}-1.txz" | cut -d ' ' -f1)" != "$(wget -qO- "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_V}-${KERNEL_V}-1.txz.md5" | cut -d ' ' -f1)" ]; then
        /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_V} but a checksum error occurred! Please try to install the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
        crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
        exit 1
      fi
      sed -i '/local_version=/c\local_version='${LATEST_V}'' "/boot/config/plugins/nvidia-driver/settings.cfg"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
    else
      /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_V} but a download error occurred! Please try to download the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
      exit 1
    fi
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "New Nvidia Driver v${LATEST_V} found and downloaded! Please reboot your Server to install the new version!" -l "/Main"
    crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
  fi
elif [ "${SELECTED_V}" == "latest_prb" ]; then
  AVAIL_V="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E 'nvidia-.*.txz' | grep -E -v '\.md5$' | awk -F "-" '{print $2}' | sort -V)"
  PRB_V="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep "PRB" | cut -d '=' -f2 | sort -V)"
  LATEST_PRB_V="$(comm -12 <(echo "${AVAIL_V}") <(echo "${PRB_V}") | tail -1)"
  if [ -z ${LATEST_PRB_V} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest Production Branch version number!"
    exit 1
  elif [ "${LATEST_PRB_V}" != "${INSTALLED_V}" ]; then
    if wget -q -O "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_PRB_V}-${KERNEL_V}-1.txz" "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_PRB_V}-${KERNEL_V}-1.txz" ; then
      if [ "$(md5sum "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_PRB_V}-${KERNEL_V}-1.txz" | cut -d ' ' -f1)" != "$(wget -qO- "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_PRB_V}-${KERNEL_V}-1.txz.md5" | cut -d ' ' -f1)" ]; then
        /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_PRB_V} but a checksum error occurred! Please try to install the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
        crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
        exit 1
      fi
      sed -i '/local_version=/c\local_version='${LATEST_PRB_V}'' "/boot/config/plugins/nvidia-driver/settings.cfg"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
    else
      /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_PRB_V} but a download error occurred! Please try to download the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
      exit 1
    fi
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "New Nvidia Driver v${LATEST_PRB_V} found and downloaded! Please reboot your Server to install the new version!" -l "/Main"
    crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
  fi
elif [ "${SELECTED_V}" == "latest_nfb" ]; then
  AVAIL_V="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E 'nvidia-.*.txz' | grep -E -v '\.md5$' | awk -F "-" '{print $2}' | sort -V)"
  NFB_V="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep "NFB" | cut -d '=' -f2 | sort -V)"
  LATEST_NFB_V="$(comm -12 <(echo "${AVAIL_V}") <(echo "${NFB_V}") | tail -1)"
  if [ -z ${LATEST_NFB_V} ]; then
    logger "Nvidia-Driver-Plugin: Automatic update check failed, can't get latest New Feature Branch version number!"
    exit 1
  elif [ "${LATEST_NFB_V}" != "${INSTALLED_V}" ]; then
    if wget -q -O "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_NFB_V}-${KERNEL_V}-1.txz" "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_NFB_V}-${KERNEL_V}-1.txz" ; then
      if [ "$(md5sum "/boot/config/plugins/nvidia-driver/packages/nvidia-${LATEST_NFB_V}-${KERNEL_V}-1.txz" | cut -d ' ' -f1)" != "$(wget -qO- "https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}/nvidia-${LATEST_NFB_V}-${KERNEL_V}-1.txz.md5" | cut -d ' ' -f1)" ]; then
        /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_NFB_V} but a checksum error occurred! Please try to install the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
        crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
        exit 1
      fi
      sed -i '/local_version=/c\local_version='${LATEST_NFB_V}'' "/boot/config/plugins/nvidia-driver/settings.cfg"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
    else
      /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "Found new Nvidia Driver v${LATEST_NFB_V} but a download error occurred! Please try to download the driver manually!" -i "alert" -l "/Settings/nvidia-driver"
      crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
      exit 1
    fi
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "New Nvidia Driver v${LATEST_NFB_V} found and downloaded! Please reboot your Server to install the new version!" -l "/Main"
    crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-driver/include/update-check.sh'  | crontab -
  fi
fi
