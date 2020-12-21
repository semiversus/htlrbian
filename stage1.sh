#!/bin/bash

DOWNLOAD_URL=https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2020-12-04/2020-12-02-raspios-buster-armhf.zip
NAME=2020-12-02-htlrbian-buster

GIT_REV=`git describe --always --dirty --tags`
CHROOT_PATH=.rootfs

# download and unzip raspbian img
if [ ! -f ${NAME}_base.zip ]; then
    echo "Downloading Raspbian..."
    wget ${DOWNLOAD_URL} -O ${NAME}_base.zip -q --show-progress
fi

function cleanup {
    echo 'Cleanup...'
    umount ${CHROOT_PATH}/{dev/pts,dev,sys,proc,boot,}
    losetup -d `cat .loop`
    rm .loop ${CHROOT_PATH} -rf
}

set -e

echo "Prepare image..."
unzip -p ${NAME}_base.zip > ${NAME}.img
truncate -s 5G ${NAME}.img  # add zero bytes up to 5*1024^3 Bytes
parted ${NAME}.img resizepart 2 100%  # extend partition
losetup -f -P --show ${NAME}.img > .loop
resize2fs -f `cat .loop`p2  # extend filesystem
trap cleanup EXIT
mkdir ${CHROOT_PATH}/boot -p
mount -o rw `cat .loop`p2 ${CHROOT_PATH}
mount -o rw `cat .loop`p1 ${CHROOT_PATH}/boot
mount --bind /dev ${CHROOT_PATH}/dev/
mount --bind /sys ${CHROOT_PATH}/sys/
mount --bind /proc ${CHROOT_PATH}/proc/
mount --bind /dev/pts ${CHROOT_PATH}/dev/pts

echo "Copy overlay"
cp overlay/* ${CHROOT_PATH} -r

# image version in welcome message
sed -e "s/__GITREV__/$GIT_REV/" -i ${CHROOT_PATH}/etc/update-motd.d/20-image

echo "Prepare chroot..."
sed -i 's/^/#CHROOT /g' ${CHROOT_PATH}/etc/ld.so.preload
cp stage2.sh ${CHROOT_PATH}
cp req* ${CHROOT_PATH}
cp /usr/bin/qemu-arm-static ${CHROOT_PATH}/usr/bin

echo "Start stage 2..."
chroot ${CHROOT_PATH} bin/bash -c "/stage2.sh"

echo "Cleanup image..."
sed -i 's/^#CHROOT //g' ${CHROOT_PATH}/etc/ld.so.preload
rm ${CHROOT_PATH}/stage2.sh
rm ${CHROOT_PATH}/req*
rm ${CHROOT_PATH}/usr/bin/qemu-arm-static
rm ${CHROOT_PATH}/home/pi/MagPi -rf

trap - EXIT
cleanup
#echo "Zip image..."
#zip ${NAME}.zip ${NAME}.img
