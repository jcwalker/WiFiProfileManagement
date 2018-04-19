if( $env:BHProjectName -and $env:BHProjectName.Count -eq 1 )
{
    Deploy Module {
        By PSGalleryModule {
            FromSource $PSScriptRoot\Release\$env:BHProjectName
            To PSGallery
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
            }
        }
    }
}
