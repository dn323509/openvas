# Create the GVM User
echo 'export PATH="$PATH:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"' | tee -a /etc/profile.d/gvm.sh &&\
chmod 0755 /etc/profile.d/gvm.sh &&\
source /etc/profile.d/gvm.sh &&\
bash -c 'cat << EOF > /etc/ld.so.conf.d/gvm.conf
# gmv libs location
/opt/gvm/lib
EOF'

mkdir /opt/gvm &&\
adduser gvm --disabled-password --home /opt/gvm/ --no-create-home --gecos '' &&\
usermod -aG redis gvm &&\
chown gvm:gvm /opt/gvm/

sudo su - gvm

# Download and Install Software (GVM)
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

# Install gvm-libs (GVM)
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
cd openvas-smb &&\
export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH &&\
mkdir build &&\
cd build/ &&\
cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm .. &&\
make &&\
make install &&\
cd /opt/gvm/src

# Install the scanner (GVM)
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

cat << EOF > /etc/systemd/system/disable-thp.service
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

sed 's/Defaults\s.*secure_path=\"\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin:\/snap\/bin\"/Defaults secure_path=\"\/usr\/local\/sbin:\/usr\/local\/bin:\/usr\/sbin:\/usr\/bin:\/sbin:\/bin:\/snap\/bin:\/opt\/gvm\/sbin\"/g' /etc/sudoers | EDITOR='tee' visudo

echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/openvas" > /etc/sudoers.d/gvm
echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/gsad" >> /etc/sudoers.d/gvm

# Update NVT (GVM)
greenbone-nvt-sync


