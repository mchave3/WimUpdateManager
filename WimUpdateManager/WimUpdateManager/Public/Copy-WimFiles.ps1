<#
.SYNOPSIS
    Copies WIM files from a source folder to a destination folder.
.DESCRIPTION
    This function copies WIM files from a source folder to a destination folder.
    It first removes all files from the destination folder, then copies the specified WIM files.
    The function supports copying specific Windows versions based on provided filters.
.PARAMETER sourceFolder
    The source folder containing the WIM files to copy.
.PARAMETER destinationFolder
    The destination folder where the WIM files will be copied.
.PARAMETER versions
    An array of version strings to filter which WIM files to copy.
.EXAMPLE
    Copy-WimFiles -sourceFolder "E:\Sources\Masters" -destinationFolder "E:\Work\WIM" -versions @("win10","win11")
    Copies all WIM files containing "win10" or "win11" in their names from the source to destination folder.
.NOTES
    Author:  Mickaël CHAVE
    Date:    2024-02-28
    Version: 1.0
#>
function Copy-WimFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$sourceFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$destinationFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$versions
    )

    begin {
        Write-Host "Starting Copy-WimFiles operation"
        Write-Host "Source folder: $sourceFolder"
        Write-Host "Destination folder: $destinationFolder"
        Write-Host "Versions to copy: $($versions -join ', ')"
    }

    process {
        try {
            # Remove all files and folders in the destinationFolder
            Write-Host "Removing all files in $destinationFolder"
            Remove-Item -Path $destinationFolder\* -Recurse -Force
            Write-Host "All files removed from $destinationFolder"

            # Copy the .wim files from the source folder to the destinationFolder
            foreach ($ver in $versions) {
                Write-Host "Processing version: $ver"
                Write-Host "Searching for files matching pattern *$ver*"
                
                $files = Get-ChildItem -Path $sourceFolder -Recurse -File -Include "*$ver*"
                
                foreach ($file in $files) {
                    Write-Host "Copying $($file.Name) to destination"
                    Copy-Item -Path $file.FullName -Destination $destinationFolder -Force
                    Write-Host "$($file.Name) copied successfully"
                }
            }
            
            Write-Host "All WIM files copied successfully"
        }
        catch {
            Write-Error "Error occurred while copying WIM files: $($_.Exception.Message)"
        }
    }

    end {
    }
}