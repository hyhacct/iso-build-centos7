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
