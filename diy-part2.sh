#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================
sed -i '/DTS_DIR:=$(LINUX_DIR)/a\BUILD_DATE_PREFIX := $(shell date +'%F')' ./include/image.mk
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(BUILD_DATE_PREFIX)-/g' ./include/image.mk


#!/bin/bash
ZZZ="package/lean/default-settings/files/zzz-default-settings"
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#

sed -i "/uci commit fstab/a\uci commit network" $ZZZ
sed -i "/uci commit network/i\uci set network.lan.ipaddr='192.168.100.222'" $ZZZ          # IPv4 地址(openwrt后台地址)
sed -i "/uci commit network/i\uci set network.lan.netmask='255.255.255.0'" $ZZZ           # IPv4 子网掩码
sed -i "/uci commit network/i\uci set network.lan.gateway='192.168.100.254'" $ZZZ         # IPv4 网关
sed -i "/uci commit network/i\uci set network.lan.broadcast='192.168.100.255'" $ZZZ       # IPv4 广播
sed -i "/uci commit network/i\uci set network.lan.dns='223.5.5.5 114.114.114.114'" $ZZZ   # DNS(多个DNS要用空格分开)
sed -i "/uci commit network/i\uci set network.lan.delegate='0'" $ZZZ                      # 去掉LAN口使用内置的 IPv6 管理

sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile   # 强制选择argon为默认主题选项
sed -i "/uci commit luci/i\uci set luci.main.mediaurlbase=/luci-static/argon" $ZZZ        # 选择argon为默认主题

sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt'" $ZZZ           # 修改主机名称

sed -i "s/OpenWrt /Star $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" $ZZZ                   # 增加自己个性名称281677160

sed -i '/CYXluq4wUazHjmCDBCqXF/d' $ZZZ                                                    # 设置密码为空

#sed -i 's/PATCHVER:=5.4/PATCHVER:=4.19/g' target/linux/x86/Makefile                      # 修改内核版本为4.19

#sed -i 's/192.168.1.1/192.168.100.222/g' package/base-files/files/bin/config_generate
#sed -i '/uci commit system/i\uci set system.@system[0].hostname='OpenWrt'' package/lean/default-settings/files/zzz-default-settings
#sed -i "s/OpenWrt /Star $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' package/lean/default-settings/files/zzz-default-settings

sed -i '60s/ITdesk01/firkerword/' ./package/jd_openwrt_script/files/jd_openwrt_script

rm -rf ./package/lean/luci-theme-argon

rm -rf ./feeds/packages/net/https-dns-proxy
rm -rf ./feeds/diy/luci-app-vssr-plus
rm -rf ./feeds/diy/vssr

svn co https://github.com/Lienol/openwrt-packages/trunk/net/https-dns-proxy feeds/packages/net/https-dns-proxy
find package/*/ feeds/*/ -maxdepth 2 -path "*luci-app-bypass/Makefile" | xargs -i sed -i 's/shadowsocksr-libev-ssr-redir/shadowsocksr-libev-alt/g' {}
find package/*/ feeds/*/ -maxdepth 2 -path "*luci-app-bypass/Makefile" | xargs -i sed -i 's/shadowsocksr-libev-ssr-server/shadowsocksr-libev-server/g' {}

