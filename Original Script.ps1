<#
.SYNOPSIS
This script adds Windows updates to .wim files.

.DESCRIPTION
The script performs the following operations:
- Mounts .wim files
- Adds Windows updates based on Windows version
- Enables .NET Framework 3.5 for Windows 11
- Handles Windows 10, Windows 11, and Windows 11 24H2 updates
- Provides detailed logging and progress tracking

.NOTES
Author: Mickaël CHAVE
Date: 28/02/2024
Version: 2.0
#>

Clear-Host

# Enhanced Get-Timestamp function with more precision
function Get-Timestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

# Modified Test-Prerequisites function to fix null array issue and check elevation first
Function Test-Prerequisites {
    $requirements = @{
        "Admin Rights" = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
    }

    # Add disk space check only after workFolder is defined
    if ($workFolder) {
        $requirements["Disk Space"] = { (Get-PSDrive -Name $workFolder[0]).Free -gt 10GB }
    }

    $failed = @()
    foreach ($req in $requirements.GetEnumerator()) {
        if (-not (& $req.Value)) {
            $failed += $req.Key
        }
    }
    return $failed
}

# Modified cleanup function with better error handling
Function Invoke-Cleanup {
    param([string]$mountDir)
    Write-Host "$(Get-Timestamp) - Starting cleanup procedure..."
    
    try {
        # Check if a mount point exists using PowerShell
        $mountedImages = Get-WindowsImage -Mounted
        if ($mountedImages.ImagePath -match $mountDir) {
            Write-Host "$(Get-Timestamp) - Found mounted image, attempting to unmount..."
            Dismount-WindowsImage -Path $mountDir -Discard
            Write-Host "$(Get-Timestamp) - Successfully unmounted image."
        }
    }
    catch {
        Write-Error "$(Get-Timestamp) - Failed to perform cleanup: $($_.Exception.Message)"
    }
}

# Function to mount .wim file
Function Mount-WimFile {
    Param ([string]$wimPath, [string]$mountDir)
    Write-Host "$(Get-Timestamp) - Mounting $wimPath"
    try {
        Mount-WindowsImage -ImagePath $wimPath -Index 1 -Path $mountDir
        Write-Host "$(Get-Timestamp) - $wimPath mounted successfully."
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while mounting: $($_.Exception.Message)"
    }
}

# Function to unmount .wim file
Function Dismount-WimFile {
    Param ([string]$mountDir)
    Write-Host "$(Get-Timestamp) - Unmounting $mountDir"
    try {
        Dismount-WindowsImage -Path $mountDir -Save
        Write-Host "$(Get-Timestamp) - $mountDir unmounted successfully."
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while unmounting: $($_.Exception.Message)"
    }
}

# Function: Show-Progress
function Show-Progress {
    param (
        [int]$Current,
        [int]$Total,
        [string]$Status,
        [switch]$IsUpdate,
        [int]$ParentPercentComplete
    )

    if ($IsUpdate) {
        # Secondary progress bar for updates
        $percentComplete = [math]::Round(($Current / $Total) * 100, 2)
        Write-Progress -Id 1 -Activity "Processing Updates" -Status $Status -PercentComplete $percentComplete
    } else {
        # Main progress bar for WIMs
        Write-Progress -Activity "Processing WIM Files" -Status $Status -PercentComplete $ParentPercentComplete
    }
}

