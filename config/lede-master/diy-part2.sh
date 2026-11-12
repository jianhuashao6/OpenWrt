#!/bin/bash
# OpenWrt/LEDE build hook: run after feeds update/install.
set -eu

log() { printf '[diy-part2] %s\n' "$*"; }
die() { printf '[diy-part2] ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "include/toplevel.mk" ] || die "请在 OpenWrt 源码根目录执行此脚本。"

settings_file="package/lean/default-settings/files/zzz-default-settings"
cfg_gen="package/base-files/files/bin/config_generate"
DEFAULT_IP="192.168.100.253"

# ---------------------------------------------------------------------------
# 0. 剔除上游易坏 Go 包（会导致整次编译失败）
# ---------------------------------------------------------------------------
rm -rf \
  feeds/helloworld/v2ray-plugin package/feeds/helloworld/v2ray-plugin \
  feeds/packages/net/geoview package/feeds/packages/geoview \
  2>/dev/null || true
log "已移除易坏包：v2ray-plugin、geoview（若存在）"

# ---------------------------------------------------------------------------
# 1. 默认主题依赖全部指向 Argon（再删其它主题）
# ---------------------------------------------------------------------------
if [ -d "feeds/luci/collections" ]; then
  while IFS= read -r mf; do
    [ -f "$mf" ] || continue
    if grep -qE 'luci-theme-(bootstrap|design|material)' "$mf"; then
      sed -i \
        -e 's/luci-theme-bootstrap/luci-theme-argon/g' \
        -e 's/luci-theme-design/luci-theme-argon/g' \
        -e 's/luci-theme-material/luci-theme-argon/g' \
        "$mf"
      log "主题依赖已统一为 Argon: $mf"
    fi
  done < <(find feeds/luci/collections -type f -name 'Makefile' 2>/dev/null || true)
fi

if [ -f "include/target.mk" ]; then
  sed -i \
    -e 's/luci-theme-bootstrap/luci-theme-argon/g' \
    -e 's/luci-theme-design/luci-theme-argon/g' \
    include/target.mk 2>/dev/null || true
  log "include/target.mk 默认主题已指向 Argon"
fi

if [ -f "$settings_file" ]; then
  sed -i \
    -e 's/luci-theme-bootstrap/luci-theme-argon/g' \
    -e 's/luci-theme-design/luci-theme-argon/g' \
    -e 's|/luci-static/bootstrap|/luci-static/argon|g' \
    -e 's|/luci-static/design|/luci-static/argon|g' \
    "$settings_file" 2>/dev/null || true
  if ! grep -q "luci.main.mediaurlbase" "$settings_file"; then
    printf "\nuci set luci.main.mediaurlbase='/luci-static/argon'\nuci commit luci\n" >> "$settings_file"
  fi
  log "default-settings 默认主题已指向 Argon"
fi

# ---------------------------------------------------------------------------
# 2. .config：只启用 Argon；关闭易坏包与其它主题
# ---------------------------------------------------------------------------
if [ -f .config ]; then
  if grep -q 'CONFIG_PACKAGE_luci-theme-argon' .config; then
    sed -i 's/.*CONFIG_PACKAGE_luci-theme-argon.*/CONFIG_PACKAGE_luci-theme-argon=y/' .config
  else
    echo 'CONFIG_PACKAGE_luci-theme-argon=y' >> .config
  fi

  if [ -d "package/luci-app-argon-config" ] || [ -d "feeds/luci/applications/luci-app-argon-config" ]; then
    if grep -q 'CONFIG_PACKAGE_luci-app-argon-config' .config; then
      sed -i 's/.*CONFIG_PACKAGE_luci-app-argon-config.*/CONFIG_PACKAGE_luci-app-argon-config=y/' .config
    else
      echo 'CONFIG_PACKAGE_luci-app-argon-config=y' >> .config
    fi
  fi

  for t in bootstrap design material openwrt openwrt-2020 netgear pink purple; do
    if grep -q "CONFIG_PACKAGE_luci-theme-${t}" .config; then
      sed -i "s/^CONFIG_PACKAGE_luci-theme-${t}=[ym]/# CONFIG_PACKAGE_luci-theme-${t} is not set/" .config
    else
      echo "# CONFIG_PACKAGE_luci-theme-${t} is not set" >> .config
    fi
  done

  sed -i \
    -e 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' \
    -e 's/^CONFIG_PACKAGE_v2ray-plugin=y/# CONFIG_PACKAGE_v2ray-plugin is not set/' \
    -e 's/^CONFIG_PACKAGE_geoview=y/# CONFIG_PACKAGE_geoview is not set/' \
    -e 's/^CONFIG_DEFAULT_luci-app-ssr-plus=y/# CONFIG_DEFAULT_luci-app-ssr-plus is not set/' \
    .config || true

  for pkg in v2ray-plugin geoview; do
    grep -q "CONFIG_PACKAGE_${pkg}" .config \
      || echo "# CONFIG_PACKAGE_${pkg} is not set" >> .config
  done

  log ".config 已设置为仅启用 luci-theme-argon，并关闭易坏包"
fi

# ---------------------------------------------------------------------------
# 3. 删除其它主题目录（feeds 更新后）
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
    case "$d" in
      *luci-theme-argon*) continue ;;
    esac
    rm -rf "$d"
    log "已删除主题: $d"
  done < <(find package feeds -type d -name "$t" 2>/dev/null || true)
