#!/usr/bin/env bash

# shellcheck disable=SC2162,SC2155

# 2. 网络-手动配置

set -euo pipefail

declare -A _cfg

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# 验证IP地址格式
validate_ip() {
  local ip=$1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    IFS='.' read -ra ip_parts <<<"$ip"
    for part in "${ip_parts[@]}"; do
      if [[ $part -lt 0 || $part -gt 255 ]]; then
        return 1
      fi
    done
    return 0
  fi
  return 1
}

# 验证子网掩码
validate_mask() {
  local mask=$1
  if [[ $mask =~ ^[0-9]+$ ]] && [[ $mask -ge 1 && $mask -le 32 ]]; then
    return 0
  fi
  return 1
}

# 验证VLAN ID
validate_vlan() {
  local vlan=$1
  if [[ $vlan =~ ^[0-9]+$ ]] && [[ $vlan -ge 1 && $vlan -le 4094 ]]; then
    return 0
  fi
  return 1
}

# 测试网络连接
test_network() {
  local ip=$1
  local gateway=$2

  log_info "正在测试网络连接..."

  # 测试网关连通性
  if ping -c 3 -W 2 "$gateway" >/dev/null 2>&1; then
    log_success "网关 $gateway 可达"
  else
    log_warning "网关 $gateway 不可达"
  fi

  # 测试DNS解析
  if nslookup baidu.com >/dev/null 2>&1; then
    log_success "DNS解析正常"
  else
    log_warning "DNS解析失败"
  fi

  # 测试外网连接
  if ping -c 3 -W 2 8.8.8.8 >/dev/null 2>&1; then
    log_success "外网连接正常"
  else
    log_warning "外网连接失败"
  fi
}

# 备份现有配置
backup_config() {
  local nic_name=$1
  local config_file="/etc/sysconfig/network-scripts/ifcfg-$nic_name"

  if [[ -f "$config_file" ]]; then
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$config_file" "$backup_file"
    log_info "已备份原配置到: $backup_file"
  fi
}

