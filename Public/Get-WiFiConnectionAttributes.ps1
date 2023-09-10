<#
    .SYNOPSIS
        Returns the wifi connection attributes.

    .DESCRIPTION
        Returns the wifi connection attributes by calling the WlanQueryInterface function
        with the wlan_intf_opcode_current_connection opcode.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wifi adapter to retrieve the connection attributes from.

    .EXAMPLE
        Get-WiFiConnectionAttributes

        WiFiAdapter               : Wi-Fi
        InterfaceGuid             : {28A46E1B-6284-41CA-9CB6-AA4C18A9254B}
        isState                   : connected
        wlanConnectionMode        : wlan_connection_mode_profile
        strProfileName            : 145AW Commercial Wireless
        wlanAssociationAttributes : WiFi.ProfileManagement+WLAN_ASSOCIATION_ATTRIBUTES
        wlanSecurityAttributes    : WiFi.ProfileManagement+WLAN_SECURITY_ATTRIBUTES

    .EXAMPLE
        $attributes = Get-WiFiConnectionAttributes

        PS > $attributes.wlanAssociationAttributes

        dot11Ssid         : Commercial Wireless
        dot11BssType      : Infrastructure
        dot11Bssid        : 3C:3A:C3:AE:D3:3E
        dot11PhyType      : dot11_phy_type_vht
        uDot11PhyIndex    : 4
        wlanSignalQuality : 82
        ulRxRate          : 173300
        ulTxRate          : 173300

        This example illustrates how to view the wlanAssociatedAttributes.

#>
function Get-WiFiConnectionAttributes
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName
    )

    try
    {
        $interfaceInfo = Get-InterfaceInfo -WiFiAdapterName $WiFiAdapterName

        $result = @()
        $outDataCollection = @()
        $clientHandle = New-WiFiHandle

        foreach ($interface in $interfaceInfo)
        {
            $outData = [System.IntPtr]::zero
            $dataSize = [System.Runtime.InteropServices.Marshal]::SizeOf($outData)

            $resultCode = [WiFi.ProfileManagement]::WlanQueryInterface(
                $clientHandle,
                [ref] $interface.InterfaceGuid,
                [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_current_connection,
                [IntPtr]::zero,
                [ref]$dataSize,
                [ref]$outData,
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                Write-Error -Message ($script:localizedData.ErrorFailedWithExitCode -f $resultCode)
            }

            $attributes = [System.Runtime.InteropServices.Marshal]::ptrToStructure(
                $outData,
                [System.Type]([WiFi.ProfileManagement+WLAN_CONNECTION_ATTRIBUTES])
            )

            $outDataCollection += $outdata

            $result += Add-DefaultProperty -InputObject $attributes -InterfaceInfo $interface
        }

        $result
    }
    catch
    {
        $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }

        if ($outDataCollection)
        {
            Invoke-WlanFreeMemory -Pointer $outDataCollection
        }
    }
}
