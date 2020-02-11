#!/bin/bash

################################################################################################
# Name of the script : Linux_System_check_light.sh
# Date               : last update 11/Feb/2020
# Version 			 : v1.2
#
# Written by Uktae Kim of IBM Korea Technical Solutions
#
# This script checks current status of linux server, and compare with now and
# before server status data. This script executes several commands, so there
# may be a little bit system load for a very short time.
#
# This script needs to install some packages (sysstat, pciutils, net-tools, lsscsi)
# If you don't install the packages, it won't execute some commands.
#
# Change History :
# 10/Jan/2020 - v1.0 First created
# 07/Feb/2020 - v1.1 Compatibility, Functional enhancement
# 11/Feb/2020 - v1.2 Devided to 2 versions, Full version, Light version. / Functional enhancement.
#
#################################################################################################


########## Environment Variables ##########

export LANG=C
export LANG=en_US
HOST=`/bin/hostname`
HOST=`/bin/hostname`
TODAY=`/bin/date +%Y%m%d-%H%M%S`
LOGPATH="/IBM_System_check/Result"
tmp_file=$LOGPATH/$TODAY.$HOST.system_check.log
SCRIPTNAME=Linux_System_check_IBM.sh
CHKDATE_NOW=`date "+%Y%m"`
CHKDATE_BEFORE=`date -d "-1 months" "+%Y%m"`
OSCHK=`uname -r | awk -F '.' '{print $1}'`
CHKID=`id | grep root | wc -l`
CLUSTERCHK=`rpm -qa | egrep "pacemaker|rgmanager" | awk -F '-' '{print $1}' | sed -n '1p'`
CHKNTP=`ps -ef | grep -v grep | grep -c ntp`
CHKCHRONY=`ps -ef | grep -v grep | grep -c chrony`


########### User Check Procedure ##########

if [ $CHKID -eq 0 ]; then
  echo
  echo "You must login as root... Try again."
  echo
  exit
fi


########## Begin executing Script ##########

clear
echo -e "\nBegining The script : $SCRIPTNAME"
echo -e "It may take several minutes..\n"
echo "$SCRIPTNAME" &>> $tmp_file
echo "Collect Date : "$TODAY &>> $tmp_file
echo -e "\n" &>> $tmp_file
mkdir /IBM_System_check/Resource/$CHKDATE_NOW


########## Basic Information ##########

echo "**************************************************************************" &>> $tmp_file
echo "BASIC INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== HOSTNAME ==" &>> $tmp_file
hostname &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== OS VERSION ==" &>> $tmp_file
if [ -f /etc/redhat-release ];
then
  cat /etc/redhat-release &>> $tmp_file
else
  cat /etc/centos-release &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== KERNEL VERSION ==" &>> $tmp_file
uname -r &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== SYSTEM INFORMATION ==" &>> $tmp_file
dmidecode -t system | egrep "Manufacturer|Product|Serial" | sed -e 's/\s//g' &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## Hardware Information ##########

echo "**************************************************************************" &>> $tmp_file
echo "HARDWARE INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== lspci CHANGES ==" &>> $tmp_file
lspci &>> /IBM_System_check/Resource/$CHKDATE_NOW/lspci
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/lspci /IBM_System_check/Resource/$CHKDATE_NOW/lspci &>> $tmp_file
echo -e "\n" &>> $tmp_file

########## CPU Information ##########

