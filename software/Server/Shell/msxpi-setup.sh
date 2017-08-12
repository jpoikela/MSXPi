#|===========================================================================|
#|                                                                           |
#| MSXPi Interface                                                           |
#|                                                                           |
#| Version : 0.8.1                                                             |
#|                                                                           |
#| Copyright (c) 2015-2017 Ronivon Candido Costa (ronivon@outlook.com)       |
#|                                                                           |
#| All rights reserved                                                       |
#|                                                                           |
#| Redistribution and use in source and compiled forms, with or without      |
#| modification, are permitted under GPL license.                            |
#|                                                                           |
#|===========================================================================|
#|                                                                           |
#| This file is part of MSXPi Interface project.                             |
#|                                                                           |
#| MSX PI Interface is free software: you can redistribute it and/or modify  |
#| it under the terms of the GNU General Public License as published by      |
#| the Free Software Foundation, either version 3 of the License, or         |
#| (at your option) any later version.                                       |
#|                                                                           |
#| MSX PI Interface is distributed in the hope that it will be useful,       |
#| but WITHOUT ANY WARRANTY; without even the implied warranty of            |
#| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
#| GNU General Public License for more details.                              |
#|                                                                           |
#| You should have received a copy of the GNU General Public License         |
#| along with MSX PI Interface.  If not, see <http://www.gnu.org/licenses/>. |
#|===========================================================================|
#
# File history :
# 0.1    : Initial version.
#!/bin/sh
MSXPIHOME=/home/pi/msxpi
MYTMP=/tmp
RMFILES=true

ssid=YourWiFiId
psk=YourWiFiPassword

# ------------------------------------------
# Install libraries required by msxpi-server
# ------------------------------------------
cd $MYTMP
sudo apt-get -y install alsa-utils
sudo apt-get -y install music123
sudo apt-get -y install smbclient
sudo apt-get -y install html2text
sudo apt-get -y install libcurl4-nss-dev
wget abyz.co.uk/rpi/pigpio/pigpio.tar
tar xvf pigpio.tar
cd PIGPIO
make -j4
sudo make install

# ------------------
# Enable ssh into Pi
# ------------------
touch /boot/ssh

# ----------------------------------------------------------
# Configure Wireless network with provided SSID and Password
# ----------------------------------------------------------
cat <<EOF | sed "s/myssid/$ssid/" | sed "s/mypsk/$psk/"  >/etc/wpa_supplicant/wpa_supplicant.conf
country=GB
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
	ssid="myssid"
	psk="mypsk"
}
EOF

# -------------------------------------------
# Create msxpi directory and link on home dir
# -------------------------------------------
mkdir -p $MSXPIHOME/disks
chown -R pi.pi $MSXPIHOME
ln -s $MSXPIHOME /home/msxpi

# ----------------------------------------
# Install msxpi-server service for systemd
# ----------------------------------------
cat <<EOF >/lib/systemd/system/msxpi-server.service
[Unit]
Description=Start MSXPi Server

[Service]
WorkingDirectory=/home/pi/msxpi
#Type=forking
#ExecStart=/bin/bash start_msx.sh
ExecStart=/home/pi/msxpi/msxpi-server

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable msxpi-server

# --------------------------------------------------
# Configure PWM (analog audio) on GPIO18 and GPIO13
# --------------------------------------------------
echo "dtoverlay=pwm-2chan,pin=18,func=2,pin2=13,func2=4" >> /boot/config.txt
amixer cset numid=3 1

# Download and compile the msxpi.server
cd $MSXPIHOME
mkdir msxpi-code
cd msxpi-code
wget --no-check-certificate https://raw.githubusercontent.com/costarc/MSXPi/dev/software/Server/C/src/msxpi-server.c
cc -Wall -pthread -o msxpi-server msxpi-server.c -lpigpio -lrt -lcurl
mv msxpi-server $MSXPIHOME/

cd $MSXPIHOME/disks/
wget --no-check-certificate https://github.com/costarc/MSXPi/raw/dev/software/target/disks/msxpiboot.dsk
wget --no-check-certificate https://github.com/costarc/MSXPi/raw/dev/software/target/disks/msxpitools.dsk

chown -R pi.pi $MSXPIHOME

