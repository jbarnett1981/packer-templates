cat > /usr/local/share/EXPAND_ROOT <<EOF
disk="sda"
startsector=\$(fdisk -u -l /dev/\$disk | grep \${disk}2 | awk '{print \$2}')
parted /dev/\$disk --script rm 2
parted /dev/\$disk --script "mkpart primary ext4 \${startsector}s -1s"
parted /dev/\$disk --script set 2 lvm on
pvresize /dev/\${disk}2
lvextend --extents +100%FREE /dev/mapper/vg00-lv_root --resizefs
EOF
chmod +x /usr/local/share/EXPAND_ROOT