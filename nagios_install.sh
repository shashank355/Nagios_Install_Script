#!/bin/bash

if [ ! -d "nagios" ]; then
  mkdir nagios
fi

cd nagios

if ! command -v wget &> /dev/null; then
  dnf -y install wget
fi

if [ ! -f nagios-4.4.6.tar.gz ]; then 
  wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.4.6.tar.gz
fi

if [ ! -f nagios-plugins-2.3.3.tar.gz ]; then 
  wget http://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
fi 

/usr/bin/id nagios 

if [ $? -ne 0 ]; then
  useradd nagios
fi

/usr/bin/getent group nagcmd

if [ $? -ne 0 ]; then
  groupadd nagcmd
fi

usermod -a -G nagcmd nagios
usermod -a -G nagios,nagcmd apache

dnf install -y httpd php gcc glibc glibc-common gd gd-devel make net-snmp unzip 

tar xvfz nagios-4.4.6.tar.gz
tar xvfz nagios-plugins-2.3.3.tar.gz

cd nagios-4.4.6

./configure --with-command-group=nagcmd

make all

make install

make install-init

make install-config

make install-commandmode

make install-webconf

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/

chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

systemctl start nagios
systemctl start httpd

htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin newpassword

cd ../nagios-plugins-2.3.3

./configure --with-nagios-user=nagios --with-nagios-group=nagios

make

make install 

systemctl enable nagios
systemctl enable httpd

systemctl restart nagios
systemctl restart httpd

