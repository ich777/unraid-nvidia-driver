# Download the Nvidia driver package
cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run http://us.download.nvidia.com/XFree86/Linux-x86_64/${NV_DRV_V}/NVIDIA-Linux-x86_64-${NV_DRV_V}.run
fi

# Make the Nvidia driver executable and install it in a temporary directory
chmod +x ${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run
mkdir -p /NVIDIA/usr/lib64/xorg/modules/{drivers,extensions} /NVIDIA/usr/bin /NVIDIA/etc /NVIDIA/lib/modules/${UNAME}/kernel/drivers/video /NVIDIA/lib/firmware
${DATA_DIR}/NVIDIA_v${NV_DRV_V}.run --kernel-name=$UNAME \
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
  --skip-depmod \
  --j${CPU_COUNT} \
  --silent

# Copy files for OpenCL and Vulkan over to temporary installation directory
if [ -d /lib/firmware/nvidia ]; then
  cp -R /lib/firmware/nvidia /NVIDIA/lib/firmware/
fi
cp /usr/bin/nvidia-modprobe /NVIDIA/usr/bin/
cp -R /etc/OpenCL /NVIDIA/etc/
cp -R /etc/vulkan /NVIDIA/etc/

# Download libnvidia-container, nvidia-container-runtime & container-toolkit and extract it to temporary installation directory
# Source libnvidia-container: https://github.com/ich777/libnvidia-container
# Source nvidia-container-runtime: https://github.com/ich777/nvidia-container-runtime
# Source nvidia-container-toolkit: https://github.com/ich777/nvidia-container-toolkit
cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz https://github.com/ich777/libnvidia-container/releases/download/${LIBNVIDIA_CONTAINER_V}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz
fi
tar -C /NVIDIA -xf ${DATA_DIR}/libnvidia-container-v${LIBNVIDIA_CONTAINER_V}.tar.gz

#DEPRECATED
#cd ${DATA_DIR}
#wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz https://github.com/ich777/nvidia-container-runtime/releases/download/${NVIDIA_CONTAINER_RUNTIME_V}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz
#tar -C /NVIDIA -xf ${DATA_DIR}/nvidia-container-runtime-v${NVIDIA_CONTAINER_RUNTIME_V}.tar.gz
#Removed from Slackware description: $PLUGIN_NAME: nvidia-container-runtime v${NVIDIA_CONTAINER_RUNTIME_V}

cd ${DATA_DIR}
if [ ! -f ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz https://github.com/ich777/nvidia-container-toolkit/releases/download/${CONTAINER_TOOLKIT_V}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz
fi
tar -C /NVIDIA -xf ${DATA_DIR}/nvidia-container-toolkit-v${CONTAINER_TOOLKIT_V}.tar.gz

# Create Slackware package
PLUGIN_NAME="nvidia-driver"
BASE_DIR="/NVIDIA"
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
$PLUGIN_NAME: libnvidia-container v{LIBNVIDIA_CONTAINER_V}
$PLUGIN_NAME: nvidia-container-runtime v${NVIDIA_CONTAINER_RUNTIME_V}
$PLUGIN_NAME: nvidia-container-toolkit v${CONTAINER_TOOLKIT_V}
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz
md5sum $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz | awk '{print $1}' > $TMP_DIR/${PLUGIN_NAME%%-*}-${NV_DRV_V}-${UNAME}-1.txz.md5