# Function: Add-Updates
Function Add-Updates {
    Param (
        [string]$wimName,
        [string]$mountDir,
        [System.IO.FileInfo[]]$updates,
        [string]$windowsUpdatesPath,
        [int]$parentProgress
    )
    $updateCount = $updates.Count
    $currentUpdate = 0
    $successCount = 0
    $failedUpdates = @()

    # For Windows 11 24H2, check if KB5043080 is present and install it first
    if ($windowsUpdatesPath -eq $windows11_24h2UpdatesPath) {
        $priorityUpdate = $updates | Where-Object { $_.Name -like "*kb5043080*" }
        if ($priorityUpdate) {
            Write-Host "$(Get-Timestamp) - Found KB5043080, checking if already installed..."
            
            # Check if KB5043080 is already installed
            $kb5043080Installed = Get-WindowsPackage -Path $mountDir | Where-Object { $_.PackageName -like "*KB5043080*" }
            
            if ($kb5043080Installed) {
                Write-Host "$(Get-Timestamp) - KB5043080 is already installed, skipping..."
                $successCount++
            } else {
                Write-Host "$(Get-Timestamp) - KB5043080 not found, installing it first..."
                Show-Progress -Current 1 -Total $updateCount -Status "Installing KB5043080" -IsUpdate -ParentPercentComplete $parentProgress
                
                try {
                    Add-WindowsPackage -Path $mountDir -PackagePath "$windowsUpdatesPath\$priorityUpdate"
                    Write-Host "$(Get-Timestamp) - KB5043080 installed successfully."
                    $successCount++
                }
                catch {
                    Write-Error "$(Get-Timestamp) - Error installing KB5043080: $($_.Exception.Message)"
                    $failedUpdates += $priorityUpdate.Name
                }
            }
            
            # Filter KB5043080 from other updates
            $updates = $updates | Where-Object { $_ -ne $priorityUpdate }
        }
    }

    # Install other updates
    ForEach ($update in $updates) {
        $currentUpdate++
        Show-Progress -Current $currentUpdate -Total $updateCount -Status "Checking $($update.Name)" -IsUpdate -ParentPercentComplete $parentProgress
        
        # Check if update is already installed
        $updateInfo = Get-WindowsPackage -Path $mountDir | Where-Object { $_.PackageName -like "*$($update.BaseName)*" }
        if ($updateInfo) {
            Write-Host "$(Get-Timestamp) - $($update.Name) is already installed, skipping..."
            continue
        }

        Show-Progress -Current $currentUpdate -Total $updateCount -Status "Adding $($update.Name)" -IsUpdate -ParentPercentComplete $parentProgress
        Write-Host "$(Get-Timestamp) - Adding $update to $wimName..."
        try {
            Add-WindowsPackage -Path $mountDir -PackagePath "$windowsUpdatesPath\$update"
            Write-Host "$(Get-Timestamp) - $update added to $wimName."
            $successCount++
        }
        catch {
            Write-Error "$(Get-Timestamp) - Error occurred while adding $update to $wimName : $($_.Exception.Message)"
            $failedUpdates += $update.Name
        }
    }
    Write-Progress -Id 1 -Activity "Processing Updates" -Completed
    return @{
        Total = $updateCount
        Success = $successCount
        Failed = $failedUpdates
    }
}

# Function: Copy-WimFiles
Function Copy-WimFiles {
    Param ([string]$sourceFolder, [string]$destinationFolder, [string[]]$versions)
    try {
        # Remove all files and folders in the destinationFolder
        Write-Host "$(Get-Timestamp) - Removing all .wim files in $destinationFolder"
        Remove-Item -Path $destinationFolder\* -Recurse -Force
        Write-Host "$(Get-Timestamp) - All .wim files removed from $destinationFolder"

        # Copy the .wim files from the source folder to the destinationFolder
        foreach ($ver in $versions) {
            Write-Host "$(Get-Timestamp) - Copying .wim files from $sourceFolder to $destinationFolder"
            $files = Get-ChildItem -Path $sourceFolder -Recurse -File -Include "*$ver*"
            foreach ($file in $files) {
                Copy-Item -Path $file.FullName -Destination $destinationFolder -Force
                Write-Host "$(Get-Timestamp) - $file copied to $destinationFolder"
            }
        }
        Write-Host "$(Get-Timestamp) - .wim files copied successfully."
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while copying .wim files : $($_.Exception.Message)"
    }
}

