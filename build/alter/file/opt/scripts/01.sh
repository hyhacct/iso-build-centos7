#!/usr/bin/env bash

# shellcheck disable=SC2162

# 1. 网络-自动获取(DHCP)

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

__main() {
  _nics=$(ip -br a | awk '{print $1,$2}' | grep -vE '^mv|docker|@|lo')

  IFS=$'\n'
  _i=0
  for item in ${_nics}; do
    ((_i++))
    _item_name=$(echo "$item" | awk '{print $1}')
    _item_status=$(echo "$item" | awk '{print $NF}')

    _item_speed=$(awk 'NF' "/sys/class/net/$_item_name/speed")
    _item_driver=$(ethtool -i "$_item_name" | grep '^driver' | awk '{print $NF}')

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

  # 循环取用户输入
  while true; do
    read -p "网卡序号(1-${#_cfg[@]}): " _index

    if [ -z "$_index" ]; then
      log_error "请输入正确的网卡序号"
      continue
    fi

    _item_name=${_cfg[$_index]}

    if [ -z "$_item_name" ]; then
      log_error "网卡信息不存在..."
      break
    fi

    log_info "开始为网卡[$_item_name]进行 dhcp"
    nmcli connection modify "$_item_name" ipv4.method auto
    nmcli connection modify "$_item_name" connection.autoconnect yes
    systemctl restart NetworkManager
    ip r
    break
  done
}
__main
