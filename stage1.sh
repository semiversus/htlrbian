#!/bin/bash

DOWNLOAD_URL=$1
CHROOT_PATH=.rootfs

# download and unzip raspbian img
if [ ! -f raspbian.zip ]; then
    echo "Downloading Raspbian..."
    wget ${DOWNLOAD_URL} -O raspbian.zip -q --show-progress
fi

function cleanup {
    echo 'Cleanup...'
    umount ${CHROOT_PATH}/{dev/pts,dev,sys,proc,boot,}
    losetup -d `cat .loop`
    rm .loop ${CHROOT_PATH} -rf
}

set -e

echo "Prepare image..."
unzip -p raspbian.zip > htlrbian.img
losetup -f -P --show htlrbian.img > .loop
trap cleanup EXIT
mkdir ${CHROOT_PATH}/boot -p
mount -o rw `cat .loop`p2 ${CHROOT_PATH}
mount -o rw `cat .loop`p1 ${CHROOT_PATH}/boot
mount --bind /dev ${CHROOT_PATH}/dev/
mount --bind /sys ${CHROOT_PATH}/sys/
mount --bind /proc ${CHROOT_PATH}/proc/
mount --bind /dev/pts ${CHROOT_PATH}/dev/pts

echo "Copy overlay"
cp overlay_network/* ${CHROOT_PATH} -r
cp overlay_htlrbian/* ${CHROOT_PATH} -r

echo "Prepare chroot..."
sed -i 's/^/#CHROOT /g' ${CHROOT_PATH}/etc/ld.so.preload
cp stage2.sh ${CHROOT_PATH}
cp /usr/bin/qemu-arm-static ${CHROOT_PATH}/usr/bin

echo "Start stage 2..."
chroot ${CHROOT_PATH} bin/bash -c "/stage2.sh"

echo "Cleanup image..."
sed -i 's/^#CHROOT //g' ${CHROOT_PATH}/etc/ld.so.preload
rm ${CHROOT_PATH}/stage2.sh
rm ${CHROOT_PATH}/usr/bin/qemu-arm-static

echo "Zip image..."
trap - EXIT
cleanup
zip htlrbian.zip htlrbian.img
