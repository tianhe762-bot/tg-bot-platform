# TG Bot Platform

<p align="center">
<b>Telegram 服务器管理平台 · 一键部署 · 纯 Bash 实现</b>
</p>

一个基于 Debian Linux 的 Telegram 服务器管理平台。安装完成后，你只需要在 Telegram 里发消息，就能随时随地查看服务器状态、测速切换代理节点、查询服务端口、备份和更新机器人、远程开机等。

```bash
curl -fsSL https://raw.githubusercontent.com/tianhe762-bot/tg-bot-platform/main/install.sh | bash
```

---

## ✨ 功能一览

| 能力 | 说明 |
| --- | --- |
| 📊 系统状态总览 | CPU 使用率 / 温度 / 内存 / 磁盘 / 网络流量 / Docker 容器 / Mihomo 节点，一次看全 |
| 🚀 代理节点测速 | 自动展开到最底层节点，并行测速，只显示可用节点（≤800ms） |
| 🔀 一键切换节点 | `/switch 节点名`，切换后立刻报告新节点延迟 |
| 🌐 服务端口查询 | 自动扫描 Docker 与非 Docker 程序的端口，直接给出局域网访问地址 |
| 💾 自动备份 | 数据、配置定时备份，支持加密 |
| 📦 版本检查与更新 | 查看当前/最新版本，确认后自动升级并保留配置，失败自动回滚 |
| ⚡ WOL 远程唤醒 | 发送 Magic Packet，远程开机局域网设备 |
| 🔔 自动监控报警 | CPU / 内存 / 磁盘 / Docker 异常自动推送 Telegram |
| 🩺 诊断与自修复 | 一键诊断配置、服务、环境，并自动修复 |
| 🛡️ 安全机制 | 管理员验证、危险操作二次确认、SHA256 校验、更新前自动备份 |

---

## 📸 功能展示

### 📊 服务器状态总览 `/status`

一条命令查看整台服务器的运行情况：

```text
📋 服务器状态汇报

🖥️ 主机: my-server
💻 系统: Debian GNU/Linux 13 (trixie)
⏱️ 已持续运行: up 4 hours
📊 CPU 使用率: 23% · 温度: 52°C
🧠 内存: 2.0G / 3.3G（61%）
💾 系统盘: 21%
🗄️ 数据盘: 4%
🌐 网络: 网卡: eth0 · 下载: 1.2G · 上传: 345M
🐳 Docker: 6 个容器
• 网盘 : Up 3 hours
• 相册 : Up 4 hours (healthy)
🛰️ Mihomo: ✅ 已开启 · 当前节点: 节点-香港01 · 延迟: 120ms
```

### 🚀 代理节点测速 `/mihomo`

自动展开到最底层节点并并行测速，只保留**连通且延迟 ≤800ms** 的节点，按延迟从低到高排列，当前节点标 `▶`：

```text
🚀 Mihomo 节点测速（可用 4 个）

🇭🇰 香港节点:
▶ 节点-香港01 — 120ms
• 节点-香港02 — 350ms

🇯🇵 日韩节点:
• 节点-日本02 — 180ms

其他节点:
• 共享节点 — 200ms
```

### 🔀 一键切换节点 `/switch`

从 `/mihomo` 复制节点名，发送 `/switch 完整节点名` 即可切换，并立即反馈新节点延迟：

```text
✅ 已切换至: 节点-新加坡03
📶 当前延迟: 350ms
```

> 新手不知道怎么发？发送 `/help`，里面有完整模板：先 `/mihomo` 看节点 → 复制名字 → `/switch 节点名`。

### 🌐 局域网服务端口 `/ports`

不用再记端口号。自动扫描 Docker 容器、非 Docker 程序（ss 扫描）和手动配置的服务，直接给出可点击的访问地址：

```text
🌐 局域网服务端口

服务器IP: 192.168.1.100

🐳 Docker:
• 网盘 — http://192.168.1.100:5244
• 相册 — http://192.168.1.100:2283

💻 其他程序:
• Mihomo 面板 — http://192.168.1.100:9999
• 面板 — http://192.168.1.100:16601

📝 手动配置:
• 下载器 — http://192.168.1.100:8080
```

未自动识别的服务可通过 `system.env` 里的 `PANEL_SERVICES="名称=端口"` 补充。

