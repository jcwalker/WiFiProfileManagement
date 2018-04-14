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
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='UsingArguments')]
        [System.String]
        $ProfileName,

        [Parameter(ParameterSetName='UsingArguments')]
        [ValidateSet('manual','auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter(ParameterSetName='UsingArguments')]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter(ParameterSetName='UsingArguments')]
        [System.String]
        $Encryption = 'AES',

        [Parameter(Mandatory=$true,ParameterSetName='UsingArguments')]
        [System.Security.SecureString]
        $Password,

        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi',

        [Parameter(Mandatory=$true,ParameterSetName='UsingXml')]
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
        $profilePointer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($profileXML)

        [WiFi.ProfileManagement]::WlanSetProfile(
                                        $clientHandle,
                                        [ref]$interfaceGuid,
                                        $flags,
                                        $profilePointer,
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