echo "**************************************************************************" &>> $tmp_file
echo "CPU INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== CPU dmidecode CHANGES ==" &>> $tmp_file
dmidecode -t processor | egrep "Version|Core|Thread" &>> /IBM_System_check/Resource/$CHKDATE_NOW/dmidecode_cpu
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/dmidecode_cpu /IBM_System_check/Resource/$CHKDATE_NOW/dmidecode_cpu &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== cpuinfo CHANGES ==" &>> $tmp_file
cat /proc/cpuinfo &>> /IBM_System_check/Resource/$CHKDATE_NOW/cpuinfo
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/cpuinfo /IBM_System_check/Resource/$CHKDATE_NOW/cpuinfo &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## MEMORY INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "MEMORY INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== MEMORY USAGE ==" &>> $tmp_file
free -m &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== SWAP CHANGES ==" &>> $tmp_file
swapon -s | awk {'print $1"   "$2"   "$3'} &>> /IBM_System_check/Resource/$CHKDATE_NOW/swapons
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/swapons /IBM_System_check/Resource/$CHKDATE_NOW/swapons &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== CORRUPTED MEMORY ==" &>> $tmp_file
cat /proc/meminfo | grep -i "HardwareCorrupted" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== MEMORY dmidecode CHANGES ==" &>> $tmp_file
dmidecode -t memory | egrep "Installed|Enabled" &>> /IBM_System_check/Resource/$CHKDATE_NOW/dmidecode_mem
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/dmidecode_mem /IBM_System_check/Resource/$CHKDATE_NOW/dmidecode_mem &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## BOOTING CONFIGURATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "BOOTING CONFIGURATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== UPTIME ==" &>> $tmp_file
uptime &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== grub.cfg CHANGES ==" &>> $tmp_file
if [ -f /boot/efi/EFI/redhat/grub.cfg ]; then
  cat /boot/efi/EFI/redhat/grub.cfg &>> /IBM_System_check/Resource/$CHKDATE_NOW/grub-cfg
elif [ -d /boot/efi/EFI/centos/grub.cfg ]; then
  cat /boot/efi/EFI/centos/grub.cfg &>> /IBM_System_check/Resource/$CHKDATE_NOW/grub-cfg
else
  cat /boot/grub2/grub.cfg &>> /IBM_System_check/Resource/$CHKDATE_NOW/grub-cfg
fi
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/grub-cfg /IBM_System_check/Resource/$CHKDATE_NOW/grub-cfg &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== grub Prameter CHANGES ==" &>> $tmp_file
cat /proc/cmdline &>> /IBM_System_check/Resource/$CHKDATE_NOW/grub_cmdline
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/grub_cmdline /IBM_System_check/Resource/$CHKDATE_NOW/grub_cmdline &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== Booting Target CHANGES ==" &>> $tmp_file
if [ $OSCHK -eq 3 ];
then
   systemctl get-default &>> /IBM_System_check/Resource/$CHKDATE_NOW/get-default
   diff /IBM_System_check/Resource/$CHKDATE_BEFORE/get-default /IBM_System_check/Resource/$CHKDATE_NOW/get-default &>> $tmp_file
else
   who -r &>> /IBM_System_check/Resource/$CHKDATE_NOW/who_r
   diff /IBM_System_check/Resource/$CHKDATE_BEFORE/who_r /IBM_System_check/Resource/$CHKDATE_NOW/who_r &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== fstab CHANGES ==" &>> $tmp_file
cat /etc/fstab &>> /IBM_System_check/Resource/$CHKDATE_NOW/fstab
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/fstab /IBM_System_check/Resource/$CHKDATE_NOW/fstab &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== rc.local CHANGES ==" &>> $tmp_file
cat /etc/rc.local &>> /IBM_System_check/Resource/$CHKDATE_NOW/rc_local
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/rc_local /IBM_System_check/Resource/$CHKDATE_NOW/rc_local &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## SYSTEM ENVIRONMENT INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "SYSTEM ENVIRONMENT INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== selinux CHANGES ==" &>> $tmp_file
cat /etc/selinux/config &>> /IBM_System_check/Resource/$CHKDATE_NOW/selinux
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/selinux /IBM_System_check/Resource/$CHKDATE_NOW/selinux &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== sysctl CHANGES ==" &>> $tmp_file
cat /etc/sysctl.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/sysctl_conf
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/sysctl_conf /IBM_System_check/Resource/$CHKDATE_NOW/sysctl_conf &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== GLOBAL ENVIRONMENT CHANGES ==" &>> $tmp_file
echo -e "\n" &>> $tmp_file
echo "/etc/profile" &>> $tmp_file
cat /etc/profile &>> /IBM_System_check/Resource/$CHKDATE_NOW/profile
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/profile /IBM_System_check/Resource/$CHKDATE_NOW/profile &>> $tmp_file
echo -e "\n" &>> $tmp_file
echo "/etc/bashrc" &>> $tmp_file
cat /etc/bashrc &>> /IBM_System_check/Resource/$CHKDATE_NOW/bashrc
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/bashrc /IBM_System_check/Resource/$CHKDATE_NOW/bashrc &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## ACCOUNT INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "ACCOUNT INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== SESSIONS NOW CONNECTED ==" &>> $tmp_file
echo "$(last | grep still | wc -l) session connected now." &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== /etc/passwd CHANGES ==" &>> $tmp_file
cat /etc/passwd &>> /IBM_System_check/Resource/$CHKDATE_NOW/account_passwd
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/account_passwd /IBM_System_check/Resource/$CHKDATE_NOW/account_passwd &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== /etc/group CHANGES ==" &>> $tmp_file
cat /etc/group &>> /IBM_System_check/Resource/$CHKDATE_NOW/account_group
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/account_group /IBM_System_check/Resource/$CHKDATE_NOW/account_group &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## STORAGE INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "STORAGE INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== FILESYSTEM USAGE OVER 80% ==" &>> $tmp_file
FSTHRESHOLD=80
### Check Filesystem Usage
FS_USE_LISTS=`df -Ph | grep -v Filesystem | awk '{print $6,$5}'`
FSIDX=1
for FSTMP in ${FS_USE_LISTS}; do
        REMNUM=`expr ${FSIDX} % 2`
        if [ ${REMNUM} -ne 0 ]; then
                FS_NAME=${FSTMP}
        else
                FSUSAGESIZE=`echo ${FSTMP} | cut -d ' ' -f 2 | cut -d '%' -f 1`
                #echo ${FSUSAGESIZE}
                if [ ${FSUSAGESIZE} -gt ${FSTHRESHOLD} ]; then
                        echo ''${FS_NAME}' = '${FSUSAGESIZE}'%' &>> $tmp_file
                fi
        fi
        FSIDX=$((FSIDX+1))
