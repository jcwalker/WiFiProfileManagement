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
        [Parameter()]
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
        [void][WiFi.ProfileManagement]::WlanGetAvailableNetworkList($clientHandle,$interfaceGUID,0,[IntPtr]::zero,[ref]$networkPointer)
        $availableNetworks = [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK_LIST]::new($networkPointer)
        
        foreach ($network in $availableNetworks.wlanAvailableNetwork)
        {
            [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK]$network
        }
    }
    end
    {        
        [WiFi.ProfileManagement]::WlanFreeMemory($networkPointer) 
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}
