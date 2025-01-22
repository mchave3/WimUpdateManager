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
    Describe "Copy-WimFiles" {
        BeforeAll {
            # Création des chemins de test
            $testSourceFolder = "TestDrive:\Source"
            $testDestFolder = "TestDrive:\Destination"
            $testVersions = @("test1.wim", "test2.wim")

            # Création du dossier source
            New-Item -Path $testSourceFolder -ItemType Directory
            New-Item -Path $testDestFolder -ItemType Directory

            # Création de fichiers de test
            "Test Content 1" | Set-Content -Path (Join-Path $testSourceFolder $testVersions[0])
            "Test Content 2" | Set-Content -Path (Join-Path $testSourceFolder $testVersions[1])
        }

        It "Should copy files successfully when source files exist" {
            # Arrange
            $sourcePath1 = Join-Path $testSourceFolder $testVersions[0]
            $destPath1 = Join-Path $testDestFolder $testVersions[0]

            # Act
            Copy-WimFiles -sourceFolder $testSourceFolder -destinationFolder $testDestFolder -versions $testVersions

            # Assert
            Test-Path $destPath1 | Should -Be $true
            Get-Content $destPath1 | Should -Be "Test Content 1"
        }

        It "Should handle non-existent source files gracefully" {
            # Arrange
            $nonExistentVersions = @("nonexistent.wim")

            # Act & Assert
            Copy-WimFiles -sourceFolder $testSourceFolder -destinationFolder $testDestFolder -versions $nonExistentVersions -WarningVariable warningMessage
            $warningMessage | Should -Match "Source file not found"
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Copy-WimFiles -sourceFolder $testSourceFolder -destinationFolder $testDestFolder } | 
                Should -Throw
        }
    }
}