done
echo -e "\n" &>> $tmp_file

echo "== I-NODE USAGE OVER 80% ==" &>> $tmp_file
INODETHRESHOLD=80
### Check Filesystem Usage
FS_USE_LISTS=`df -Pi | grep -v Filesystem | awk '{print $6,$5}' | grep -v /boot/efi`
INODEIDX=1
for INODETMP in ${FS_USE_LISTS}; do
        REMNUM=`expr ${INODEIDX} % 2`
        if [ ${REMNUM} -ne 0 ]; then
                FS_NAME=${INODETMP}
        else
                INODEUSAGESIZE=`echo ${INODETMP} | cut -d ' ' -f 2 | cut -d '%' -f 1`
                #echo ${INODEUSAGESIZE}
                if [ ${INODEUSAGESIZE} -gt ${INODETHRESHOLD} ]; then
                        echo ''${FS_NAME}' = '${INODEUSAGESIZE}'%' &>> $tmp_file
                fi
        fi
        INODEIDX=$((INODEIDX+1))
done
echo -e "\n" &>> $tmp_file

echo "== PV CHANGES ==" &>> $tmp_file
pvs &>> /IBM_System_check/Resource/$CHKDATE_NOW/pvs
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/pvs /IBM_System_check/Resource/$CHKDATE_NOW/pvs &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== VG CHANGES ==" &>> $tmp_file
vgs &>> /IBM_System_check/Resource/$CHKDATE_NOW/vgs
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/vgs /IBM_System_check/Resource/$CHKDATE_NOW/vgs &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== LV CHANGES ==" &>> $tmp_file
lvs &>> /IBM_System_check/Resource/$CHKDATE_NOW/lvs
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/lvs /IBM_System_check/Resource/$CHKDATE_NOW/lvs &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== lvm.conf CHANGES ==" &>> $tmp_file
cat /etc/lvm/lvm.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/lvmconf
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/lvmconf /IBM_System_check/Resource/$CHKDATE_NOW/lvmconf &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== RO mount STATUS ==" &>> $tmp_file
mount | grep ro, | grep -v tmpfs &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== MULTIPATH STATUS ==" &>> $tmp_file
if [ -f /etc/multipath.conf ];
then
  multipath -ll &>> $tmp_file
else
  echo "multipath is not installed .." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== multipath.conf CHANGES ==" &>> $tmp_file
if [ -f /etc/multipath.conf ];
then
  cat /etc/multipath.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/multipathconf
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/multipathconf /IBM_System_check/Resource/$CHKDATE_NOW/multipathconf &>> $tmp_file
else
  echo "multipath is not installed .." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== multipath WWID CHANGES ==" &>> $tmp_file
