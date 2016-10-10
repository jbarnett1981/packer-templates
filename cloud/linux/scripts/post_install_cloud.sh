### Tableau post config

# Register with RHN and enable repos if Red Hat detected system
swtype=$(awk '{print $1 " " $2}' /etc/redhat-release)
if [[ $swtype == "Red Hat" ]]; then
sudo /usr/sbin/subscription-manager register --username=devit-tableau --password=P@ssw0rd! --auto-attach --force
fi

# Configure timezone
sudo timedatectl set-timezone America/Los_Angeles

# Install firewalld but disable and stop it
sudo yum install -y firewalld
sudo systemctl disable firewalld
sudo systemctl stop firewalld

# Create DevIT dir
# sudo mkdir -p /usr/local/devit
# sudo chmod 775 /usr/local/devit
# sudo chown it:root /usr/local/devit

# Tell NetworkManager to STEP OFF of resolv.conf, we got dis
sudo runuser -l root -c 'echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf'

# Configure resolv.conf
sudo runuser -l root -c 'cat > /etc/resolv.conf <<EOF
search tsi.lan dev.tsi.lan
nameserver 10.26.160.31
nameserver 10.26.160.32
EOF'
sudo chmod 644 /etc/resolv.conf

# Install git
sudo yum -y install git

# # Install git repo for devit
# cd /tmp
# /usr/bin/git clone https://devit-admin:1xKAWF6mm6@gitlab.tableausoftware.com/devit/linux.git
# rm linux/imaging/packer*
# sudo mv linux/imaging/* /usr/local/devit
# sudo chmod +x /usr/local/devit/*
# sudo chown it:root /usr/local/devit/*
# sudo rm -rf linux

# Install required tools
sudo yum -y install net-tools openssh-server nfs-utils samba-client samba-common cifs-utils wget perl zip redhat-lsb-core bind-utils tree

# Disable requiretty in sudoers
sudo runuser -l root -c 'echo "Defaults:devlocal !requiretty" >> /etc/sudoers'

# Add Tableau DevIT sudoers file
sudo runuser -l root -c 'cat > /etc/sudoers.d/tableau-devit <<EOF
# Tableau DevIT Managed
# Allow zabbix user to restart puppet agent
zabbix ALL=NOPASSWD: /etc/init.d/puppet restart

# Allow following accounts full admin with no password prompt
builder  ALL=(ALL)  NOPASSWD: ALL

# Allow following groups full admin with password prompt
%devit  ALL=(ALL)   NOPASSWD: ALL
%development    ALL=(ALL)       ALL
EOF'
sudo chmod 644 /etc/sudoers.d/tableau-devit

# Install EPEL repo
swver=$(lsb_release -r | awk '{print $2}')
if [[ $swver == 6.* ]]; then
    sudo wget -O /tmp/epel.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
else
    sudo wget -O /tmp/epel.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
fi
sudo yum -y install /tmp/epel.rpm

sudo yum -y install htop screen yum-utils mlocate gcc

# Add devit dir to system path
# sudo runuser -l root -c 'echo "PATH=$PATH:/usr/local/devit" >> /etc/profile'
# sudo runuser -l root -c 'echo "export PATH" >> /etc/profile'

sudo yum -y install ntp
sudo systemctl start ntpd
sudo systemctl enable ntpd

### Yum setup and update'
sudo runuser -l root -c 'echo "metadata_expire=1800" >> /etc/yum.conf'
sudo runuser -l root -c 'echo "installonlypkgs=kernel kernel*" >> /etc/yum.conf'
#rpm --import /etc/pki/rpm-gpg/*

### base build is complete ###

#######################################################
### Tableau Custom Configurations ###

### Configure Sendmail to use our relays
sudo yum -y install sendmail
sudo sed -i 's/^DS$/DSsmarthost.tsi.lan/' /etc/mail/sendmail.cf

