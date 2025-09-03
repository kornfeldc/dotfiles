Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -NoExit"
    exit
}

# --- Script continues here with admin rights ---
Write-Host "Running with Administrator privileges." -ForegroundColor Green

$homedir = $env:USERPROFILE
$dotfiles = "$homedir\source\repos\dotfiles"
$reposDir = "$homedir\Source\Repos"

# Function to safely handle file operations with intelligent backup/restore
function Create-SafeSymlink {
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Mode = "AUTO"  # AUTO, BACKUP, RESTORE
    )
    
    Write-Host "Processing: $SourcePath"
    
    # Determine operation mode if AUTO
    if ($Mode -eq "AUTO") {
        $sourceExists = Test-Path $SourcePath
        $targetExists = Test-Path $TargetPath
        
        if ($sourceExists -and !$targetExists) {
            $Mode = "BACKUP"
        }
        elseif (!$sourceExists -and $targetExists) {
            $Mode = "RESTORE"
        }
        elseif ($sourceExists -and $targetExists) {
            $Mode = "SYNC"
        }
        else {
            Write-Host "  Neither source nor target exists, skipping" -ForegroundColor Yellow
            return
        }
    }
    
    switch ($Mode) {
        "BACKUP" {
            Write-Host "  Mode: BACKUP - Moving file to dotfiles and creating symlink"
            # Ensure target directory exists
            $targetDir = Split-Path $TargetPath -Parent
            if (!(Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            # Check if source is already a symlink
            if (Test-Path $SourcePath -PathType Leaf) {
                $item = Get-Item $SourcePath
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    Write-Host "    Already a symlink, skipping move operation"
                } else {
                    Move-Item $SourcePath $TargetPath -ErrorAction SilentlyContinue
                }
            }
        }
        
        "RESTORE" {
            Write-Host "  Mode: RESTORE - Creating symlink from dotfiles"
            # Ensure source directory exists
            $sourceDir = Split-Path $SourcePath -Parent
            if (!(Test-Path $sourceDir)) {
                New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
            }
        }
        
        "SYNC" {
            Write-Host "  Mode: SYNC - Both exist, updating symlink"
            # In sync mode, we assume dotfiles version is authoritative
        }
    }
    
    # Create or recreate symlink
    Write-Host "  Creating symlink: $SourcePath -> $TargetPath"
    New-Item -ItemType SymbolicLink -Path $SourcePath -Target $TargetPath -Force
}

