
$script:localizedData = Import-LocalizedData -BaseDirectory "$PSScriptRoot\en-US" -FileName WiFiProfileManagement.strings.psd1
<#
    .SYNOPSIS
        Retrieves the guid of the network interface.
    .PARAMETER WiFiAdapterName
        The name of the wireless network adapter.
#>
function Get-WiFiInterfaceGuid
{
    [CmdletBinding()]
    [OutputType([System.Guid])]
    param 
    (
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )
    $osVersion = [Environment]::OSVersion.Version

    if ($osVersion -ge ([Version] 6.2))
    {
        [Guid]$interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName).interfaceguid
    }
    else
    {
        $wifiAdapterInfo = Get-WmiObject -Query "select Name, NetConnectionID from Win32_NetworkAdapter where NetConnectionID = '$WiFiAdapterName'"
        [Guid]$interfaceGuid = (Get-WmiObject -Query "select SettingID from Win32_NetworkAdapterConfiguration where Description = '$($wifiAdapterInfo.Name)'").SettingID
    }

    return $interfaceGuid
}

<#
    .SYNOPSIS
        Opens a WiFi handle
#>
function New-WiFiHandle
{    
    [CmdletBinding()]
    [OutputType([System.IntPtr])]
    param()

    $maxClient = 2
    [Ref]$negotiatedVersion = 0
    $clientHandle = [IntPtr]::zero

    $handle = [WiFi.ProfileManagement]::WlanOpenHandle($maxClient,[IntPtr]::Zero,$negotiatedVersion,[ref]$clientHandle)
    
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
        Closes an open WiFi handle
    .Parameter ClientHandle
        Specifies the object that represents the open WiFi handle.
#>
function Remove-WiFiHandle
{
    [CmdletBinding()]
    param
    (
        [IntPtr]$ClientHandle    
    )

    $closeHandle = [WiFi.ProfileManagement]::WlanCloseHandle($ClientHandle,[IntPtr]::zero)

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

        Get the WiFi profile information on wireless profile TestWiFi

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
        [String]$pstrProfileXml = $null
        $wlanAccess = 0
        $ProfileListPtr = 0
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName

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
        [Guid]$interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName).interfaceguid
        if (!$ProfileName)
        {
            [WiFi.ProfileManagement]::WlanGetProfileList($clientHandle,$interfaceGUID,[IntPtr]::zero,[ref]$ProfileListPtr) | Out-Null
            $WiFiProfileList = [WiFi.ProfileManagement+WLAN_PROFILE_INFO_LIST]::new($ProfileListPtr)
            $ProfileName = ($WiFiProfileList.ProfileInfo).strProfileName
        }

        foreach ($WiFiProfile in $ProfileName)
        {
            Get-WiFiProfileInfo -ProfileName $WiFiProfile -InterfaceGuid $interfaceGUID -ClientHandle $clientHandle -WlanProfileFlags $wlanProfileFlags
        }        
    }
    end
    {        
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}

<#
    .SYNOPSIS
        Deletes a WiFi profile.
    .PARAMETER ProfileName
        The name of the profile to be deleted. Profile names are case-sensitive.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
    C:\>Remove-WiFiProfile -ProfileName FreeWiFi

    This examples deletes the FreeWiFi profile.
#>
function Remove-WiFiProfile
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    Param 
    (
        [Parameter(Position = 0,Mandatory=$true,ValueFromPipeLine=$true)]
        [System.String[]]
        $ProfileName,

        [Parameter(Position = 1,Mandatory=$false)]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        $interfaceGUID = Get-WiFiInterfaceGuid
        $clientHandle = New-WiFiHandle
    }
    process
    {
        foreach ($WiFiProfile in $ProfileName)
        {
            if ($PSCmdlet.ShouldProcess("$($script:localizedData.ShouldProcessDelete -f $WiFiProfile)"))
            {
                $deleteProfileResult = [WiFi.ProfileManagement]::WlanDeleteProfile($clientHandle,$interfaceGUID,$ProfileName,[IntPtr]::zero)            

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

    $stringBuilder = [Text.StringBuilder]::new(1024)
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
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        $flags = 0
        $allUserProfileSecurity = [IntPtr]::zero
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
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
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
    .EXAMPLE
        PS C:\>Get-WiFiAvailableNetwork

        SSID         SignalStength SecurityEnabled  dot11DefaultAuthAlgorithm dot11DefaultCipherAlgorithm
        ----         ------------- ---------------  ------------------------- ---------------------------
                                63            True   DOT11_AUTH_ALGO_RSNA_PSK      DOT11_CIPHER_ALGO_CCMP
        gogoinflight            63           False DOT11_AUTH_ALGO_80211_OPEN      DOT11_CIPHER_ALGO_NONE
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
        $interfaceGUID = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        $clientHandle = New-WiFiHandle
        $networkPointer = 0
    }
    process
    {        
        [void][WiFi.ProfileManagement]::WlanGetAvailableNetworkList($clientHandle,$interfaceGUID,2,[IntPtr]::zero,[ref]$networkPointer)
        $availableNetworks = [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK_LIST]::new($networkPointer)
        
        foreach ($network in $availableNetworks.wlanAvailableNetwork)
        {
            <#
            [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK]@{
                SSID = $network.dot11Ssid.ucSSID
                SignalStength = $network.wlanSignalQuality
                SecurityEnabled = $network.bSecurityEnabled
                dot11DefaultAuthAlgorithm = $network.dot11DefaultAuthAlgorithm
                dot11DefaultCipherAlgorithm = $network.dot11DefaultCipherAlgorithm
            }
            #>
            [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK]$network
        }
    }
    end
    {        
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}
