$moduleRoot = Resolve-Path "$PSScriptRoot\.."
$moduleName = Split-Path $moduleRoot -Leaf
$commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
$astTokens = $null
$astError = $null

Describe "General project validation: $moduleName" {
    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object {@{file = $_}}
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param($file)

        $file.fullname | Should Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should Be 0
    }
}

Describe "General function validation" {
    & $moduleRoot\Classes\AddNativeWiFiFunctions.ps1
    $functionFolders = 'public', 'private'

    $paths = $functionFolders | ForEach-Object {Join-Path -Path $moduleRoot -ChildPath $_}
    $functions = $paths | ForEach-Object { Get-ChildItem $_ } | ForEach-Object {Import-Module $_.FullName -PassThru -Force}
    $functionTestCase = $functions | Foreach-Object {@{function = $_ }}

    It "Function <function> should have help with required properties" -TestCases $functionTestCase {
        param ($function)

        $helpParameterCount = ($function | Get-Help -ErrorAction 0).parameters.parameter | Measure-Object        
        $parameters =  (Get-Command $function.Name).parameters.keys | Where-Object {$_ -notin $commonParameters}

        $parameters.count | Should Be $helpParameterCount.count
    }
}
