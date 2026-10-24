# Dot-sourced from $PROFILE by Install-TerminalSetup.ps1. Edits here apply to every new tab.

. (Join-Path $PSScriptRoot 'TerminalTheme.ps1')
$TerminalSetupShared = Join-Path (Split-Path $PSScriptRoot) 'shared'

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config (Join-Path $TerminalSetupShared 'M365Princess.omp.json') | Invoke-Expression
}

# Shows the F-14 fastfetch screen. Runs on startup; type `ff` to show it again.
function ff {
    $env:FASTFETCH_F14_ROOT = Join-Path $TerminalSetupShared 'fastfetch'
    fastfetch --config (Join-Path $env:FASTFETCH_F14_ROOT 'config.jsonc')
}

$isInteractive = -not ([Environment]::GetCommandLineArgs() -match '^-NonI')
if ($isInteractive -and $env:TERM_PROGRAM -ne 'vscode' -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    ff
}
