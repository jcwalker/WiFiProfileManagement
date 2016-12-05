
$script:localizedData = Import-LocalizedData -BaseDirectory "$PSScriptRoot\en-US" -FileName WiFiProfileManagement.strings.psd1
<#
	.SYNOPSIS
        Opens a wifi handle
#>
function New-WiFiHandle
{
    
    [CmdletBinding()]
    [OutputType([System.IntPtr])]
    param()

    $maxClient = 2
    [Ref]$negotiatedVersion = 0
    $clientHandle = [System.IntPtr]::zero

    $handle = [Wifi.ProfileManagement]::WlanOpenHandle($maxClient,[IntPtr]::Zero,$negotiatedVersion,[ref]$clientHandle)
    
    if ($handle -eq 0)
    {
        return $clientHandle
    }
    else
    {
        throw $($Script:localizedData.ErrorOpeningHandle)
    }    	
}

<#
    .SYNOPSIS
        Closes an open wifi handle
    .Parameter ClientHandle
        Specifies the object that represents the open wifi handle.
#>
function Remove-WiFiHandle
{
	[CmdletBinding()]
	param
    (
        [System.IntPtr]$ClientHandle    
    )

    $closeHandle = [wifi.ProfileManagement]::WlanCloseHandle($ClientHandle,[System.IntPtr]::zero)

    if ($closeHandle -eq 0)
    {
        Write-Verbose -Message $script:localizedData.HandleClosed
    }
    else
    {
        throw $($script:localizedData.ErrorClosingHandle)
    }
}

<#
    .SYNOPSIS
        Retrieves the information of a WiFi profile.
    .PARAMETER ProfileName
        The name of the WiFi profile.
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native wifi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the natvie wifi functions.
    .PARAMETER WlanProfileFlags
        A pointer to the address location used to provide additional information about the request.

#>
function Get-WiFiProfileInfo
{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]    
    param
    (
        [System.String]
        $ProfileName,

        [System.Guid]
        $InterfaceGuid,

        [System.IntPtr]
        $ClientHandle,

        [System.Int16]
        $WlanProfileFlags
    )
    
    begin
    {
        [System.String]$pstrProfileXml = $null    
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

        [pscustomobject]@{
            SSIDName       = $wlanProfile.WLANProfile.name
            ConnectionMode = $wlanProfile.WLANProfile.connectionMode
            Authentication = $wlanProfile.WLANProfile.MSM.security.authEncryption.authentication
            Encyption      = $wlanProfile.WLANProfile.MSM.security.authEncryption.encryption
            Password       = $password
        }
    }
    end 
    {
        $xmlPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAuto($pstrProfileXml)
        [WiFi.ProfileManagement]::WlanFreeMemory($xmlPtr) 
    }
}

<#
    .SYNOPSIS
        Lists the wireless profiles and their configuration settings.
    .PARAMETER ProfileName
        The name of the WiFi profile.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .PARAMETER ClearKey
        Specifies if the password of the profile is to be returned.
    .EXAMPLE
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encyption      : AES
        Password       : 

        Get the WiFi profile information on wireless profile TestWifi

    .EXAMPLE 
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi -CLearKey

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encyption      : AES
        Password       : password1

        This examples shows the use of the ClearKey switch to return the WiFi profile password.

    .EXAMPLE
        PS C:\>Get-WiFiProfile | where {$_.ConnectionMode -eq 'auto' -and $_.Authentication -eq 'open'}

        This example shows how to find WiFi profiles with insecure connection settings.

#>
function Get-WiFiProfile
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [System.String[]]
        $ProfileName,

        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [Switch]
        $ClearKey
    )    

    begin
    {
        [System.String]$pstrProfileXml = $null
        $wlanAccess = 0
        $ProfileListPtr = 0

        [System.Guid]$interfaceGUID = (Get-NetAdapter -Name $WiFiAdapterName).interfaceguid
        $clientHandle        = New-WiFiHandle

        if ($ClearKey)
        {
          $wlanProfileFlags = 13
        }
        else
        {
           $wlanProfileFlags = 0
        }
    }
    process
    {        
        if (!$ProfileName)
        {
            [wifi.ProfileManagement]::WlanGetProfileList($clientHandle,$interfaceGUID,[System.IntPtr]::zero,[ref]$ProfileListPtr) | Out-Null
            $wifiProfileList = [WiFi.ProfileManagement+WLAN_PROFILE_INFO_LIST]::new($ProfileListPtr)
            $ProfileName = ($wifiProfileList.ProfileInfo).strProfileName
        }

        foreach ($wifiProfile in $ProfileName)
        {
            Get-WiFiProfileInfo -ProfileName $wifiProfile -InterfaceGuid $interfaceGUID -ClientHandle $clientHandle -WlanProfileFlags $wlanProfileFlags
        }        
    }
    end
    {        
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

Export-ModuleMember -Function *
