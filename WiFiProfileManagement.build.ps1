task . Clean, Build, Tests, Stats, DeployToGallery
task Tests ImportCompipledModule, Pester
task CreateManifest CopyPSD, UpdatPublicFunctionsToExport
task Build Compile, CreateManifest, CopyFormatXml, CopyLocalization
task Stats RemoveStats, WriteStats

$script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$script:ModuleRoot = $PSScriptRoot
$script:OutPutFolder = "$PSScriptRoot\Release"
$script:ImportFolders = @('PreReqs','Public','Private','Classes')
$script:PsmPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($script:ModuleName)\$($script:ModuleName).psm1"
$script:PsdPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($script:ModuleName)\$($script:ModuleName).psd1"
$script:ps1XmlPath  = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($script:ModuleName)\$($script:ModuleName).Format.ps1xml"
$script:LocalizationPath = Join-Path -Path $PSScriptRoot -ChildPath "Release\$($script:ModuleName)\en-US"
$script:PublicFolder = 'Public'

task Clean {
    if (-not(Test-Path $script:OutPutFolder))
    {
        New-Item -ItemType Directory -Path $script:OutPutFolder > $null
    }

    Remove-Item -Path "$($script:OutPutFolder)\*" -Force -Recurse
}

$compileParams = @{
    Inputs = {
        foreach ($folder in $script:ImportFolders)
        {
            Get-ChildItem -Path $folder -Recurse -File -Filter '*.ps1'
        }
    }

    Output = {
        $script:PsmPath
    }
}

task Compile @compileParams {
    if (Test-Path -Path $script:PsmPath)
    {
        Remove-Item -Path $script:PsmPath -Recurse -Force
    }

    New-Item -Path $script:PsmPath -Force > $null
 
    foreach ($folder in $script:ImportFolders)
    {
        $currentFolder = Join-Path -Path $script:ModuleRoot -ChildPath $folder
        Write-Verbose -Message "Checking folder [$currentFolder]"

        if (Test-Path -Path $currentFolder)
        {
            $files = Get-ChildItem -Path $currentFolder -File -Filter '*.ps1'
            foreach ($file in $files)
            {
                Write-Verbose -Message "Adding $($file.FullName)"
                Get-Content -Path $file.FullName -Raw | Out-File -FilePath $script:PsmPath -Append -Encoding utf8 
            }
        }
    }
}

task CopyPSD {
    New-Item -Path (Split-Path $script:PsdPath) -ItemType Directory -ErrorAction 0
    $copy = @{
        Path        = "$($script:ModuleName).psd1"
        Destination = $script:PsdPath
        Force       = $true
        Verbose     = $true
    }
    Copy-Item @copy
}

task CopyFormatXml {
    $copy = @{
        Path        = "$($script:ModuleName).Format.ps1xml"
        Destination = $script:ps1XmlPath
        Force       = $true
        Verbose     = $true
    }
    Copy-Item @copy
}

task CopyLocalization {
    $copy = @{
        Path        = "en-US"
        Destination = $script:LocalizationPath
        Force       = $true
        Verbose     = $true
        Container   = $true
        Recurse     = $true
    }
    Copy-Item @copy
}

task UpdatPublicFunctionsToExport -if (Test-Path -Path $script:PublicFolder) {
    $publicFunctions = (Get-ChildItem -Path $script:PublicFolder |
            Select-Object -ExpandProperty BaseName) -join "', '"

    $publicFunctions = "FunctionsToExport = @('{0}')" -f $publicFunctions

    (Get-Content -Path $script:PsdPath) -replace "FunctionsToExport = '\*'", $publicFunctions |
        Set-Content -Path $script:PsdPath
}

task ImportCompipledModule -if (Test-Path -Path $script:PsmPath) {
    Get-Module -Name $script:ModuleName | Remove-Module -Force
    Import-Module -Name $script:PsdPath -Force
}

task Pester {
    $resultFile = "{0}\testResults{1}.xml" -f $script:OutPutFolder, (Get-date -Format 'yyyyMMdd_hhmmss')
    $testFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Tests\*'
    Invoke-Pester -Path $testFolder -OutputFile $resultFile -OutputFormat NUnitxml
}

task RemoveStats -if (Test-Path -Path "$($script:OutPutFolder)\stats.json") {
    Remove-Item -Force -Verbose -Path "$($script:OutPutFolder)\stats.json" 
}

task WriteStats {
    $folders = Get-ChildItem -Directory | 
        Where-Object {$PSItem.Name -ne 'Output'}
    
    $stats = foreach ($folder in $folders)
    {
        $files = Get-ChildItem "$($folder.FullName)\*" -File
        if($files)
        {
            Get-Content -Path $files | 
            Measure-Object -Word -Line -Character | 
            Select-Object -Property @{N = "FolderName"; E = {$folder.Name}}, Words, Lines, Characters
        }
    }
    $stats | ConvertTo-Json > "$script:OutPutFolder\stats.json"
}

task DeployToGallery {
    Set-BuildEnvironment
    # Gate deployment 
    if (
        $ENV:BHBuildSystem -ne 'Unknown' -and
        $ENV:BHBranchName -eq "master" -and
        $ENV:BHCommitMessage -match '!deploy'
    )
    {
        $Params = @{
            Path  = $ProjectRoot
            Force = $true
        }

        Invoke-PSDeploy @Verbose @Params
    }
    else
    {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }
}
