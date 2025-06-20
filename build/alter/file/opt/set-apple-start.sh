#!/usr/bin/env bash

# shellcheck disable=SC1091

# 检查设备唯一 ID 是否存在
{
    _file_guid="/data/local/device_guid"
    mkdir -p "$(dirname $_file_guid)"
    if [ ! -f "$_file_guid" ]; then
        _item_guid_1="$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 12)"
        _item_guid_2="$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 12)"
        _item_guid_3="$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 12)"
        _item_guid_4="$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 12)"
        _timestamp="$(date +%s)"

        echo -n "$_item_guid_1-$_item_guid_2-$_item_guid_3-$_item_guid_4-$_timestamp" | md5sum | awk '{print $1}' | xargs -I@ echo -n 'wdy-@' >"$_file_guid"

        echo "create guid is: $(awk 'NF' "$_file_guid")"
    fi
}

# 设置命令别名
{
    echo 'alias ss="bash /opt/scripts/print-menu.sh"' >>/root/.bashrc
    source /root/.bashrc
}

# 配置 tty1
{
    _file_tty1="/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    mkdir -p "$(dirname $_file_tty1)"
    cat >"$_file_tty1" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF
    systemctl daemon-reexec
    systemctl enable getty@tty1.service
    systemctl restart getty@tty1.service

    # 注意不是 .bashrc，因为 .bash_profile 是 login shell 专用
    echo 'bash /opt/scripts/menu.sh' >/root/.bash_profile
}
