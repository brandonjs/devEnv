#!/bin/bash -x
exec > /tmp/outfile.out

export PACKAGE=amazon-hwmon;
export VERSION=$1
export RELEASE=$2
export ARCH=$3
export HWMONRPM=$PACKAGE-$VERSION-$RELEASE.$ARCH.noarch;
#export USER=$3
export rhel5_prereqs="amazon-storlib-wrapper-python python-crypto python-simplejson python-multiprocessing"

echo "Enter your password for fetching RPM from devcentral"
read -s password
lkdir /tmp/amazon-hwmond_functional;
cd /tmp/amazon-hwmond_functional;
#wget http://koji.amazon.com/packages/$PACKAGE/$VERSION/$RELEASE/noarch/$HWMONRPM.rpm
wget --password=$password --user=$USER -O/tmp/$HWMONRPM.rpm https://devcentral.amazon.com/ac/brazil/package-master/package/view/HWMonAgent%3B$VERSION%3BRHEL5_64%3BDEV.STD.PTHREAD%3Bpackages/HWMonAgent/$HWMONRPM.rpm
for prereq in $(eval echo \${${ARCH}_prereqs}); do
   rpm -q $prereq || sudo yum -y install $prereq
done

rpm -q amazon-hwmon || sudo yum -y install amazon-hwmon;
rpm -q amazon-hwmon;
sudo rpm -Uhv /tmp/$HWMONRPM.rpm;
rpm -q amazon-hwmon;
sudo rpm -e --nodeps amazon-hwmon;
sudo rpm -ihv /tmp/$HWMONRPM.rpm;
rpm -q amazon-hwmon;
/etc/init.d/monit restart
sudo mv /etc/monit.rc/amazon-hwmon.rc /tmp;
sudo monit reload;
sudo /etc/init.d/amazon-hwmond stop;
sleep 15 && ps aux|grep amazon-hwmon;
sudo /etc/init.d/amazon-hwmond start;
sleep 15 && ps aux|grep amazon-hwmon;
sudo /etc/init.d/amazon-hwmond restart;
sleep 15 && ps aux|grep amazon-hwmon;
sudo /etc/init.d/amazon-hwmond stop;
sleep 15 && ps aux|grep amazon-hwmon;
sudo mv /tmp/amazon-hwmon.rc /etc/monit.rc;
sudo monit reload;
sleep 15 && ps aux|grep amazon-hwmon;
sudo /usr/local/sbin/amazon-hwmond report -v;
sleep 60 && curl -k -s https://hwmon-global.amazon.com/failures/`sudo /opt/systems/bin/hardwareid`;
sudo /usr/local/sbin/amazon-hwmond report -v;
sleep 60 && curl -k -s https://hwmon-global.amazon.com/failures/`sudo /opt/systems/bin/hardwareid`;
cd ..; sudo rm -r /tmp/amazon-hwmond_functional;
cat /tmp/outfile.out|mail -s "$HOSTNAME: $HWMONRPM Functional Testing Results" $USER@amazon.com
rm /tmp/outfile.out
sudo rpm -e --nodeps amazon-hwmon;
sudo yum -y install amazon-hwmon;
