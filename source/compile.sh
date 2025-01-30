#!/bin/bash
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Please go to the end of this script for usage examples
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

if [ -z "${1}" ]; then
  echo "No Nvidia Driver version specified!"
  exit 1
fi

VERSIONS="$(wget -qO- https://github.com/ich777/versions/raw/refs/heads/master/Unraid-Kernel-Helper)"
if [ -z "${VERSIONS}" ]; then
  echo "ERROR: Can't get versions!"
  exit 1
fi
LIBNVIDIA_CONTAINER_V="$(echo "${VERSIONS}" | grep "LIBNVIDIA_CONTAINER_V" | cut -d '=' -f2 | sed 's/"//g')"
CONTAINER_TOOLKIT_V="$(echo "${VERSIONS}" | grep "CONTAINER_TOOLKIT_V" | cut -d '=' -f2 | sed 's/"//g')"

nvidia_driver () {
  if [ "${2}" == "opensource" ]; then
    NV_PROPRIETARY="--kernel-module-type=open"
  else
    # Version compare for 560 driver
    TARGET_V="560"
    COMPARE="${1%%-*}
$TARGET_V"
    if [ "$TARGET_V" == "$(echo "$COMPARE" | sort -V | tail -1)" ]; then
      NV_PROPRIETARY=""
    else
      NV_PROPRIETARY="--kernel-module-type=proprietary \
"
    fi
  fi

  cd ${DATA_DIR}
  rm -rf /NVIDIA /lib/firmware/nvidia

  if [ ! -f ${DATA_DIR}/NVIDIA_v${1}.run ]; then
    wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${1}.run http://us.download.nvidia.com/XFree86/Linux-x86_64/${1}/NVIDIA-Linux-x86_64-${1}.run
  fi

  chmod +x ${DATA_DIR}/NVIDIA_v${1}.run
  mkdir -p /NVIDIA/usr/lib64/xorg/modules/{drivers,extensions} /NVIDIA/usr/bin /NVIDIA/etc /NVIDIA/lib/modules/${UNAME}/kernel/drivers/video /NVIDIA/lib/firmware

  # Patch incompatible version
  if [ "${1}" == "470.256.02" ]; then
    ${DATA_DIR}/NVIDIA_v${1}.run --extract-only
    cd NVIDIA*-${1}

    patch -p0 < ${DATA_DIR}/nvidia-patch_470.256.02.patch

    ./nvidia-installer --kernel-name=$UNAME \
      --no-precompiled-interface \
      --disable-nouveau \
      --x-prefix=/NVIDIA/usr \
      --x-library-path=/NVIDIA/usr/lib64 \
      --x-module-path=/NVIDIA/usr/lib64/xorg/modules \
      --opengl-prefix=/NVIDIA/usr \
      --installer-prefix=/NVIDIA/usr \
      --utility-prefix=/NVIDIA/usr \
      --documentation-prefix=/NVIDIA/usr \
      --application-profile-path=/NVIDIA/usr/share/nvidia \
      --proc-mount-point=/NVIDIA/proc \
      --kernel-install-path=/NVIDIA/lib/modules/${UNAME}/kernel/drivers/video \
      --compat32-prefix=/NVIDIA/usr \
      --compat32-libdir=/lib \
      --install-compat32-libs \
      --no-x-check \
      --no-nouveau-check \
      --no-systemd \
      --skip-depmod \
      --j${CPU_COUNT} \
      --silent

    cd ${DATA_DIR}
    rm -rf NVIDIA*-${1}
  else
    ${DATA_DIR}/NVIDIA_v${1}.run --kernel-name=$UNAME \
      --no-precompiled-interface \
      --disable-nouveau \
      --x-prefix=/NVIDIA/usr \
      --x-library-path=/NVIDIA/usr/lib64 \
      --x-module-path=/NVIDIA/usr/lib64/xorg/modules \
      --opengl-prefix=/NVIDIA/usr \
      --installer-prefix=/NVIDIA/usr \
      --utility-prefix=/NVIDIA/usr \
      --documentation-prefix=/NVIDIA/usr \
      --application-profile-path=/NVIDIA/usr/share/nvidia \
      --proc-mount-point=/NVIDIA/proc \
      --kernel-install-path=/NVIDIA/lib/modules/${UNAME}/kernel/drivers/video \
      --compat32-prefix=/NVIDIA/usr \
      --compat32-libdir=/lib \
      --install-compat32-libs \
      --no-x-check \
      --no-nouveau-check \
      --no-systemd \
      --skip-depmod \
      --j${CPU_COUNT} \
      ${NV_PROPRIETARY} --silent
  fi

  if [ -d /lib/firmware/nvidia ]; then
    cp -R /lib/firmware/nvidia /NVIDIA/lib/firmware/
  fi
  cp /usr/bin/nvidia-modprobe /NVIDIA/usr/bin/
  cp -R /etc/OpenCL /NVIDIA/etc/
  cp -R /etc/vulkan /NVIDIA/etc/


  cd ${DATA_DIR}
  if [ ! -f ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz ]; then
    wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz https://github.com/ich777/libnvidia-container/releases/download/${LIBNVIDIA_CONTAINER_V}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz
  fi
  tar -C /NVIDIA -xf ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz

  cd ${DATA_DIR}
  if [ ! -f ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz ]; then
    wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz https://github.com/ich777/nvidia-container-toolkit/releases/download/${CONTAINER_TOOLKIT_V}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz
  fi
  tar -C /NVIDIA -xf ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz


  if [ "${2}" == "opensource" ]; then
    PLUGIN_NAME="nvos-driver"
  else
    PLUGIN_NAME="nvidia-driver"
  fi
  BASE_DIR="/NVIDIA"
  TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
  VERSION="$(date +'%Y.%m.%d')"

  mkdir -p $TMP_DIR/$VERSION
  cd $TMP_DIR/$VERSION
  cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
  mkdir $TMP_DIR/$VERSION/install

  if [ "${2}" == "opensource" ]; then
    tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Nvidia open source Kernel modules and Nvidia proprietary
$PLUGIN_NAME: binaries/libraries based on driver v${1}
$PLUGIN_NAME: libnvidia-container v${LIBNVIDIA_CONTAINER_V}
$PLUGIN_NAME: nvidia-container-toolkit v${CONTAINER_TOOLKIT_V}
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
  else
    tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Nvidia-Driver v${1}
$PLUGIN_NAME: libnvidia-container v${LIBNVIDIA_CONTAINER_V}
$PLUGIN_NAME: nvidia-container-toolkit v${CONTAINER_TOOLKIT_V}
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
  fi
  ${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/${PLUGIN_NAME%%-*}-${1}-${UNAME}-1.txz
  md5sum $TMP_DIR/${PLUGIN_NAME%%-*}-${1}-${UNAME}-1.txz | awk '{print $1}' > $TMP_DIR/${PLUGIN_NAME%%-*}-${1}-${UNAME}-1.txz.md5
}

# ----- USAGE --- USAGE --- USAGE --- USAGE --- USAGE --- USAGE --- USAGE -----
#
# This script is fully comatible with this Docker container:
# https://github.com/ich777/unraid_kernel
#
# To compile the driver with the proprietary Kernelmodules:
# compile.sh "<DRIVER_VERSION>"
#
# To compile the driver with thh open-source modules (driver version 560+):
# compile.sh "<DRIVER_VERSION>" "opensource"
#
# !!! Replace <DRIVER_VERSION> with the driver version you want to compile !!!
#
# Example for the proprietary Kernel module: compile.sh "565.77"
# Example for the open-source Kernel module: compile.sh "565.77" "opensource"
#
# ----- USAGE --- USAGE --- USAGE --- USAGE --- USAGE --- USAGE --- USAGE -----