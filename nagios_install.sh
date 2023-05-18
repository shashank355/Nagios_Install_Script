#!/bin/bash
#Install required packages

yum -y install httpd php gcc glibc glibc-common gd gd-devel make net-snmp unzip
Create Nagios user and group

useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd apache
# Download Nagios and Nagios plugins source code

cd /tmp
wget -O nagios.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.6.tar.gz
wget -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.3.3.tar.gz
#Extract Nagios and Nagios plugins source code

tar xzf nagios.tar.gz
tar xzf nagios-plugins.tar.gz
#Compile and install Nagios

cd nagioscore-nagios-4.4.6/
./configure --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf

# Compile and install Nagios plugins

cd ../nagios-plugins-release-2.3.3/
./tools/setup
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install
#Create Nagios admin user and generate password

htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin adminpassword
#Create Nagios service file

cat > /etc/systemd/system/nagios.service <<EOF
[Unit]
Description=Nagios
After=httpd.service

[Service]
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
ExecReload=/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg && systemctl reload httpd.service
User=nagios
Group=nagios

[Install]
WantedBy=multi-user.target
EOF
#Reload systemd daemon and start Nagios service

systemctl daemon-reload
systemctl enable nagios.service
systemctl start nagios.service
#Enable and start Apache service

systemctl enable httpd.service
systemctl start httpd.service

echo "Installation completed successfully."
echo "Nagios admin username: nagiosadmin"
echo "Nagios admin password: adminpassword"

