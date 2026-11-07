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
- 若要改频率：编辑 `.github/workflows/build-x86.yml` 里的 `schedule.cron`（[cron 语法](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)）。
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

> 用于上传 Artifact、创建 Release。只读权限会导致发布步骤失败。
>
> 本仓库工作流使用 Actions 内置的 `GITHUB_TOKEN`，**一般不需要**再创建名为 `GH_TOKEN` 的 Secret（原版视频/教程里那一步可跳过）。

### 3. 修改配置（可选）

| 文件 | 用途 |
|------|------|
| [`config/lede-master/config`](config/lede-master/config) | 目标架构与软件包（`.config`） |
| [`config/lede-master/diy-part1.sh`](config/lede-master/diy-part1.sh) | feeds 更新**前**钩子（加 feed、删包等） |
| [`config/lede-master/diy-part2.sh`](config/lede-master/diy-part2.sh) | feeds 更新**后**钩子（默认 IP、主题、版本信息） |

默认 LAN IP 已在 `diy-part2.sh` 中设为 `192.168.100.253`。改其它地址时，在该脚本中搜索并替换即可。

### 4. 开始编译

**手动：**

1. 打开 **Actions**
2. 左侧选择 **X86设备编译固件 (lede-master)**
3. 右侧点击 **Run workflow**
4. 分支选 `main`（或用于试验的 `dev`）
5. 再点 **Run workflow** 确认

**自动：** 每周日定时任务会自行启动（无需点击）。

本仓库**只有这一个**编译工作流，无需像原版那样选择「通用设备 / 电视盒子」。

### 5. 等待与下载

- 编译通常需要数小时，视 GitHub Runner 负载而定
- 成功后：
  - **Actions** 页面下载 Artifact（保留约 7 天）
  - **Releases** 会自动发布（标签形如 `x86-YYYYMMDD_HHMM`）
- 失败时：查看日志；可能有 `openwrt-build-log-*` Artifact 便于排查

### 6. 刷机后访问

管理地址一般为：`http://192.168.100.253`

## 与原版视频教程的差异

原版视频基于 [xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt)，支持多源码、电视盒子与 IMG 打包。本仓库已精简：

| 原版视频 | 本仓库 |
|----------|--------|
| Fork 原作者再改 | 直接使用本仓库 |
| 配置 `GH_TOKEN` Secret | 通常不需要 |
| 选「通用 / 电视盒子」多种流程 | 仅 X86 lede 一个流程 |
| 多源码、多架构 | 仅 lede + X86_64 |

## 目录结构

```
.
├── .github/workflows/build-x86.yml   # 唯一编译工作流（含定时）
├── config/
│   ├── README.md
│   └── lede-master/
│       ├── config                    # .config（X86_64）
│       ├── diy-part1.sh              # feeds 更新前
│       └── diy-part2.sh              # feeds 更新后 / 默认 IP 等
└── README.md
```

## 相对原版的主要差异

- 只编译 lede `master` → X86_64
- 无电视盒子打包、无 Docker 流程
- 工作流使用固定 apt 依赖（不依赖短链）
- ccache 按 config 哈希复用
- 默认 LAN：`192.168.100.253`，主题 Argon
- 不强制改写内核版本
- 每周自动用最新 lede 源码编译

## 旁路由说明

刷机后管理地址一般为 `http://192.168.100.253`。  
OpenClash 作旁路由时建议开启「旁路由兼容」，清空 WAN 接口名，并同步更新 Meta 内核。  
`.config` 中若同时有 OpenClash 与 PassWall，建议只启用其中一个，避免冲突。

## 致谢

- 云编译方案原作者：[xinlingduyu/build-openwrt](https://github.com/xinlingduyu/build-openwrt)
- 操作视频：[实用技能 @shiyongjineng](https://www.youtube.com/watch?v=6j4ofS0GT38)
- OpenWrt 源码：[coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)

## 说明

- 内核版本跟随源码分支。
- 插件以 `config/lede-master/config` 为准。
- 修改配置后请在 Actions 跑一次完整编译验证。
