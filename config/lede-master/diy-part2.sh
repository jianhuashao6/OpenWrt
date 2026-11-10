#!/bin/bash
# OpenWrt/LEDE build hook: run after feeds update/install.
set -eu

log() { printf '[diy-part2] %s\n' "$*"; }
die() { printf '[diy-part2] ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "include/toplevel.mk" ] || die "请在 OpenWrt 源码根目录执行此脚本。"

# ---------------------------------------------------------------------------
# Drop broken/optional packages (helloworld v2ray-plugin Go module break)
# ---------------------------------------------------------------------------
if [ -d feeds/helloworld/v2ray-plugin ]; then
  rm -rf feeds/helloworld/v2ray-plugin
  log "已移除 feeds/helloworld/v2ray-plugin。"
fi
rm -rf package/feeds/helloworld/v2ray-plugin 2>/dev/null || true

# ---------------------------------------------------------------------------
# Argon: 必须从 jerrykuku 拉取源码（lede 未必自带可用 Argon）
# 其它主题目录删除，避免被编进固件；默认主题统一改为 argon
# ---------------------------------------------------------------------------
log "配置唯一默认主题：luci-theme-argon…"

# 去掉源码树里可能冲突/过时的 Argon 与其它主题
rm -rf package/lean/luci-theme-argon \
  feeds/luci/themes/luci-theme-argon \
  package/feeds/luci/luci-theme-argon 2>/dev/null || true

for th in bootstrap material openwrt openwrt-2020 design netgear neobird infinityfreedom argon-mod; do
  rm -rf "feeds/luci/themes/luci-theme-${th}" \
    "package/feeds/luci/luci-theme-${th}" \
    "package/lean/luci-theme-${th}" 2>/dev/null || true
done

# 拉取官方维护的 Argon（master 适配较新 LuCI / 当前 lede）
rm -rf package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
log "已克隆 jerrykuku/luci-theme-argon → package/luci-theme-argon"

# 可选：主题配置插件（体积小，方便改壁纸等）
if [ ! -d package/luci-app-argon-config ]; then
  git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config 2>/dev/null \
    && log "已克隆 luci-app-argon-config" \
    || log "luci-app-argon-config 克隆失败（可忽略）。"
fi

# LuCI 集合默认依赖：bootstrap/design → argon
if [ -d feeds/luci/collections ]; then
  while IFS= read -r -d '' mk; do
    sed -i \
      -e 's/luci-theme-bootstrap/luci-theme-argon/g' \
      -e 's/luci-theme-design/luci-theme-argon/g' \
      -e 's/luci-theme-material/luci-theme-argon/g' \
      -e 's/luci-theme-openwrt-2020/luci-theme-argon/g' \
      -e 's/luci-theme-openwrt/luci-theme-argon/g' \
      "$mk"
  done < <(find feeds/luci/collections -type f -name Makefile -print0 2>/dev/null)
  log "已将 feeds/luci/collections 默认主题依赖改为 luci-theme-argon。"
fi

# 首次启动强制 mediaurlbase=argon（防止仍指向其它主题）
settings_file="package/lean/default-settings/files/zzz-default-settings"
if [ -f "$settings_file" ]; then
  if ! grep -q "luci.main.mediaurlbase='/luci-static/argon'" "$settings_file"; then
    # 插在 exit 0 之前；若无 exit 0 则追加
    if grep -q '^exit 0' "$settings_file"; then
      sed -i "/exit 0/i\uci set luci.main.mediaurlbase='/luci-static/argon'\nuci commit luci" "$settings_file"
    else
      printf "\nuci set luci.main.mediaurlbase='/luci-static/argon'\nuci commit luci\n" >> "$settings_file"
    fi
    log "已在 default-settings 中写入 Argon 为默认主题。"
  fi
fi

# .config：只保留 Argon，关掉其它主题包
if [ -f .config ]; then
  sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' .config || true
  sed -i 's/^CONFIG_PACKAGE_v2ray-plugin=y/# CONFIG_PACKAGE_v2ray-plugin is not set/' .config || true
  sed -i 's/^CONFIG_PACKAGE_v2ray-plugin-git=y/# CONFIG_PACKAGE_v2ray-plugin-git is not set/' .config || true
  sed -i 's/^CONFIG_DEFAULT_luci-app-ssr-plus=y/# CONFIG_DEFAULT_luci-app-ssr-plus is not set/' .config || true

  # 启用 Argon（及配置插件，若存在）
  sed -i 's/^# CONFIG_PACKAGE_luci-theme-argon is not set/CONFIG_PACKAGE_luci-theme-argon=y/' .config || true
  if ! grep -q '^CONFIG_PACKAGE_luci-theme-argon=y' .config; then
    echo 'CONFIG_PACKAGE_luci-theme-argon=y' >> .config
  fi
  if [ -d package/luci-app-argon-config ]; then
    sed -i 's/^# CONFIG_PACKAGE_luci-app-argon-config is not set/CONFIG_PACKAGE_luci-app-argon-config=y/' .config || true
    if ! grep -q '^CONFIG_PACKAGE_luci-app-argon-config=y' .config; then
      echo 'CONFIG_PACKAGE_luci-app-argon-config=y' >> .config
    fi
  fi

  # 明确关闭其它主题
  for th in bootstrap material openwrt openwrt-2020 design netgear neobird infinityfreedom; do
    sed -i "s/^CONFIG_PACKAGE_luci-theme-${th}=y/# CONFIG_PACKAGE_luci-theme-${th} is not set/" .config || true
    if ! grep -q "CONFIG_PACKAGE_luci-theme-${th}" .config; then
      echo "# CONFIG_PACKAGE_luci-theme-${th} is not set" >> .config
    fi
  done
  log "已调整 .config：仅启用 luci-theme-argon。"
fi

# Do not force KERNEL_PATCHVER; follow upstream lede branch.

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

log "构建后自定义步骤完成。"