# Function: Invoke-WimFileProcessing
Function Invoke-WimFileProcessing {
    Param (
        [System.IO.FileInfo]$wimFile,
        [int]$parentProgress = 0
    )
    Write-Host "$(Get-Timestamp) - Processing $wimFile"
    $wimName = $wimFile.Name
    $wimPath = $wimFile.FullName

    # Get the Windows version of the .wim file
    $wimInfo = Get-WindowsImage -ImagePath $wimPath -Index 1
    $wimVersion = [version]$wimInfo.Version

    # Mount the .wim file
    Mount-WimFile -wimPath $wimPath -mountDir $mountDir

    # Windows version specific updates
    if ($wimVersion -lt "10.0.22000.0") {
        # Windows 10
        $script:windows10Results = Add-Updates -wimName $wimName -mountDir $mountDir -updates $windows10Updates -windowsUpdatesPath $windows10UpdatesPath -parentProgress $parentProgress
    }
    elseif ($wimVersion -ge "10.0.22000.0" -and $wimVersion -lt "10.0.26100.0") {
        # Windows 11 (versions 22000-26099)
        $script:windows11Results = Add-Updates -wimName $wimName -mountDir $mountDir -updates $windows11Updates -windowsUpdatesPath $windows11UpdatesPath -parentProgress $parentProgress
    }
    else {
        # Windows 11 24H2 (version 26100 and above)
        $script:windows11_24h2Results = Add-Updates -wimName $wimName -mountDir $mountDir -updates $windows11_24h2Updates -windowsUpdatesPath $windows11_24h2UpdatesPath -parentProgress $parentProgress
    }

    # Enable .Net 3.5
    Write-Host "$(Get-Timestamp) - Enabling .Net 3.5 for $wimName..."
    try {
        # Check the version of the .wim file before enabling .Net 3.5
        if ($wimVersion -ge "10.0.22621.0" -and $wimVersion -lt "10.0.26100.0") {
            # Check if SxS folder exists for Windows 11 23H2
            if (Test-Path -Path $windows11_23H2SxsPath) {
                Enable-WindowsOptionalFeature -Path $mountDir -FeatureName "NetFx3" -All -Source $windows11_23H2SxsPath -LimitAccess
                Write-Host ".Net 3.5 enabled for $wimName using Windows 11 23H2 SxS."
            }
            else {
                throw "The SxS folder for Windows 11 23H2 does not exist."
            }
        }
        elseif ($wimVersion -ge "10.0.26100.0") {
            # Check if SxS folder exists for Windows 11 24H2
            if (Test-Path -Path $windows11_24H2SxsPath) {
                Enable-WindowsOptionalFeature -Path $mountDir -FeatureName "NetFx3" -All -Source $windows11_24H2SxsPath -LimitAccess
                Write-Host ".Net 3.5 enabled for $wimName using Windows 11 24H2 SxS."
            }
            else {
                throw "The SxS folder for Windows 11 24H2 does not exist."
            }
        }
        else {
            throw "The .wim file version is not supported for enabling .Net 3.5."
        }
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while enabling .Net 3.5 for $wimName : $($_.Exception.Message)"
    }

    # Unmount the .wim file
    Dismount-WimFile -mountDir $mountDir
}

