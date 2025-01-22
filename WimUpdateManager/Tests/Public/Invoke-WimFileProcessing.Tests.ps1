$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace((Join-Path "Tests" Public), (Join-Path WimUpdateManager Public))
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. (Join-Path $here $sut)

# To make test runable from project root, and from test directory itself. Do quick validation.
$testsPath = Join-Path "Tests" "Public"
if ((Get-Location).Path -match [Regex]::Escape($testsPath)) {
    $psmPath = (Resolve-Path "..\..\WimUpdateManager\WimUpdateManager.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\WimUpdateManager\WimUpdateManager.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "WimUpdateManager" {
    Describe "Invoke-WimFileProcessing" {
        BeforeAll {
            # Mock all dependent functions
            Mock Mount-WimFile { }
            Mock Dismount-WimFile { }
            Mock Get-WindowsVersion { return "Windows 10" }
            Mock Get-WindowsUpdates { 
                return @(
                    [PSCustomObject]@{
                        Name = "Update1.cab"
                        FullName = "TestDrive:\Updates\Update1.cab"
                    }
                )
            }
            Mock Add-Updates { }
            Mock Invoke-Cleanup { }
            Mock Write-Verbose { }
            Mock Write-Warning { }
            Mock Write-Error { }
            Mock Get-Timestamp { return "2024-01-22 12:00:00" }
            Mock Remove-Item { }
            Mock Test-Path { return $true }
            Mock New-Item { }

            # Create test data
            $testWimFile = [PSCustomObject]@{
                Name = "test.wim"
                FullName = "TestDrive:\test.wim"
            }
            $testWimFile | Add-Member -MemberType ScriptMethod -Name "GetType" -Value { return [System.IO.FileInfo] }
        }

        It "Should process WIM file successfully with updates" {
            # Act
            Invoke-WimFileProcessing -wimFile $testWimFile

            # Assert
            Should -Invoke Mount-WimFile -Times 1
            Should -Invoke Get-WindowsVersion -Times 1
            Should -Invoke Get-WindowsUpdates -Times 1
            Should -Invoke Add-Updates -Times 1
            Should -Invoke Dismount-WimFile -Times 1
            Should -Invoke Write-Error -Times 0
        }

        It "Should handle scenario with no updates available" {
            # Arrange
            Mock Get-WindowsUpdates { return $null }

            # Act
            Invoke-WimFileProcessing -wimFile $testWimFile

            # Assert
            Should -Invoke Add-Updates -Times 0
            Should -Invoke Write-Warning -Times 1
        }

        It "Should handle mount failures and perform cleanup" {
            # Arrange
            Mock Mount-WimFile { throw "Mount failed" }

            # Act
            Invoke-WimFileProcessing -wimFile $testWimFile

            # Assert
            Should -Invoke Write-Error -Times 1
            Should -Invoke Invoke-Cleanup -Times 1
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Invoke-WimFileProcessing } | Should -Throw
        }
    }
}
