#!/usr/bin/env bash

# 关闭防火墙和 SELinux
__set_system() {
    firewall-cmd --state
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    chkconfig NetworkManager off
    service NetworkManager stop
    setenforce 0
    sed -i 's,^SELINUX=.*$,SELINUX=disabled,' /etc/selinux/config
}

# 配置yum源
__repo_application_package() {
    cat >/etc/yum.repos.d/Local-alter.repo <<EOF
[cdrom-alter]
name=CentOS-CDROM - Media
baseurl=file://${_repo}
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
    cat >/etc/yum.repos.d/Local-iso.repo <<EOF
[cdrom-default]
name=CentOS-Local - Media
baseurl=file:///mnt
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
    yum makecache fast --disablerepo=* --enablerepo=cdrom-alter
    yum update -y --disablerepo=* --enablerepo=cdrom-alter

    echo "安装 qemu-kvm"
    yum install -y --disablerepo=* --enablerepo=cdrom-alter centos-release-qemu-ev libvirt-daemon-kvm qemu-kvm-ev virt-*

    echo "安装常用工具tool"
    yum install -y --disablerepo=* --enablerepo=cdrom-alter \
        bash-completion bash-completion-extras \
        docker-ce-19.03.9-3.el7.x86_64 docker-ce-cli-19.03.9-3.el7.x86_64 containerd.io container-selinux libcgroup fuse-overlayfs slirp4netns \
        nftables net-tools bind-utils bridge-utils nfs-utils telnet lrzsz ntp ntpdate wget \
        vim vim-enhanced git jq bc tree unzip zip dos2unix sysstat psmisc lsof sshpass expect xfsprogs-devel \
        vnstat htop perf dstat glances fio lshw ntp xfsprogs-devel \
        pciutils bzip2 dmraid dosfstools lsof lvm2 man-pages man-pages-overrides mdadm ipmitool \
        rng-tools rsync smartmontools systemtap-runtime tcpdump time traceroute xfsdump yum-langpacks yum-utils moreutils qrencode

    echo "安装tmux"
    yum install -y --disablerepo=* --enablerepo=cdrom-alter tmux

    echo "安装桌面"
    yum install -y --disablerepo=* --enablerepo=cdrom-alter \
        gnome-classic-session gnome-terminal nautilus-open-terminal control-center \
        xorg-x11-server-Xorg xorg-x11-drv-* firefox wqy-microhei-fonts

    echo "安装内核"
    yum install -y --disablerepo=* --enablerepo=cdrom-alter kernel-5.4.119-19.0006.tl2.x86_64
    cat >/etc/default/grub <<'EOF'
GRUB_DEFAULT="saved"
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DISABLE_SUBMENU=true
GRUB_DISABLE_RECOVERY="true"
GRUB_TIMEOUT="2"
GRUB_TERMINAL="console serial"
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rd.driver.pre=ixgbe ixgbe.allow_unsupported_sfp=1 intel_iommu=ats intel_iommu=unsafe_interrupts intel_iommu=on iommu=pt numa=off cpufreq_governor=performance transparent_hugepage=always ksm=off zswap.enabled=0 crashkernel=auto rhgb quiet"
GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0,115200"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
EOF
    grub2-set-default 0
    grub2-mkconfig -o /boot/grub2/grub.cfg
    grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

    # 开机免密码
    sed -i 's,^ExecStart=.*$,ExecStart=-/sbin/agetty --autologin root --noclear %I,' /usr/lib/systemd/system/serial-getty@.service
    sed -i 's,^ExecStart=.*$,ExecStart=-/sbin/agetty --autologin root --noclear %I,' /usr/lib/systemd/system/getty@.service
    systemctl enable serial-getty@ttyS0.service
}

# 配置ntp
__set_ntp() {
    sec=$(shuf -i 1-59 -n 1)
    hour=$(shuf -i 1-23 -n 1)
    cat <<EOF >/etc/cron.d/ntptask
$sec $hour * * * root /usr/sbin/ntpdate -u ntp.ubuntu.com cn.pool.ntp.org ntp.aliyun.com &>/dev/null;clock -w &>/dev/null
EOF
}

# 配置rc.local
__set_rc() {
    echo "bash /opt/set-apple-start.sh" >>/etc/rc.local # 开机启动apple
    # echo "bash /opt/set-kernel-parameter.sh" >>/etc/rc.local # 优化内核参数
    chmod +x /etc/rc.d/rc.local w
}

# 配置docker
__init_docker() {
    usermod -aG docker root
    mkdir -p /etc/docker
    systemctl daemon-reload
    systemctl enable docker
}

# 主函数
__main() {
    _repo="/mnt/alter/repo/"
    __set_system
    __repo_application_package
    __init_docker
    __set_ntp
    tar zxvpf /mnt/alter/file.tar.gz -C / --strip-components 1
    ln -sf /usr/local/bin/qemu-system-x86_64 /usr/libexec/qemu-kvm
    __set_rc
}
__main
