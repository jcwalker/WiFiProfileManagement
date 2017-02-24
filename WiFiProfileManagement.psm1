
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

        [wifi.ProfileManagement+ProfileInfo]@{
            ProfileName    = $wlanProfile.WLANProfile.SSIDConfig.SSID.name
            ConnectionMode = $wlanProfile.WLANProfile.connectionMode
            Authentication = $wlanProfile.WLANProfile.MSM.security.authEncryption.authentication
            Encyption      = $wlanProfile.WLANProfile.MSM.security.authEncryption.encryption
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
        [Parameter(Position=0)]
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
        $clientHandle = New-WiFiHandle

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

<#
    .SYNOPSIS
        Deletes a wifi profile.
    .PARAMETER ProfileName
        The name of the profile to be deleted. Profile names are case-sensitive.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
    C:\>Remove-WiFiProfile -ProfileName FreeWifi

    This examples deletes the FreeWifi profile.
#>
function Remove-WiFiProfile
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    Param 
    (
        [Parameter(Position = 0,
            Mandatory=$true,
            ValueFromPipeLine=$true)]
            [System.String[]]
            $ProfileName,

        [Parameter(Position = 1,
            Mandatory=$false)]
            [System.String]
            $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        [System.Guid]$interfaceGUID = (Get-NetAdapter -Name $WiFiAdapterName).InterfaceGuid
        $clientHandle = New-WiFiHandle
    }
    process
    {
        foreach ($wifiProfile in $ProfileName)
        {
            if ($PSCmdlet.ShouldProcess("$($script:localizedData.ShouldProcessDelete -f $wifiProfile)"))
            {
                $deleteProfileResult = [WiFi.ProfileManagement]::WlanDeleteProfile($clientHandle,$interfaceGUID,$ProfileName,[System.IntPtr]::zero)            

                if ($deleteProfileResult -ne 0)
                {                
                    throw $($script:localizedData.ErrorDeletingProfile -f $deleteProfileResult)
                }   
            }
        }      
    }
    end 
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

<#
    .SYNOPSIS
        An internal function to format the reason code returned by WlanSetProfile
    .PARAMETER ReasonCode
        A vlaue that indicates why the profile failed.
#>
function Format-WiFiReasonCode
{
    [OutputType([System.String])]
    [Cmdletbinding()]
    param
    (
        [System.IntPtr]
        $ReasonCode
    )

    $stringBuilder = [System.Text.StringBuilder]::new(1024)
    [WiFi.ProfileManagement]::WlanReasonCodeToString($ReasonCode.ToInt32(),$stringBuilder.Capacity,$stringBuilder,[IntPtr]::zero) | Out-Null

    return $stringBuilder.ToString()

}

<#
    .SYNOPSIS
        Create a string of XML that represents the wireless profile.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated.  Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
#>
function New-WiFiProfileXml
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param 
    (
         [parameter(Mandatory=$true,Position=0)]
        [System.String]
        $ProfileName,
        
        [parameter(Mandatory=$false)]
        [ValidateSet('manual','auto')]
        [System.String]
        $ConnectionMode = 'auto',
        
        [parameter(Mandatory=$false)]
        [System.String]
        $Authentication = 'WPA2PSK',
        
        [parameter(Mandatory=$false)]
        [System.String]
        $Encryption = 'AES',
        
        [parameter(Mandatory=$true)]
        [System.String]
        $Password   
    )
    
    process
    {
        $stringWriter = [System.IO.StringWriter]::new()
        $xmlWriter    = [System.Xml.XmlTextWriter]::new($stringWriter)

        $xmlWriter.WriteStartDocument()
        $xmlWriter.WriteStartElement("WLANProfile","http://www.microsoft.com/networking/WLAN/profile/v1");
        $xmlWriter.WriteElementString("name", "$profileName");
        $xmlWriter.WriteStartElement("SSIDConfig");
        $xmlWriter.WriteStartElement("SSID");
        $xmlWriter.WriteElementString("name", "$profileName");
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteElementString("connectionType", "ESS");
        $xmlWriter.WriteElementString("connectionMode", $ConnectionMode);
        $xmlWriter.WriteStartElement("MSM");
        $xmlWriter.WriteStartElement("security");
        $xmlWriter.WriteStartElement("authEncryption");
        $xmlWriter.WriteElementString("authentication", $Authentication);
        $xmlWriter.WriteElementString("encryption", "$Encryption");
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteStartElement("sharedKey");
        $xmlWriter.WriteElementString("keyType", "passPhrase");
        $xmlWriter.WriteElementString("protected", "false");
        $xmlWriter.WriteElementString("keyMaterial", $plainPassword);
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndDocument();

        $xmlWriter.Close()
        $stringWriter.ToString()
    }
}

