# Download the Nvidia driver package
cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run http://us.download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run
fi

# Make the Nvidia driver executable and install it in a temporary directory
chmod +x ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run
mkdir -p /NVIDIA_OS/usr/lib64/xorg/modules/{drivers,extensions} /NVIDIA_OS/usr/bin /NVIDIA_OS/etc /NVIDIA_OS/lib/modules/${UNAME}/kernel/drivers/video /NVIDIA_OS/lib/firmware
${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run --kernel-name=$UNAME \
  --no-precompiled-interface \
  --disable-nouveau \
  --x-prefix=/NVIDIA_OS/usr \
  --x-library-path=/NVIDIA_OS/usr/lib64 \
  --x-module-path=/NVIDIA_OS/usr/lib64/xorg/modules \
  --opengl-prefix=/NVIDIA_OS/usr \
  --installer-prefix=/NVIDIA_OS/usr \
  --utility-prefix=/NVIDIA_OS/usr \
  --documentation-prefix=/NVIDIA_OS/usr \
  --application-profile-path=/NVIDIA_OS/usr/share/nvidia \
  --proc-mount-point=/NVIDIA_OS/proc \
  --compat32-prefix=/NVIDIA_OS/usr \
  --compat32-libdir=/lib \
  --install-compat32-libs \
  --no-x-check \
  --no-nouveau-check \
  --skip-depmod \
  --no-kernel-modules \
  --j${CPU_COUNT} \
  --silent

# Clone Open Source Nvidia driver, compile it and install it to temporary directory
git clone https://github.com/NVIDIA/open-gpu-kernel-modules ${DATA_DIR}/NvidiaOpenSource-Kernel
cd ${DATA_DIR}/NvidiaOpenSource-Kernel
git checkout ${NV_DRV_V}
make modules -j${CPU_COUNT}
INSTALL_MOD_PATH=/NVIDIA_OS make modules_install -j${CPU_COUNT}
rm -f /NVIDIA_OS/lib/modules/$UNAME/modules*

# Copy files for OpenCL and Vulkan over to temporary installation directory
if [ -d /lib/firmware/nvidia ]; then
  cp -R /lib/firmware/nvidia /NVIDIA_OS/lib/firmware/
fi
cp /usr/bin/nvidia-modprobe /NVIDIA_OS/usr/bin/
cp -R /etc/OpenCL /NVIDIA_OS/etc/
cp -R /etc/vulkan /NVIDIA_OS/etc/

# Download libnvidia-container, nvidia-container-runtime & container-toolkit and extract it to temporary installation directory
# Source libnvidia-container: https://github.com/ich777/libnvidia-container
# Source nvidia-container-runtime: https://github.com/ich777/nvidia-container-runtime
# Source nvidia-container-toolkit: https://github.com/ich777/nvidia-container-toolkit
cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz https://github.com/ich777/libnvidia-container/releases/download/${LIBNVIDIA_CONTAINER_V}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz
fi
tar -C /NVIDIA_OS -xf ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz

#DEPRECATED
#cd ${DATA_DIR}
#wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz https://github.com/ich777/nvidia-container-runtime/releases/download/${NVIDIA_CONTAINER_RUNTIME_V}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz
#tar -C /NVIDIA_OS -xf ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz
#Removed from Slackware description: $PLUGIN_NAME: nvidia-container-runtime v${NVIDIA_CONTAINER_RUNTIME_V}

cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz https://github.com/ich777/nvidia-container-toolkit/releases/download/${CONTAINER_TOOLKIT_V}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz
fi
tar -C /NVIDIA_OS -xf ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz

# Create Slackware package
PLUGIN_NAME="nvos-driver"
BASE_DIR="/NVIDIA_OS"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Nvidia-Driver v${NV_DRV_V}
$PLUGIN_NAME: libnvidia-container v${LIBNVIDIA_CONTAINER_V}
$PLUGIN_NAME: nvidia-container-runtime v${NVIDIA_CONTAINER_RUNTIME_V}
$PLUGIN_NAME: nvidia-container-toolkit v${CONTAINER_TOOLKIT_V}
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz
md5sum $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz | awk '{print $1}' > $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz.md5
