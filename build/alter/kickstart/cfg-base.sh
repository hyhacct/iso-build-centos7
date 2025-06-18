#!/usr/bin/env bash

__cfg_base() {

    cat >/tmp/cfg-base <<'EOF'

#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
# network  --bootproto=dhcp --device=eth0 --onboot=off --ipv6=auto --no-activate
# network  --hostname=localhost.localdomain
network --hostname=WdyCDN

# Root password
rootpw --iscrypted $6$Sy53RrlGakCmu2uw$NFNQU3KIsFroMNyExEqmhVtugrxpH5T2WLdu3XMNHN8IfmynLGpz0lBQQWW8g/z/6qvlmgFxnrE0OhDtLWi7f0

# System services
services --disabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc --nontp

selinux --disabled  # 关闭selinux
firewall --disabled # 关闭防火墙
reboot

%packages
@^minimal
@core
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

EOF
}

__cfg_base