### Configure etc/snmpd
sudo yum -y install net-snmp
sudo cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
sudo runuser -l root -c 'cat > /etc/snmp/snmpd.conf <<EOF
com2sec local     localhost       public
com2sec mynetwork 10.0.0.0/8      public
group MyRWGroup v1         local
group MyRWGroup v2c        local
group MyRWGroup usm        local
group MyROGroup v1         mynetwork
group MyROGroup v2c        mynetwork
group MyROGroup usm        mynetwork
view all    included  .1                               80
access MyROGroup ""      any       noauth    exact  all    none   none
access MyRWGroup ""      any       noauth    exact  all    none   none
syslocation Tableau DevIT, Internap
syscontact DevIT_Infrastructure <devit-inf@tableausoftware.com>
proc sshd
disk / 15%
load 8 8 8
EOF'

### Configure sysconfig/snmpd
sudo runuser -l root -c 'echo "OPTIONS=\"-LS0-5d -Lf /dev/null -p /var/run/snmpd.pid -a\"" >> /etc/sysconfig/snmpd'

### Disable core dumps by default
sudo runuser -l root -c 'echo "* soft core 0" >> /etc/security/limits.conf'
sudo runuser -l root -c 'echo "* hard core 0" >> /etc/security/limits.conf'

### Disable Ctl-alt-del reboot
sudo systemctl mask ctrl-alt-del.target

### Modify kernel parameters
### remove dumb progress bar at boot
### enable fifo disk writes
sudo grubby --update-kernel=ALL --remove-args="rhgb"
sudo grubby --update-kernel=ALL --args="elevator=noop"


### Add login banner
sudo runuser -l root -c 'cat > /etc/issue <<EOF
*** WARNING ***

THIS IS A PRIVATE COMPUTER SYSTEM. It is for authorized use only.
Users (authorized or unauthorized) have no explicit or implicit
expectation of privacy. THERE IS NO RIGHT OF PRIVACY IN THIS SYSTEM.
System personnel may disclose any potential evidence of crime found
on computer systems for any reason.  USE OF THIS SYSTEM BY ANY USER,
AUTHORIZED OR UNAUTHORIZED, CONSTITUTES CONSENT TO THIS MONITORING,
INTERCEPTION, RECORDING, READING, COPYING, or CAPTURING and DISCLOSURE.

EOF'
sudo cp -f /etc/issue /etc/issue.net

### Protect root directory
sudo chmod -R go-rwx /root

### Configure auth.* syslog channel
sudo runuser -l root -c 'echo "auth.* /var/log/secure" >> /etc/syslog.conf'

# Turn on reverse path filtering.
sudo runuser -l root -c 'echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf'
# Don't allow outsiders to alter the routing tables.
sudo runuser -l root -c 'echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf'
sudo runuser -l root -c 'echo "net.ipv4.conf.all.secure_redirects = 0" >> /etc/sysctl.conf'
# Don't reply to broadcasts.  Prevents joining a smurf attack.
sudo runuser -l root -c 'echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf'
# Bump up TCP socket queue to help with syn floods.
sudo runuser -l root -c 'echo "net.ipv4.tcp_max_syn_backlog = 4096" >> /etc/sysctl.conf'

