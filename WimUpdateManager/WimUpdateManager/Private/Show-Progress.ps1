<#
.SYNOPSIS
Displays a progress bar for WIM file operations.

.DESCRIPTION
This function manages the display of progress bars for both WIM file processing and update installation.
It supports nested progress bars through the parent progress parameter and can show different activities
based on whether it's displaying update progress or general WIM processing progress.

.PARAMETER Current
The current item number being processed.

.PARAMETER Total
The total number of items to process.

.PARAMETER Status
The status message to display in the progress bar.

.PARAMETER IsUpdate
Switch parameter indicating if this is an update installation progress (affects progress bar title and calculation).

.PARAMETER ParentPercentComplete
The percentage complete of the parent operation, used for nested progress bars.
Default is 0.

.EXAMPLE
# Show WIM processing progress
Show-Progress -Current 2 -Total 5 -Status "Processing file2.wim"

.EXAMPLE
# Show update installation progress with parent progress
Show-Progress -Current 3 -Total 10 -Status "Installing KB123456" -IsUpdate -ParentPercentComplete 50

.NOTES
This is an internal function that should not be called directly from outside the module.
#>
function Show-Progress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Current,
        
        [Parameter(Mandatory = $true)]
        [int]$Total,
        
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [Parameter()]
        [switch]$IsUpdate,
        
        [Parameter()]
        [int]$ParentPercentComplete = 0
    )

    begin {
        $percentComplete = [math]::Round(($Current / $Total) * 100)
    }

    process {
        if ($IsUpdate) {
            $adjustedPercent = [math]::Round($ParentPercentComplete + ($percentComplete / $Total))
            Write-Progress -Activity "Installing Updates" -Status $Status -PercentComplete $adjustedPercent
        }
        else {
            Write-Progress -Activity "Processing WIM Files" -Status $Status -PercentComplete $percentComplete
        }
    }

    end {
    }
}