### Main Script Logic
try {
    # Check if running as administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script requires administrator privileges. Please restart as administrator."
    }

    # Define working paths before prerequisites check
    $workFolder = "E:\Scripts\OSD\UpdateWIM" # Define the working directory
    
    # Create log directory if it doesn't exist
    $logPath = "$PSScriptRoot\Logs"
    if (!(Test-Path -Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }

    # Start transcript with error handling
    $Logfile = "$logPath\Add-KB-to-wim_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    try {
        Start-Transcript -Path $Logfile -Append
    }
    catch {
        Write-Warning "Could not start transcript: $($_.Exception.Message)"
    }

    # Check prerequisites after paths are defined
    $failedRequirements = Test-Prerequisites
    if ($failedRequirements.Count -gt 0) {
        throw "Missing prerequisites: $($failedRequirements -join ', ')"
    }

    # Initialize cleanup on interruption
    $cleanupScript = {
        Invoke-Cleanup -mountDir $mountDir
    }
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $cleanupScript

    Write-Host "$(Get-Timestamp) - Script started."

    $wimFolder = "$workFolder\Wim" # Define the folder for .wim files
    $masterFolder = "E:\Sources\Masters" # Define the folder for master .wim files

    # Get all .wim files in the masterFolder
    $wimFiles = Get-ChildItem -Path $masterFolder -Filter "*.wim"

    $windows10UpdatesPath = "$workFolder\Updates\Windows10" # Define the path for Windows 10 updates
    $windows11UpdatesPath = "$workFolder\Updates\Windows11" # Define the path for Windows 11 updates
    $windows11_24h2UpdatesPath = "$workFolder\Updates\Windows11_24h2"  # New path

    $windows10Updates = Get-ChildItem -Path "$windows10UpdatesPath" -Filter "*.msu" # Get all .msu files in the Windows 10 updates folder
    $windows11Updates = Get-ChildItem -Path "$windows11UpdatesPath" -Filter "*.msu" # Get all .msu files in the Windows 11 updates folder
    $windows11_24h2Updates = Get-ChildItem -Path "$windows11_24h2UpdatesPath" -Filter "*.msu"  # New updates

    $windows11_23H2SxsPath = "$workFolder\SxS\Windows 11 23H2" # Define the path for Windows 11 23H2 SxS cab files
    $windows11_24H2SxsPath = "$workFolder\SxS\Windows 11 24H2" # Define the path for Windows 11 23H2 SxS cab files

    $mountDir = "$workFolder\Mount" # Define the directory for mounting

    # Add after the variable declarations and before the menu
    $windows10Results = @{ }
    $windows11Results = @{ }
    $windows11_24h2Results = @{ }  # New results container
    $processedWimFiles = @()

    # Check if the mount directory exists, if not create it
    If (!(Test-Path -Path $mountDir))
    {
        New-Item -Path $mountDir -ItemType Directory
    }

    # Check if the wimFolder and masterFolder exist
    if ((Test-Path $wimFolder) -and (Test-Path $masterFolder)) {
        Clear-Host
        # Display the menu to the user
        Write-Host ""
        Write-Host "============================================================"
        Write-Host "  Windows Image Update Manager"
        Write-Host "  $(Get-Timestamp)"
        Write-Host "============================================================"
        Write-Host ""
        Write-Host " 1  - Update ALL WIM files"
        Write-Host " M  - Update Multiple WIM files (custom selection)"
        Write-Host "------------------------------"

        # Generate menu items based on the .wim files
        for ($i = 0; $i -lt $wimFiles.Length; $i++) {
            Write-Host " $($i + 2)  -"$wimFiles[$i].Name
            Write-Host "      Size:" ([math]::Round(($wimFiles[$i].Length / 1GB), 2)) "GB"
        }

        Write-Host ""
        Write-Host "============================================================"
        Write-Host "Press 'Q' to quit"
        Write-Host "============================================================"
        Write-Host ""

        # Get the user's selection
        $selection = Read-Host "Enter your selection"
        Write-Host ""

        # Perform an action based on the user's selection
        switch ($selection) {
            "1" {
                Clear-Host
                # Copy all .wim files
                Copy-WimFiles -sourceFolder $masterFolder -destinationFolder $wimFolder -versions $wimFiles.Name

                # Get all .wim files in the wimFolder
                $wimFiles = Get-ChildItem -Path $wimFolder -Filter "*.wim"
                $totalWims = $wimFiles.Count
                $currentWim = 0

                # Only if we have more than one WIM to process
                if ($totalWims -gt 1) {
                    # Loop through all .wim files
                    ForEach ($wimFile in $wimFiles) {
                        $currentWim++
                        $parentProgress = [math]::Round(($currentWim / $totalWims) * 100, 2)
                        Show-Progress -Current $currentWim -Total $totalWims -Status "Processing $($wimFile.Name)" -ParentPercentComplete $parentProgress

                        # Modify the call to Add-Updates in Invoke-WimFileProcessing to pass the parentProgress
                        Invoke-WimFileProcessing -wimFile $wimFile -parentProgress $parentProgress
                        $processedWimFiles += $wimFile
                    }
                    Write-Progress -Activity "Processing WIM Files" -Completed
                } else {
                    # If only one WIM, no need for double progress bar
                    Invoke-WimFileProcessing -wimFile $wimFiles[0]
                    $processedWimFiles += $wimFiles[0]
                }
            }
            "M" {
                Clear-Host
                Write-Host "Multiple WIM Selection Mode"
                Write-Host "-------------------------"
                Write-Host "Available WIM files:"
                Write-Host ""
                
                # Display available WIMs
                for ($i = 0; $i -lt $wimFiles.Length; $i++) {
                    Write-Host " $($i + 1)  -" $wimFiles[$i].Name
                    Write-Host "      Size:" ([math]::Round(($wimFiles[$i].Length / 1GB), 2)) "GB"
                }
                
                Write-Host "`nEnter the numbers of the WIMs you want to process (separated by commas)"
                Write-Host "Example: 1,3,5"
                $selectedIndices = Read-Host "Selection"
                Clear-Host
                
                # Parse and validate selection
                try {
                    $selectedIndices = $selectedIndices.Split(',').Trim() | 
                                     Where-Object { $_ -match '^\d+$' } |
                                     ForEach-Object { [int]$_ - 1 } |
                                     Where-Object { $_ -ge 0 -and $_ -lt $wimFiles.Length }
                    
                    if ($selectedIndices.Count -eq 0) {
                        throw "No valid selections made"
                    }

                    # Get selected WIM files
                    $selectedWims = $selectedIndices | ForEach-Object { $wimFiles[$_] }
                    
                    # Copy selected WIM files
                    Copy-WimFiles -sourceFolder $masterFolder -destinationFolder $wimFolder -versions $selectedWims.Name
                    
                    # Get copied WIM files
                    $selectedWimFiles = Get-ChildItem -Path $wimFolder -Filter "*.wim"
                    $totalWims = $selectedWimFiles.Count
                    $currentWim = 0
                    
                    # Process selected WIMs with progress bars
                    ForEach ($wimFile in $selectedWimFiles) {
                        $currentWim++
                        $parentProgress = [math]::Round(($currentWim / $totalWims) * 100, 2)
                        Show-Progress -Current $currentWim -Total $totalWims -Status "Processing $($wimFile.Name)" -ParentPercentComplete $parentProgress
                        
                        Invoke-WimFileProcessing -wimFile $wimFile -parentProgress $parentProgress
                        $processedWimFiles += $wimFile
                    }
                    Write-Progress -Activity "Processing WIM Files" -Completed
                }
                catch {
                    Write-Error "Invalid selection: $($_.Exception.Message)"
                    return
                }
            }
            "q"{
                Write-Host "Exiting script..."
                Stop-Transcript
                Exit
            }
            default {
                if (($selection -gt 1) -and ($selection -le ($wimFiles.Length + 1))) {
                    Clear-Host
                    # Copy only the selected version
                    $selectedWim = $wimFiles[$selection - 2]
                    Copy-WimFiles -sourceFolder $masterFolder -destinationFolder $wimFolder -versions @($selectedWim.Name)
            
                    # Get the .wim file for the selected version in the wimFolder
                    $wimFile = Get-ChildItem -Path $wimFolder -Filter $selectedWim.Name

                    # Process the selected .wim file
                    Invoke-WimFileProcessing -wimFile $wimFile
                    $processedWimFiles += $wimFile
                }
                else {
                    Write-Host "Invalid selection"
                }
            }
        }

        Clear-Host
        # Add summary at the end
        Write-Host "`n============================================================"
        Write-Host "                        SUMMARY"
        Write-Host "============================================================"
        Write-Host "Total WIM files processed: $($processedWimFiles.Count)"
        
        # Global summary variables
        $totalUpdatesAttempted = 0
        $totalUpdatesSuccess = 0
        $totalUpdatesFailed = 0
        
        ForEach ($wimFile in $processedWimFiles) {
            Write-Host "`n----------------------------------------"
            Write-Host "WIM File: $($wimFile.Name)"
            Write-Host "----------------------------------------"
            $version = [version](Get-WindowsImage -ImagePath $wimFile.FullName -Index 1).Version
            
            if ($version -lt "10.0.22000.0") {
                Write-Host "Windows Version: Windows 10"
                $updateResults = $windows10Results
            } elseif ($version -ge "10.0.26100.0") {
                Write-Host "Windows Version: Windows 11 24H2"
                $updateResults = $windows11_24h2Results
            } else {
                Write-Host "Windows Version: Windows 11"
                $updateResults = $windows11Results
            }
            
            # Update global counters
            $totalUpdatesAttempted += $updateResults.Total
            $totalUpdatesSuccess += $updateResults.Success
            $totalUpdatesFailed += $updateResults.Failed.Count
            
            Write-Host "Updates Summary:"
            Write-Host "  - Total updates attempted: $($updateResults.Total)"
            Write-Host "  - Successfully installed: $($updateResults.Success)"
            Write-Host "  - Failed installations: $($updateResults.Failed.Count)"
            
            if ($updateResults.Failed.Count -gt 0) {
                Write-Host "`nFailed Updates Details:"
                foreach ($failedUpdate in $updateResults.Failed) {
                    Write-Host "  - $failedUpdate"
                }
            }
        }
        
        # Global summary
        Write-Host "`n============================================================"
        Write-Host "                     GLOBAL SUMMARY"
        Write-Host "============================================================"
        Write-Host "Total Updates Statistics:"
        Write-Host "  - Total updates attempted across all WIMs: $totalUpdatesAttempted"
        Write-Host "  - Total successful installations: $totalUpdatesSuccess"
        Write-Host "  - Total failed installations: $totalUpdatesFailed"
        Write-Host "  - Success rate: $(if ($totalUpdatesAttempted -gt 0) { [math]::Round(($totalUpdatesSuccess/$totalUpdatesAttempted)*100,2) } else { "0" })%"
        
        Write-Host "`n$(Get-Timestamp) - Script completed."
        Stop-Transcript
    }
    else {
        Write-Error "$(Get-Timestamp) - The wimFolder or masterFolder does not exist."
        Stop-Transcript
        Exit
    }
}
catch {
    Write-Error "$(Get-Timestamp) - A critical error occurred: $($_.Exception.Message)"
    Invoke-Cleanup -mountDir $mountDir
}
finally {
    # Safe transcript stop
    try {
        Stop-Transcript -ErrorAction SilentlyContinue
    }
    catch { }

    # Safe event unregistration
    try {
        Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    }
    catch { }
}