# scoop

个人使用的 Scoop bucket，用于锁定常用软件版本，并对国内网络环境下的安装体验做了一些默认优化。

## 快速开始

### 添加 Bucket

```powershell
scoop bucket add main https://github.com/ztj1993/scoop.git
```

### 安装软件

```powershell
scoop install git
scoop install uv
```

### 常用命令

```powershell
# 安装应用时不更新 Scoop
scoop install chrome --no-update-scoop

# 更新指定应用
scoop update main/7zip

# 将自动更新检测时间设置到很远，避免每次命令都触发 Scoop 自更新
scoop config last_update "2099-01-01 00:00:00"
```

## 初始化 Scoop

如果当前机器还没有安装 Scoop，可以直接运行仓库提供的安装脚本。脚本基于官方安装器，会自动安装 Scoop 并将本仓库作为 `main` bucket 克隆到默认目录：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

如国内网络访问 GitHub 不稳定，可通过加速代理（如 `ghfast.top`）安装：

```powershell
$env:SCOOP_INSTALLER_URL = "https://ghfast.top/https://raw.githubusercontent.com/ScoopInstaller/Install/master/src/install.ps1"
$env:SCOOP_PACKAGE_GIT_REPO = "https://ghfast.top/https://github.com/ScoopInstaller/Scoop.git"
$env:SCOOP_MAIN_BUCKET_GIT_REPO = "https://ghfast.top/https://github.com/ztj1993/scoop.git"
irm https://ghfast.top/https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

如需自定义 Scoop 安装目录（默认 `%USERPROFILE%\scoop`）：

```powershell
$env:SCOOP = "D:\scoop"
irm https://raw.githubusercontent.com/ztj1993/scoop/master/install.ps1 | iex
```

## 文档导航

- [部署说明](docs/deployment.md) - 安装、配置和维护 Scoop 及本 bucket 的完整指南
- [常用运行时安装](docs/runtime-installation.md) - Python、Go、Node.js 等运行时安装指南
- [本仓库软件清单](docs/software-list.md) - 本 bucket 包含的所有软件包
- [软件使用指南](docs/guides/) - bucket 目录下软件的常用使用方法
- [参考 Bucket](docs/reference-buckets.md) - 官方和社区 bucket 参考
- [Manifest 编写提示](docs/manifest-tips.md) - Scoop manifest 编写常用变量参考
- [加速前缀脚本](docs/cn-proxy.md) - 修改软件下载 URL 和 git 远端地址添加加速前缀
- [仓库维护与更新指南](docs/bucket-maintenance.md) - checkver 版本检测与更新、JSON 格式化等维护脚本使用说明