# 显示网卡信息
show_nic_info() {
  log_info "检测到的网卡信息:"
  echo "=================================="

  _nics=$(ip -br a | awk '{print $1,$2}' | grep -vE '^mv|docker|@|lo')

  IFS=$'\n'
  _i=0
  for item in ${_nics}; do
    ((_i++))
    _item_name=$(echo "$item" | awk '{print $1}')
    _item_status=$(echo "$item" | awk '{print $NF}')

    # 获取网卡速度（可能不存在）
    _item_speed="N/A"
    if [[ -f "/sys/class/net/$_item_name/speed" ]]; then
      _item_speed=$(awk 'NF' "/sys/class/net/$_item_name/speed")
    fi

    # 获取驱动信息
    _item_driver="N/A"
    if command -v ethtool >/dev/null 2>&1; then
      _item_driver=$(ethtool -i "$_item_name" 2>/dev/null | grep '^driver' | awk '{print $NF}' || echo "N/A")
    fi

    # 获取MAC地址
    _item_mac=$(ip link show "$_item_name" | grep -o -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)

    if [[ "$_item_status" == "UP" ]]; then
      _status_color="$GREEN"
    elif [[ "$_item_status" == "DOWN" ]]; then
      _status_color="$RED"
    else
      _status_color="$NC"
    fi

    _cfg[$_i]="$_item_name"

    echo -e "$_i. [$CYAN$_item_name$NC] \t [$_status_color$_item_status$NC] \t [Speed: $_item_speed Mbps] \t [Driver: $_item_driver]"
  done

  if [[ ${#_cfg[@]} -eq 0 ]]; then
    log_error "未检测到可用网卡"
    return 1
  fi
}

# 选择网卡
select_nic() {
  while true; do
    read -p "请选择网卡序号(1-${#_cfg[@]}): " _index

    if [[ -z "$_index" ]]; then
      log_error "请输入正确的网卡序号"
      continue
    fi

    if ! [[ "$_index" =~ ^[0-9]+$ ]]; then
      log_error "请输入数字"
      continue
    fi

    if [[ $_index -gt ${#_cfg[@]} ]]; then
      log_error "网卡序号超出范围"
      continue
    fi

    if [[ $_index -lt 1 ]]; then
      log_error "网卡序号不能小于1"
      continue
    fi

    _item_name=${_cfg[$_index]}

    if [[ -z "$_item_name" ]]; then
      log_error "网卡信息不存在，请重新选择"
      continue
    fi

    log_success "已选择网卡: $_item_name"
    break
  done
}

# 配置VLAN
configure_vlan() {
  local use_vlan=""
  while true; do
    read -p "是否配置VLAN? (y/n): " use_vlan
    case $use_vlan in
    [Yy]*)
      while true; do
        read -p "请输入VLAN ID (1-4094): " _vlan
        if validate_vlan "$_vlan"; then
          break
        else
          log_error "VLAN ID无效，请输入1-4094之间的数字"
        fi
      done
      break
      ;;
    [Nn]*)
      _vlan=""
      break
      ;;
    *)
      log_error "请输入 y 或 n"
      ;;
    esac
  done
}

# 获取IP配置
get_ip_config() {
  # 获取IP地址和掩码
  while true; do
    read -p "请输入IP地址/掩码 (例如: 192.168.1.100/24): " _ip_mask
    if [[ -z "$_ip_mask" ]]; then
      log_error "请输入正确的IP地址/掩码"
      continue
    fi

    _ip=$(echo "$_ip_mask" | awk -F '/' '{print $1}')
    _mask=$(echo "$_ip_mask" | awk -F '/' '{print $2}')

    if ! validate_ip "$_ip"; then
      log_error "IP地址格式无效"
      continue
    fi

    if ! validate_mask "$_mask"; then
      log_error "子网掩码无效，请输入1-32之间的数字"
      continue
    fi

    break
  done

  # 获取网关
  while true; do
    read -p "请输入网关地址: " _gateway
    if [[ -z "$_gateway" ]]; then
      log_error "请输入正确的网关地址"
      continue
    fi

    if ! validate_ip "$_gateway"; then
      log_error "网关地址格式无效"
      continue
    fi

    break
  done
}

# 写入配置文件
write_config() {
  local nic_name=$1
  local config_file="/etc/sysconfig/network-scripts/ifcfg-$nic_name"

  # 备份现有配置
  backup_config "$nic_name"

  log_info "正在写入配置文件: $config_file"

  if [[ -n "$_vlan" ]]; then
    # VLAN配置
    cat >"$config_file" <<EOF
VLAN=yes
TYPE=Vlan
PHYSDEV=$nic_name
VLAN_ID=$_vlan
REORDER_HDR=yes
GVRP=no
MVRP=no
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=$_ip
PREFIX=$_mask
GATEWAY=$_gateway
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=${nic_name}.$_vlan
DEVICE=${nic_name}.$_vlan
ONBOOT=yes
DNS1=223.5.5.5
DNS2=114.114.114.115
DNS3=119.29.29.29
EOF
  else
    # 普通网卡配置
    cat >"$config_file" <<EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=$_ip
PREFIX=$_mask
GATEWAY=$_gateway
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=$nic_name
DEVICE=$nic_name
ONBOOT=yes
DNS1=223.5.5.5
DNS2=114.114.114.115
DNS3=119.29.29.29
EOF
  fi

  log_success "配置文件已写入"
}

# 重启网络服务
restart_network() {
  local restart_choice=""
  while true; do
    read -p "是否立即重启网络服务? (y/n): " restart_choice
    case $restart_choice in
    [Yy]*)
      log_info "正在重启网络服务..."
      if systemctl restart network >/dev/null 2>&1; then
        log_success "网络服务重启成功"
        sleep 3
        test_network "$_ip" "$_gateway"
      else
        log_error "网络服务重启失败"
      fi
      break
      ;;
    [Nn]*)
      log_info "请手动重启网络服务: systemctl restart network"
      break
      ;;
    *)
      log_error "请输入 y 或 n"
      ;;
    esac
  done
}

__main() {
  log_info "开始配置网络..."

  # 检查权限
  if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要root权限运行"
    exit 1
  fi

  # 显示网卡信息
  if ! show_nic_info; then
    exit 1
  fi

  # 选择网卡
  select_nic

  # 配置VLAN
  configure_vlan

  # 获取IP配置
  get_ip_config

  # 显示配置摘要
  echo
  log_info "配置摘要:"
  echo "=================================="
  echo "网卡: $_item_name"
  if [[ -n "$_vlan" ]]; then
    echo "VLAN ID: $_vlan"
    echo "设备名: ${_item_name}.$_vlan"
  fi
  echo "IP地址: $_ip"
  echo "子网掩码: /$_mask"
  echo "网关: $_gateway"
  echo "=================================="

  # 确认配置
  local confirm=""
  while true; do
    read -p "确认以上配置? (y/n): " confirm
    case $confirm in
    [Yy]*) break ;;
    [Nn]*)
      log_info "配置已取消"
      exit 0
      ;;
    *) log_error "请输入 y 或 n" ;;
    esac
  done

  # 写入配置
  write_config "$_item_name"

  # 重启网络服务
  restart_network

  log_success "网络配置完成！"
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

__main
