param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppName,

    [Parameter(Position = 1)]
    [string]$Prefix = "https://ghfast.top/",

    [switch]$Remove,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$bucketRoot = (Resolve-Path "$PSScriptRoot\..").Path

$manifestPath = @(
    "$bucketRoot\bucket\$AppName.json",
    "$bucketRoot\deprecated\$AppName.json"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $manifestPath) {
    Write-Error "Manifest for '$AppName' not found."
    exit 1
}

Write-Host "Found manifest: $manifestPath"

$manifest = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Update-Url {
    param($Url)
    if ($Url -is [array]) {
        return $Url | ForEach-Object { Update-Url $_ }
    }
    if ($Url -is [string]) {
        if ($Remove) {
            return $Url -replace "^$([regex]::Escape($Prefix))", ""
        } else {
            if (-not $Url.StartsWith($Prefix)) {
                return "$Prefix$Url"
            }
            return $Url
        }
    }
    return $Url
}

function Update-UrlField {
    param($Obj, [string]$FieldName = "url")
    if ($null -eq $Obj) { return }
    $props = $Obj.PSObject.Properties
    foreach ($prop in $props) {
        if ($prop.Name -eq $FieldName -and $null -ne $prop.Value) {
            $prop.Value = Update-Url $prop.Value
        }
    }
}

function Update-ArchitectureUrls {
    param($Arch)
    if ($null -eq $Arch) { return }
    foreach ($key in $Arch.PSObject.Properties.Name) {
        $section = $Arch.$key
        if ($null -ne $section.url) {
            $section.url = Update-Url $section.url
        }
    }
}

if ($manifest.url) {
    $manifest.url = Update-Url $manifest.url
}

if ($manifest.architecture) {
    Update-ArchitectureUrls $manifest.architecture
}

if ($manifest.autoupdate -and $manifest.autoupdate.architecture) {
    Update-ArchitectureUrls $manifest.autoupdate.architecture
}

if ($manifest.autoupdate -and $manifest.autoupdate.url) {
    $manifest.autoupdate.url = Update-Url $manifest.autoupdate.url
}

$json = $manifest | ConvertTo-Json -Depth 20
$json = $json -replace "`r`n", "`n"
$json = $json -replace '\\u0027', "'"

if ($DryRun) {
    Write-Host "`n--- Dry Run: Preview of changes ---`n" -ForegroundColor Yellow
    Write-Host $json
    Write-Host "`n--- End Preview ---`n" -ForegroundColor Yellow
} else {
    Set-Content -Path $manifestPath -Value $json -Encoding UTF8 -NoNewline
    $action = if ($Remove) { "removed prefix from" } else { "added prefix to" }
    Write-Host "Successfully $action URLs in '$AppName'." -ForegroundColor Green
}
