# 加速前缀脚本

本项目提供两个脚本（位于 `bin/` 目录下），用于为 GitHub 资源添加加速前缀，解决国内网络下载缓慢的问题。

- `bin/cn-proxy-url.ps1` - 修改软件包 manifest 中的下载 URL
- `bin/cn-proxy-git.ps1` - 修改 bucket 和 scoop 的 git 远端地址

---

## cn-proxy-url.ps1

修改 bucket 中指定软件包的下载 URL，添加加速前缀。

### 基本用法

```powershell
# 使用默认前缀 https://ghfast.top/
.\bin\cn-proxy-url.ps1 <软件名称>

# 使用自定义前缀
.\bin\cn-proxy-url.ps1 <软件名称> <前缀地址>

# 仅显示变更内容，不实际修改文件
.\bin\cn-proxy-url.ps1 <软件名称> -DryRun

# 移除已添加的前缀，恢复原始 URL
.\bin\cn-proxy-url.ps1 <软件名称> -Remove
```

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `AppName` | 字符串 | 是 | - | 软件名称，对应 bucket 中的 JSON 文件名（不含扩展名） |
| `Prefix` | 字符串 | 否 | `https://ghfast.top/` | 要添加的加速前缀地址 |
| `-Remove` | 开关 | 否 | - | 移除前缀模式 |
| `-DryRun` | 开关 | 否 | - | 仅预览变更，不修改文件 |

### 使用示例

```powershell
# 为 clash-verge-rev 添加加速前缀
.\bin\cn-proxy-url.ps1 clash-verge-rev

# 使用自定义前缀
.\bin\cn-proxy-url.ps1 git "https://mirror.ghproxy.com/"

# 先预览再执行
.\bin\cn-proxy-url.ps1 7zip -DryRun
.\bin\cn-proxy-url.ps1 7zip

# 移除已添加的前缀
.\bin\cn-proxy-url.ps1 clash-verge-rev -Remove
```

### 支持的 URL 字段

脚本会自动处理 manifest 中以下位置的 URL：

- 顶层 `url` 字段
- `architecture` 下的 `url` 字段（如 `architecture.64bit.url`）
- `autoupdate` 下的 `url` 字段
- `autoupdate.architecture` 下的 `url` 字段

### 查找范围

脚本会在以下目录中查找 manifest 文件（按优先级）：

1. `bucket/` - 当前版本
2. `deprecated/` - 已弃用版本

---

## cn-proxy-git.ps1

修改 bucket 和 scoop 的 git 远端地址，添加加速前缀。

### 基本用法

```powershell
# 列出所有 bucket 和 scoop 的 git remote
.\bin\cn-proxy-git.ps1 -List

# 修改指定 bucket 的 remote
.\bin\cn-proxy-git.ps1 <bucket名称>

# 修改 scoop 本身的 remote
.\bin\cn-proxy-git.ps1 -Scoop

# 批量修改所有 bucket
.\bin\cn-proxy-git.ps1 -All

# 使用自定义前缀
.\bin\cn-proxy-git.ps1 <bucket名称> <前缀地址>

# 仅显示变更内容，不实际修改
.\bin\cn-proxy-git.ps1 <bucket名称> -DryRun

# 移除已添加的前缀
.\bin\cn-proxy-git.ps1 <bucket名称> -Remove
```

### 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `BucketName` | 字符串 | 否 | - | bucket 名称（与 `-Scoop`、`-All`、`-List` 互斥） |
| `Prefix` | 字符串 | 否 | `https://ghfast.top/` | 要添加的加速前缀地址 |
| `-Scoop` | 开关 | 否 | - | 修改 scoop 本身的 remote |
| `-All` | 开关 | 否 | - | 批量修改所有 bucket |
| `-List` | 开关 | 否 | - | 列出所有 git remote |
| `-Remove` | 开关 | 否 | - | 移除前缀模式 |
| `-DryRun` | 开关 | 否 | - | 仅预览变更，不修改 |

### 使用示例

```powershell
# 查看当前所有 git remote
.\bin\cn-proxy-git.ps1 -List

# 修改 main bucket 的 remote
.\bin\cn-proxy-git.ps1 main

# 修改 scoop 本身的 remote
.\bin\cn-proxy-git.ps1 -Scoop

# 批量修改所有 bucket
.\bin\cn-proxy-git.ps1 -All

# 先预览再执行
.\bin\cn-proxy-git.ps1 -All -DryRun
.\bin\cn-proxy-git.ps1 -All

# 使用自定义前缀
.\bin\cn-proxy-git.ps1 main "https://mirror.ghproxy.com/"

# 移除已添加的前缀
.\bin\cn-proxy-git.ps1 main -Remove
```

---

## 注意事项

1. 脚本会自动检测 URL 是否已包含指定前缀，避免重复添加
2. 使用 `-Remove` 参数时，只会移除精确匹配的前缀
3. 建议在修改前使用 `-DryRun` 参数预览变更
4. 修改 manifest 后的 JSON 文件会保持 UTF-8 编码
