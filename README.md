# 云编译 OpenWrt（仅 X86 / lede）

**本仓库：** https://github.com/jianhuashao6/OpenWrt

在 [xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt) 思路上，对齐 [cs-star/OpenWrt](https://github.com/cs-star/OpenWrt) 精简方案，并保留自用优化。

## 当前支持

| 项目 | 说明 |
|------|------|
| 源码 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) `master`（每次重新拉取） |
| 架构 | **X86_64** |
| 默认 IP | `192.168.100.253` |
| 主题 | **仅 Argon**（jerrykuku 源码编入） |
| 时区 | Asia/Shanghai |
| 定时 | 每周一 UTC 02:00 |

## 使用方法

1. **Settings → Actions → General → Workflow permissions → Read and write → Save**
2. （可选）改 `config/lede-master/`
3. **Actions → X86设备编译固件 (lede-master) → Run workflow**（选 `main`）
4. 成功后从 Artifact / **Releases** 下载
5. 访问：`http://192.168.100.253`（`root`，密码空）

视频参考：https://www.youtube.com/watch?v=6j4ofS0GT38

## 稳定性处理

上游部分 Go 包会编挂，本仓库构建时会剔除：

- `v2ray-plugin`
- `geoview`

**OpenClash 不受影响。** PassWall 仍可用 Xray / SingBox 等。

## 致谢

[xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt) · [cs-star/OpenWrt](https://github.com/cs-star/OpenWrt) · [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) · [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
