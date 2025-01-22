<#
.SYNOPSIS
Generates a formatted timestamp string.

.DESCRIPTION
This function returns a timestamp in the format "yyyy-MM-dd HH:mm:ss.fff".
Used for consistent timestamp formatting throughout the module.

.EXAMPLE
$timestamp = Get-Timestamp
Write-Verbose "$(Get-Timestamp) - Operation started"

.OUTPUTS
System.String
Returns a formatted timestamp string.

.NOTES
This is an internal function that should not be called directly from outside the module.
The timestamp includes milliseconds for precise logging.
#>
function Get-Timestamp {
    [CmdletBinding()]
    param()

    begin {
    }
    
    process {
        return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    }

    end {
    }
}
