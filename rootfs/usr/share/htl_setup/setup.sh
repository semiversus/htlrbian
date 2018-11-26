#!/bin/bash

# cleanup files from previous boots
rm /etc/apt.conf.d/htl_proxy
rm /etc/profile.d/htl_proxy.sh

# source configuration to get configuration
. /boot/htl.config

# check if a new username and password is given
if [ -z "$user" ];
then
	exit
fi

# replace configuration with the template
cat <<EOT > /boot/htl.config
user=
password=
EOT

# adapt wpa_supplicant.conf file for wifi access to the HTL network
cp /usr/share/htl_setup/wpa_supplicant.conf /etc/wpa_supplicant -f
sed -e "s/identity=/identity=\"$user\"/" -i /etc/wpa_supplicant/wpa_supplicant.conf
sed -e "s/password=/password=\"$password\"/" -i /etc/wpa_supplicant/wpa_supplicant.conf

# set the hostname if given or generate one with the given username
if [ -z "$hostname" ];
then
	hostname=`echo "pi-$user" | tr '[._/]' '-'`
fi

echo $hostname > /etc/hostname
sed -e "s/127\.0\.0\.1.*/127.0.0.1\tlocalhost $hostname/" -i /etc/hosts
hostnamectl set-hostname $hostname

# set password for user pi to the given user password
echo "pi:$password" | chpasswd

# enable ssh
update-rc.d ssh enable && invoke-rc.d ssh start 
