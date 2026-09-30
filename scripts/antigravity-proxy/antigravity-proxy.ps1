<#
.SYNOPSIS
    Antigravity-Proxy 管理工具 (适用于 Google Antigravity / Antigravity IDE)

.DESCRIPTION
    管理 Antigravity 免 TUN 代理注入 (version.dll / dbghelp.dll 劫持)，支持自动识别 Scoop 及系统安装路径。
    支持针对 cli 与 ide 独立配置与应用代理组件。

.EXAMPLE
    antigravity-proxy cli config -ProxyHost 127.0.0.1 -ProxyPort 7890
    antigravity-proxy cli apply
    antigravity-proxy cli uninstall
    antigravity-proxy cli status
    antigravity-proxy ide config -ProxyPort 7890
    antigravity-proxy ide apply
    antigravity-proxy ide uninstall
    antigravity-proxy ide status
    antigravity-proxy web
#>

param(
    [Parameter(Position = 0)]
    [string]$TargetType,

    [Parameter(Position = 1)]
    [string]$Action,

    [Parameter(Position = 2)]
    [string]$Target,

    [string]$ProxyType,
    [string]$ProxyHost,
    [int]$ProxyPort
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8

# 参数解析与分流
if ($TargetType -in @("web")) {
    $Action = "web"
} elseif ($TargetType -in @("help", "-h", "--help", "/?", "") -or ($null -eq $TargetType)) {
    $Action = "help"
} elseif ($TargetType -notin @("cli", "ide")) {
    Write-Host "错误: 第一个参数必须为 'cli' 或 'ide' (例如: antigravity-proxy cli apply)" -ForegroundColor Red
    Write-Host "特例: 'antigravity-proxy web' 可直接打开 Web 可视化配置页面。" -ForegroundColor Yellow
    Write-Host "运行 'antigravity-proxy help' 查看完整帮助信息。" -ForegroundColor Gray
    exit 1
} else {
    if ([string]::IsNullOrWhiteSpace($Action)) {
        $Action = "status"
    }
    if ($Action -notin @("status", "config", "apply", "uninstall", "web", "help")) {
        Write-Host "错误: 未知命令 '$Action'。支持的命令为: status, config, apply, uninstall, web, help" -ForegroundColor Red
        exit 1
    }
}

# 定位源文件根目录
$scriptDir = $PSScriptRoot
if (Test-Path "$scriptDir\ide") {
    $sourceDir = $scriptDir
} elseif (Test-Path "$scriptDir\..\ide") {
    $sourceDir = (Resolve-Path "$scriptDir\..").Path
} elseif (Test-Path "$env:USERPROFILE\scoop\apps\antigravity-proxy\current\ide") {
    $sourceDir = "$env:USERPROFILE\scoop\apps\antigravity-proxy\current"
} else {
    $sourceDir = $scriptDir
}

# 获取特定组件（cli 或 ide）的源目录
function Get-ComponentDir {
    param([string]$Type)
    if (Test-Path "$sourceDir\$Type") {
        return "$sourceDir\$Type"
    }
    return $sourceDir
}

function Get-AntigravityLocations {
    param([string]$Type)

    $paths = [System.Collections.Generic.List[string]]::new()

    if ($Target) {
        if (Test-Path $Target) {
            $paths.Add((Resolve-Path $Target).Path)
        } else {
            Write-Warning "指定的目录不存在: $Target"
        }
        return $paths
    }

    if ($Type -eq "cli") {
        $cliExe = Get-Command "agy.exe" -ErrorAction SilentlyContinue
        if ($cliExe) {
            $paths.Add((Split-Path $cliExe.Source -Parent))
        }
        $candidates = @(
            "$env:USERPROFILE\scoop\apps\antigravity\current",
            "$env:USERPROFILE\scoop\apps\antigravity-ide\current",
            "$env:LOCALAPPDATA\Programs\Antigravity",
            "$env:LOCALAPPDATA\Programs\Antigravity IDE"
        )
    } else {
        $candidates = @(
            "$env:USERPROFILE\scoop\apps\antigravity\current",
            "$env:USERPROFILE\scoop\apps\antigravity-ide\current",
            "$env:LOCALAPPDATA\Programs\Antigravity",
            "$env:LOCALAPPDATA\Programs\Antigravity IDE",
            "${env:ProgramFiles}\Antigravity",
            "${env:ProgramFiles(x86)}\Antigravity"
        )
    }

    foreach ($cand in $candidates) {
        if ($cand -and (Test-Path $cand) -and -not $paths.Contains($cand)) {
            $paths.Add((Resolve-Path $cand).Path)
        }
    }

    return $paths
}

function Show-Header {
    param([string]$SubTitle = "")
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         Antigravity-Proxy 免 TUN 代理注入管理工具        " -ForegroundColor Cyan
    if ($SubTitle) {
        Write-Host "                     [$SubTitle]                          " -ForegroundColor Yellow
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Get-ProxyConfig {
    param([string]$Dir)
    $cfgPath = "$Dir\config.json"
    if (Test-Path $cfgPath) {
        try {
            return Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Set-ProxyConfigValue {
    param(
        [string]$Dir,
        [string]$Type,
        [string]$HostVal,
        [int]$PortVal
    )

    $cfgFile = Join-Path $Dir "config.json"
    $cfg = Get-ProxyConfig $Dir
    if (-not $cfg) {
        $cfg = [PSCustomObject]@{
            proxy = [PSCustomObject]@{
                type = "socks5"
                host = "127.0.0.1"
                port = 7890
            }
            target_processes = @(
                "agy.exe",
                "language_server.exe",
                "language_server_windows",
                "Antigravity.exe",
                "Antigravity IDE.exe",
                "node.exe"
            )
        }
    }

    if ($Type) { $cfg.proxy.type = $Type }
    if ($HostVal) { $cfg.proxy.host = $HostVal }
    if ($PortVal) { $cfg.proxy.port = $PortVal }

    $jsonContent = $cfg | ConvertTo-Json -Depth 10
    Set-Content -Path $cfgFile -Value $jsonContent -Encoding UTF8
    return $cfg
}

switch ($Action) {
    "help" {
        Show-Header
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  antigravity-proxy <cli|ide> <命令> [参数]"
        Write-Host "  antigravity-proxy web`n"
        Write-Host "目标模式 (必填，除 web 外):" -ForegroundColor Yellow
        Write-Host "  cli                   针对 Antigravity CLI (agy.exe) 进行操作"
        Write-Host "  ide                   针对 Antigravity 桌面端 / IDE 进行操作`n"
        Write-Host "命令:" -ForegroundColor Yellow
        Write-Host "  status                查看指定目标的代理注入状态及配置 (默认)"
        Write-Host "  config                查看或修改默认代理配置 (-ProxyHost, -ProxyPort, -ProxyType)"
        Write-Host "  apply                 向目标应用组件并同步配置（含端口连通性检查）"
        Write-Host "  uninstall             从目标移除注入组件"
        Write-Host "  web                   在默认浏览器中打开可视化配置页面 (config-web.html)"
        Write-Host "  help                  显示此帮助信息`n"
        Write-Host "可选参数:" -ForegroundColor Yellow
        Write-Host "  -Target <目录路径>    指定 Antigravity 安装目录（非默认路径时使用）"
        Write-Host "  -ProxyType <类型>     更新代理协议 (socks5 / http)"
        Write-Host "  -ProxyHost <主机>     更新代理主机 (如 127.0.0.1)"
        Write-Host "  -ProxyPort <端口>     更新代理端口 (如 7890)`n"
        Write-Host "示例:" -ForegroundColor Yellow
        Write-Host "  antigravity-proxy cli config -ProxyHost 127.0.0.1 -ProxyPort 7890" -ForegroundColor Gray
        Write-Host "  antigravity-proxy cli apply" -ForegroundColor Gray
        Write-Host "  antigravity-proxy cli uninstall" -ForegroundColor Gray
        Write-Host "  antigravity-proxy ide config -ProxyPort 7890" -ForegroundColor Gray
        Write-Host "  antigravity-proxy ide apply" -ForegroundColor Gray
        Write-Host "  antigravity-proxy ide uninstall" -ForegroundColor Gray
        Write-Host "  antigravity-proxy ide status" -ForegroundColor Gray
        Write-Host "  antigravity-proxy web" -ForegroundColor Gray
        Write-Host ""
    }

    "status" {
        $compDir = Get-ComponentDir $TargetType
        Show-Header "模式: $($TargetType.ToUpper())"

        $locs = Get-AntigravityLocations -Type $TargetType
        if ($locs.Count -eq 0) {
            Write-Host "未自动检测到已安装的 Antigravity $($TargetType.ToUpper()) 目录。" -ForegroundColor Yellow
            Write-Host "如果安装在自定义路径，请使用: antigravity-proxy $TargetType status -Target `"<路径>`"" -ForegroundColor Gray
        } else {
            Write-Host "已检测到的 Antigravity $($TargetType.ToUpper()) 目标目录:" -ForegroundColor Green
            foreach ($loc in $locs) {
                Write-Host "`n  [目标目录] $loc" -ForegroundColor White
                if ($TargetType -eq "cli") {
                    $isCliInjected = (Test-Path "$loc\dbghelp.dll") -or (Test-Path "$loc\antigravity_proxy.dll")
                    if ($isCliInjected) {
                        Write-Host "  - CLI 代理注入状态: [已启用 (dbghelp.dll)]" -ForegroundColor Green
                    } else {
                        Write-Host "  - CLI 代理注入状态: [未启用]" -ForegroundColor DarkGray
                    }
                } else {
                    $isInjected = Test-Path "$loc\version.dll"
                    if ($isInjected) {
                        Write-Host "  - IDE 代理注入状态: [已启用 (version.dll)]" -ForegroundColor Green
                    } else {
                        Write-Host "  - IDE 代理注入状态: [未启用]" -ForegroundColor DarkGray
                    }
                }

                $cfg = Get-ProxyConfig $loc
                if ($cfg -and $cfg.proxy) {
                    $pt = $cfg.proxy.type
                    $ph = $cfg.proxy.host
                    $pp = $cfg.proxy.port
                    Write-Host "  - 当前生效配置:     $pt`://$ph`:$pp" -ForegroundColor Cyan
                }
            }
        }

        # 检查组件默认配置及连通性
        $srcCfg = Get-ProxyConfig $compDir
        if ($srcCfg -and $srcCfg.proxy) {
            $ph = $srcCfg.proxy.host
            $pp = $srcCfg.proxy.port
            $pt = $srcCfg.proxy.type
            $srcCfgFile = Join-Path $compDir "config.json"
            Write-Host "`n$($TargetType.ToUpper()) 默认代理配置 [$srcCfgFile]:" -ForegroundColor Gray
            Write-Host "  协议: $pt | 主机: $ph | 端口: $pp" -ForegroundColor Gray

            $endpointStr = "$ph`:$pp"
            Write-Host "正在检测代理端口连通性 [$endpointStr]... " -NoNewline
            try {
                $conn = Test-NetConnection -ComputerName $ph -Port $pp -WarningAction SilentlyContinue
                if ($conn.TcpTestSucceeded) {
                    Write-Host "可用 [已连接]" -ForegroundColor Green
                } else {
                    Write-Host "不可达 [请确认代理软件是否已启动并开放该端口]" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "检测跳过" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }

    "config" {
        $compDir = Get-ComponentDir $TargetType
        Show-Header "配置: $($TargetType.ToUpper())"

        $hasUpdate = $ProxyType -or $ProxyHost -or $ProxyPort

        if ($hasUpdate) {
            # 仅更新指定目标（cli 或 ide）的默认配置，不直接修改目标安装目录配置
            $updatedCfg = Set-ProxyConfigValue -Dir $compDir -Type $ProxyType -HostVal $ProxyHost -PortVal $ProxyPort
            Write-Host "已更新 $($TargetType.ToUpper()) 默认配置 [$compDir\config.json]:" -ForegroundColor Green
            Write-Host "  协议: $($updatedCfg.proxy.type) | 主机: $($updatedCfg.proxy.host) | 端口: $($updatedCfg.proxy.port)" -ForegroundColor Cyan
            Write-Host "提示: 目标安装目录的配置将在执行 'antigravity-proxy $TargetType apply' 时同步应用。" -ForegroundColor Yellow

            # 连通性测试
            $ph = $updatedCfg.proxy.host
            $pp = $updatedCfg.proxy.port
            Write-Host "`n正在检测代理端口连通性 [$ph`:$pp]... " -NoNewline
            try {
                $conn = Test-NetConnection -ComputerName $ph -Port $pp -WarningAction SilentlyContinue
                if ($conn.TcpTestSucceeded) {
                    Write-Host "可用 [已连接]" -ForegroundColor Green
                } else {
                    Write-Host "不可达 [请确认代理软件是否已启动并开放该端口]" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "检测跳过" -ForegroundColor Gray
            }
        } else {
            $srcCfg = Get-ProxyConfig $compDir
            $srcCfgFile = Join-Path $compDir "config.json"
            if ($srcCfg -and $srcCfg.proxy) {
                Write-Host "$($TargetType.ToUpper()) 当前代理配置 [$srcCfgFile]:" -ForegroundColor White
                Write-Host "  协议 (Type): $($srcCfg.proxy.type)" -ForegroundColor Cyan
                Write-Host "  主机 (Host): $($srcCfg.proxy.host)" -ForegroundColor Cyan
                Write-Host "  端口 (Port): $($srcCfg.proxy.port)" -ForegroundColor Cyan
                if ($srcCfg.target_processes) {
                    Write-Host "  目标进程:   $($srcCfg.target_processes -join ', ')" -ForegroundColor Gray
                }
            } else {
                Write-Host "未找到配置文件 [$srcCfgFile]，可使用参数直接创建初始配置。" -ForegroundColor Yellow
            }

            Write-Host "`n修改配置命令示例:" -ForegroundColor Yellow
            Write-Host "  antigravity-proxy $TargetType config -ProxyPort 7890" -ForegroundColor Gray
            Write-Host "  antigravity-proxy $TargetType config -ProxyHost 127.0.0.1 -ProxyPort 7890 -ProxyType socks5" -ForegroundColor Gray
            Write-Host "若需打开可视化 Web 控制台，请运行: antigravity-proxy web" -ForegroundColor Gray
        }
        Write-Host ""
    }

    "apply" {
        $compDir = Get-ComponentDir $TargetType
        Show-Header "应用: $($TargetType.ToUpper())"

        $locs = Get-AntigravityLocations -Type $TargetType
        if ($locs.Count -eq 0) {
            Write-Error "未能找到 Antigravity $($TargetType.ToUpper()) 安装目录，请通过 -Target 参数指定路径。"
            exit 1
        }

        # 检查代理端口连通性
        $srcCfg = Get-ProxyConfig $compDir
        if ($srcCfg -and $srcCfg.proxy) {
            $ph = $srcCfg.proxy.host
            $pp = $srcCfg.proxy.port
            $pt = $srcCfg.proxy.type
            $endpointStr = "$ph`:$pp"
            Write-Host "正在检测代理端口连通性 [$endpointStr]... " -NoNewline
            try {
                $conn = Test-NetConnection -ComputerName $ph -Port $pp -WarningAction SilentlyContinue
                if ($conn.TcpTestSucceeded) {
                    Write-Host "可用 [已连接]" -ForegroundColor Green
                } else {
                    Write-Host "不可达 [警告: 代理软件可能未启动或未开放端口]" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "检测跳过" -ForegroundColor Gray
            }
        }

        # 检查相关运行中进程
        $running = Get-Process -Name "Antigravity", "Antigravity IDE", "agy", "language_server*" -ErrorAction SilentlyContinue
        if ($running) {
            Write-Warning "检测到 Antigravity 相关进程正在运行中，应用后建议重启进程以使代理生效！"
        }

        foreach ($loc in $locs) {
            Write-Host "`n正在向目标应用代理组件及配置: $loc" -ForegroundColor Cyan

            if ($TargetType -eq "cli") {
                # CLI 模式部署 dbghelp.dll 与 antigravity_proxy.dll
                if (Test-Path "$compDir\dbghelp.dll") {
                    Copy-Item "$compDir\dbghelp.dll" "$loc\dbghelp.dll" -Force
                    Write-Host "  + 已部署 dbghelp.dll" -ForegroundColor Green
                } else {
                    Write-Warning "未找到 $compDir\dbghelp.dll"
                }
                if (Test-Path "$compDir\antigravity_proxy.dll") {
                    Copy-Item "$compDir\antigravity_proxy.dll" "$loc\antigravity_proxy.dll" -Force
                    Write-Host "  + 已部署 antigravity_proxy.dll" -ForegroundColor Green
                } else {
                    Write-Warning "未找到 $compDir\antigravity_proxy.dll"
                }
            } else {
                # IDE 模式部署 version.dll
                if (-not (Test-Path "$compDir\version.dll")) {
                    Write-Error "源文件 version.dll 未找到: $compDir\version.dll"
                    exit 1
                }
                Copy-Item "$compDir\version.dll" "$loc\version.dll" -Force
                Write-Host "  + 已部署 version.dll" -ForegroundColor Green
            }

            # 同步应用 config.json 到目标安装目录
            if (Test-Path "$compDir\config.json") {
                Copy-Item "$compDir\config.json" "$loc\config.json" -Force
                Write-Host "  + 已同步应用 config.json" -ForegroundColor Green
            }

            # 复制 config-web.html 方便调试
            if (Test-Path "$compDir\config-web.html") {
                Copy-Item "$compDir\config-web.html" "$loc\config-web.html" -Force
            }

            Write-Host "成功应用 $($TargetType.ToUpper()) 代理注入与配置！" -ForegroundColor Green
        }
        Write-Host "`n提示: 若 Antigravity 正在运行，请完全退出并重新启动它以加载代理。" -ForegroundColor Yellow
    }

    "uninstall" {
        Show-Header "卸载: $($TargetType.ToUpper())"

        $locs = Get-AntigravityLocations -Type $TargetType
        if ($locs.Count -eq 0) {
            Write-Error "未能找到 Antigravity $($TargetType.ToUpper()) 安装目录，请通过 -Target 参数指定路径。"
            exit 1
        }

        foreach ($loc in $locs) {
            Write-Host "`n正在从目标目录卸载代理注入组件: $loc" -ForegroundColor Cyan
            $removed = $false

            if ($TargetType -eq "cli") {
                if (Test-Path "$loc\dbghelp.dll") {
                    Remove-Item "$loc\dbghelp.dll" -Force
                    Write-Host "  - 已移除 dbghelp.dll" -ForegroundColor Yellow
                    $removed = $true
                }
                if (Test-Path "$loc\antigravity_proxy.dll") {
                    Remove-Item "$loc\antigravity_proxy.dll" -Force
                    Write-Host "  - 已移除 antigravity_proxy.dll" -ForegroundColor Yellow
                    $removed = $true
                }
            } else {
                if (Test-Path "$loc\version.dll") {
                    Remove-Item "$loc\version.dll" -Force
                    Write-Host "  - 已移除 version.dll" -ForegroundColor Yellow
                    $removed = $true
                }
            }

            if ($removed) {
                Write-Host "已成功卸载 $($TargetType.ToUpper()) 代理注入组件！" -ForegroundColor Green
            } else {
                Write-Host "目标目录未检测到注入组件，无需卸载。" -ForegroundColor Gray
            }
        }
    }

    "web" {
        $compDir = if ($TargetType -in @("cli", "ide")) { Get-ComponentDir $TargetType } else { $null }
        $candidates = @()
        if ($compDir) {
            $candidates += "$compDir\config-web.html"
            $candidates += "$compDir\config.json"
        }
        $candidates += "$sourceDir\ide\config-web.html"
        $candidates += "$sourceDir\cli\config-web.html"
        $candidates += "$sourceDir\config-web.html"
        $candidates += "$sourceDir\ide\config.json"
        $candidates += "$sourceDir\cli\config.json"
        $candidates += "$sourceDir\config.json"

        $opened = $false
        foreach ($cand in $candidates) {
            if ($cand -and (Test-Path $cand)) {
                if ($cand.EndsWith(".html")) {
                    Write-Host "正在打开可视化配置页面: $cand" -ForegroundColor Green
                    Start-Process $cand
                } else {
                    Write-Host "正在打开配置文件: $cand" -ForegroundColor Green
                    Start-Process notepad.exe -ArgumentList "`"$cand`""
                }
                $opened = $true
                break
            }
        }

        if (-not $opened) {
            Write-Error "未找到配置文件或可视化页面。"
            exit 1
        }
    }
}
