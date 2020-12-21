#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

set -e
trap exit 1 ERR

export LANGUAGE=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8
locale-gen en_GB.UTF-8

ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
echo "setxkbmap de" >> /home/pi/.bashrc

apt update -qq
apt upgrade -qqy

xargs apt install -qqy < requirements_apt.txt

python3 -m pip install -r requirements_pip.txt

# change shellinabox settings
mv /etc/default/__shellinabox__ /etc/default/shellinabox
mv "/etc/shellinabox/options-enabled/00+Black on White.css" "/etc/shellinabox/options-enabled/00_Black on White.css"
mv "/etc/shellinabox/options-enabled/00_White On Black.css" "/etc/shellinabox/options-enabled/00+White On Black.css"

# create autostart.sh
echo "#!/bin/bash" > /home/pi/autostart.sh
chmod 755 /home/pi/autostart.sh
chown pi:pi /home/pi/autostart.sh

# ssh IPQoS flags to maintain interactive connection
echo "IPQoS 0x00" >> /etc/ssh/sshd_config
echo "IPQoS 0x00" >> /etc/ssh/ssh_config

# setup NoMachine
wget https://download.nomachine.com/download/6.12/Raspberry/nomachine_6.12.3_5_armhf.deb -q -O nomachine.deb
dpkg -i nomachine.deb
rm nomachine.deb
/etc/NX/nxserver --stop
echo "hdmi_group=2" >> /boot/config.txt
echo "hdmi_mode=32" >> /boot/config.txt
echo "hdmi_force_hotplug=1" >> /boot/config.txt

# disable piwiz at desktop startup
rm /etc/xdg/autostart/piwiz.desktop

# copy htl.txt and wifi.txt
cp /usr/share/htl_setup/htl.txt /boot
cp /usr/share/htl_setup/wifi.txt /boot


# enable services
systemctl enable ssh
systemctl enable shellinabox
systemctl enable smbd
systemctl enable nmbd
systemctl enable autostart
systemctl enable htl-network
systemctl enable fix-mime

# temporary fix for WPA Enterprise on Raspbian Buster
apt remove wpasupplicant -y
mv -f /etc/apt/sources.list /etc/apt/sources.list.bak
echo 'deb http://raspbian.raspberrypi.org/raspbian/ stretch main contrib non-free rpi' > /etc/apt/sources.list
apt update
apt install wpasupplicant -y
apt-mark hold wpasupplicant
mv -f /etc/apt/sources.list.bak /etc/apt/sources.list

# cleanup apt
apt update -qq
apt autoremove -qqy
apt clean

# fill left space with zeros (for better compression ratio)
dd if=/dev/zero of=zero_file && :
rm zero_file
