<#
    .SYNOPSIS
        Sets the content of a specified wireless profile.
    .DESCRIPTION
        Calls the WlanSetProfile native function with override parameter set to true.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated. Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
    .PARAMETER Password
        The network key or passphrase of the wireless profile in the form of a secure string.
    .PARAMETER ConnectHiddenSSID
        Specifies whether the profile can connect to networks which does not broadcast SSID. The default is false.
    .PARAMETER EAPType
        (Only 802.1X) Specifies the type of 802.1X EAP. You can select "PEAP"(aka MSCHAPv2) or "TLS".
    .PARAMETER ServerNames
        (Only 802.1X) Specifies the server that will be connect to validate certification.
    .PARAMETER TrustedRootCA
        (Only 802.1X) Specifies the certificate thumbprint of the Trusted Root CA.
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
    [CmdletBinding(DefaultParameterSetName = 'UsingArguments')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArguments')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'UsingArgumentsWithEAP')]
        [Alias('SSID', 'Name')]
        [System.String]
        $ProfileName,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('manual', 'auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('open', 'shared', 'WPA', 'WPAPSK', 'WPA2', 'WPA2PSK', 'WPA3SAE', 'WPA3ENT192', 'OWE')]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('none', 'WEP', 'TKIP', 'AES', 'GCMP256')]
        [System.String]
        $Encryption = 'AES',

        [Parameter(ParameterSetName = 'UsingArguments')]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName = 'UsingArguments')]
        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.Boolean]
        $ConnectHiddenSSID = $false,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [ValidateSet('PEAP', 'TLS')]
        [System.String]
        $EAPType,

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [AllowEmptyString()]
        [System.String]
        $ServerNames = '',

        [Parameter(ParameterSetName = 'UsingArgumentsWithEAP')]
        [System.String]
        $TrustedRootCA,

        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter(Mandatory = $true, ParameterSetName = 'UsingXml')]
        [System.String]
        $XmlProfile
    )

    New-WiFiProfile @PSBoundParameters -Overwrite $true
}
