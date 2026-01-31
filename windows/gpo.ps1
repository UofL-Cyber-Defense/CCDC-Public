# ----
# This script creates a new GPO on an Active Directory computer's connected Domain.
# When downloaded, the other 'inprogress.ps1' script gets installed with this. This script also connects the 'inprogress' script to a startup script in the GPO
# More functionality will come soon with deploying firewall rules.
# ----

Import-Module ActiveDirectory
Import-Module GroupPolicy

# ----
# Variables
# ----
$GPOName      = "InitialRun"
$ScriptName   = "inprogress.ps1"
$LauncherName = "RunInitialScript.cmd"

$Domain        = (Get-ADDomain).DNSRoot
$DomainDN      = (Get-ADDomain).DistinguishedName
$SysVol        = "\\$Domain\SYSVOL\$Domain"

Write-Host "Current domain detected: $Domain"

# ----
# Copy Software and Scripts folders recursively
# ----
$SourceFolders = @("Software","scripts")

foreach ($Folder in $SourceFolders) {
    $SourcePath = Join-Path $PSScriptRoot $Folder
    $DestinationPath = Join-Path $SysVol $Folder

    if (Test-Path $SourcePath) {
        Write-Host "Copying '$Folder' to SYSVOL..."
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
        Write-Host "'$Folder' copied successfully."
    } else {
        Write-Host "Source folder '$Folder' does not exist. Skipping."
    }
}

# ----
# Create or get GPO
# ----
$GPO = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $GPO) {
    $GPO = New-GPO -Name $GPOName -Comment "Startup hardening script"
    Write-Host "GPO '$GPOName' created."
} else {
    Write-Host "GPO '$GPOName' already exists."
}

# ----
# Link GPO if needed
# ----
$Links = (Get-GPInheritance -Target $DomainDN).GpoLinks
if ($Links.GpoName -notcontains $GPOName) {
    New-GPLink -Name $GPOName -Target $DomainDN
    Write-Host "GPO linked to domain root."
} else {
    Write-Host "GPO already linked."
}

# ----
# Startup script folder
# ----
$GPOId = $GPO.Id.ToString().ToUpper()
$StartupFolder = "\\$Domain\SYSVOL\$Domain\Policies\{$GPOId}\Machine\Scripts\Startup"

New-Item -ItemType Directory -Path $StartupFolder -Force | Out-Null

# ----
# Copy PowerShell script
# ----
Copy-Item "$SysVol\scripts\$ScriptName" $StartupFolder -Force

# ----
# Create CMD launcher (ExecutionPolicy Bypass)
# ----
$LauncherPath = Join-Path $StartupFolder $LauncherName
@"
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "$ScriptName"
"@ | Set-Content $LauncherPath -Force

# ----
# Register startup script
# ----
$scriptsIni = Join-Path $StartupFolder "scripts.ini"

if (-not (Test-Path $scriptsIni)) {
@"
[Startup]
0CmdLine=$LauncherName
0Parameters=
"@ | Set-Content $scriptsIni -Force
    Write-Host "Startup script registered."
}
else {
    $content = Get-Content $scriptsIni
    if ($content -notmatch [regex]::Escape($LauncherName)) {
        $index = ($content | Select-String "^(\d+)CmdLine=").Matches.Value |
                 ForEach-Object { ($_ -replace 'CmdLine=.*','') -as [int] } |
                 Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

        if ($index -eq $null) { $index = 0 } else { $index++ }

        Add-Content $scriptsIni "$index`CmdLine=$LauncherName"
        Add-Content $scriptsIni "$index`Parameters="
        Write-Host "Startup script appended."
    }
    else {
        Write-Host "Startup script already registered."
    }
}

Write-Host "DONE. Script will run at startup with ExecutionPolicy Bypass."
