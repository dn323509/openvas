#This Script for Install Openvas 20 on Ubuntu 20.04
#From URL https://www.mikeslab.net/install-greenbone-vulnerability-manager-20-08-on-ubuntu-20-04/
#Install Prerequisites
sudo su -
apt update &&\
apt -y dist-upgrade &&\
apt -y autoremove &&\
apt install -y software-properties-common &&\
apt install -y build-essential cmake pkg-config libglib2.0-dev libgpgme-dev libgnutls28-dev uuid-dev libssh-gcrypt-dev libldap2-dev doxygen graphviz libradcli-dev libhiredis-dev libpcap-dev bison libksba-dev libsnmp-dev gcc-mingw-w64 heimdal-dev libpopt-dev xmltoman redis-server xsltproc libical-dev postgresql postgresql-contrib postgresql-server-dev-all gnutls-bin nmap rpm nsis curl wget fakeroot gnupg sshpass socat snmp smbclient libmicrohttpd-dev libxml2-dev python3-polib gettext rsync xml-twig-tools python3-paramiko python3-lxml python3-defusedxml python3-pip python3-psutil python3-impacket virtualenv vim git &&\
apt install -y texlive-latex-extra --no-install-recommends &&\
apt install -y texlive-fonts-recommended &&\
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
apt update &&\
apt -y install yarn &&\
yarn install &&\
yarn upgrade
