<#
.SYNOPSIS
    Returns the current timestamp in the format "yyyy-MM-dd HH:mm:ss.fff".
.DESCRIPTION
    This function returns the current timestamp in the format "yyyy-MM-dd HH:mm:ss.fff".
.EXAMPLE
    Get-Timestamp
    Returns the current timestamp in the format "yyyy-MM-dd HH:mm:ss.fff".
.NOTES
    Author:  Mickaël CHAVE
    Date:    2025-01-22
    Version: 1.0
#>
function Get-Timestamp {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    begin {
    }
    
    process {
        return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    }
    
    end {
    }
}