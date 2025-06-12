#!/usr/bin/env bash
#shellcheck disable=SC2010

__cfg_part() {
    # 取系统第一块磁盘
    _disk=$(grep </proc/partitions '8        0 ' | awk '{print $NF}')

    # 取得容量最小的磁盘
    # _disk=$(grep </proc/partitions'sd.$' | awk '{print $3 " " $4}' | sort -n | awk '{print $2}' | head -1)

    if [ ! -L "/dev/disk/by-label/SYS_DATA" ]; then
        cat >/tmp/cfg-disk <<EOF
ignoredisk --only-use=$_disk
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=$_disk
zerombr #安装时自动清空MBR
clearpart --all --initlabel
# 磁盘分区信息
part /boot/efi --fstype="efi" --ondisk=$_disk --label=SYS_EFI --size=64 --fsoptions="umask=0077,shortname=winnt"
part /     --fstype="xfs" --ondisk=$_disk --label=SYS_ROOT --size=51200  # grow把剩余容量都给这个分区
part /boot --fstype="xfs" --ondisk=$_disk --label=SYS_BOOT --size=512
part /disk --fstype="xfs" --ondisk=$_disk --label=SYS_DISK --size=512
part /pcdn_data/pcdn_index_data --fstype="xfs" --ondisk=$_disk --label=SYS_DATA --grow
EOF
    else
        _clearpart_list=$(ls -al /dev/disk/by-label | grep 'SYS_EFI|SYS_BOOT|SYS_ROOT|SYS_DISK' -E | awk -F '/' '{print $NF}' | paste -sd ',')
        cat >/tmp/cfg-disk <<EOF
ignoredisk --only-use=$_disk
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=$_disk
zerombr #安装时自动清空MBR
# clearpart --initlabel --list=$_clearpart_list
clearpart --initlabel --none
# 磁盘分区信息
part /boot/efi --fstype="efi" --onpart=/dev/disk/by-label/SYS_EFI --label=SYS_EFI
part /     --fstype="xfs" --onpart=/dev/disk/by-label/SYS_ROOT --label=SYS_ROOT
part /boot --fstype="xfs" --onpart=/dev/disk/by-label/SYS_BOOT --label=SYS_BOOT
part /disk --fstype="xfs" --onpart=/dev/disk/by-label/SYS_DISK --label=SYS_DISK
part /pcdn_data/pcdn_index_data --fstype="xfs" --onpart=/dev/disk/by-label/SYS_DATA --noformat
EOF
    fi

}

__cfg_part
