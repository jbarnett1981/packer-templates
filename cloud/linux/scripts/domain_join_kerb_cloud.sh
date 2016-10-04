#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

/usr/bin/yum -y install realmd sssd oddjob oddjob-mkhomedir adcli samba-common ntpdate ntp krb5-workstation sssd-tools redhat-lsb-core

/usr/sbin/authconfig --enablesssd --enablesssdauth --enablemkhomedir --update

NIC=$(ip route ls | grep default | awk '{print $5}')

cat > /etc/samba/smb.conf <<EOF
[global]

workgroup = TSI
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
realm = TSI.LAN
security = ads
EOF

cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = tsi.lan
config_file_version = 2
services = nss, pam

[domain/tsi.lan]
ad_domain = tsi.lan
krb5_realm = TSI.LAN
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/tsi/%u
auth_provider = ad
access_provider = ad
ad_site = TSI-NADataCenter
#ad_access_filter = FOREST:TSI.LAN:(memberOf=cn=DevIT Infrastructure,ou=DevIT_delegated,ou=User Groups,ou=High Sec Groups,ou=TSI Groups,dc=tsi,dc=lan)
ad_gpo_access_control = permissive
ad_gpo_map_remote_interactive = +sshd
dyndns_update = True
dyndns_iface = $NIC
dyndns_refresh_interval = 86400
dyndns_update_ptr = True
EOF

chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

cat > /etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = TSI.LAN
EOF

sed -i 's/.*KerberosAuthentication.*/KerberosAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/.*KerberosOrLocalPasswd.*/KerberosOrLocalPasswd yes/' /etc/ssh/sshd_config
sed -i 's/.*KerberosTicketCleanup.*/KerberosTicketCleanup yes/' /etc/ssh/sshd_config

sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPICleanupCredentials.*/GSSAPICleanupCredentials yes/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIStrictAcceptorCheck.*/GSSAPIStrictAcceptorCheck no/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIEnablek5users.*/GSSAPIEnablek5users yes/' /etc/ssh/sshd_config
sed -i 's/.*UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

if [[ ${HOSTNAME} != *"tsi.lan"* ]]; then
   hostnamectl set-hostname $HOSTNAME.tsi.lan
   HOSTNAME=$(hostname)
fi

SHORTNAME=$(echo $HOSTNAME | cut -d'.' -f1)
OSVER=$(lsb_release -r | awk '{print $2}')
OSNAME=$(lsb_release -i | awk '{print $3}')

sed -i "s/^127.0.0.1.*/127.0.0.1   $HOSTNAME $SHORTNAME localhost localhost.localdomain localhost4 localhost4.localdomain4/" /etc/hosts
sed -i "s/^::1.*/::1   $HOSTNAME $SHORTNAME localhost localhost.localdomain localhost6 localhost6.localdomain6/" /etc/hosts

printf "Enter TSI Username: " && read NAME
kinit $NAME@TSI.LAN
net ads -k join createcomputer="TSI_DevIT/Build" osName=$OSNAME osVer=$OSVER

systemctl enable sssd.service
systemctl enable sshd.service
systemctl enable oddjobd.service
systemctl restart sssd.service
systemctl restart sshd.service
systemctl restart oddjobd.service