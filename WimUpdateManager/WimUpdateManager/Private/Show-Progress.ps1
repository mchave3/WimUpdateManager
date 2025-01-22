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

    $percentComplete = [math]::Round(($Current / $Total) * 100)
    
    if ($IsUpdate) {
        $adjustedPercent = [math]::Round($ParentPercentComplete + ($percentComplete / $Total))
        Write-Progress -Activity "Installing Updates" -Status $Status -PercentComplete $adjustedPercent
    }
    else {
        Write-Progress -Activity "Processing WIM Files" -Status $Status -PercentComplete $percentComplete
    }
}