if [ -f /etc/multipath.conf ];
then
  cat /etc/multipath/wwids &>> /IBM_System_check/Resource/$CHKDATE_NOW/wwids
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/wwids /IBM_System_check/Resource/$CHKDATE_NOW/wwids &>> $tmp_file
else
  echo "multipath is not installed .." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== multipath Bindings CHANGES ==" &>> $tmp_file
if [ -f /etc/multipath.conf ];
then
  cat /etc/multipath/bindings &>> /IBM_System_check/Resource/$CHKDATE_NOW/bindings
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/bindings /IBM_System_check/Resource/$CHKDATE_NOW/bindings &>> $tmp_file
else
  echo "multipath is not installed .." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== lsscsi CHANGES ==" &>> $tmp_file
lsscsi --scsi_id &>> /IBM_System_check/Resource/$CHKDATE_NOW/lsscsi
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/lsscsi /IBM_System_check/Resource/$CHKDATE_NOW/lsscsi &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## PACKAGE STATUS ##########
# it marks "#" during test period, because it takes a lot of time.#

echo "**************************************************************************" &>> $tmp_file
echo "PACKAGE STATUS" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== yum history CHANGES ==" &>> $tmp_file
yum history &>> /IBM_System_check/Resource/$CHKDATE_NOW/yumhistory
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/yumhistory /IBM_System_check/Resource/$CHKDATE_NOW/yumhistory &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== last rpm CHANGES ==" &>> $tmp_file
rpm -qa --last &>> /IBM_System_check/Resource/$CHKDATE_NOW/rpmlast
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/rpmlast /IBM_System_check/Resource/$CHKDATE_NOW/rpmlast &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## KDUMP INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "KDUMP INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== KDUMP STATUS ==" &>> $tmp_file
if [ $OSCHK -eq 3 ];
then
   systemctl status kdump &>> $tmp_file
else
   service kdump status &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== KDUMP FILE CHECK ==" &>> $tmp_file
if [ `ls -artl /boot | grep kdump | wc -l` -eq 0 ];
then
  echo "There is no kdump.img file.." &>> $tmp_file
