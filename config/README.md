# 配置说明

本目录仅保留 **lede-master** 一套配置，供 X86_64 云编译使用。

仓库：https://github.com/jianhuashao6/OpenWrt

## 文件

| 文件 | 作用 |
|------|------|
| [`lede-master/config`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/config) | 传给 `make defconfig` 的 `.config`（目标、软件包） |
| [`lede-master/diy-part1.sh`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/diy-part1.sh) | feeds `update/install` **之前**执行（可选加 feed、删包） |
| [`lede-master/diy-part2.sh`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/diy-part2.sh) | feeds 安装 **之后**执行（默认 IP、主题、版本标识等） |

## 常用修改

1. **增减软件包**  
   编辑 [`lede-master/config`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/config)，或本地 `make menuconfig` 后把生成的 `.config` 覆盖回去。

2. **默认 IP**  
   已在 [`diy-part2.sh`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/diy-part2.sh) 中设为 `192.168.100.222`。若要改成其它地址，搜索并替换该脚本中的 IP 即可。

3. **额外 feed / 第三方包**  
   在 [`diy-part1.sh`](https://github.com/jianhuashao6/OpenWrt/blob/main/config/lede-master/diy-part1.sh) 中按注释示例取消注释或自行添加（注意与 lede 分支兼容性）。

## 旁路由提示

当前 `.config` 已包含 OpenClash、dnsmasq-full、kmod-tun 等。若同时启用 PassWall 与 OpenClash，体积更大且可能冲突，建议日常只开其中一个。

更完整的使用步骤见根目录 [README.md](https://github.com/jianhuashao6/OpenWrt/blob/main/README.md)。
