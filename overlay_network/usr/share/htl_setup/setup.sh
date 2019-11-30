#!/bin/bash

# cleanup files from previous boots
rm /etc/apt/apt.conf.d/htl_proxy
rm /etc/profile.d/htl_proxy.sh
git config --system unset http.proxy

# source configuration to get configuration
user=`grep "user=" /boot/htl.txt|tr -d '\r'|cut -f2 -d=|xargs echo`
password=`grep "password=" /boot/htl.txt|tr -d '\r'|cut -f2 -d=|xargs echo`
hostname=`grep "hostname=" /boot/htl.txt|tr -d '\r'|cut -f2 -d=|xargs echo`

# check if a new username and password is given
if [ -z "$user" ];
then
	exit
fi

# replace configuration with the template
cp /usr/share/htl_setup/htl.txt /boot

# adapt wpa_supplicant.conf file for wifi access to the HTL network
hash=`echo -n $password | iconv -t utf16le | openssl md4|cut -f2 -d\ `
sed -e "s/identity=.*# HTL network/identity=\"$user\"/ # HTL network" -i /etc/wpa_supplicant/wpa_supplicant.conf
sed -e "s/password=.*# HTL network/password=hash:$hash # HTL network/" -i /etc/wpa_supplicant/wpa_supplicant.conf

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
echo -ne "$password\n$password\n" | smbpasswd -a -s pi
