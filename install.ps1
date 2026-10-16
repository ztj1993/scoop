$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$installerUrl = if ($env:SCOOP_INSTALLER_URL) {
    $env:SCOOP_INSTALLER_URL
} else {
    "https://get.scoop.sh"
}

. ([ScriptBlock]::Create((Invoke-RestMethod -Uri $installerUrl)))

$SCOOP_MAIN_BUCKET_GIT_REPO = if ($env:SCOOP_MAIN_BUCKET_GIT_REPO) {
    $env:SCOOP_MAIN_BUCKET_GIT_REPO
} else {
    "https://github.com/ztj1993/scoop.git"
}

$SCOOP_MAIN_BUCKET_REPO = if ($env:SCOOP_MAIN_BUCKET_REPO) {
    $env:SCOOP_MAIN_BUCKET_REPO
} else {
    "https://github.com/ztj1993/scoop/archive/master.zip"
}

if ($env:SCOOP_PACKAGE_GIT_REPO) {
    $SCOOP_PACKAGE_GIT_REPO = $env:SCOOP_PACKAGE_GIT_REPO
}

if ($env:SCOOP_PACKAGE_REPO) {
    $SCOOP_PACKAGE_REPO = $env:SCOOP_PACKAGE_REPO
}

Install-Scoop
