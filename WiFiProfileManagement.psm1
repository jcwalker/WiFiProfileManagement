
$script:localizedData = Import-LocalizedData -BaseDirectory "$PSScriptRoot\en-US" -FileName WiFiProfileManagement.strings.psd1

# Import everything in these folders
foreach($folder in @('private', 'public', 'classes'))
{    
    $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
    if(Test-Path -Path $root)
    {
        Write-Verbose "processing folder $root"
        $files = Get-ChildItem -Path $root -Filter *.ps1

        # dot source each file
        $files | where-Object { $PSItem.name -NotLike '*.Tests.ps1'} | 
            ForEach-Object{Write-Verbose $PSItem.name; . $PSItem.FullName}
    }
}

Export-ModuleMember -function (Get-ChildItem -Path "$PSScriptRoot\public\*.ps1").basename
