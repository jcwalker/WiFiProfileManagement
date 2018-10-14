<#
    .SYNOPSIS
        Retrieves the information of a WiFi profile.
    .PARAMETER ProfileName
        The name of the WiFi profile. Profile names are case-sensitive.
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the native WiFi functions.
    .PARAMETER WlanProfileFlags
        A pointer to the address location used to provide additional information about the request.
#>
function Get-WiFiProfileInfo
{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.Guid]
        $InterfaceGuid,

        [Parameter()]
        [System.IntPtr]
        $ClientHandle,

        [System.Int16]
        $WlanProfileFlags
    )
    
    begin
    {
        [String]$pstrProfileXml = $null
        $wlanAccess = 0
        $WlanProfileFlagsInput = $WlanProfileFlags
    }
    process
    {
        $result = [WiFi.ProfileManagement]::WlanGetProfile(
            $ClientHandle,
            $InterfaceGuid,
            $ProfileName,
            [IntPtr]::Zero,
            [ref]$pstrProfileXml,
            [ref]$WlanProfileFlags,
            [ref]$wlanAccess
        )

        if ($result -ne 0)
        {
            $errorMessage = Format-Win32Exception -ReturnCode $result
            throw $($script:localizedData.ErrorGettingProfile -f $errorMessage)
        }

        $wlanProfile = [xml]$pstrProfileXml

        if ($WlanProfileFlagsInput -eq 13)
        {
            $password = $wlanProfile.WLANProfile.MSM.security.sharedKey.keyMaterial
        }
        else
        {
            $password = $null
        }

        [WiFi.ProfileManagement+ProfileInfo]@{
            ProfileName    = $wlanProfile.WLANProfile.SSIDConfig.SSID.name
            ConnectionMode = $wlanProfile.WLANProfile.connectionMode
            Authentication = $wlanProfile.WLANProfile.MSM.security.authEncryption.authentication
            Encryption     = $wlanProfile.WLANProfile.MSM.security.authEncryption.encryption
            Password       = $password
            Xml            = $pstrProfileXml
        }
    }
    end
    {
        $xmlPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAuto($pstrProfileXml)
        Invoke-WlanFreeMemory -Pointer $xmlPtr
    }
}
