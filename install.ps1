$ErrorActionPreference = "Stop"

$ForceScoop = [bool]$env:FORCE_SCOOP
$ForceMainBucket = [bool]$env:FORCE_MAIN_BUCKET

function Install-Scoop {
    param([switch]$Force)

    $repo = if ($env:SCOOP_PACKAGE_REPO) {
        $env:SCOOP_PACKAGE_REPO
    } else {
        "https://github.com/ScoopInstaller/Scoop/archive/master.zip"
    }
    $appDir = if ($env:SCOOP_APP_DIR) {
        $env:SCOOP_APP_DIR
    } else {
        "$env:USERPROFILE\scoop\apps\scoop\current"
    }

    if (!$Force -and (Test-Path "$appDir\lib\core.ps1")) {
        Write-Host "Scoop already installed, skipping."
        return
    }

    New-Item -ItemType Directory -Path "$appDir" -Force
    $zipfile = "$appDir\scoop.zip"
    Invoke-WebRequest -Uri $repo -OutFile $zipfile
    $tempDir = "$appDir\_tmp"
    Expand-Archive -Path $zipfile -DestinationPath $tempDir
    Copy-Item "$tempDir\scoop-*\*" $appDir -Recurse -Force
    Remove-Item $tempDir -Recurse -Force
    Remove-Item $zipfile
}

function Install-ScoopMainBucket {
    param([switch]$Force)

    $repo = if ($env:SCOOP_MAIN_BUCKET_REPO) {
        $env:SCOOP_MAIN_BUCKET_REPO
    } else {
        "https://github.com/ztj1993/scoop/archive/master.zip"
    }
    $bucketDir = if ($env:SCOOP_MAIN_BUCKET_DIR) {
        $env:SCOOP_MAIN_BUCKET_DIR
    } else {
        "$env:USERPROFILE\scoop\buckets\main"
    }

    if (!$Force -and (Test-Path "$bucketDir\bucket")) {
        Write-Host "Scoop main bucket already installed, skipping."
        return
    }

    New-Item -ItemType Directory -Path "$bucketDir" -Force
    $zipfile = "$bucketDir\scoop.zip"
    Invoke-WebRequest -Uri $repo -OutFile $zipfile
    $tempDir = "$bucketDir\_tmp"
    Expand-Archive -Path $zipfile -DestinationPath $tempDir
    Copy-Item "$tempDir\scoop-*\*" $bucketDir -Recurse -Force
    Remove-Item $tempDir -Recurse -Force
    Remove-Item $zipfile
}

Install-Scoop -Force:$ForceScoop
Install-ScoopMainBucket -Force:$ForceMainBucket

.$env:USERPROFILE\scoop\apps\scoop\current\lib\system.ps1
.$env:USERPROFILE\scoop\apps\scoop\current\bin\refresh.ps1
