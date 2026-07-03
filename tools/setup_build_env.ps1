<#
.SYNOPSIS
    Automated setup script for the KoK3 WE Engine decompilation build environment.
    
.DESCRIPTION
    This script helps set up a Windows machine (or VM) as a build environment
    for compiling the decompiled WE Engine source code with the original toolchain.
    
    It validates the required tools are installed and configures paths.
    
.NOTES
    Required software (must be installed manually — this script validates):
    - Visual Studio 2005 Professional or Team Edition
    - Visual Studio 2005 SP1 (KB926601)
    - DirectX SDK (June 2006 or later)
    - Platform SDK for Windows Server 2003 SP1 (or Windows SDK 6.0)
    
    The script also optionally sets up the machine as a GitHub Actions self-hosted runner.
#>

param(
    [switch]$SetupRunner,
    [string]$GitHubRepo,
    [string]$RunnerToken
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " KoK3 WE Engine Build Environment Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# --- Check Visual Studio 2005 ---
Write-Host "[1/5] Checking Visual Studio 2005..." -ForegroundColor Yellow

$vs2005Paths = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio 8",
    "${env:ProgramFiles}\Microsoft Visual Studio 8"
)

$vs2005Found = $false
$vs2005Path = ""
foreach ($p in $vs2005Paths) {
    if (Test-Path "$p\VC\vcvarsall.bat") {
        $vs2005Found = $true
        $vs2005Path = $p
        break
    }
}

if ($vs2005Found) {
    Write-Host "  [OK] Found VS 2005 at: $vs2005Path" -ForegroundColor Green
    
    # Check SP1
    $clPath = "$vs2005Path\VC\bin\cl.exe"
    if (Test-Path $clPath) {
        $clVersion = (Get-Item $clPath).VersionInfo.FileVersion
        Write-Host "  cl.exe version: $clVersion" -ForegroundColor Gray
        if ($clVersion -match "14\.00\.50727") {
            Write-Host "  [OK] VS 2005 SP1 confirmed (build 50727)" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] cl.exe version doesn't match SP1 (expected 14.00.50727.x)" -ForegroundColor Yellow
            Write-Host "     Install VS 2005 SP1 (KB926601)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [ERROR] Visual Studio 2005 NOT FOUND" -ForegroundColor Red
    Write-Host "     Install Visual Studio 2005 Professional + SP1" -ForegroundColor Red
    Write-Host "     Expected at: ${env:ProgramFiles(x86)}\Microsoft Visual Studio 8" -ForegroundColor Gray
}

# --- Check DirectX SDK ---
Write-Host ""
Write-Host "[2/5] Checking DirectX SDK..." -ForegroundColor Yellow

$dxsdkPaths = @(
    $env:DXSDK_DIR,
    "${env:ProgramFiles(x86)}\Microsoft DirectX SDK (June 2006)",
    "${env:ProgramFiles(x86)}\Microsoft DirectX SDK (February 2006)",
    "${env:ProgramFiles(x86)}\Microsoft DirectX SDK (August 2006)",
    "${env:ProgramFiles(x86)}\Microsoft DirectX SDK"
)

$dxsdkFound = $false
foreach ($p in ($dxsdkPaths | Where-Object { $_ })) {
    if (Test-Path "$p\Include\d3dx9.h") {
        $dxsdkFound = $true
        Write-Host "  [OK] Found DirectX SDK at: $p" -ForegroundColor Green
        break
    }
}

if (-not $dxsdkFound) {
    Write-Host "  [ERROR] DirectX SDK NOT FOUND" -ForegroundColor Red
    Write-Host "     Install DirectX SDK (June 2006 or later)" -ForegroundColor Red
    Write-Host "     The binary uses d3dx9_30.dll - ensure your SDK version includes this" -ForegroundColor Gray
}

# --- Check Platform SDK ---
Write-Host ""
Write-Host "[3/5] Checking Platform SDK..." -ForegroundColor Yellow

$sdkPaths = @(
    "${env:ProgramFiles}\Microsoft Platform SDK",
    "${env:ProgramFiles(x86)}\Microsoft Platform SDK",
    "${env:ProgramFiles}\Microsoft SDKs\Windows\v6.0",
    "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v6.0"
)

$sdkFound = $false
foreach ($p in $sdkPaths) {
    if (Test-Path "$p\Include\Windows.h") {
        $sdkFound = $true
        Write-Host "  [OK] Found Platform SDK at: $p" -ForegroundColor Green
        break
    }
}

if (-not $sdkFound) {
    Write-Host "  [WARN] Platform SDK not found (VS 2005 includes basic headers)" -ForegroundColor Yellow
    Write-Host "     For complete compatibility, install Windows Server 2003 SP1 SDK" -ForegroundColor Gray
}

# --- Check Git ---
Write-Host ""
Write-Host "[4/5] Checking Git..." -ForegroundColor Yellow

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    $gitVersion = & git --version
    Write-Host "  [OK] Git found: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Git NOT FOUND" -ForegroundColor Red
    Write-Host "     Install Git from https://git-scm.com/" -ForegroundColor Red
}

# --- Summary ---
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$allGood = $vs2005Found -and $dxsdkFound -and $gitCmd
if ($allGood) {
    Write-Host "  [OK] All required tools found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To build the project:" -ForegroundColor White
    Write-Host "    1. Open a VS 2005 Command Prompt" -ForegroundColor Gray
    Write-Host "    2. cd to the project directory" -ForegroundColor Gray
    Write-Host "    3. Run: msbuild WE.sln /p:Configuration=Debug" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Some tools are missing. See above for details." -ForegroundColor Yellow
}

# --- Optional: GitHub Actions Runner Setup ---
if ($SetupRunner) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host " GitHub Actions Runner Setup" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    if (-not $GitHubRepo -or -not $RunnerToken) {
        Write-Host "  [ERROR] -GitHubRepo and -RunnerToken are required for runner setup" -ForegroundColor Red
        Write-Host "  Usage: .\setup_build_env.ps1 -SetupRunner -GitHubRepo 'owner/repo' -RunnerToken 'TOKEN'" -ForegroundColor Gray
        exit 1
    }
    
    $runnerDir = "C:\actions-runner"
    
    Write-Host "  Setting up runner at: $runnerDir" -ForegroundColor White
    
    if (-not (Test-Path $runnerDir)) {
        New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
    }
    
    # Download latest runner
    Write-Host "  Downloading GitHub Actions runner..." -ForegroundColor Gray
    $runnerUrl = "https://github.com/actions/runner/releases/download/v2.335.1/actions-runner-win-x64-2.335.1.zip"
    $runnerZip = "$runnerDir\actions-runner.zip"
    
    if (-not (Test-Path "$runnerDir\config.cmd")) {
        Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip
        Expand-Archive -Path $runnerZip -DestinationPath $runnerDir -Force
        Remove-Item $runnerZip
    }
    
    # Configure runner
    Write-Host "  Configuring runner for $GitHubRepo..." -ForegroundColor Gray
    Push-Location $runnerDir
    & .\config.cmd --url "https://github.com/$GitHubRepo" --token $RunnerToken --name "kok3-vs2005-builder" --labels "self-hosted,windows,vs2005" --runasservice
    Pop-Location
    
    Write-Host "  [OK] Runner configured and registered!" -ForegroundColor Green
    Write-Host "  The runner will start automatically as a Windows service." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Cyan
