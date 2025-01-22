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
    Describe "Add-Updates" {
        BeforeAll {
            # Mock the required functions
            Mock Add-WindowsPackage { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Show-Progress { }
            Mock Get-Timestamp { return "2024-01-22 12:00:00" }

            # Create test data
            $testWimName = "test.wim"
            $testMountDir = "TestDrive:\Mount"
            $testUpdates = @(
                [PSCustomObject]@{
                    Name = "Update1.cab"
                    FullName = "TestDrive:\Updates\Update1.cab"
                },
                [PSCustomObject]@{
                    Name = "Update2.cab"
                    FullName = "TestDrive:\Updates\Update2.cab"
                }
            )
        }

        It "Should process all updates successfully" {
            # Act
            Add-Updates -wimName $testWimName -mountDir $testMountDir -updates $testUpdates

            # Assert
            Should -Invoke Add-WindowsPackage -Times $testUpdates.Count -Exactly
            Should -Invoke Write-Error -Times 0
        }

        It "Should handle failed updates gracefully" {
            # Arrange
            Mock Add-WindowsPackage { throw "Installation failed" }

            # Act
            Add-Updates -wimName $testWimName -mountDir $testMountDir -updates $testUpdates

            # Assert
            Should -Invoke Write-Error -Times $testUpdates.Count -Exactly
        }

        It "Should show progress for each update" {
            # Act
            Add-Updates -wimName $testWimName -mountDir $testMountDir -updates $testUpdates -parentProgress 50

            # Assert
            Should -Invoke Show-Progress -Times $testUpdates.Count -Exactly
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Add-Updates -wimName $testWimName -mountDir $testMountDir } | 
                Should -Throw
        }
    }
}
