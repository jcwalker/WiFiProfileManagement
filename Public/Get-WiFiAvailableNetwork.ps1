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
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706749(v=vs.85).aspx
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

    $interfaceGUID = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName -ErrorAction Stop
    $clientHandle = New-WiFiHandle
    $networkPointer = 0
    $flag = 0

    try
    {
        $result = [WiFi.ProfileManagement]::WlanGetAvailableNetworkList(
            $clientHandle,
            $interfaceGUID,
            $flag,
            [IntPtr]::zero,
            [ref]$networkPointer
        )

        if ( $result -ne 0 )
        {
            $errorMessage = Format-Win32Exception -ReturnCode $result
            throw $($script:localizedData.ErrorGetAvailableNetworkList -f $errorMessage)
        }

        $availableNetworks = [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK_LIST]::new($networkPointer)

        foreach ($network in $availableNetworks.wlanAvailableNetwork)
        {
            [WiFi.ProfileManagement+WLAN_AVAILABLE_NETWORK]$network
        }
    }
    catch
    {
        Write-Error $_
    }
    finally
    {
        Invoke-WlanFreeMemory -Pointer $networkPointer

        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
    
}
