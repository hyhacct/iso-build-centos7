#!/bin/bash
# 设置静态IP
# 技术支持 QQ 1717329947 https://www.yuque.com/lwmacct
# /opt/set-br-admin-lan.sh p4p1    <ipmotool auto-complete>
# /opt/set-br-admin-lan.sh p4p1.99 192.168.2.254 192.168.2.2 24
# /opt/set-br-admin-lan.sh <interface> <ipmotool auto-complete>
# /opt/set-br-admin-lan.sh <interface> <gateway> <ip addres> <mask>

__init_args() {

    # if [ $# -gt 3 ]; then echo 0; fi

    _wk=$1
    _wg=$2
    _ip=$3
    _prefix=$4

    if [[ "${_ip}" == "" ]]; then
        _ipmi=$(ipmitool lan print)
        _ip=$(echo "$_ipmi" | grep 'IP Address' | grep '[0-9\.]{6,15}$' -Eo | cut -d. -f1-3 | awk '{print $1".3"}')
        _wg=$(echo "$_ipmi" | grep 'Default Gateway IP' | grep '[0-9\.]{6,15}$' -Eo)
        _mask=$(echo "$_ipmi" | grep 'Subnet Mask' | grep '[0-9\.]{6,15}$' -Eo)

    fi

    _eth=/etc/sysconfig/network-scripts/ifcfg-${_wk}
    _bridge="br-admin-lan"

    if [[ "${SKIP_IP_CHECK}" != "1" ]]; then
        _ip_hz=$(echo "$_ip" | awk -F '.' '{print $NF}')
        if [[ "${_ip_hz}" == "1" || "${_ip_hz}" == "254" ]]; then
            echo "ip 最后一位不允许为 1, 或者 254, 这些ip 通常是网关地址"
            echo "为避免网络故障设置已中断, 如要跳过检查, SKIP_IP_CHECK=1"
            exit 0
        fi
    fi

    _nic=$(echo "$_wk" | awk -F '.' '{print $1}')
    _vlan=$(echo "$_wk" | awk -F '.' '{print $2}')
    _parent_mac=$(cat /sys/class/net/"$_nic"/address 2>/dev/null)
    _macaddr=$(echo "$_parent_mac-$_nic.$_vlan" | md5sum | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/66:\1:\2:\3:\4:\5/')

    if [[ "${_parent_mac}" == "" ]]; then
        echo "网卡 $_nic 不存在,请检查参数"
        exit 0
    fi

    if [ "$_prefix" ]; then
        _subnet_mask="PREFIX=$_prefix"
    else
        _subnet_mask="NETMASK=$_mask"
    fi

    cat >/etc/sysconfig/network-scripts/ifcfg-$_bridge <<-AEOF
DEVICE=$_bridge
ONBOOT="yes"
TYPE="Bridge"
STP="off"
DELAY="0"

# 网桥上配置 IP
DEFROUTE="yes"
BOOTPROTO="static"
GATEWAY=$_wg
IPADDR=$_ip
$_subnet_mask
DNS1=223.5.5.5
DNS2=119.29.29.29
AEOF

    if [[ "${_vlan}" == "" ]]; then
        cat >"$_eth" <<-AEOF
ONBOOT="yes"
DEVICE=$_wk
BRIDGE=$_bridge
AEOF
    else
        cat >"$_eth" <<-AEOF
ONBOOT="yes"
DEVICE=$_wk
BRIDGE=$_bridge
VLAN="yes"
VLAN_ID=$_vlan
AEOF

    fi

}

__init_args "$@"
/etc/init.d/network restart

echo -e '_wk\t'"$_wk"
echo -e '_wg\t'"$_wg"
echo -e '_ip\t'"$_ip"

ping -c2 -W1 baidu.com
