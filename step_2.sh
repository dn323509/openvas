#Create the GVM User
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
