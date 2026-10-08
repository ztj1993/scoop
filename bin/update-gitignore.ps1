# 更新 .gitignore 文件，将 deprecated 目录下的文件添加到忽略列表
# 格式: /bucket/<filename>.json

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path "$PSScriptRoot/.."
$gitignorePath = Join-Path $repoRoot '.gitignore'

# 获取 deprecated 目录下的所有 .json 文件
$deprecatedFiles = Get-ChildItem -Path "$repoRoot/deprecated" -Filter '*.json' -ErrorAction SilentlyContinue

# 构建需要忽略的文件列表（格式: /bucket/<filename>.json）
$filesToIgnore = @()

foreach ($file in $deprecatedFiles) {
    $filesToIgnore += "/bucket/$($file.Name)"
}

# 排序并去重
$filesToIgnore = $filesToIgnore | Sort-Object | Get-Unique

# 读取现有的 .gitignore 内容
$existingContent = @()
if (Test-Path $gitignorePath) {
    $existingContent = Get-Content $gitignorePath -Encoding UTF8 | Where-Object { $_ -ne '' }
}

# 找出已存在的条目（以 /bucket/ 开头的行）
$existingBucketEntries = $existingContent | Where-Object { $_ -match '^/bucket/' }

# 找出需要添加的新条目
$newEntries = $filesToIgnore | Where-Object { $existingBucketEntries -notcontains $_ }

# 找出需要删除的条目（在 .gitignore 中但不在文件列表中的）
$entriesToRemove = $existingBucketEntries | Where-Object { $filesToIgnore -notcontains $_ }

# 构建新的 .gitignore 内容
$newContent = @()

# 保留非 /bucket/ 开头的行
$newContent += $existingContent | Where-Object { $_ -notmatch '^/bucket/' }

# 添加所有需要忽略的文件条目
$newContent += $filesToIgnore

# 写入文件
$newContent | Set-Content $gitignorePath -Encoding UTF8

# 输出结果
Write-Host "已更新 .gitignore 文件:" -ForegroundColor Green
Write-Host "  - 总条目数: $($filesToIgnore.Count)" -ForegroundColor Cyan

if ($newEntries.Count -gt 0) {
    Write-Host "  - 新增条目: $($newEntries.Count)" -ForegroundColor Green
    foreach ($entry in $newEntries) {
        Write-Host "    + $entry" -ForegroundColor DarkGreen
    }
}

if ($entriesToRemove.Count -gt 0) {
    Write-Host "  - 移除条目: $($entriesToRemove.Count)" -ForegroundColor Yellow
    foreach ($entry in $entriesToRemove) {
        Write-Host "    - $entry" -ForegroundColor DarkYellow
    }
}

if ($newEntries.Count -eq 0 -and $entriesToRemove.Count -eq 0) {
    Write-Host "  - 无需更改" -ForegroundColor Gray
}
