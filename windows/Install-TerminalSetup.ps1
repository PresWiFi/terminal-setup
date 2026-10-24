#Requires -Version 5.1
<#
.SYNOPSIS
Sets up Windows Terminal from the unknown-technology.com "Terminal could look THIS good" guide:
Oh My Posh (M365Princess), Meslo Nerd Font, F-14 fastfetch, btop, acrylic transparency,
and the Iceberg Light / Calamity color schemes. Safe to re-run. Runs in pwsh 7 or Windows PowerShell 5.1.
.PARAMETER Opacity
Terminal background opacity (0-100). Lower is more see-through.
.PARAMETER NoWinget
Skip winget and install portable builds from GitHub into %LOCALAPPDATA%\Programs\TerminalTools.
This also happens automatically when winget is missing or fails. No admin rights needed.
#>
param(
    [ValidateRange(0, 100)][int]$Opacity = 90,
    [switch]$NoWinget
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # 5.1's Invoke-WebRequest is very slow with the progress bar
. (Join-Path $PSScriptRoot 'TerminalTheme.ps1')

$toolsRoot = Join-Path $env:LOCALAPPDATA 'Programs\TerminalTools'
$tools = @(
    @{ Command = 'oh-my-posh'; WingetId = 'JanDeDobbeleer.OhMyPosh'; Repo = 'JanDeDobbeleer/oh-my-posh'; Asset = 'posh-windows-amd64.exe' }
    @{ Command = 'fastfetch'; WingetId = 'Fastfetch-cli.Fastfetch'; Repo = 'fastfetch-cli/fastfetch'; Asset = 'fastfetch-windows-amd64.zip' }
    @{ Command = 'btop'; WingetId = 'aristocratos.btop4win'; Repo = 'aristocratos/btop4win'; Asset = 'btop4win-x64.zip' }
)

function Add-UserPath([string]$Dir) {
    $userPath = "$([Environment]::GetEnvironmentVariable('Path', 'User'))".TrimEnd(';')
    if (($userPath -split ';') -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$Dir".TrimStart(';'), 'User')
    }
    if (($env:Path -split ';') -notcontains $Dir) { $env:Path += ";$Dir" }
}

function Install-FromGitHub($Tool) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    [Net.WebRequest]::DefaultWebProxy.Credentials = [Net.CredentialCache]::DefaultNetworkCredentials

    $dir = Join-Path $toolsRoot $Tool.Command
    $download = Join-Path $env:TEMP $Tool.Asset
    Write-Host "Downloading $($Tool.Asset) from GitHub"
    Invoke-WebRequest "https://github.com/$($Tool.Repo)/releases/latest/download/$($Tool.Asset)" -OutFile $download -UseBasicParsing
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if ($Tool.Asset -like '*.zip') {
        Expand-Archive -LiteralPath $download -DestinationPath $dir -Force
        Remove-Item -LiteralPath $download
    } else {
        Move-Item -LiteralPath $download -Destination (Join-Path $dir "$($Tool.Command).exe") -Force
    }
    # btop4win ships as btop4win\btop4win.exe; give it the same `btop` name winget does.
    if ($Tool.Command -eq 'btop') { Set-Content -LiteralPath (Join-Path $dir 'btop.cmd') -Value '@"%~dp0btop4win\btop4win.exe" %*' -Encoding Ascii }

    Add-UserPath $dir
}

# 1. Tools: winget when it works, otherwise portable GitHub builds
$useWinget = -not $NoWinget -and (Get-Command winget -ErrorAction SilentlyContinue)
foreach ($tool in $tools) {
    if (Get-Command $tool.Command -ErrorAction SilentlyContinue) { Write-Host "$($tool.Command) already installed"; continue }

    if ($useWinget) {
        winget install --id $tool.WingetId -e --source winget --accept-package-agreements --accept-source-agreements
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        if (Get-Command $tool.Command -ErrorAction SilentlyContinue) { continue }
        Write-Warning "winget couldn't install $($tool.Command); falling back to GitHub"
    }
    Install-FromGitHub $tool
}

# 2. Nerd Font (per-user, no admin)
oh-my-posh font install meslo

# 3. Windows Terminal: schemes, font, transparency
try {
    $settingsPath = Get-WTSettingsPath
    Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"

    $settings = Read-WTSettings
    $newSchemes = Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'shared/schemes.json') -Raw | ConvertFrom-Json
    $schemes = @($settings.schemes | Where-Object { $_.name -notin $newSchemes.name }) + @($newSchemes)
    $settings | Add-Member -NotePropertyName schemes -NotePropertyValue $schemes -Force

    Set-WTDefault $settings 'font' ([pscustomobject]@{ face = 'MesloLGM Nerd Font' })
    Set-WTDefault $settings 'opacity' $Opacity
    Set-WTDefault $settings 'useAcrylic' $true
    if (-not $settings.profiles.defaults.colorScheme) { Set-WTDefault $settings 'colorScheme' $TerminalThemes.light }
    Save-WTSettings $settings
    Write-Host "Windows Terminal configured. Backup saved next to $settingsPath"
} catch {
    Write-Warning "Skipped Windows Terminal settings: $($_.Exception.Message)"
}

# 4. PowerShell profiles (pwsh 7 and Windows PowerShell 5.1)
$line = ". '$(Join-Path $PSScriptRoot 'profile.ps1')'"
$documents = [Environment]::GetFolderPath('MyDocuments')
foreach ($profilePath in 'PowerShell', 'WindowsPowerShell' | ForEach-Object { Join-Path $documents "$_\Microsoft.PowerShell_profile.ps1" }) {
    if (-not (Test-Path -LiteralPath $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }
    if (-not (Select-String -LiteralPath $profilePath -SimpleMatch $line -Quiet)) { Add-Content -LiteralPath $profilePath $line }
}

# 5.1 defaults to Restricted on Windows clients, which blocks profiles. Match pwsh 7's default.
# Process scope is skipped: it only reflects how this installer was launched.
$getWinPsPolicy = @'
$p = 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine' |
    ForEach-Object { Get-ExecutionPolicy -Scope $_ } | Where-Object { $_ -ne 'Undefined' } | Select-Object -First 1
if ($p) { "$p" } else { 'Restricted' }
'@
if ((powershell.exe -NoProfile -Command $getWinPsPolicy) -eq 'Restricted') {
    # Throws ExecutionPolicyOverride when launched with -ExecutionPolicy Bypass, though the setting still saves.
    powershell.exe -NoProfile -Command 'try { Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force -ErrorAction Stop } catch [System.Security.SecurityException] {}'
    Write-Host 'Windows PowerShell 5.1 execution policy set to RemoteSigned (CurrentUser)'
}
$policy = powershell.exe -NoProfile -Command $getWinPsPolicy
if ($policy -in 'Restricted', 'AllSigned') {
    Write-Warning "Execution policy is $policy (likely Group Policy), so the profile won't load in Windows PowerShell 5.1."
}

Write-Host "`nDone. Open a new terminal tab."