# Function to find and process all Rider run configurations
function Process-RiderRunConfigurations {
    param(
        [string]$ReposDirectory,
        [string]$DotfilesDirectory,
        [string]$Mode = "BACKUP"
    )
    
    Write-Host ""
    Write-Host "=== Rider Run Configurations ($Mode mode) ===" -ForegroundColor Cyan
    
    if ($Mode -eq "BACKUP") {
        if (!(Test-Path $ReposDirectory)) {
            Write-Host "Repos directory not found: $ReposDirectory" -ForegroundColor Yellow
            return
        }
        
        # Find all runConfigurations directories
        $runConfigPaths = Get-ChildItem -Path $ReposDirectory -Recurse -Directory -Name "runConfigurations" | 
                          ForEach-Object { Join-Path $ReposDirectory $_ }
        
        if ($runConfigPaths.Count -eq 0) {
            Write-Host "No runConfigurations directories found" -ForegroundColor Yellow
            return
        }
        
        Write-Host "Found $($runConfigPaths.Count) runConfigurations directories"
        
        foreach ($runConfigPath in $runConfigPaths) {
            # Extract project name from path
            $relativePath = $runConfigPath.Replace($ReposDirectory, "").TrimStart("\")
            $projectName = $relativePath.Split("\")[0]
            
            Write-Host "  Project: $projectName"
            
            # Get all XML files in the runConfigurations directory
            $configFiles = Get-ChildItem -Path $runConfigPath -Filter "*.xml" -File
            
            foreach ($configFile in $configFiles) {
                $targetPath = Join-Path $DotfilesDirectory "rider\runConfigurations\$projectName\$($configFile.Name)"
                Create-SafeSymlink $configFile.FullName $targetPath "BACKUP"
            }
        }
    }
    else {
        # RESTORE mode
        $riderConfigsPath = Join-Path $DotfilesDirectory "rider\runConfigurations"
        
        if (!(Test-Path $riderConfigsPath)) {
            Write-Host "No rider configurations found in dotfiles" -ForegroundColor Yellow
            return
        }
        
        # Get all project directories in dotfiles
        $projectDirs = Get-ChildItem -Path $riderConfigsPath -Directory
        
        Write-Host "Found configurations for $($projectDirs.Count) projects"
        
        foreach ($projectDir in $projectDirs) {
            $projectName = $projectDir.Name
            Write-Host "  Project: $projectName"
            
            # Check if project exists in repos
            $projectPath = Join-Path $ReposDirectory $projectName
            if (!(Test-Path $projectPath)) {
                Write-Host "    Project directory not found, skipping" -ForegroundColor Yellow
                continue
            }
            
            # Find or create the runConfigurations directory in the project
            $runConfigPath = Get-ChildItem -Path $projectPath -Recurse -Directory -Name "runConfigurations" | 
                             Select-Object -First 1 | 
                             ForEach-Object { Join-Path $projectPath $_ }
            
            if (!$runConfigPath) {
                Write-Host "    No runConfigurations directory found, skipping" -ForegroundColor Yellow
                continue
            }
            
            # Get all config files in dotfiles for this project
            $configFiles = Get-ChildItem -Path $projectDir.FullName -Filter "*.xml" -File
            
            foreach ($configFile in $configFiles) {
                $sourcePath = Join-Path $runConfigPath $configFile.Name
                Create-SafeSymlink $sourcePath $configFile.FullName "RESTORE"
            }
        }
    }
}

# Function to determine overall operation mode
function Get-OperationMode {
    # Check individual files
    $ideavimrcExists = Test-Path "$homedir\.ideavimrc"
    $ideavimrcInDotfiles = Test-Path "$dotfiles\ideavim\.ideavimrc"
    $ahkExists = Test-Path "$homedir\Documents\AutoHotkey\Untitled.ahk"
    $ahkInDotfiles = Test-Path "$dotfiles\ahk\Untitled.ahk"
    $ahkWbExists = Test-Path "$homedir\Documents\AutoHotkey\Windowborder.ahk"
    $ahkWbInDotfiles = Test-Path "$dotfiles\ahk\Windowborder.ahk"
    
    # Check Rider configs
    $hasRunConfigsInRepos = (Get-ChildItem -Path $reposDir -Recurse -Directory -Name "runConfigurations" -ErrorAction SilentlyContinue).Count -gt 0
    $riderConfigsPath = Join-Path $dotfiles "rider\runConfigurations"
    $hasRunConfigsInDotfiles = (Test-Path $riderConfigsPath) -and ((Get-ChildItem -Path $riderConfigsPath -Directory -ErrorAction SilentlyContinue).Count -gt 0)
    
    # Decision logic
    $filesInOriginalLocation = $ideavimrcExists -or $ahkExists -or $ahkWbExists -or $hasRunConfigsInRepos
    $filesInDotfiles = $ideavimrcInDotfiles -or $ahkInDotfiles -or $ahkWbInDotfiles -or $hasRunConfigsInDotfiles
    
    if ($filesInOriginalLocation -and !$filesInDotfiles) {
        return "BACKUP"    # First time backup
    }
    elseif (!$filesInOriginalLocation -and $filesInDotfiles) {
        return "RESTORE"   # Restore after PC reset
    }
    elseif ($filesInOriginalLocation -and $filesInDotfiles) {
        return "SYNC"      # Both exist, sync mode
    }
    else {
        return "NONE"      # Nothing found
    }
}

# Main execution
$mode = Get-OperationMode
Write-Host ""
Write-Host "=== Operation Mode: $mode ===" -ForegroundColor Cyan

switch ($mode) {
    "BACKUP" {
        Write-Host "Backing up all configurations to dotfiles..." -ForegroundColor Green
        
        # Individual files
        Create-SafeSymlink "$homedir\.ideavimrc" "$dotfiles\ideavim\.ideavimrc" "BACKUP"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Untitled.ahk" "$dotfiles\ahk\Untitled.ahk" "BACKUP"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Windowborder.ahk" "$dotfiles\ahk\Windowborder.ahk" "BACKUP"
        
        # Rider configurations
        Process-RiderRunConfigurations $reposDir $dotfiles "BACKUP"
    }
    
    "RESTORE" {
        Write-Host "Restoring all configurations from dotfiles..." -ForegroundColor Green
        
        # Individual files
        Create-SafeSymlink "$homedir\.ideavimrc" "$dotfiles\ideavim\.ideavimrc" "RESTORE"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Untitled.ahk" "$dotfiles\ahk\Untitled.ahk" "RESTORE"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Windowborder.ahk" "$dotfiles\ahk\Windowborder.ahk" "RESTORE"
        
        # Rider configurations
        Process-RiderRunConfigurations $reposDir $dotfiles "RESTORE"
    }
    
    "SYNC" {
        Write-Host "Synchronizing configurations..." -ForegroundColor Green
        
        # Individual files (AUTO mode will handle appropriately)
        Create-SafeSymlink "$homedir\.ideavimrc" "$dotfiles\ideavim\.ideavimrc"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Untitled.ahk" "$dotfiles\ahk\Untitled.ahk"
        Create-SafeSymlink "$homedir\Documents\AutoHotkey\Windowborder.ahk" "$dotfiles\ahk\Windowborder.ahk"
        
        # Rider configurations
        Process-RiderRunConfigurations $reposDir $dotfiles "BACKUP"
    }
    
    "NONE" {
        Write-Host "No configurations found in either location" -ForegroundColor Yellow
        Write-Host "Please ensure your dotfiles repository contains configurations, or create some configurations first" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Dotfiles setup completed! ===" -ForegroundColor Green

# Keep the window open so you can see the results
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

