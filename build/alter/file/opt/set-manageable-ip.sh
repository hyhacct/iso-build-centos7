#!/usr/bin/env bash

__set() {
    #清理
    find /etc/sysconfig/network-scripts/* -name '*.99*' -type f -delete
    for item in $_nic; do
        ip link set "$item" up && printf "%s set up\n" "$item"
        sleep 3s
        if ip -br a show dev "$item" | grep "UP" &>/dev/null && ethtool "$item" | grep 'Speed: 10000Mb/s' &>/dev/null; then
            sleep 3s
            /opt/set-br-admin-lan.sh "$item".99 "$_gw" "$_ip" 16 11
            break
        fi
    done
}

__main() {

    _ip=$(ipmitool lan print 2>/dev/null | awk -F ': ' '/IP Address +:/{gsub(/.1$/,".3",$2);print $2}')
    _gw=$(ipmitool lan print 2>/dev/null | awk -F ': ' '/Default Gateway IP +:/{print $2}')
    #检测判断
    {

        if [ -z "$_ip" ] || [ -z "$_gw" ]; then
            printf "ipmitool error aborting\n"
            return
        fi

        if ip -br a | grep "$_ip" &>/dev/null; then
            printf "manageable ip already exist\n"
            return
        fi

    }
    # 设置ip
    {
        _nic=$(find /sys/class/net/* -not -lname '*virtual*' -printf '%f\n')
        __set
    }

}
__main
