﻿#
# Module manifest for module 'WiFiProfileManagement'
#
# Generated by: Jason Walker
#
# Generated on: 4/12/2018
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'WiFiProfileManagement.psm1'

    # Version number of this module.
    ModuleVersion     = '2.0.0'

    # ID used to uniquely identify this module
    GUID              = '91ed6e00-7f98-4f49-84f5-c3ee1a10e4d0'

    # Author of this module
    Author            = 'Jason Walker'

    # Description of the functionality provided by this module
    Description       = 'Leverages the native WiFi functions to manage WiFi profiles.'

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess  = @('WiFiProfileManagement.Format.ps1xml')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Connect-WiFiProfile',
        'Get-WiFiAvailableNetwork',
        'Get-WiFiProfile',
        'New-WiFiProfile',
        'Remove-WiFiProfile',
        'Set-WiFiProfile',
        'Search-WiFiNetwork',
        'Set-WiFiInterface'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            Prerelease = 'beta7'
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @('WiFi')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/jcwalker/WiFiProfileManagement/blob/connectWifiProfile/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/jcwalker/WiFiProfileManagement'
        }
    }
}