done

# ---------------------------------------------------------------------------
# 4. 固件版本日期
# ---------------------------------------------------------------------------
build_date="$(date +%Y.%m.%d)"
if [ -f "$settings_file" ] && grep -q '@BUILD_DATE@' "$settings_file"; then
  sed -i "s/@BUILD_DATE@/${build_date}/g" "$settings_file"
  log "已设置固件构建日期：${build_date}"
fi

# ---------------------------------------------------------------------------
# 5. 源码标识
# ---------------------------------------------------------------------------
release_file="package/base-files/files/etc/openwrt_release"
if [ -f "$release_file" ]; then
  if grep -q '^DISTRIB_SOURCECODE=' "$release_file"; then
    sed -i "s|^DISTRIB_SOURCECODE=.*|DISTRIB_SOURCECODE='lede'|" "$release_file"
  else
    printf "DISTRIB_SOURCECODE='lede'\n" >> "$release_file"
  fi
  log "已设置固件源码标识：lede"
fi

# ---------------------------------------------------------------------------
# 6. 默认 LAN IP
# ---------------------------------------------------------------------------
if [ -f "$cfg_gen" ]; then
  sed -i "s/192\.168\.[0-9]\+\.[0-9]\+/${DEFAULT_IP}/g" "$cfg_gen" || \
    sed -i "s/192\.168\.[0-9]\+\.1/${DEFAULT_IP}/g" "$cfg_gen"
  log "config_generate 默认 IP → ${DEFAULT_IP}"
fi
if [ -f "$settings_file" ]; then
  sed -i "s/192\.168\.[0-9]\+\.[0-9]\+/${DEFAULT_IP}/g" "$settings_file" 2>/dev/null || true
  log "default-settings IP → ${DEFAULT_IP}"
fi

# ---------------------------------------------------------------------------
# 7. 默认时区 Asia/Shanghai
# ---------------------------------------------------------------------------
if [ -f "$cfg_gen" ]; then
  sed -i "s/timezone='UTC'/timezone='CST-8'/g" "$cfg_gen" || true
  sed -i "s/zonename='UTC'/zonename='Asia\/Shanghai'/g" "$cfg_gen" || true
  log "默认时区 → Asia/Shanghai (CST-8)"
fi
if [ -f "$settings_file" ]; then
  sed -i "s/timezone='UTC'/timezone='CST-8'/g" "$settings_file" 2>/dev/null || true
  sed -i "s/zonename='UTC'/zonename='Asia\/Shanghai'/g" "$settings_file" 2>/dev/null || true
fi

log "构建后自定义步骤完成（仅 Argon）。"
