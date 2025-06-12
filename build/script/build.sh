#!/usr/bin/env bash

# shellcheck disable=SC2164

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取当前时间戳
get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# 格式化日志消息
format_message() {
  local level=$1
  local color=$2
  local symbol=$3
  local message=$4
  printf "${color}[%s] %s %s: %s${NC}\n" "$(get_timestamp)" "$level" "$symbol" "$message"
}

# 日志级别函数
log_info() {
  format_message "INFO" "$BLUE" "$1"
}
log_success() {
  format_message "SUCCESS" "$GREEN" "$1"
}
log_warning() {
  format_message "WARNING" "$YELLOW" "$1"
}
log_error() {
  format_message "ERROR" "$RED" "$1"
}

# 初始化目录环境
{
  _path_home="/apps/data"
}

# 清理上次构建的缓存
{
  log_warning "开始清理 Yum 缓存..."
  yum clean all
  yum clean all --disablerepo="*" --enablerepo="alter-cdrom"
  yum-complete-transaction --cleanup-only

  log_warning "开始清理缓存文件..."
  rm -rf "$_path_home/build/alter/file.tar.gz"
  rm -rf "/mnt/alter/"
  rm -rf "$_path_home/isofs"
  rm -rf "$_path_home/product"
  rm -rf "$_path_home/repo.tar.gz"

  log_warning "开始清理其他资源..."
  rpm --rebuilddb
  mkdir -p /mnt/alter/repo

  # 重新补充环境
  mkdir -p "$_path_home" || true && cd "$_path_home"
  mkdir -p "$_path_home/product"
}

# 提取镜像内容
{
  _path_iso="$(find "$_path_home/iso" -type f | grep -v 'centos7-images.iso$' | head -n1)"

  if [ -z "$_path_iso" ]; then
    log_error "未发现镜像文件,请下载原版镜像后放置到 /apps/data/iso 下"
    exit 1
  fi

  log_info "已读取到镜像文件: $_path_iso"
  sleep 3 # 稍微延迟一下,如果镜像错了能有反应时间结束脚本
  log_info "正在提取镜像内容..."

  $_path_home/poweriso-x64 extract "$_path_iso" / -od "$_path_home/isofs"
  if [ ! -d "$_path_home/isofs/isolinux" ]; then
    log_error "镜像内容提取失败,无法找到isolinux"
    exit 1
  fi

  log_success "镜像内容提取成功"
}

# 准备工作
{
  log_info "正在打包文件..."
  tar zcpvf "$_path_home/build/alter/file.tar.gz" "$_path_home/build/alter/file/"

  log_info "正在准备 ISO 文件目录..."
  rm -rf "$_path_home/isofs/alter" || true && mkdir -p "$_path_home/isofs/alter"

  log_info "正在复制文件..."
  cp -a $_path_home/build/alter/{kickstart,repo,file.tar.gz} "$_path_home/isofs/alter/"

  log_info "正在替换 isolinux.cfg..."
  cat "$_path_home/build/alter/kickstart/isolinux.cfg" >"$_path_home/isofs/isolinux/isolinux.cfg"

  log_success "准备工作完成,即将开始打包"
}

# 工作完成,开始打包
{
  mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak \
    -o "$_path_home/product/build_centos7.iso" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v \
    -T "$_path_home/isofs"

  log_success "打包完成,镜像生成于: "$_path_home/product/build_centos7.iso""
}
