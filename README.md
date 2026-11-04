# 云编译 OpenWrt（仅 X86 / lede）

基于 [cs-star/OpenWrt](https://github.com/cs-star/OpenWrt) 的精简 fork：只保留 **lede + X86_64**，去掉电视盒子、多源码分支与 Docker 相关内容，便于旁路由/软路由长期自用编译。

**本仓库：** https://github.com/jianhuashao6/OpenWrt

## 当前支持

| 项目 | 说明 |
|------|------|
| 源码 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) `master` |
| 架构 | **X86_64** 通用设备 |
| 默认 IP | `192.168.100.222` |
| 默认主题 | Argon |
| 已禁用 | 电视盒子、官方 OpenWrt、ImmortalWrt、Docker 编译 |

## 使用方法

1. **权限**  
   Repository → **Settings** → **Actions** → **General** → **Workflow permissions** → 选择 **Read and write permissions** → **Save**。

2. **修改配置（可选）**  
   - 软件包与目标：[`config/lede-master/config`](config/lede-master/config)  
   - 编译前钩子：[`config/lede-master/diy-part1.sh`](config/lede-master/diy-part1.sh)  
   - 编译后钩子：[`config/lede-master/diy-part2.sh`](config/lede-master/diy-part2.sh)（默认 IP、主题、版本信息等）

3. **开始编译**  
   - 打开 **Actions**  
   - 选择 **X86设备编译固件 (lede-master)**  
   - 点击 **Run workflow**

4. **下载固件**  
   - Actions Artifact（保留 7 天）  
   - Releases 自动发布（标签形如 `x86-YYYYMMDD_HHMM`）

编译通常需要数小时。失败时会上传构建日志 Artifact。

## 目录结构

```
.
├── .github/workflows/build-x86.yml   # 唯一编译工作流
├── config/
│   ├── README.md
│   └── lede-master/
│       ├── config                    # .config（X86_64）
│       ├── diy-part1.sh              # feeds 更新前
│       └── diy-part2.sh              # feeds 更新后 / 默认 IP 等
└── README.md
```

## 本 fork 要点

- 只编译 lede `master` → X86_64  
- 无电视盒子打包、无 Docker 流程  
- 工作流使用固定 apt 依赖（不依赖短链）  
- ccache 按 config 哈希复用  
- 默认 LAN：`192.168.100.222`，主题 Argon  
- 不强制改写内核版本  

## 旁路由说明

刷机后管理地址一般为 `http://192.168.100.222`。  
OpenClash 作旁路由时建议开启「旁路由兼容」，清空 WAN 接口名，并同步更新 Meta 内核。  
`.config` 中若同时有 OpenClash 与 PassWall，建议只启用其中一个，避免冲突。

## 说明

- 内核版本跟随源码分支。  
- 插件以 `config/lede-master/config` 为准。  
- 修改配置后请在 Actions 跑一次完整编译验证。  
