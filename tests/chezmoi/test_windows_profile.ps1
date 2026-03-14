Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-FileExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "missing file: $Path"
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $content = Get-Content -Raw -LiteralPath $Path
    if ($content -notmatch [regex]::Escape($Pattern)) {
        throw $Message
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$baseline = Join-Path $repoRoot "home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl"
$profileV7 = Join-Path $repoRoot "home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl"
$profileV5 = Join-Path $repoRoot "home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl"
$baseInstall = Join-Path $repoRoot "run_once_before_10-install-base-packages.ps1.tmpl"

Assert-FileExists -Path $baseline
Assert-FileExists -Path $profileV7
Assert-FileExists -Path $profileV5
Assert-FileExists -Path $baseInstall

Assert-Contains -Path $baseline -Pattern '$optionalModules = @("Terminal-Icons", "ZLocation", "PSFzf")' -Message "public baseline missing module list"
Assert-Contains -Path $baseline -Pattern 'starship init powershell' -Message "public baseline missing starship init"
Assert-Contains -Path $baseline -Pattern '$ProfileScope = if ($PSVersionTable.PSVersion.Major -ge 7)' -Message "public baseline missing profile scope switch"

Assert-Contains -Path $profileV7 -Pattern 'Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"' -Message "pwsh7 profile missing baseline path"
Assert-Contains -Path $profileV5 -Pattern 'Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"' -Message "pwsh5 profile missing baseline path"
Assert-Contains -Path $profileV7 -Pattern ". $baselinePath" -Message "pwsh7 profile missing baseline source"
Assert-Contains -Path $profileV5 -Pattern ". $baselinePath" -Message "pwsh5 profile missing baseline source"

Assert-Contains -Path $baseInstall -Pattern '$modules = @("Terminal-Icons", "ZLocation", "PSFzf")' -Message "windows base install missing module parity"
Assert-Contains -Path $baseInstall -Pattern 'Documents\PowerShell' -Message "windows base install missing PowerShell 7 profile dir"
Assert-Contains -Path $baseInstall -Pattern 'Documents\WindowsPowerShell' -Message "windows base install missing PowerShell 5.1 profile dir"

Write-Host "task5 windows profile checks: ok"
