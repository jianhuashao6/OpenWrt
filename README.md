# 云编译 OpenWrt（仅 X86 / lede）

基于 [cs-star/OpenWrt](https://github.com/cs-star/OpenWrt) 的精简 fork：只保留 **lede + X86_64**，去掉电视盒子、多源码分支与 Docker 相关内容，便于旁路由/软路由长期自用编译。

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
   Repository → Settings → Actions → General → Workflow permissions → 勾选 **Read and write permissions**。

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

编译通常需要数小时，视 Runner 负载而定。失败时会尝试上传构建日志 Artifact。

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

## 本 fork 相对通用云编译仓库的差异

- 只编译 lede `master` → X86_64，无多架构/多源码矩阵  
- 无电视盒子打包、无 Docker 镜像流程  
- 工作流依赖改为固定 apt 列表（不依赖短链）  
- ccache 按 config 哈希复用  
- `diy-part2`：默认 LAN `192.168.100.222`、Argon、不强制 KERNEL_PATCHVER  

## 说明

- 内核版本跟随源码分支，脚本不强制改写。  
- OpenClash / PassWall 等以 `config` 中选项为准；旁路由建议以 OpenClash 为主，避免多代理插件同时启用冲突。  
- 二次修改后请自行在 Actions 验证一次完整编译。  
