# Antigravity-Proxy 使用指南

## 简介

Antigravity-Proxy 是专门为 **Google Antigravity** 与 **Antigravity IDE** 量身定制的免 TUN 强制代理注入工具（基于 MinHook + Windows DLL 劫持）。

- **版本**: v2.4
- **许可证**: BSD-2-Clause
- **官方仓库**: https://github.com/yuaotian/antigravity-proxy
- **核心定位**: 解决中国大陆网络环境下 Antigravity 核心后端（如 `language_server_windows_x64.exe`、`node.exe`、`agy.exe` 等）无法走系统代理、只能被迫开启全局 TUN 模式的痛点。

---

## 核心特性与工作原理

### 1. 解决的痛点
- **无需 TUN 模式**: 不需要管理员权限开启 Clash/Mihomo 的全局 TUN 网卡模式。
- **精准进程代理**: 仅对 Antigravity 及其派生的子进程（语言服务器、Node 运行时、CLI 进程）透明重定向网络流量，不干扰系统其他程序。
- **完全透明**: 宿主进程无感知，底层通过 Winsock API Hook 将出站 TCP/UDP 流量桥接至本地 SOCKS5/HTTP 代理。

### 2. 工作原理
- **IDE 桌面端**: 利用 Windows 动态链接库搜索机制，将编译好的 `version.dll` 放置于 Antigravity 安装根目录（与 `Antigravity.exe` 同级），在主程序启动时优先加载并安装 API Hook。
- **CLI 命令行端**: 通过 `dbghelp.dll` 引导加载 `antigravity_proxy.dll`，无缝劫持 `agy.exe` 的网络通信。

---

## 安装方法

通过 Scoop 直接安装：

```powershell
scoop install antigravity-proxy
```

如国内访问 GitHub 不稳定，可通过加速前缀安装：

```powershell
.\bin\cn-proxy-url.ps1 antigravity-proxy
scoop install antigravity-proxy
```

---

## 常用命令与管理工具

安装后即可在终端全局使用 `antigravity-proxy` 命令行工具。除 `web` 命令外，所有操作均需指定目标模式（`cli` 或 `ide`）：

### 1. 查看当前状态

```powershell
# 查看 CLI 模式代理状态及配置
antigravity-proxy cli status

# 查看 IDE 桌面端代理状态及配置
antigravity-proxy ide status
```
自动扫描 Scoop 安装目录及系统全局目录下的对应 Antigravity 目标，展示其注入状态、当前代理配置以及本地代理端口连通性。

### 2. 独立配置默认代理参数 (`config`)

`config` 命令仅更新 `cli` 目录或 `ide` 目录下的默认配置文件（`config.json`），**不会直接修改目标安装目录的配置**。只有在执行 `apply` 命令时才会将配置同步部署至目标：

```powershell
# 配置 CLI 的默认代理主机和端口
antigravity-proxy cli config -ProxyHost 127.0.0.1 -ProxyPort 7890

# 配置 IDE 的默认代理端口与协议
antigravity-proxy ide config -ProxyPort 7890 -ProxyType socks5

# 查看 CLI 当前默认配置
antigravity-proxy cli config

# 查看 IDE 当前默认配置
antigravity-proxy ide config
```

### 3. 应用代理组件与配置 (`apply`)

`apply` 命令执行时会自动进行**代理端口连通性检查**，并将组件 DLL 与最新配置同步部署至目标 Antigravity 目录：

```powershell
# 应用 Antigravity CLI 代理组件与配置
antigravity-proxy cli apply

# 应用 Antigravity IDE 桌面端代理组件与配置
antigravity-proxy ide apply

# 如安装在自定义路径，可使用 -Target 参数
antigravity-proxy ide apply -Target "D:\Tools\Antigravity"
```

> **注意**: 如果 Antigravity 正在运行中，应用注入后请完全退出并重启 Antigravity 以使代理生效。

### 4. 从目标卸载代理组件 (`uninstall`)

```powershell
# 卸载 CLI 代理组件
antigravity-proxy cli uninstall

# 卸载 IDE 代理组件
antigravity-proxy ide uninstall
```
安全从目标目录中移除劫持 DLL 文件（`dbghelp.dll` / `antigravity_proxy.dll` 或 `version.dll`），恢复默认直连状态。

### 5. 打开可视化配置页面 (Web 控制台)

```powershell
# 打开可视化 Web 控制台 (无需指定 cli 或 ide)
antigravity-proxy web
```
在默认浏览器中打开可视化的配置控制台（`config-web.html`）或用编辑器直接查看 `config.json`。

---

## 配置文件说明 (`config.json`)

默认配置文件结构如下：

```json
{
  "proxy": {
    "type": "socks5",
    "host": "127.0.0.1",
    "port": 7890
  },
  "target_processes": [
    "agy.exe",
    "language_server.exe",
    "language_server_windows",
    "Antigravity.exe",
    "Antigravity IDE.exe",
    "node.exe"
  ]
}
```

- `proxy.type`: 代理协议类型，支持 `socks5`（推荐）或 `http`。
- `proxy.host`: 本地代理监听地址，通常为 `127.0.0.1`。
- `proxy.port`: 本地代理端口（如 Clash 的 `7890` / `7891`，v2rayN 的 `10808`）。
- `target_processes`: 目标劫持注入的进程清单。

---

## 故障排查

### 1. 启动报错 0xc0000142
- **原因**: 系统缺少 Microsoft Visual C++ 运行库。
- **解决**: 执行 `scoop install vcredist-aio` 安装完整的微软常用运行库合集。

### 2. 对话报错 `Agent execution terminated due to error`
- **排查建议**:
  1. 检查 `<Antigravity安装目录>\logs\proxy-YYYYMMDD.log`，若看到 `SOCKS5: 隧道建立成功` 说明 DLL 注入正常工作。
  2. 检查 `%APPDATA%\Antigravity\logs\<最新目录>\ls-main.log`，若提示 `FAILED_PRECONDITION (code 400): User location is not supported for the API use.`，说明当前代理节点的出口 IP 不受支持，请更换原生/住宅代理节点或非机房节点。
