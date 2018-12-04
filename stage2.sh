#!/bin/bash

# update locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/default/locale
locale-gen en_US.UTF-8
update-locale en_US.UTF-8

# install packages
apt update -qq
apt upgrade -qqy
apt install -qqy shellinabox chezdav

# copy htl.config
cp /usr/share/htl_setup/htl.config /boot

# enable services
systemctl enable ssh
systemctl enable htl-network