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

#Create the GVM User
echo 'export PATH="$PATH:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"' | tee -a /etc/profile.d/gvm.sh &&\
chmod 0755 /etc/profile.d/gvm.sh &&\
source /etc/profile.d/gvm.sh &&\
bash -c 'cat < /etc/ld.so.conf.d/gvm.conf
# gmv libs location
/opt/gvm/lib
EOF'

mkdir /opt/gvm &&\
adduser gvm --disabled-password --home /opt/gvm/ --no-create-home --gecos '' &&\
usermod -aG redis gvm &&\
chown gvm:gvm /opt/gvm/
sudo su - gvm

#Download and install Software (GVM)
mkdir src &&\
cd src &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH

git clone -b gvm-libs-20.08 --single-branch  https://github.com/greenbone/gvm-libs.git &&\
git clone -b openvas-20.08 --single-branch https://github.com/greenbone/openvas.git &&\
git clone -b gvmd-20.08 --single-branch https://github.com/greenbone/gvmd.git &&\
git clone -b master --single-branch https://github.com/greenbone/openvas-smb.git &&\
git clone -b gsa-20.08 --single-branch https://github.com/greenbone/gsa.git &&\
git clone -b ospd-openvas-20.08 --single-branch  https://github.com/greenbone/ospd-openvas.git &&\
git clone -b ospd-20.08 --single-branch https://github.com/greenbone/ospd.git

#Install gvm-libs (GVM)
cd gvm-libs &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH &&\
mkdir build &&\
cd build &&\
cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm .. &&\
make &&\
make doc &&\
make install &&\
cd /opt/gvm/src

# Install openvas-smb (GVM)
# Now enter openvas-smb directory and compile the source code:

cd openvas-smb &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH &&\
mkdir build &&\
cd build/ &&\
cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm .. &&\
make &&\
make install &&\
cd /opt/gvm/src

# Install the scanner (GVM)
# Like in the previous steps, we will now build and install openvas scanner:

cd openvas &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH &&\
mkdir build &&\
cd build/ &&\
cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm .. &&\
make &&\
make doc &&\
make install &&\
cd /opt/gvm/src

# Fix redis for OpenVAS Install (root)
# Now we must log out of the current session to get back to the privilege user by Type 'exit' in the terminal.
# Now paste the following code to terminal:

export LC_ALL="C" &&\
ldconfig &&\
cp /etc/redis/redis.conf /etc/redis/redis.orig &&\
cp /opt/gvm/src/openvas/config/redis-openvas.conf /etc/redis/ &&\
chown redis:redis /etc/redis/redis-openvas.conf &&\
echo "db_address = /run/redis-openvas/redis.sock" > /opt/gvm/etc/openvas/openvas.conf &&\
systemctl enable redis-server@openvas.service &&\
systemctl start redis-server@openvas.service
sysctl -w net.core.somaxconn=1024 &&\
sysctl vm.overcommit_memory=1 &&\
echo "net.core.somaxconn=1024"  >> /etc/sysctl.conf &&\
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
cat << /etc/systemd/system/disable-thp.service
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload &&\
systemctl start disable-thp &&\
systemctl enable disable-thp &&\
systemctl restart redis-server

# Add the /opt/gvm/sbin path to the secure_path variable:

sed 's/Defaults\s.*secure_path=\"\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin:\/snap\/bin\"/Defaults secure_path=\"\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin:\/snap\/bin:\/opt\/gvm\/sbin\"/g' /etc/sudoers | EDITOR='tee' visudo

# Allow the user running ospd-openvas to launch with root permissions:

echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/openvas" > /etc/sudoers.d/gvm
echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/gsad" >> /etc/sudoers.d/gvm

# Update NVT (GVM)
# We will now run the greenbone-nvt-sync to update the vulnerability file definitions.
# First switch back to the GVM user session

sudo su – gvm
greenbone-nvt-sync

# Upload Plugins in redis with OpenVAS (GVM)
sudo openvas -u

exit
echo "/opt/gvm/lib > /etc/ld.so.conf.d/gvm.conf 
ldconfig
sudo su - gvm

# Install Manager (GVM)
cd /opt/gvm/src/gvmd &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH &&\
mkdir build &&\
cd build/ &&\
cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm .. &&\
make &&\
make doc &&\
make install &&\
cd /opt/gvm/src

# Configure PostgreSQL (Sudoers User)
exit
cd /
sudo -u postgres bash
export LC_ALL="C"
createuser -DRS gvm
createdb -O gvm gvmd

psql gvmd
create role dba with superuser noinherit;
grant dba to gvm;
create extension "uuid-ossp";
create extension "pgcrypto";
exit
exit

# Fix Certificates (GVM)
sudo su - gvm
gvm-manage-certs -a

# Create Admin User (GVM)
gvmd --create-user=admin --password=admin

# Configure and Update Feeds (GVM)
gvmd --get-users --verbose
