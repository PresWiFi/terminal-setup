# Windows Terminal helpers shared by profile.ps1 and Install-TerminalSetup.ps1.
# Works in both pwsh 7 and Windows PowerShell 5.1.

$TerminalThemes = @{ light = 'Iceberg Light'; dark = 'Calamity' }

function Get-WTSettingsPath {
    $candidates = @(
        'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
        'Microsoft\Windows Terminal\settings.json'  # unpackaged install
    ) | ForEach-Object { Join-Path $env:LOCALAPPDATA $_ }
    $path = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $path) { throw 'Windows Terminal settings.json not found. Open Windows Terminal once, then re-run.' }
    $path
}

function Read-WTSettings {
    $json = Get-Content -LiteralPath (Get-WTSettingsPath) -Raw
    # 5.1's ConvertFrom-Json rejects comments; drop whole-line // comments.
    if ($PSVersionTable.PSVersion.Major -lt 7) { $json = $json -replace '(?m)^\s*//.*$', '' }
    $json | ConvertFrom-Json
}

function Save-WTSettings($Settings) {
    # 5.1 wraps arrays as {"value":[...],"Count":n} unless this type data is removed.
    if ($PSVersionTable.PSVersion.Major -lt 7) { Remove-TypeData System.Array -ErrorAction SilentlyContinue }
    $json = $Settings | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText((Get-WTSettingsPath), $json, (New-Object Text.UTF8Encoding $false))
}

function Set-WTDefault($Settings, [string]$Name, $Value) {
    if (-not $Settings.profiles.defaults) {
        $Settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $Settings.profiles.defaults | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

<#
.SYNOPSIS
Switches Windows Terminal between Iceberg Light and Calamity. No argument toggles.
.EXAMPLE
theme light
#>
function Set-TerminalTheme {
    param([ValidateSet('light', 'dark', 'toggle')][string]$Mode = 'toggle')

    $settings = Read-WTSettings
    if ($Mode -eq 'toggle') {
        $Mode = if ($settings.profiles.defaults.colorScheme -eq $TerminalThemes.light) { 'dark' } else { 'light' }
    }
    Set-WTDefault $settings 'colorScheme' $TerminalThemes[$Mode]
    Save-WTSettings $settings
    Write-Host "Terminal theme: $($TerminalThemes[$Mode])"
}

Set-Alias -Name theme -Value Set-TerminalTheme
