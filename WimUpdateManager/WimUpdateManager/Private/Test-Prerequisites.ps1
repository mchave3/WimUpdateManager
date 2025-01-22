<#
.SYNOPSIS
Checks if all prerequisites for WIM file operations are met.

.DESCRIPTION
This function verifies that all necessary prerequisites for WIM file operations are satisfied.
It checks for:
1. Administrative privileges
2. Available disk space (if a work folder is specified)

The function returns an array of failed requirements, which is empty if all checks pass.

.PARAMETER workFolder
Optional. The working folder path to check for available disk space.
If specified, ensures at least 10GB of free space is available.

.OUTPUTS
System.String[]
Returns an array of failed prerequisite names. Empty array if all prerequisites are met.

.EXAMPLE
# Check prerequisites without disk space check
$failed = Test-Prerequisites
if ($failed) {
    Write-Error "Missing prerequisites: $($failed -join ', ')"
}

.EXAMPLE
# Check prerequisites including disk space
$failed = Test-Prerequisites -workFolder "C:"
if ($failed) {
    Write-Error "Missing prerequisites: $($failed -join ', ')"
}

.NOTES
This is an internal function that should not be called directly from outside the module.
The disk space requirement is set to 10GB minimum.
#>
function Test-Prerequisites {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$workFolder
    )

    begin {
        $requirements = @{
            "Admin Rights" = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
        }

        # Add disk space check only after workFolder is defined
        if ($workFolder) {
            $requirements["Disk Space"] = { (Get-PSDrive -Name $workFolder[0]).Free -gt 10GB }
        }
    }

    process {
        $failed = @()
        foreach ($req in $requirements.GetEnumerator()) {
            if (-not (& $req.Value)) {
                $failed += $req.Key
            }
        }
        return $failed
    }

    end {
    }
}
