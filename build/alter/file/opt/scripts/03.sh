#!/usr/bin/env bash

# shellcheck disable=SC2162

# 3. 系统-重启

__main() {
  echo "系统将在 3 秒后重启,如需停止请按下 Ctrl+C"
  sleep 3
  reboot
}
__main
