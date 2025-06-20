#!/usr/bin/env bash

# shellcheck disable=SC2162

# 4. 系统-关机

__main() {
  echo "系统将在 3 秒后关机,如需停止请按下 Ctrl+C"
  sleep 3
  poweroff
}
__main
