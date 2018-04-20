if( $env:BHProjectName -and $env:BHProjectName.Count -eq 1 )
{
    Deploy Module {
        By PSGalleryModule {
            FromSource $PSScriptRoot\Release\WiFiProfileManagement
            To PSGallery
            WithOptions @{
                ApiKey = $env:NugetApiKey
            }
        }
    }
}
