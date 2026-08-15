param(
    [Parameter(Mandatory=$true, HelpMessage="Full path to the MT5 Data Folder (e.g. C:\Users\User\AppData\Roaming\MetaQuotes\Terminal\...)")]
    [string]$Mt5DataFolder
)

$ErrorActionPreference = "Stop"

# Project root directory (where this script is located)
$ProjectRoot = $PSScriptRoot

# Source directories in the project
$SourceInclude = Join-Path $ProjectRoot "MQL5\Include\SyntheticTestHarness"
$SourceScripts = Join-Path $ProjectRoot "MQL5\Scripts\SyntheticTestHarness"

# Target directories in MT5
$TargetInclude = Join-Path $Mt5DataFolder "MQL5\Include\SyntheticTestHarness"
$TargetScripts = Join-Path $Mt5DataFolder "MQL5\Scripts\SyntheticTestHarness"

function Create-MkLink {
    param(
        [string]$Target,
        [string]$Source
    )
    
    if (Test-Path $Target) {
        Write-Host "Symlink or folder already exists at: $Target" -ForegroundColor Yellow
        return
    }

    # Verify if source directory actually exists in the project
    if (-not (Test-Path $Source)) {
        Write-Host "Warning: Source directory not found ($Source)" -ForegroundColor Red
        return
    }

    # Create parent folder in destination if it does not exist (e.g. ensures MQL5\Include exists)
    $ParentDir = Split-Path $Target -Parent
    if (-not (Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir | Out-Null
    }

    Write-Host "Creating symlink: $Target -> $Source" -ForegroundColor Cyan
    
    # Executes cmd mklink (may require running as Administrator depending on Windows settings,
    # although Windows 10/11 with Developer Mode enabled does not require it).
    $cmd = "cmd /c mklink /D `"$Target`" `"$Source`""
    Invoke-Expression $cmd
}

Write-Host "Installing symbolic links..." -ForegroundColor Green

Create-MkLink -Target $TargetInclude -Source $SourceInclude
Create-MkLink -Target $TargetScripts -Source $SourceScripts

Write-Host "Done!" -ForegroundColor Green