<#
    .SYNOPSIS
        Sets the content of a specified wireless profile.
    .DESCRIPTION
        Calls the WlanSetProfile native function with overide parameter set to true.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated.  Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
    .PARAMETER Password
        The network key or passpharse of the wireless profile in the form of a secure string.
    .PARAMETER XmlProfile
        The XML representation of the profile. 
    .EXAMPLE
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>Set-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password 

        This examples shows how to update or create a wireless profile by using the individual parameters.
    .EXAMPLE
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>            
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>Set-WiFiProfile -XmlProfile $templateProfileXML

        This example demonstrates how to update a wireless profile with the XmlProfile parameter.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706795(v=vs.85).aspx
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms707381(v=vs.85).aspx
#>
function Set-WiFiProfile
{
    [CmdletBinding()]
    param 
    (
        [parameter(Mandatory=$true,Position=0,ParameterSetName='UsingArguments')]
        [System.String]
        $ProfileName,
        
        [parameter(Mandatory=$false,ParameterSetName='UsingArguments')]
        [ValidateSet('manual','auto')]
        [System.String]
        $ConnectionMode = 'auto',
        
        [parameter(Mandatory=$true,ParameterSetName='UsingArguments')]
        [System.String]
        $Authentication = 'WPA2PSK',
        
        [parameter(Mandatory=$false,ParameterSetName='UsingArguments')]
        [System.String]
        $Encryption = 'AES',

        [parameter(Mandatory=$true,ParameterSetName='UsingArguments')]
        [System.Security.SecureString]
        $Password,
        
        [parameter(Mandatory=$false)]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [parameter(Mandatory=$true,ParameterSetName='UsingXml')]
        [System.String]
        $XmlProfile
    )

    begin
    {
        if ($Password)
        {
            $secureStringToBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainPassword      = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secureStringToBstr) 
        }
        $clientHandle = New-WiFiHandle
        [System.Guid]$interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName).InterfaceGuid
        $flags = 0
        $allUserProfileSecurity = [System.IntPtr]::zero
        $overwrite = $true
        $reasonCode = [IntPtr]::Zero                  

        if ($XmlProfile)
        {
            $profileXML = $XmlProfile
        }
        else
        {
            $newProfileParameters = @{
                ProfileName    = $ProfileName
                ConnectionMode = $ConnectionMode
                Authentication = $Authentication
                Password       = $plainPassword
            }

            $profileXML = New-WiFiProfileXml @newProfileParameters
        }
    }

    process
    {
        $profilePtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($profileXML)

        $setProfileResults = [WiFi.ProfileManagement]::WlanSetProfile(
                                        $clientHandle,
                                        [ref]$interfaceGuid,
                                        $flags,
                                        $profilePtr,
                                        [IntPtr]::Zero,
                                        $overwrite,
                                        [IntPtr]::Zero,
                                        [ref]$reasonCode
                                        )

        Format-WiFiReasonCode -ReasonCode $reasonCode
    }

    end
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

<#
    .SYNOPSIS
        Creates the content of a specified wireless profile.
    .DESCRIPTION
        Creates the content of a wireless profile by calling the WlanSetProfile native function but with the overide parameter set to false. 
    .PARAMETER ProfileName
        The name of the wireless profile to be updated.  Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
    .PARAMETER Password
        The network key or passpharse of the wireless profile in the form of a secure string.
    .PARAMETER XmlProfile
        The XML representation of the profile. 
    .EXAMPLE
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password 

        This examples shows how to create a wireless profile by using the individual parameters.
    .EXAMPLE
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>            
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>New-WiFiProfile -XmlProfile $templateProfileXML

        This example demonstrates how to update a wireless profile with the XmlProfile parameter.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706795(v=vs.85).aspx
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms707381(v=vs.85).aspx
#>
function New-WiFiProfile
{
    [CmdletBinding()]
    param 
    (
        [parameter(Mandatory=$true,Position=0,ParameterSetName='UsingArguments')]
        [System.String]
        $ProfileName,
        
        [parameter(Mandatory=$false,ParameterSetName='UsingArguments')]
        [ValidateSet('manual','auto')]
        [System.String]
        $ConnectionMode = 'auto',
        
        [parameter(Mandatory=$true,ParameterSetName='UsingArguments')]
        [System.String]
        $Authentication = 'WPA2PSK',
        
        [parameter(Mandatory=$false,ParameterSetName='UsingArguments')]
        [System.String]
        $Encryption = 'AES',

        [parameter(Mandatory=$true,ParameterSetName='UsingArguments')]
        [System.Security.SecureString]
        $Password,
        
        [parameter(Mandatory=$false)]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [parameter(Mandatory=$true,ParameterSetName='UsingXml')]
        [System.String]
        $XmlProfile

    )

    begin
    {
        if ($Password)
        {
            $secureStringToBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainPassword      = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secureStringToBstr) 
        }
        $clientHandle = New-WiFiHandle
        [System.Guid]$interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName).InterfaceGuid
        $flags = 0
        $allUserProfileSecurity = [System.IntPtr]::zero
        $overwrite = $false
        $reasonCode = [IntPtr]::Zero                  

        if ($XmlProfile)
        {
            $profileXML = $XmlProfile
        }
        else
        {
            $newProfileParameters = @{
                ProfileName    = $ProfileName
                ConnectionMode = $ConnectionMode
                Authentication = $Authentication
                Password       = $plainPassword
            }

            $profileXML = New-WiFiProfileXml @newProfileParameters
        }
    }

    process
    {
        $profilePtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($profileXML)

        $setProfileResults = [WiFi.ProfileManagement]::WlanSetProfile(
                                        $clientHandle,
                                        [ref]$interfaceGuid,
                                        $flags,
                                        $profilePtr,
                                        [IntPtr]::Zero,
                                        $overwrite,
                                        [IntPtr]::Zero,
                                        [ref]$reasonCode
                                        )

        Format-WiFiReasonCode -ReasonCode $reasonCode
    }

    end
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

<#
    .SYNOPSIS
        Retrieves the list of available networks on a wireless LAN interface.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
#>
function Get-WiFiAvailableNetwork
{
    [CmdletBinding()]
    [OutputType([WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK])]
    param
    (
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )    

    begin
    {
        [System.Guid]$interfaceGUID = (Get-NetAdapter -Name $WiFiAdapterName).interfaceguid
        $clientHandle = New-WiFiHandle
        $networkPointer = 0
    }
    process
    {        
        [WiFi.ProfileManagement]::WlanGetAvailableNetworkList($clientHandle,$interfaceGUID,2,[System.IntPtr]::zero,[ref]$networkPointer)
        $availableNetowrks = [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK_LIST]::new($networkPointer)
        $availableNetowrks.wlanAvailableNetwork
    }
    end
    {        
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}
