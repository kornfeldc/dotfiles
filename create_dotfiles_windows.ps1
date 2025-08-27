Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script as Administrator..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- Script continues here with admin rights ---
Write-Host "Running with Administrator privileges."

$homedir = $env:USERPROFILE
$dotfiles = "$homedir\source\repos\dotfiles"
$reposDir = "$homedir\Source\Repos"

# Function to safely handle file operations
function Create-SafeSymlink {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    Write-Host "Processing: $SourcePath"
    
    # Check if source is already a symlink
    if (Test-Path $SourcePath -PathType Leaf) {
        $item = Get-Item $SourcePath
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "  Already a symlink, skipping move operation"
        } else {
            Write-Host "  Moving original file to dotfiles"
            # Ensure target directory exists
            $targetDir = Split-Path $TargetPath -Parent
            if (!(Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Move-Item $SourcePath $TargetPath -ErrorAction SilentlyContinue
        }
    }
    
    # Create or recreate symlink
    Write-Host "  Creating symlink"
    New-Item -ItemType SymbolicLink -Path $SourcePath -Target $TargetPath -Force
}

# Function to find and process all Rider run configurations
function Process-RiderRunConfigurations {
    param(
        [string]$ReposDirectory,
        [string]$DotfilesDirectory
    )
    
    Write-Host ""
    Write-Host "=== Scanning for Rider Run Configurations ===" -ForegroundColor Cyan
    
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
    
    Write-Host "Found $($runConfigPaths.Count) runConfigurations directories:" -ForegroundColor Green
    
    foreach ($runConfigPath in $runConfigPaths) {
        Write-Host "  $runConfigPath" -ForegroundColor Gray
        
        # Extract project name from path
        # C:\Users\christian.kornfeld\Source\Repos\ICM6\.idea\.idea.ICM6\.idea\runConfigurations
        $relativePath = $runConfigPath.Replace($ReposDirectory, "").TrimStart("\")
        $projectName = $relativePath.Split("\")[0]
        
        Write-Host "    Project: $projectName" -ForegroundColor Gray
        
        # Get all XML files in the runConfigurations directory
        $configFiles = Get-ChildItem -Path $runConfigPath -Filter "*.xml" -File
        
        if ($configFiles.Count -eq 0) {
            Write-Host "    No XML configuration files found" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "    Found $($configFiles.Count) configuration files" -ForegroundColor Green
        
        foreach ($configFile in $configFiles) {
            # Create target path maintaining project structure
            $targetPath = Join-Path $DotfilesDirectory "rider\runConfigurations\$projectName\$($configFile.Name)"
            
            # Process the file
            Create-SafeSymlink $configFile.FullName $targetPath
        }
    }
}

Write-Host ""
Write-Host "=== Processing Individual Files ===" -ForegroundColor Cyan

# Use the function for individual files
Create-SafeSymlink "$homedir\.ideavimrc" "$dotfiles\ideavim\.ideavimrc"
Create-SafeSymlink "$homedir\Documents\AutoHotkey\Untitled.ahk" "$dotfiles\ahk\Untitled.ahk"

# Process all Rider run configurations
Process-RiderRunConfigurations $reposDir $dotfiles

Write-Host ""
Write-Host "=== Dotfiles setup completed! ===" -ForegroundColor Green

