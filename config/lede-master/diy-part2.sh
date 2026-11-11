#!/bin/bash
# OpenWrt/LEDE build hook: run after feeds update/install.
set -eu

log() { printf '[diy-part2] %s\n' "$*"; }
die() { printf '[diy-part2] ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "include/toplevel.mk" ] || die "请在 OpenWrt 源码根目录执行此脚本。"

# ---------------------------------------------------------------------------
# 上游易坏 Go 包：直接删掉源码 + 在 .config 关闭
# - v2ray-plugin: helloworld Go module 不完整
# - geoview: packages/net/geoview Go module 不完整（PassWall 常拉入）
# ---------------------------------------------------------------------------
rm -rf \
  feeds/helloworld/v2ray-plugin package/feeds/helloworld/v2ray-plugin \
  feeds/packages/net/geoview package/feeds/packages/geoview \
  2>/dev/null || true
log "已移除易坏包：v2ray-plugin、geoview（若存在）。"

# ---------------------------------------------------------------------------
# Argon 唯一默认主题
# ---------------------------------------------------------------------------
log "配置默认主题：luci-theme-argon…"

rm -rf package/lean/luci-theme-argon \
  feeds/luci/themes/luci-theme-argon \
  package/feeds/luci/luci-theme-argon \
  package/luci-theme-argon 2>/dev/null || true

for th in material openwrt openwrt-2020 design netgear neobird infinityfreedom argon-mod; do
  rm -rf "feeds/luci/themes/luci-theme-${th}" \
    "package/feeds/luci/luci-theme-${th}" \
    "package/lean/luci-theme-${th}" 2>/dev/null || true
done

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon \
  || die "克隆 luci-theme-argon 失败，请检查网络或上游仓库。"
[ -f package/luci-theme-argon/Makefile ] || die "luci-theme-argon 缺少 Makefile。"
log "已克隆 jerrykuku/luci-theme-argon → package/luci-theme-argon"

rm -rf package/luci-app-argon-config 2>/dev/null || true
if git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config 2>/dev/null; then
  log "已克隆 luci-app-argon-config"
else
  log "luci-app-argon-config 不可用，跳过。"
fi

if [ -d feeds/luci/collections ]; then
  find feeds/luci/collections -type f -name Makefile 2>/dev/null | while read -r mk; do
    sed -i \
      -e 's/luci-theme-bootstrap/luci-theme-argon/g' \
      -e 's/luci-theme-design/luci-theme-argon/g' \
      -e 's/luci-theme-material/luci-theme-argon/g' \
      -e 's/luci-theme-openwrt-2020/luci-theme-argon/g' \
      -e 's/luci-theme-openwrt/luci-theme-argon/g' \
      "$mk"
  done
  log "已将 luci collections 默认主题改为 luci-theme-argon。"
fi

settings_file="package/lean/default-settings/files/zzz-default-settings"

if [ -f "$settings_file" ]; then
  if ! grep -q "mediaurlbase='/luci-static/argon'" "$settings_file"; then
    if grep -q '^exit 0' "$settings_file"; then
      sed -i "/exit 0/i\uci set luci.main.mediaurlbase='/luci-static/argon'\nuci commit luci" "$settings_file"
    else
      printf "\nuci set luci.main.mediaurlbase='/luci-static/argon'\nuci commit luci\n" >> "$settings_file"
    fi
    log "已写入 default-settings：默认主题 Argon。"
  fi
fi

if [ -f .config ]; then
  sed -i \
    -e 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' \
    -e 's/^CONFIG_PACKAGE_v2ray-plugin=y/# CONFIG_PACKAGE_v2ray-plugin is not set/' \
    -e 's/^CONFIG_PACKAGE_v2ray-plugin-git=y/# CONFIG_PACKAGE_v2ray-plugin-git is not set/' \
    -e 's/^CONFIG_PACKAGE_geoview=y/# CONFIG_PACKAGE_geoview is not set/' \
    -e 's/^CONFIG_DEFAULT_luci-app-ssr-plus=y/# CONFIG_DEFAULT_luci-app-ssr-plus is not set/' \
    .config || true

  # 若仍出现这些符号，再追加关闭
  for pkg in v2ray-plugin v2ray-plugin-git geoview; do
    grep -q "CONFIG_PACKAGE_${pkg}" .config \
      || echo "# CONFIG_PACKAGE_${pkg} is not set" >> .config
  done
  grep -q 'INCLUDE_V2ray_Plugin' .config \
    || echo '# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set' >> .config

  sed -i 's/^# CONFIG_PACKAGE_luci-theme-argon is not set/CONFIG_PACKAGE_luci-theme-argon=y/' .config || true
  grep -q '^CONFIG_PACKAGE_luci-theme-argon=y' .config || echo 'CONFIG_PACKAGE_luci-theme-argon=y' >> .config

  if [ -d package/luci-app-argon-config ] && [ -f package/luci-app-argon-config/Makefile ]; then
    sed -i 's/^# CONFIG_PACKAGE_luci-app-argon-config is not set/CONFIG_PACKAGE_luci-app-argon-config=y/' .config || true
    grep -q '^CONFIG_PACKAGE_luci-app-argon-config=y' .config || echo 'CONFIG_PACKAGE_luci-app-argon-config=y' >> .config
  fi

  for th in bootstrap material openwrt openwrt-2020 design netgear neobird infinityfreedom; do
    sed -i "s/^CONFIG_PACKAGE_luci-theme-${th}=y/# CONFIG_PACKAGE_luci-theme-${th} is not set/" .config || true
    grep -q "CONFIG_PACKAGE_luci-theme-${th}" .config \
      || echo "# CONFIG_PACKAGE_luci-theme-${th} is not set" >> .config
  done
  log "已调整 .config：Argon + 关闭易坏包。"
fi

build_date="$(date +%Y.%m.%d)"
if [ -f "$settings_file" ] && grep -q '@BUILD_DATE@' "$settings_file"; then
  sed -i "s/@BUILD_DATE@/$build_date/g" "$settings_file"
  log "构建日期：$build_date"
fi

release_file="package/base-files/files/etc/openwrt_release"
if [ -f "$release_file" ]; then
  if grep -q '^DISTRIB_SOURCECODE=' "$release_file"; then
    sed -i "s|^DISTRIB_SOURCECODE=.*|DISTRIB_SOURCECODE='lede'|" "$release_file"
  else
    printf "DISTRIB_SOURCECODE='lede'\n" >> "$release_file"
  fi
fi

cfg_gen="package/base-files/files/bin/config_generate"
if [ -f "$cfg_gen" ]; then
  sed -i 's/192.168.1.1/192.168.100.253/g' "$cfg_gen"
  log "默认 IP：192.168.100.253"
fi
if [ -f "$settings_file" ]; then
  sed -i 's/192.168.1.1/192.168.100.253/g' "$settings_file" || true
fi

log "构建后自定义步骤完成。"
