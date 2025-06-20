#!/usr/bin/env bash

# shellcheck disable=SC2162

# 主菜单函数
__show_menu() {
  clear
  echo "=========================================="
  echo "          系统管理控制台"
  echo "=========================================="
  echo ""
  # 文件是否存在
  if [[ -f /data/local/device_guid ]]; then
    qrencode -t ansiutf8 "https://wdycdn.com/api/v1/apple/register?guid=$(awk 'NF' /data/local/device_guid)"
  else
    echo "未生成设备GUID,请尝试重启系统或联系运维解决..."
  fi
  echo ""
  echo "请选择操作："
  echo "1. 网络-自动获取(DHCP)"
  echo "2. 网络-手动配置"
  echo "3. 系统-重启"
  echo "4. 系统-关机"
  echo "5. 系统-刷新终端"
  echo "6. 系统-进入终端"
  echo ""
}

# 处理用户选择
__choice() {
  read -p "请输入选项 (1-5): " _choice

  if [[ -z "$_choice" ]]; then
    echo "请输入选项"
    return
  fi

  case $_choice in
  1)
    bash /opt/scripts/01.sh
    ;;
  2)
    bash /opt/scripts/02.sh
    ;;
  3)
    bash /opt/scripts/03.sh
    ;;
  4)
    bash /opt/scripts/04.sh
    ;;
  5)
    __show_menu # 重新显示菜单
    ;;
  6)
    exit 0 # 退出代码为 0
    ;;
  *)
    echo "无效选项，请重新选择"
    sleep 2
    ;;
  esac
}

# 主循环
__main() {
  __show_menu # 菜单首次只显示一次
  while true; do
    __choice
  done
}
__main
