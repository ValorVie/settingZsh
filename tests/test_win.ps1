# =============================================================================
# Windows 環境測試腳本
# 測試 setup_win.ps1 / update_win.ps1 的各項功能
# 使用方式：
#   pwsh -NoProfile -ExecutionPolicy Bypass -File tests\test_win.ps1
# =============================================================================

$ErrorActionPreference = "Continue"
$Pass = 0; $Fail = 0; $Warn = 0

function Test-Pass($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green; $script:Pass++ }
function Test-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:Fail++ }
function Test-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:Warn++ }

Write-Host "=== Windows 環境測試 ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)"
Write-Host "OS: $([Environment]::OSVersion.VersionString)"
Write-Host ""

# --- Test 1: PS Version & Profile Path ---
Write-Host "--- Test 1: PS 版本與 Profile 路徑 ---"
$PSMajor = $PSVersionTable.PSVersion.Major
if ($PSMajor -ge 7) {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    Test-Pass "PS $PSMajor (7+) -> $ProfileDir"
} else {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell"
    Test-Pass "PS $PSMajor (5.1) -> $ProfileDir"
}

# --- Test 2: Source Profile ---
Write-Host "--- Test 2: Source Profile ---"
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$SourceProfile = Join-Path $ScriptDir "Windows-Powershell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $SourceProfile) {
    Test-Pass "Source Profile exists: $SourceProfile"
} else {
    Test-Fail "Source Profile MISSING: $SourceProfile"
}

# --- Test 3: Profile dynamic paths ---
Write-Host "--- Test 3: Profile 動態路徑 ---"
if (Test-Path $SourceProfile) {
    $content = Get-Content $SourceProfile -Raw
    if ($content -match 'C:\\Users\\jack3') {
        Test-Fail "Profile 仍有寫死路徑 (C:\Users\jack3)"
    } else {
        Test-Pass "Profile 使用動態路徑 (`$env:USERPROFILE)"
    }
}

# --- Test 4: winget ---
Write-Host "--- Test 4: winget ---"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Test-Pass "winget available"
} else {
    Test-Warn "winget NOT found"
}

# --- Test 5: Modules ---
Write-Host "--- Test 5: PowerShell 模組 ---"
@("Terminal-Icons", "ZLocation", "PSFzf") | ForEach-Object {
    if (Get-Module -ListAvailable $_ -ErrorAction SilentlyContinue) {
        Test-Pass "$_ installed"
    } else {
        Test-Warn "$_ NOT installed"
    }
}

# --- Test 6: Font URL ---
Write-Host "--- Test 6: 字型下載 URL ---"
$MapleVersion = "v7.9"
$MapleArchive = "MapleMonoNL-NF-CN.zip"
$MapleUrl = "https://github.com/subframe7536/maple-font/releases/download/$MapleVersion/$MapleArchive"
try {
    $resp = Invoke-WebRequest -Uri $MapleUrl -Method Head -UseBasicParsing -ErrorAction Stop
    Test-Pass "Font URL HTTP $($resp.StatusCode): $MapleArchive"
} catch {
    Test-Fail "Font URL FAILED: $MapleArchive"
}

# --- Test 7: Font install path ---
Write-Host "--- Test 7: 字型安裝路徑 ---"
$UserFontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
if (Test-Path $UserFontDir) {
    Test-Pass "Font dir exists: $UserFontDir"
} else {
    Test-Warn "Font dir missing (will be created during install)"
}

# --- Test 8: Font registry ---
Write-Host "--- Test 8: 字型登錄檔 ---"
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
if (Test-Path $RegPath) {
    Test-Pass "Registry path exists: $RegPath"
} else {
    Test-Warn "Registry path missing"
}

# --- Test 9: setup_win.ps1 font archive name check ---
Write-Host "--- Test 9: setup_win.ps1 字型檔名 ---"
$SetupScript = Join-Path $ScriptDir "setup_win.ps1"
if (Test-Path $SetupScript) {
    $setupContent = Get-Content $SetupScript -Raw
    if ($setupContent -match 'MapleMonoNL-NF-CN\.zip') {
        Test-Pass "setup_win.ps1 uses correct archive name"
    } else {
        Test-Fail "setup_win.ps1 has wrong archive name"
    }
}

# --- Test 10: update_win.ps1 font archive name check ---
Write-Host "--- Test 10: update_win.ps1 字型檔名 ---"
$UpdateScript = Join-Path $ScriptDir "update_win.ps1"
if (Test-Path $UpdateScript) {
    $updateContent = Get-Content $UpdateScript -Raw
    if ($updateContent -match 'MapleMonoNL-NF-CN\.zip') {
        Test-Pass "update_win.ps1 uses correct archive name"
    } else {
        Test-Fail "update_win.ps1 has wrong archive name"
    }
}

# --- Summary ---
Write-Host ""
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "  PASS: $Pass" -ForegroundColor Green
Write-Host "  FAIL: $Fail" -ForegroundColor $(if ($Fail -gt 0) { "Red" } else { "Green" })
Write-Host "  WARN: $Warn" -ForegroundColor $(if ($Warn -gt 0) { "Yellow" } else { "Green" })
Write-Host "===============================" -ForegroundColor Cyan
if ($Fail -gt 0) {
    Write-Host "  Result: FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  Result: PASSED" -ForegroundColor Green
}
