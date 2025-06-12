#!/bin/bash
# 设置静态IP
# 技术支持 QQ 1717329947 https://www.yuque.com/lwmacct
# /opt/set-static-ip.sh p4p1    192.168.2.254 192.168.2.2 24 11
# /opt/set-static-ip.sh p4p1.99 192.168.2.254 192.168.2.2 24 12
# /opt/set-static-ip.sh <nic.vlan> <gateway> <ip addres> <mask> <metric>

__init_args() {

    if [ $# -gt 3 ]; then
        _wk=$1
        _wg=$2
        _ip=$3
        _prefix=$4
    fi

    if [ $# -gt 4 ]; then
        _metric=$5
    fi

    if [[ "${SKIP_IP_CHECK}" != "1" ]]; then
        _ip_hz=$(echo "$_ip" | awk -F '.' '{print $NF}')
        if [[ "${_ip_hz}" == "1" || "${_ip_hz}" == "254" ]]; then
            echo "ip 最后一位不允许为 1, 或者 254, 这些ip 通常是网关地址"
            echo "为避免网络故障设置已中断, 如要跳过检查, SKIP_IP_CHECK=1"
            exit 0
        fi
    fi

    _eth=/etc/sysconfig/network-scripts/ifcfg-${_wk}

    _nic=$(echo "$_wk" | awk -F '.' '{print $1}')
    _vlan=$(echo "$_wk" | awk -F '.' '{print $2}')
    _parent_mac=$(cat /sys/class/net/"$_nic"/address 2>/dev/null)
    _macaddr=$(echo "$_parent_mac-$_nic.$_vlan" | md5sum | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/66:\1:\2:\3:\4:\5/')

    if [[ "${_parent_mac}" == "" ]]; then
        echo "网卡 $_nic 不存在,请检查参数"
        exit 0
    fi

    if [[ "${_vlan}" != "" ]]; then
        __write_nic_vlan
    else
        __write_nic_physical
    fi

}

__write_nic_physical() {
    {
        echo 'TYPE="Ethernet"' >"$_eth"
        echo 'BOOTPROTO="static"'
        echo 'DEFROUTE="yes"'
        echo 'IPV4_FAILURE_FATAL="0"'
        if [ "$_metric" ]; then echo 'IPV4_ROUTE_METRIC='"$_metric"; fi
        echo 'NAME='"$_wk"
        echo 'DEVICE='"$_wk"
        echo 'ONBOOT="yes"'
        echo 'IPADDR='"$_ip"
        echo 'GATEWAY='"$_wg"
        echo 'PREFIX='"$_prefix"
        echo 'DNS1="223.5.5.5"'
        echo 'DNS2="119.29.29.29"'
    } >"$_eth"

}

__write_nic_vlan() {
    {
        echo 'TYPE="vlan"'
        echo 'BOOTPROTO="static"'
        echo 'DEFROUTE="yes"'
        echo 'IPV4_FAILURE_FATAL="0"'
        if [ "$_metric" ]; then echo 'IPV4_ROUTE_METRIC='"$_metric"; fi
        echo 'NAME='"$_wk"
        echo 'DEVICE='"$_wk"
        echo 'ONBOOT="yes"'
        echo 'VLAN="yes"'
        echo 'VLAN_ID='"$_vlan"
        echo 'IPADDR='"$_ip"
        echo 'GATEWAY='"$_wg"
        echo 'PREFIX='"$_prefix"
        echo 'DNS1="223.5.5.5"'
        echo 'DNS2="119.29.29.29"'
        echo 'MACADDR='"$_macaddr"
    } >"$_eth"

}

__init_args "$@"
/etc/init.d/network restart

echo -e '_wk\t'"$_wk"
echo -e '_wg\t'"$_wg"
echo -e '_ip\t'"$_ip"

ping -c2 -W1 baidu.com