### 📦 版本检查与更新 `/update`

先对比版本，确认后再升级，升级过程自动完成下载、SHA256 校验、备份、覆盖、重启与回滚：

```text
📦 版本检查

当前版本: v1.6.0
最新版本: v1.7.0

是否更新？
再次发送 /update 确认更新。
```

### ⚡ 更多能力

- `/wake` — 发送 WOL 唤醒包，远程开机局域网设备
- `/backup` — 手动触发数据与配置备份
- `/reboot`、`/shutdown` — 重启 / 关闭服务器（均需二次确认）
- `/help` — 使用帮助与切换节点模板

---

## 📋 命令速查

| 命令 | 功能 |
| --- | --- |
| `/status` | 系统状态总览（CPU/温度/内存/磁盘/网络/Docker/Mihomo） |
| `/ports` | 查看各服务访问端口与局域网地址 |
| `/mihomo` | 最底层节点测速（只显示可用节点） |
| `/switch 节点名` | 切换代理节点并显示新节点延迟 |
| `/wake` | 发送 WOL 唤醒包开机 |
| `/backup` | 备份数据与配置 |
| `/update` | 版本检查与更新机器人 |
| `/reboot` | 重启服务器（二次确认） |
| `/shutdown` | 关闭服务器（二次确认） |
| `/help` | 使用帮助与切换节点模板 |

---

## 🚀 快速开始

### 1. 一键安装

在全新的 Debian 服务器上执行：

```bash
curl -fsSL https://raw.githubusercontent.com/tianhe762-bot/tg-bot-platform/main/install.sh | bash
```

安装过程自动完成：

```text
环境检测 → 依赖安装 → 下载最新版本 → 完整性校验 → 程序部署 → 首次配置 → 服务启动
```

### 2. 首次配置

按提示填入：

- Telegram Bot Token（找 [@BotFather](https://t.me/BotFather) 创建）
- 管理员 Telegram ID
- WOL 目标电脑 MAC（可选）
- Mihomo API 地址（可选）

### 3. 开始使用

在 Telegram 里向机器人发送 `/help`，按模板操作即可。

---

## ⚙️ 配置说明

配置文件位于 `/opt/tg_bot/config/`：

| 文件 | 内容 |
| --- | --- |
| `user.env` | Telegram Token、管理员 ID、WOL MAC |
| `device.env` | 服务器显示名称、系统名称、数据目录（留空自动检测） |
| `system.env` | Mihomo API、Telegram 代理、更新地址、`PANEL_SERVICES` 手动服务端口 |

---

## 🏗️ 架构

```text
TG Bot Platform
├── install.sh         一键安装入口
├── app/
│   ├── tg_bot.sh      主程序（轮询 Telegram 消息）
│   ├── core/          路由 / 安全 / 日志 / 模块加载
│   ├── commands/      Telegram 命令处理
│   ├── modules/       功能模块（Mihomo / 备份 / WOL / 更新等）
│   ├── lib/           公共函数库
│   └── services/      后台任务（监控 / 健康检查 / 定时调度）
├── deploy/            部署 / 升级 / 诊断 / 修复 / 发布构建
├── systemd/           Linux 服务与定时器
├── scripts/           维护脚本
├── templates/         配置模板
├── tests/             自动测试
├── VERSION            当前版本号
└── release.json       Release 信息
```

Systemd 服务：

```text
tg_bot.service      Telegram Bot 主服务
tg_monitor.timer    定时监控（资源超限自动报警）
tg_backup.timer     定时备份
tg_health.timer     定期健康检查
```

---

## 🔄 更新与发布流程

```text
检测最新版本 → 下载 Release → SHA256 校验 → 创建备份 → 升级程序 → 恢复配置 → 健康检查
```

支持：

- 自动更新
- 更新失败自动回滚
- 配置与日志保留
- GitHub Actions 自动检测（Bash 语法 / ShellCheck / 发布包 CRLF 校验）

---

## 🔐 安全机制

- 仅管理员 ID 可操作
- 重启 / 关机 / 更新等危险操作需二次确认
- 安装包 SHA256 完整性校验
- 更新前自动备份，失败自动回滚
- 配置文件与密钥隔离（`config/*.env` 不进入发布包）
