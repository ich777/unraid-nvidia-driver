#!/bin/bash
PLUGIN_NAME="nvidia-driver"
BASE_DIR="/usr/local/emhttp/plugins"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp --parents -R $BASE_DIR/$PLUGIN_NAME/ $TMP_DIR/$VERSION/
makepkg -l y -c y $TMP_DIR/$PLUGIN_NAME-$VERSION.txz
md5sum $TMP_DIR/$PLUGIN_NAME-$VERSION.txz > $TMP_DIR/$PLUGIN_NAME-$VERSION.txz.md5
rm -R $TMP_DIR/$VERSION/

#rm -R $TMP_DIR
