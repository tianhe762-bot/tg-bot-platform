
---

# TG Bot Platform

<p align="center">
<b>Telegram Bot Server Management Platform</b>
</p>

一个基于 Debian Linux 的 Telegram 服务器管理平台。

通过 Telegram Bot 实现远程服务器管理，包括系统状态监控、Mihomo 管理、Wake-on-LAN、自动备份、自动更新以及故障诊断。

目标：

> 让用户通过一条命令，在全新的 Debian 系统上完成 TG Bot 平台部署。

---

# ✨ Features

## 🚀 One-click Installation

支持：

```bash
curl -fsSL https://raw.githubusercontent.com/tianhe762-bot/tg-bot-platform/main/install.sh | bash
```

自动完成：

```
环境检测
    ↓
依赖安装
    ↓
下载最新版本
    ↓
完整性校验
    ↓
程序部署
    ↓
首次配置
    ↓
服务启动
```

---

# 🤖 Telegram Remote Management

通过 Telegram Bot 远程管理服务器。

支持：

| Command     | Function     |
| ----------- | ----------- |
| `/status`   | 查看系统状态      |
| `/mihomo`   | 最底层节点测速     |
| `/switch`   | 切换代理节点    |
| `/wake`     | Wake-on-LAN |
| `/backup`   | 数据备份        |
| `/update`   | 版本检查与更新    |
| `/reboot`   | 重启服务器       |
| `/shutdown` | 关闭服务器       |

---

# 🖥 System Management

提供服务器基础管理能力：

* CPU监控
* 内存监控
* 磁盘监控
* 网络状态
* Docker状态
* 服务状态
* 系统日志查看

---

# 🌐 Mihomo Management

支持 Mihomo / Clash Meta 系列代理环境。

支持：

* Mihomo状态检测
* API连接检测
* 服务状态检查
* 多端口兼容

兼容：

```
ShellCrash
Mihomo Docker
Clash Meta
```

---

# ⚡ Wake-on-LAN

支持远程唤醒局域网设备。

功能：

* MAC地址管理
* Magic Packet发送
* Telegram远程开机

---

# 💾 Backup System

提供自动备份能力。

支持：

* 配置备份
* 数据备份
* 加密备份
* 定时备份

---

# 🔄 Automatic Update

内置版本管理系统。

更新流程：

```
检测最新版本

        ↓

下载 Release

        ↓

SHA256 校验

        ↓

创建备份

        ↓

升级程序

        ↓

恢复配置

        ↓

健康检查

```

支持：

* 自动更新
* 更新回滚
* 配置保留

---

# 🩺 System Diagnosis

提供自动诊断能力。

检测：

```
Telegram配置

Bot服务状态

Docker环境

Mihomo服务

WOL配置

磁盘空间

内存状态

Systemd Timer

更新配置
```

同时提供自动修复：

```
依赖修复

权限修复

配置恢复

服务重载

Bot重启
```

---

# 🏗 Architecture

项目采用模块化设计：

```
TG Bot Platform

├── install.sh
│
│   一键安装入口
│
├── deploy/
│
│   部署系统
│
├── app/
│
│   核心业务程序
│
├── systemd/
│
│   Linux服务管理
│
├── scripts/
│
│   系统维护脚本
│
├── templates/
│
│   配置模板
│
├── tests/
│
│   自动测试
│
└── docs/
    文档
```

---

# 📂 Directory Structure

```
tg-bot-platform/

├── app/
│
│   ├── tg_bot.sh
│   │
│   │   Telegram Bot 主程序入口
│   │
│   ├── core/
│   │
│   │   ├── loader.sh
│   │   │   模块加载
│   │   │
│   │   ├── router.sh
│   │   │   Telegram命令路由
│   │   │
│   │   ├── logger.sh
│   │   │   日志系统
│   │   │
│   │   └── security.sh
│   │       权限控制
│   │
│   ├── commands/
│   │
│   │   Telegram命令处理层
│   │
│   ├── modules/
│   │
│   │   系统功能模块
│   │
│   │   ├── system.sh
│   │   │   系统操作
│   │   │
│   │   │
│   │   ├── mihomo.sh
│   │   │   Mihomo管理
│   │   │
│   │   ├── wol.sh
│   │   │   Wake-on-LAN
│   │   │
│   │   └── backup.sh
│   │       备份管理
│   │
│   ├── lib/
│   │
│   │   公共函数库
│   │
│   └── services/
│
│       后台服务任务
│
│
├── deploy/
│
│   ├── deploy.sh
│   │   部署程序
│   │
│   ├── first_setup.sh
│   │   首次配置向导
│   │
│   ├── diagnose.sh
│   │   系统诊断
│   │
│   ├── repair.sh
│   │   自动修复
│   │
│   ├── updater.sh
│   │   自动更新
│   │
│   └── release_build.sh
│       Release构建
│
│
├── systemd/
│
│   Linux服务文件
│
│
├── scripts/
│
│   维护脚本
│
│
├── templates/
│
│   配置模板
│
│
├── tests/
│
│   测试工具
│
│
├── VERSION
│
│   当前版本号
│
├── release.json
│
│   Release信息
│
└── install.sh
    一键安装入口

```

---

# ⚙️ Installation

## Requirements

推荐环境：

```
OS:
Debian 11+

Architecture:
x86_64 / ARM64

权限:
root
```

---

## Install

执行：

```bash
curl -fsSL \
https://raw.githubusercontent.com/tianhe762-bot/tg-bot-platform/main/install.sh \
| bash
```

安装完成后：

进入 Telegram：

发送：

```
/start
```

即可开始管理服务器。

---

# 🔧 Configuration

首次安装自动生成：

```
/opt/tg_bot/config/
```

配置文件：

```
user.env

Telegram相关配置


device.env

设备相关配置


system.env

系统配置
```

---

# 🛠 Management

Systemd服务：

```
tg_bot.service

tg_monitor.timer

tg_backup.timer

tg_health.timer
```

查看状态：

```bash
systemctl status tg_bot
```

重启：

```bash
systemctl restart tg_bot
```

---

# 🔐 Security

安全机制：

* Telegram管理员ID验证
* 危险操作二次确认
* 配置文件隔离
* SHA256安装包验证
* 更新前自动备份

---

# 📦 Release Workflow

开发流程：

```
Source Code

↓

Release Build

↓

SHA256 Generate

↓

GitHub Release

↓

One-click Installation

```

---
