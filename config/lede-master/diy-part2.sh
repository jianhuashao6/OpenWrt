#!/bin/bash
# OpenWrt/LEDE build hook: run after feeds update/install.
set -eu

log() { printf '[diy-part2] %s\n' "$*"; }
die() { printf '[diy-part2] ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "include/toplevel.mk" ] || die "请在 OpenWrt 源码根目录执行此脚本。"

# Use Argon only when the current LuCI collection still references Bootstrap.
# The supplied .config already selects luci-theme-argon.
luci_collection="feeds/luci/collections/luci/Makefile"
if [ -f "$luci_collection" ] && grep -q 'luci-theme-bootstrap' "$luci_collection"; then
  sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$luci_collection"
  log "默认 LuCI 主题依赖已切换为 luci-theme-argon。"
else
  log "主题依赖无需修改，或当前 feeds 中不存在 LuCI collection 文件。"
fi

# Do not force KERNEL_PATCHVER here. The source branch controls its supported
# kernel versions; keep .config aligned with that branch and let make defconfig
# resolve dependencies. This avoids the old hard-coded 6.12 override.

# LEDE's first-boot settings script writes the final revision into
# /etc/openwrt_release using the @BUILD_DATE@ placeholder.
settings_file="package/lean/default-settings/files/zzz-default-settings"
build_date="$(date +%Y.%m.%d)"
if [ -f "$settings_file" ]; then
  if grep -q '@BUILD_DATE@' "$settings_file"; then
    sed -i "s/@BUILD_DATE@/$build_date/g" "$settings_file"
    log "已设置固件构建日期：$build_date"
  else
    log "未发现 @BUILD_DATE@ 占位符，跳过版本日期替换。"
  fi
else
  log "未找到 $settings_file，跳过版本日期替换。"
fi

release_file="package/base-files/files/etc/openwrt_release"
if [ -f "$release_file" ]; then
  if grep -q '^DISTRIB_SOURCECODE=' "$release_file"; then
    sed -i "s|^DISTRIB_SOURCECODE=.*|DISTRIB_SOURCECODE='lede'|" "$release_file"
  else
    printf "DISTRIB_SOURCECODE='lede'\n" >> "$release_file"
  fi
  log "已设置固件源码标识：lede。"
else
  log "未找到 $release_file，跳过源码标识设置。"
fi

# Default LAN IP → 192.168.100.253
cfg_gen="package/base-files/files/bin/config_generate"
if [ -f "$cfg_gen" ]; then
  sed -i 's/192.168.1.1/192.168.100.253/g' "$cfg_gen"
  log "默认 IP 已改为 192.168.100.253"
else
  log "未找到 $cfg_gen，跳过 IP 修改。"
fi
if [ -f "$settings_file" ]; then
  sed -i 's/192.168.1.1/192.168.100.253/g' "$settings_file" || true
fi

# Optional third-party packages and patches should be added only after
# checking that their Makefiles and dependencies exist in the selected feeds.
# Example:
# svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic package/luci-app-amlogic
# git apply ../config/patches/0001-example.patch

log "构建后自定义步骤完成。"
