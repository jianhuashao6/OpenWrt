#!/bin/bash
# OpenWrt/LEDE build hook: run before feeds update.
set -eu

log() { printf '[diy-part1] %s\n' "$*"; }
die() { printf '[diy-part1] ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "include/toplevel.mk" ] || die "请在 OpenWrt 源码根目录执行此脚本。"

# ---------------------------------------------------------------------------
# 1. 拉取 Argon（唯一主题）
# ---------------------------------------------------------------------------
ARGON_DIR="package/luci-theme-argon"
if [ ! -d "$ARGON_DIR/.git" ]; then
  rm -rf "$ARGON_DIR"
  log "正在克隆 luci-theme-argon ..."
  git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git "$ARGON_DIR" \
    || die "克隆 luci-theme-argon 失败"
  log "luci-theme-argon 已添加"
else
  log "luci-theme-argon 已存在，跳过克隆"
fi

ARGON_CONFIG_DIR="package/luci-app-argon-config"
if [ ! -d "$ARGON_CONFIG_DIR/.git" ]; then
  rm -rf "$ARGON_CONFIG_DIR"
  log "正在克隆 luci-app-argon-config ..."
  if git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git "$ARGON_CONFIG_DIR"; then
    log "luci-app-argon-config 已添加"
  else
    rm -rf "$ARGON_CONFIG_DIR"
    log "luci-app-argon-config 不可用，跳过（可忽略）"
  fi
fi

# ---------------------------------------------------------------------------
# 2. 清理 package 内其它主题（feeds 此时尚未更新）
# ---------------------------------------------------------------------------
for t in \
  luci-theme-bootstrap \
  luci-theme-design \
  luci-theme-material \
  luci-theme-openwrt \
  luci-theme-openwrt-2020 \
  luci-theme-netgear \
  luci-theme-pink \
  luci-theme-purple
do
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    rm -rf "$d"
    log "已删除: $d"
  done < <(find package -type d -name "$t" 2>/dev/null || true)
done

log "构建前自定义步骤完成（仅保留 Argon）。"
