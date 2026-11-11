# 云编译 OpenWrt（仅 X86 / lede）

**本仓库：** https://github.com/jianhuashao6/OpenWrt

基于 [xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt) 精简：只编译 **lede + X86_64**，适合旁路由/软路由自用。

## 当前配置

| 项目 | 说明 |
|------|------|
| 源码 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) `master`（每次重新拉取） |
| 架构 | X86_64 |
| 默认 IP | `192.168.100.253` |
| 默认主题 | **Argon**（从 [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) 拉取源码编入） |
| 定时编译 | 每周日 09:00 UTC |

## 使用方法

1. **Settings → Actions → General → Workflow permissions → Read and write → Save**
2. （可选）改 `config/lede-master/config` 或 `diy-part*.sh`
3. **Actions → X86设备编译固件 (lede-master) → Run workflow**（选 `main`）
4. 成功后从 Artifact 或 **Releases** 下载
5. 刷机访问：`http://192.168.100.253`

视频参考（原版多设备教程）：https://www.youtube.com/watch?v=6j4ofS0GT38

## 构建策略摘要

- 每次 `git clone` 最新 lede，不锁死内核版本
- **禁用** 上游易坏的 `v2ray-plugin`（PassWall 仍可用 Xray/SingBox；OpenClash 不受影响）
- **Argon**：diy-part2 强制克隆 jerrykuku 源码，collections 默认依赖改为 argon，并写入 `mediaurlbase`
- 其它主题在 `.config` 中关闭；`bootstrap` 源码保留（避免依赖解析失败），但不编进固件
- ccache + dl 缓存；失败上传日志

## 旁路由

OpenClash 建议开启旁路由兼容、清空 WAN 接口名、更新 Meta 内核。  
OpenClash 与 PassWall 建议只启用其一。

## 目录

```
.github/workflows/build-x86.yml
config/lede-master/{config,diy-part1.sh,diy-part2.sh}
```

## 致谢

[xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt) · [jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon) · [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
