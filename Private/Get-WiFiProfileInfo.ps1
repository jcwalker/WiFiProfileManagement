<#
    .SYNOPSIS
        Retrieves the information of a WiFi profile.
    .PARAMETER ProfileName
        The name of the WiFi profile.
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the natvie WiFi functions.
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
        $profileInfoResult = [WiFi.ProfileManagement]::WlanGetProfile($ClientHandle,$InterfaceGuid,$ProfileName,[IntPtr]::Zero,[ref]$pstrProfileXml,[ref]$WlanProfileFlags,[ref]$wlanAccess)

        if ($profileInfoResult -ne 0)
        {
            throw $($script:localizedData.ErrorGettingProfile -f $profileInfoResult)
        }
        elseIf ($profileInfoResult -eq 1168)
        {
            throw $($script:localizedData.ProfileNotFound -f $ProfileName)
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
        [WiFi.ProfileManagement]::WlanFreeMemory($xmlPtr) 
    }
}