else
  ls -artl /boot | grep kdump &>> $tmp_file
  stat /boot/*kdump.img | grep Modify &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== crashkernel CHANGES ==" &>> $tmp_file
cat /proc/cmdline | grep crashkernel &>> /IBM_System_check/Resource/$CHKDATE_NOW/crashkernel
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/crashkernel /IBM_System_check/Resource/$CHKDATE_NOW/crashkernel &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== KDUMP Configuration CHANGES ==" &>> $tmp_file
cat /etc/kdump.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/kdumpconf
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/kdumpconf /IBM_System_check/Resource/$CHKDATE_NOW/kdumpconf &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## DAEMON & PROCESS CHECK ##########

echo "**************************************************************************" &>> $tmp_file
echo "DAEMON & PROCESS CHECK" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== FAILED DAEMON ==" &>> $tmp_file
if [ $OSCHK -eq 3 ];
then
  systemctl --failed &>> $tmp_file
else
  service --status-all | egrep -i "stop|not|fail|unknown" &>> $tmp_file
  #the command makes "grep: /proc/fs/nfsd/portlist: No such file or directory" I don't know how to discard this message...
fi
echo -e "\n" &>> $tmp_file

echo "== ZOMBIE PROCESS CHECK ==" &>> $tmp_file
ps auxw | grep defunct &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## NETWORK INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "NETWORK INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== PACKET STATUS ==" &>> $tmp_file
ip -s link | grep -v link/ether &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== NETWORK DEVICE STATUS ==" &>> $tmp_file
ls -artl /etc/sysconfig/network-scripts |grep ifcfg | awk -F 'g-' '{print "ethtool "$2}' | sh | egrep "Setting|Speed|Duplex|detect" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== PORT STATUS ==" &>> $tmp_file
if [ `netstat -nap | egrep "CLOSING|FIN-WAIT1|CLOSE-WAIT|FIN-WAIT2|SYN_RECEIVED|SYN-SENT|CLOSED|TIME-WAIT|LAST-ACK|DISCONNECTING" | wc -l` -eq 0 ];
then
  echo "The status of All the ports is optimal." &>> $tmp_file
else
  netstat -nap | egrep "CLOSING|FIN-WAIT1|CLOSE-WAIT|FIN-WAIT2|SYN_RECEIVED|SYN-SENT|CLOSED|TIME-WAIT|LAST-ACK|DISCONNECTING" &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== BONDING STATUS ==" &>> $tmp_file
if [ -d /proc/net/bonding ]; then
  IFS=$'\n' ARR=(`ls -artl /etc/sysconfig/network-scripts |grep bond | awk -F 'g-' '{print $2}'`)
  for VALUE in "${ARR[@]}"; do echo "<---- $VALUE ---->"; done &>> /dev/null
  ls -artl /etc/sysconfig/network-scripts |grep bond | awk -F 'g-' '{print $2}' &>> /dev/null
  for value in "${ARR[@]}"; do cat /proc/net/bonding/$value; done | egrep "enp|Status|Speed|Duplex|Bond" &>> $tmp_file
else
  echo "Bonding isn't configured.." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== /etc/hosts CHANGES ==" &>> $tmp_file
cat /etc/hosts &>> /IBM_System_check/Resource/$CHKDATE_NOW/hosts
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/hosts /IBM_System_check/Resource/$CHKDATE_NOW/hosts &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== Network device CHANGES ==" &>> $tmp_file
ip a | grep -v valid &>> /IBM_System_check/Resource/$CHKDATE_NOW/ipa
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/ipa /IBM_System_check/Resource/$CHKDATE_NOW/ipa &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== route CHANGES ==" &>> $tmp_file
route &>> /IBM_System_check/Resource/$CHKDATE_NOW/route
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/route /IBM_System_check/Resource/$CHKDATE_NOW/route &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== DNS CHANGES ==" &>> $tmp_file
cat /etc/resolv.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/resolvconf
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/resolvconf /IBM_System_check/Resource/$CHKDATE_NOW/resolvconf &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== Network script CHANGES ==" &>> $tmp_file
for int in $(ls /etc/sysconfig/network-scripts/ | grep ifcfg)
do
    echo "<-------- $int -------->" &>> /IBM_System_check/Resource/$CHKDATE_NOW/netscripts
    cat /etc/sysconfig/network-scripts/$int &>> /IBM_System_check/Resource/$CHKDATE_NOW/netscripts
done
diff /IBM_System_check/Resource/$CHKDATE_BEFORE/netscripts /IBM_System_check/Resource/$CHKDATE_NOW/netscripts &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## TIME SYNC INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "TIME SYNC STATUS" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== TIME STATUS ==" &>> $tmp_file
if [ $OSCHK -eq 3 ];
then
   timedatectl &>> $tmp_file
else
   date &>> $tmp_file
   cat /etc/sysconfig/clock | grep ZONE &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== NTP CHANGES ==" &>> $tmp_file
CHKNTP=`ps -ef | grep -v grep | grep -c ntp`
if [ $CHKNTP -eq 1 ];
then
  echo -e "\n" &>> $tmp_file
  echo -e "/etc/ntp.conf" &>> $tmp_file
  cat /etc/ntp.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/ntpconf
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/ntpconf /IBM_System_check/Resource/$CHKDATE_NOW/ntpconf &>> $tmp_file
  echo -e "\n" &>> $tmp_file
  echo -e "/etc/sysconfig/ntpd" &>> $tmp_file
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/ntpd /IBM_System_check/Resource/$CHKDATE_NOW/ntpd &>> $tmp_file
  cat /etc/sysconfig/ntpd &>> /IBM_System_check/Resource/$CHKDATE_NOW/ntpd
else
  echo "NTP is not running.." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== NTP CHECK ==" &>> $tmp_file
if [ $CHKNTP -eq 1 ];
then
  ntpq -p &>> $tmp_file
else
  echo "NTP is not running.." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== Chrony CHANGES ==" &>> $tmp_file

if [ $CHKCHRONY -eq 1 ];
CHKCHRONY=`ps -ef | grep -v grep | grep -c chrony`
then
  cat /etc/chrony.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/chronyconf
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/chronyconf /IBM_System_check/Resource/$CHKDATE_NOW/chronyconf &>> $tmp_file
else
  echo "Chrony is not running.." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== CHRONY CHECK ==" &>> $tmp_file
if [ $CHKCHRONY -eq 1 ];
then
  chronyc sources -v &>> $tmp_file
  chronyc tracking &>> $tmp_file
else
  echo "Chrony is not running.." &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file




########## SYSTEM RESOURCE USAGE CHECK##########

echo "**************************************************************************" &>> $tmp_file
echo "SYSTEM RESOURCE USAGE CHECK" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== SYSTEM RESOURCE USAGE ==" &>> $tmp_file
sar -u -r -d -n DEV 1 5 | grep Average &>> $tmp_file
echo "NOTE : The check period for average is 10 seconds after execute this script." &>> $tmp_file
# this NOTE works whether execute sar or not execute. it is problem...
echo -e "\n" &>> $tmp_file

echo "== CPU USAGE TOP 10 PROCESS ==" &>> $tmp_file
ps -eo user,pid,ppid,rss,size,vsize,pmem,pcpu,time,cmd --sort -pcpu | head -n 10 &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== MEMORY USAGE TOP 10 PROCESS ==" &>> $tmp_file
ps -eo user,pid,ppid,rss,size,vsize,pmem,pcpu,time,cmd --sort -rss | head -n 10 &>> $tmp_file
echo -e "\n" &>> $tmp_file


########## CLUSTER INFORMATION ##########

echo "**************************************************************************" &>> $tmp_file
echo "CLUSTER INFORMATION" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== CLUSTER STATUS ==" &>> $tmp_file
case $CLUSTERCHK in
  'rgmanager')
  clustat &>> $tmp_file 2>&1
  ;;
  'pacemaker')
  pcs status &>> $tmp_file 2>&1
  ;;
  *)
  echo "The cluster software is not installed.." &>> $tmp_file
  ;;
esac
echo -e "\n" &>> $tmp_file

echo "== Cluster configuration CHANGES ==" &>> $tmp_file
case $CLUSTERCHK in
  'rgmanager')
  cat /etc/cluster/cluster.conf &>> /IBM_System_check/Resource/$CHKDATE_NOW/clusterconf
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/clusterconf /IBM_System_check/Resource/$CHKDATE_NOW/clusterconf &>> $tmp_file
  ;;
  'pacemaker')
  pcs config &>> /IBM_System_check/Resource/$CHKDATE_NOW/pcsconfig
  diff /IBM_System_check/Resource/$CHKDATE_BEFORE/pcsconfig /IBM_System_check/Resource/$CHKDATE_NOW/pcsconfig &>> $tmp_file
  ;;
  *)
  echo "The cluster software is not installed.." &>> $tmp_file
  ;;
esac
echo -e "\n" &>> $tmp_file


########## SYSTEM LOG ##########

echo "**************************************************************************" &>> $tmp_file
echo "SYSTEM LOG" &>> $tmp_file
echo "**************************************************************************" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== CRON LOG ==" &>> $tmp_file
if [ `cat /var/log/cron* | egrep -i "fail|error|warning|timeout|imklog" | wc -l` -eq 0 ];
then
  echo "There is no data in /var/log/cron.." &>> $tmp_file
else
  cat /var/log/cron* | egrep -i "fail|error|warning|timeout|imklog" &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file

echo "== MESSAGE LOG ==" &>> $tmp_file
cat /var/log/messages* | egrep -i "fail|error|timeout|imklog|trace:" &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== DMESG LOG ==" &>> $tmp_file
cat /var/log/dmesg* | egrep -i "fail|error|warning|timeout|bug|imklog|trace:" &>> $tmp_file
stat /var/log/dmesg | grep Modify  &>> $tmp_file
echo -e "\n" &>> $tmp_file

echo "== MCELOG ==" &>> $tmp_file
if [ -f /var/log/mcelog ]; then
  stat /var/log/mcelog | grep Modify  &>> $tmp_file
  cat /var/log/mcelog &>> $tmp_file
else
  echo "There is no mcelog file. (/var/log/mcelog)" &>> $tmp_file
fi
echo -e "\n" &>> $tmp_file



########## DONE ##########

sleep 1
echo -e "\nCollecting date is done.\n"
echo -e "The log have been saved to the following path:'/IBM_System_Check/Result'\n"
