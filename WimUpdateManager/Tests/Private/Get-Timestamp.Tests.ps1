$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace((Join-Path "Tests" Private), (Join-Path WimUpdateManager Private))
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. (Join-Path $here $sut)

# To make test runable from project root, and from test directory itself. Do quick validation.
$testsPath = Join-Path "Tests" "Private"
if ((Get-Location).Path -match [Regex]::Escape($testsPath)) {
    $psmPath = (Resolve-Path "..\..\WimUpdateManager\WimUpdateManager.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\WimUpdateManager\WimUpdateManager.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "WimUpdateManager" {
    Describe "Get-Timestamp" {
        It "Should return a string in the correct format" {
            # Act
            $result = Get-Timestamp

            # Assert
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}$'
        }

        It "Should return current time within a reasonable range" {
            # Arrange
            $before = Get-Date
            Start-Sleep -Milliseconds 100

            # Act
            $timestamp = Get-Timestamp
            $timestampDate = [DateTime]::ParseExact($timestamp, "yyyy-MM-dd HH:mm:ss.fff", $null)
            Start-Sleep -Milliseconds 100
            $after = Get-Date

            # Assert
            $timestampDate | Should -BeGreaterThan $before
            $timestampDate | Should -BeLessThan $after
        }
    }
}
