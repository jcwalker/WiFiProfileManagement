<#
    .SYNOPSIS
        Attempts to connect to a specific network.
    .PARAMETER ProfileName
        The name of the profile to be connected. Profile names are case-sensitive.
    .PARAMETER ConnectionMode
        Specifies the mode of the connection. Valid values are Profile,TemporaryProfile,DiscoveryProfile,DiscoveryUnsecure, and Auto.
    .PARAMETER Dot11BssType
        A value that indicates the BSS type of the network. If a profile is provided, this BSS type must be the same as the one in the profile.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
        PS C:\>Connect-WiFiProfile -ProfileName FreeWiFi

        This example connects to the FreeWiFi profile which is already saved on the local machine.
    .EXAMPLE
        PS C:\> $password = Read-Host -AsSecureString
        ************

        PS C:\> New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password

        The operation was successful.
        PS C:\> Connect-WiFiProfile -ProfileName MyNetwork

        This example demonstrates how to create a WiFi profile and then connect to it.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706613(v=vs.85).aspx
#>
function Connect-WiFiProfile
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto')]
        [System.String]
        $ConnectionMode = 'Profile',

        [Parameter()]
        [ValidateSet('Any', 'Independent', 'Infrastructure')]
        [System.String]
        $Dot11BssType = 'Any',

        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName -ErrorAction Stop
    }
    process
    {
        try
        {
            $clientHandle = New-WiFiHandle

            $connectionParameterList = New-WiFiConnectionParameter -ProfileName $ProfileName -ConnectionMode $ConnectionMode -Dot11BssType $Dot11BssType

            Invoke-WlanConnect -ClientHandle $clientHandle -InterfaceGuid $interfaceGuid -ConnectionParameterList $connectionParameterList
        }
        catch
        {
            Write-Error $PSItem
        }
        finally
        {
            if ($clientHandle)
            {
                Remove-WiFiHandle -ClientHandle $clientHandle
            }
        }
    }
}
