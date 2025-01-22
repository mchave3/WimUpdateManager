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
    }

    process {
        $total = $updates.Count
        $current = 0

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
