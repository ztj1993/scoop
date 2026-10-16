# 部署说明

本文档详细说明如何部署和配置 Scoop 以及本 bucket。

## 快速安装

### 首次安装

如果当前机器还没有安装 Scoop，可以直接运行仓库提供的安装脚本：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

脚本会自动完成以下操作：
1. 下载并安装 Scoop
2. 下载并配置本 bucket 为 `main` bucket

## 环境变量配置

安装脚本支持通过环境变量自定义安装行为。

### 安装源相关变量

- `SCOOP_INSTALLER_URL`：官方安装器脚本下载地址（默认 `https://get.scoop.sh`）
- `SCOOP_MAIN_BUCKET_GIT_REPO`：本 bucket Git 仓库克隆地址（默认 `https://github.com/ztj1993/scoop.git`）
- `SCOOP_MAIN_BUCKET_REPO`：本 bucket Zip 归档包下载地址，无 Git 环境时降级使用（默认 `https://github.com/ztj1993/scoop/archive/master.zip`）
- `SCOOP_PACKAGE_GIT_REPO`：Scoop 核心 Git 仓库克隆地址（默认 `https://github.com/ScoopInstaller/Scoop.git`）
- `SCOOP_PACKAGE_REPO`：Scoop 核心 Zip 归档包下载地址，无 Git 环境时降级使用（默认 `https://github.com/ScoopInstaller/Scoop/archive/master.zip`）

### 目录与系统变量

- `SCOOP`：Scoop 安装根目录（默认 `%USERPROFILE%\scoop`）
- `SCOOP_GLOBAL`：全局应用安装目录（默认 `%ProgramData%\scoop`）

## 自定义安装示例

### 使用加速代理地址

默认直接从 GitHub 官方下载。如国内网络环境访问较慢或不稳定，可使用代理加速地址（如 `ghfast.top`）：

```powershell
$env:SCOOP_INSTALLER_URL = "https://ghfast.top/https://raw.githubusercontent.com/ScoopInstaller/Install/master/src/install.ps1"
$env:SCOOP_PACKAGE_GIT_REPO = "https://ghfast.top/https://github.com/ScoopInstaller/Scoop.git"
$env:SCOOP_MAIN_BUCKET_GIT_REPO = "https://ghfast.top/https://github.com/ztj1993/scoop.git"
irm https://ghfast.top/https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

### 自定义安装目录

```powershell
$env:SCOOP = "D:\scoop"
$env:SCOOP_GLOBAL = "D:\scoop\global"
irm https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

## 安装后配置

### 基本配置

```powershell
# 查看当前配置
scoop config

# 设置 Scoop 安装目录（如果需要）
scoop config rootPath "D:\scoop"

# 设置全局应用安装目录
scoop config globalPath "D:\scoop\global"
```

### 添加 Bucket

```powershell
# 添加本 bucket（安装脚本会自动完成）
scoop bucket add main https://github.com/ztj1993/scoop.git

# 添加其他常用 bucket
scoop bucket add extras
scoop bucket add versions
```

### 安装常用软件

```powershell
# 安装基础工具
scoop install git 7zip

# 安装开发工具
scoop install uv g nvm

# 安装实用工具
scoop install powertoys rufus
```

## 更新和维护

### 更新 Scoop

```powershell
# 更新 Scoop 本身
scoop update

# 更新所有已安装的应用
scoop update *

# 更新指定应用
scoop update <应用名>
```

### 更新 Bucket

```powershell
# 更新所有 bucket
scoop update --all-buckets

# 更新指定 bucket
scoop bucket list
scoop update main
```

### 清理旧版本

```powershell
# 清理应用缓存
scoop cache rm *

# 清理旧版本
scoop cleanup *

# 清理全局旧版本
scoop cleanup --global
```

## 卸载

### 卸载单个应用

```powershell
scoop uninstall <应用名>
```

### 完全卸载 Scoop

```powershell
# 卸载所有应用
scoop uninstall *

# 删除 Scoop 目录
Remove-Item -Recurse -Force "$env:USERPROFILE\scoop"
```

## 故障排除

### 常见问题

1. **执行策略错误**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **网络连接问题**
   - 检查是否能访问 GitHub
   - 尝试使用代理或镜像

3. **权限问题**
   - 以管理员身份运行 PowerShell
   - 检查目录权限

### 查看日志

```powershell
# 查看 Scoop 日志
Get-Content "$env:USERPROFILE\scoop\apps\scoop\current\logs\scoop.log"

# 查看应用安装日志
Get-Content "$env:USERPROFILE\scoop\apps\<应用名>\current\install.log"
```
