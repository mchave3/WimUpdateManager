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
    Describe "Invoke-Cleanup" {
        BeforeAll {
            # Mock required functions
            Mock Get-WindowsImage { }
            Mock Dismount-WindowsImage { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Get-Timestamp { return "2024-01-22 12:00:00" }

            # Test parameters
            $testMountDir = "TestDrive:\Mount"
        }

        It "Should handle cleanup when no mounted image is found" {
            # Arrange
            Mock Get-WindowsImage { return @() }

            # Act
            Invoke-Cleanup -mountDir $testMountDir

            # Assert
            Should -Invoke Dismount-WindowsImage -Times 0
            Should -Invoke Write-Error -Times 0
        }

        It "Should cleanup mounted image successfully" {
            # Arrange
            Mock Get-WindowsImage { 
                return @{
                    ImagePath = "TestDrive:\Mount\image.wim"
                }
            }

            # Act
            Invoke-Cleanup -mountDir $testMountDir

            # Assert
            Should -Invoke Dismount-WindowsImage -Times 1 -ParameterFilter {
                $Path -eq $testMountDir -and
                $Discard -eq $true
            }
            Should -Invoke Write-Error -Times 0
        }

        It "Should handle cleanup failures gracefully" {
            # Arrange
            Mock Get-WindowsImage { throw "Cleanup failed" }

            # Act
            Invoke-Cleanup -mountDir $testMountDir

            # Assert
            Should -Invoke Write-Error -Times 1
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Invoke-Cleanup } | Should -Throw
        }
    }
}
