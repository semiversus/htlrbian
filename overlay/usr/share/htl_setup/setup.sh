#!/bin/bash

# cleanup files from previous boots
rm /etc/apt.conf.d/htl_proxy
rm /etc/profile.d/htl_proxy.sh

# source configuration to get configuration
user=`grep "user=" /boot/htl.config|tr -d '\r'|cut -f2 -d=`
password=`grep "password=" /boot/htl.config|tr -d '\r'|cut -f2 -d=`

# check if a new username and password is given
if [ -z "$user" ];
then
	exit
fi

# replace configuration with the template
cp /usr/share/htl_setup/htl.config /boot

# adapt wpa_supplicant.conf file for wifi access to the HTL network
sed -e "s/identity=.*# HTL network/identity=\"$user\"/ # HTL network" -i /etc/wpa_supplicant/wpa_supplicant.conf
sed -e "s/password=.*# HTL network/password=\"$password\" # HTL network/" -i /etc/wpa_supplicant/wpa_supplicant.conf

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

# set password for chezdav
realm="ChezDAV"
digest="$( printf "%s:%s:%s" "$user" "$realm" "$password" |
           md5sum | awk '{print $1}' )"

printf "%s:%s:%s\n" "$user" "$realm" "$digest" >> "/home/pi/.chezdav.htdigest"
