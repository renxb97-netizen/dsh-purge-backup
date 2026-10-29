#Requires -Version 5.1
<#
  dsh-purge-community v1.6.60 - offline restore script
  Usage: close DSH first, then right-click -> Run with PowerShell
#>
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dsh  = Join-Path $env:USERPROFILE ".dsh"
$prof = Join-Path $dsh "profiles\desktop"
$pkgCacheName = "f742c17f8f0bcd95501b7a4123c2283ebe2f135fe44ad1339fb928e0eeabc6c1"
$tgzName = "dsh-purge-community-1.6.60.tgz"

Write-Host "=== dsh-purge-community v1.6.60 restore ===" -ForegroundColor Cyan
Write-Host "backup : $here"
Write-Host "target : $dsh"

# 0) make sure DSH is not running
$running = Get-Process -Name "DeepSeekRuntime","dsh" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "[!] DSH is still running. Close it completely first." -ForegroundColor Red
    $running | Select-Object Id, ProcessName | Format-Table -AutoSize
    Read-Host "Press Enter to abort"
    exit 1
}

$srcTgz  = Join-Path $here "01-安装包\$tgzName"
$srcTree = Join-Path $here "02-已安装副本\dsh-purge-community"
if (-not (Test-Path $srcTgz))  { Write-Host "[!] missing $srcTgz" -ForegroundColor Red; Read-Host; exit 1 }
if (-not (Test-Path $srcTree)) { Write-Host "[!] missing $srcTree" -ForegroundColor Red; Read-Host; exit 1 }

# 1) restore tarball into the local package cache
$pkgDir = Join-Path $dsh "dsh-purge-community\pkgs\$pkgCacheName"
New-Item -ItemType Directory -Force -Path $pkgDir | Out-Null
Copy-Item $srcTgz (Join-Path $pkgDir $tgzName) -Force
Write-Host "[1/4] tarball restored -> $pkgDir"

# 2) restore the extracted plugin into node_modules
$nm  = Join-Path $prof "node_modules"
$dst = Join-Path $nm "dsh-purge-community"
New-Item -ItemType Directory -Force -Path $nm | Out-Null
if (Test-Path $dst) {
    $bak = "$dst.old-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    Move-Item $dst $bak -Force
    Write-Host "      existing plugin moved aside -> $bak"
}
Copy-Item $srcTree $nm -Recurse -Force
Write-Host "[2/4] plugin restored  -> $dst"

# 3) fix profile package.json (dependency path + bundles list)
$pkgJsonPath = Join-Path $prof "package.json"
if (-not (Test-Path $pkgJsonPath)) {
    '{"name":"dsh-profile-desktop","private":true,"dependencies":{},"dsh":{"profile":{"bundles":["@deepseek-ai/dsh-base","@deepseek-ai/dsh-web-app"]}}}' |
        Set-Content $pkgJsonPath -Encoding UTF8
}
$json = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
if (-not $json.dependencies) {
    $json | Add-Member -MemberType NoteProperty -Name dependencies -Value ([pscustomobject]@{})
}
$tgzForJson = (Join-Path $pkgDir $tgzName).Replace('\','/')
$dep = "file:$tgzForJson"
if ($json.dependencies.PSObject.Properties.Name -contains "dsh-purge-community") {
    $json.dependencies."dsh-purge-community" = $dep
} else {
    $json.dependencies | Add-Member -MemberType NoteProperty -Name "dsh-purge-community" -Value $dep
}
if (-not $json.dsh) {
    $json | Add-Member -MemberType NoteProperty -Name dsh -Value ([pscustomobject]@{ profile = [pscustomobject]@{ bundles = @() } })
}
$bundles = @($json.dsh.profile.bundles)
if ($bundles -notcontains "dsh-purge-community") {
    $bundles += "dsh-purge-community"
    $json.dsh.profile.bundles = $bundles
}
$json | ConvertTo-Json -Depth 12 | Set-Content $pkgJsonPath -Encoding UTF8
Write-Host "[3/4] package.json updated (dependency + bundles)"

# 4) restore runtime state (only when missing)
$stateSrc = Join-Path $here "04-运行状态"
if (Test-Path $stateSrc) {
    New-Item -ItemType Directory -Force -Path (Join-Path $dsh "dsh-purge") | Out-Null
    Get-ChildItem $stateSrc -File | ForEach-Object {
        $target = Join-Path (Join-Path $dsh "dsh-purge") $_.Name
        if ($_.Name -eq "prompt-inject.md") { $target = Join-Path $dsh "prompt-inject.md" }
        if (-not (Test-Path $target)) { Copy-Item $_.FullName $target -Force }
    }
    Write-Host "[4/4] runtime state restored (missing files only)"
}

# verify
$ok = Test-Path (Join-Path $dst "package.json")
$ver = if ($ok) { (Get-Content (Join-Path $dst "package.json") -Raw | ConvertFrom-Json).version } else { "?" }
Write-Host ""
if ($ok) {
    Write-Host "OK  plugin v$ver restored." -ForegroundColor Green
    Write-Host "Next: start DSH, then ask it to run  purge_status  (expect 80 patch status)."
} else {
    Write-Host "FAILED - plugin folder incomplete." -ForegroundColor Red
}
Read-Host "Press Enter to exit"
