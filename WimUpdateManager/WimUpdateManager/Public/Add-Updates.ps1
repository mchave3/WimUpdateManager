<#
.SYNOPSIS
Adds Windows updates to a mounted WIM file.

.DESCRIPTION
This function installs Windows updates to a mounted WIM file. It processes each update sequentially,
showing progress during installation and handling any potential errors that may occur during the process.

.PARAMETER wimName
The name of the WIM file being updated.

.PARAMETER mountDir
The directory where the WIM file is mounted.

.PARAMETER updates
An array of FileInfo objects representing the update files to be installed.

.PARAMETER parentProgress
Optional. The progress percentage of the parent operation, used for nested progress bars.
Default is 0.

.EXAMPLE
$updates = Get-ChildItem "C:\Updates\*.cab"
Add-Updates -wimName "win10.wim" -mountDir "C:\Mount" -updates $updates

.EXAMPLE
Add-Updates -wimName "win11.wim" -mountDir "D:\Mount" -updates $updates -parentProgress 50
#>
function Add-Updates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$wimName,
        
        [Parameter(Mandatory = $true)]
        [string]$mountDir,
        
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$updates,
        
        [Parameter()]
        [int]$parentProgress = 0
    )

    begin {
        Write-Verbose "$(Get-Timestamp) - Starting update process for $wimName"
        $total = $updates.Count
        $current = 0
    }

    process {
        foreach ($update in $updates) {
            $current++
            $status = "Installing update $($update.Name)"
            Show-Progress -Current $current -Total $total -Status $status -IsUpdate -ParentPercentComplete $parentProgress

            try {
                Add-WindowsPackage -Path $mountDir -PackagePath $update.FullName -NoRestart
                Write-Verbose "$(Get-Timestamp) - Successfully installed $($update.Name)"
            }
            catch {
                Write-Error "$(Get-Timestamp) - Failed to install $($update.Name): $($_.Exception.Message)"
            }
        }
    }

    end {
        Write-Verbose "$(Get-Timestamp) - Update process completed for $wimName"
    }
}