### Configure auditd
sudo runuser -l root -c 'cp /etc/audit/auditd.conf /etc/audit/auditd.conf.orig'
sudo runuser -l root -c 'cat > /etc/audit/auditd.conf <<EOF
# This file controls the configuration of the audit daemon
log_file = /var/log/audit/audit.log
log_format = RAW
log_group = root
priority_boost = 4
flush = INCREMENTAL
freq = 20
num_logs = 5
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = NONE
max_log_file = 10
max_log_file_action = ROTATE
space_left = 150
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 80
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
tcp_listen_queue = 5
tcp_max_per_addr = 1
tcp_client_max_idle = 0
enable_krb5 = no
krb5_principal = auditd
EOF'
sudo runuser -l root -c 'cp /etc/audit/audit.rules /etc/audit/audit.rules.orig'
sudo runuser -l root -c 'cat > /etc/audit/audit.rules <<EOF
# This file contains the auditctl rules that are loaded
# whenever the audit daemon is started via the initscripts.
# The rules are simply the parameters that would be passed
# to auditctl.
# First rule - delete all
-D
# Increase the buffers to survive stress events.
# Make this bigger for busy systems
-b 8192
## Set failure mode to syslog.notice
-f 1
# Things that could affect time
-a exit,always -F arch=b64 -S adjtimex -S settimeofday -k time-change
-w /etc/localtime -p wa -k time-change
# Things that affect identity
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
# Things that could affect system locale
-a exit,always -F arch=b64 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
# Things that could affect MAC policy
-w /etc/selinux/ -p wa -k MAC-policy
# Discretinary access control permission modification (unsuccessful and successful use of chown/chomd)
-a exit,always -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a exit,always -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a exit,always -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>500 -F auid!=4294967295 -k perm_mod
# Unauthorized access attempts to files (only unsuccessful)
-a exit,always -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a exit,always -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access
# Files deleted by the user (successful and unsuccessful)
-a exit,always -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete
# Watch actions to sudoers
-w /etc/sudoers -p wa -k priv_actions
## Make rule changed immutable - reboot is required to change audit rules
-e 2
EOF'

### Configure cron usage
sudo runuser -l root -c 'echo "root" > /etc/cron.allow'
sudo runuser -l root -c 'echo "ALL" > /etc/cron.deny'
sudo chmod 644 /etc/cron.allow /etc/cron.deny
sudo chmod 0400 /etc/crontab

#### Configure sshd
sudo runuser -l root -c 'cat >> /etc/ssh/sshd_config <<EOF
PermitRootLogin yes
UsePrivilegeSeparation yes
ClientAliveInterval 300
Banner /etc/issue
EOF'

### Configure Manufacturer variable
hwtype=$(dmesg | grep "DMI:" | awk '{print $4}')

#### Install Latest Dell OMSA if host is type "Dell"
if [ "$hwtype" = "Dell" ]; then

sudo wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash
sudo yum -y install syscfg srvadmin-all
fi

#### Install VMware Tools if host is type "VMware"

if [[ $hwtype = *"VMware"* ]]; then
# Vmware Virtual Machine
sudo yum -y install open-vm-tools
fi

#### Install Corp Root CA
curl -o /tmp/cert.crt http://pki.tableaucorp.com/aia/1NDCITVWPKI11.tsi.lan_CorpIT%20Issuing%20CA.crt
openssl x509 -inform der -in /tmp/cert.crt -out /tmp/tableau_corp_root_ca.pem
sudo cp /tmp/tableau_corp_root_ca.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Update system to current
sudo yum update -y

# Update GRUB2 config
sudo runuser -l root -c 'echo "GRUB_TERMINAL=serial" >> /etc/default/grub'
sudo runuser -l root -c 'echo "GRUB_SERIAL_COMMAND=serial --speed=57600 --unit=0 --word=8 --parity=no --stop=1" >> /etc/default/grub'
### System cleanup

# Remove external repos, as we're managing this internally
# rm -f /etc/yum.repos.d/CentOS-*
#sudo rm -f /root/anaconda-ks.cfg
sudo rm -rf /tmp/*

# Remove Red Hat Network bits from CentOS...
if [[ $swtype == *"CentOS"* ]]; then
sudo yum -y remove rhnsd
fi

sudo yum clean all
sudo rm -f /var/log/wtmp /var/log/btmp
history -c

### Manifest - collect info about how the server was built

echo > ~/build.manifest
echo "Created on a platform of: `(uname -m)` ." >> ~/build.manifest
cat /etc/redhat-release >> ~/build.manifest
date >> ~/build.manifest
uname -a >> ~/build.manifest
echo -e "\n-----\nPackage listing:\n\n" >> ~/build.manifest
rpm -qa --qf "%{n}-%{v}-%{r}.%{arch}\n" | sort >> ~/build.manifest

# Delete yourself
sudo rm -f $0