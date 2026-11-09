# 云编译 OpenWrt（仅 X86 / lede）

**本仓库：** https://github.com/jianhuashao6/OpenWrt

在 [xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt)（原作者云编译方案）基础上精简维护：只保留 **lede + X86_64**，去掉电视盒子、多源码分支与 Docker 相关内容，便于旁路由/软路由长期自用编译。

感谢原作者 **xinlingduyu** 提供的 Actions 云编译思路与仓库结构。

视频参考（原版通用教程，步骤略有不同）：[OpenWrt GitHub 在线编译教程](https://www.youtube.com/watch?v=6j4ofS0GT38)（实用技能 @shiyongjineng）

## 当前支持

| 项目 | 说明 |
|------|------|
| 源码 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) `master`（**每次编译重新拉取最新**） |
| 架构 | **X86_64** 通用设备 |
| 默认 IP | `192.168.100.253` |
| 默认主题 | Argon |
| 工作流 | 仅 `X86设备编译固件 (lede-master)` |
| 自动编译 | **每周日** 自动跑一次（见下） |

## 自动拉取最新源码

- **每次**手动或定时触发编译时，工作流都会重新 `git clone` [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 的 `master`（`--depth=1`），因此固件始终基于当时最新源码与 feeds。
- **定时：** 每周日 **09:00 UTC**（约北京时间 17:00 / 日本 18:00）自动编译一次。
- Release 说明中会写入当次 lede 的短 commit，便于对照版本。
- 若要改频率：编辑 `.github/workflows/build-x86.yml` 里的 `schedule.cron`。
- 若要暂停自动编译：在该文件中注释或删除 `schedule` 段即可。

> 说明：仓库里的 `config/` 不会自动改写；变的是上游 lede 源码。你本地的插件/配置仍以本仓库 `config/lede-master/` 为准。

## 使用方法

### 1. 打开仓库

https://github.com/jianhuashao6/OpenWrt

### 2. 设置 Actions 权限（必做）

1. 进入仓库 **Settings**
2. 左侧 **Actions** → **General**
3. 滚到 **Workflow permissions**
4. 选择 **Read and write permissions**
5. 点击 **Save**

> 本仓库使用内置 `GITHUB_TOKEN`，一般**不需要**再创建 `GH_TOKEN` Secret。

### 3. 修改配置（可选）

| 文件 | 用途 |
|------|------|
| [`config/lede-master/config`](config/lede-master/config) | 目标架构与软件包（`.config`） |
| [`config/lede-master/diy-part1.sh`](config/lede-master/diy-part1.sh) | feeds 更新**前**钩子 |
| [`config/lede-master/diy-part2.sh`](config/lede-master/diy-part2.sh) | feeds 更新**后**钩子（默认 IP、主题、剔除坏包等） |

默认 LAN IP：`192.168.100.253`。

### 4. 开始编译

**手动：** Actions → **X86设备编译固件 (lede-master)** → **Run workflow** → 选 `main`。

**自动：** 每周日定时任务会自行启动。

### 5. 等待与下载

- 通常数小时
- 成功后：Actions Artifact（约 7 天）或 **Releases**
- 失败时：查看 `openwrt-build-log-*` Artifact

### 6. 刷机后访问

`http://192.168.100.253`

## 构建稳定性说明（2026-11 更新）

上游 `helloworld` 中的 **v2ray-plugin** 曾因 Go 模块不完整导致整包编译失败（定时任务 run #3）。

本仓库在 `diy-part2.sh` 中已：

- 删除 `feeds/helloworld/v2ray-plugin`
- 关闭 PassWall 的 `INCLUDE_V2ray_Plugin`
- 取消默认强制 `ssr-plus`

**OpenClash 不受影响**（自带 Meta 内核）。PassWall 仍可使用 Xray / SingBox 等其它组件。

## 旁路由说明

刷机后管理地址：`http://192.168.100.253`。  
OpenClash 建议开启「旁路由兼容」，清空 WAN 接口名，并更新 Meta 内核。  
日常建议以 OpenClash **或** PassWall 之一为主，避免双代理同时启用冲突。

## 目录结构

```
.
├── .github/workflows/build-x86.yml
├── config/
│   ├── README.md
│   └── lede-master/
│       ├── config
│       ├── diy-part1.sh
│       └── diy-part2.sh
└── README.md
```

## 致谢

- 云编译方案原作者：[xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt)
- 操作视频：[实用技能 @shiyongjineng](https://www.youtube.com/watch?v=6j4ofS0GT38)
- OpenWrt 源码：[coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)

## 说明

- 内核版本跟随源码分支。
- 修改配置后请再跑一次完整编译验证。
