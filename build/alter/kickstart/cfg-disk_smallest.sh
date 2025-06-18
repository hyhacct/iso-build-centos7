#!/usr/bin/env bash

#shellcheck disable=SC2010

__main() {
    # 取得容量最小的磁盘
    _disk_smallest=$(grep "sd[a-z]$" /proc/partitions | awk '{print $3,$4}' | sort -k1n | head -n1 | awk '{print $NF}')

    # 创建分区配置文件
    cat >/tmp/cfg-disk <<EOF
# 限制安装程序只使用指定的磁盘
ignoredisk --only-use=$_disk_smallest

# 安装引导加载程序到 MBR
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=$_disk_smallest

# 安装时自动清空MBR
zerombr

# 清空所有分区
clearpart --all --initlabel

# 磁盘分区信息
part /boot/efi --fstype="efi" --ondisk=$_disk_smallest --label=SYS_EFI --size=64 --fsoptions="umask=0077,shortname=winnt"
part /     --fstype="xfs" --ondisk=$_disk_smallest --label=SYS_ROOT --size=51200 --grow
part /boot --fstype="xfs" --ondisk=$_disk_smallest --label=SYS_BOOT --size=512
part /disk --fstype="xfs" --ondisk=$_disk_smallest --label=SYS_DISK --size=512
EOF

}

__main
