<#
    .SYNOPSIS
        Retrieves the RSSI (Received signal strength indicator.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wifi adapter to get the RSSI from.

    .EXAMPLE
        Get-WiFiRssi

        RSSI
        ----
        -61

        This examples retrieves the RSSI from the default wifi network adaptor.

#>
function Get-WiFiRssi
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
        $result = @()
        $pointerCollection = @()
        $interfaceInfo = Get-InterfaceInfo -WiFiAdapterName $WiFiAdapterName
        $clientHandle = New-WiFiHandle

        $outData = [System.IntPtr]::zero
        [int]$dataSize = 0
        [WiFi.ProfileManagement+WLAN_OPCODE_VALUE_TYPE]$opcodeValueType = 0

        foreach ($interface in $interfaceInfo)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanQueryInterface(
                $clientHandle,
                [ref] $interface.InterfaceGuid,
                [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_rssi,
                [IntPtr]::zero,
                [ref]$dataSize,
                [ref]$outData,
                $opcodeValueType #[IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                return $resultCode
            }

            $pointerCollection += $outData
            $rssi = [PSCustomObject]@{
                Rssi = [System.Runtime.InteropServices.Marshal]::ReadInt32($outData)
            }

            $result += Add-DefaultProperty -InputObject $rssi -InterfaceInfo $interface
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

        if ($outData)
        {
            Invoke-WlanFreeMemory -Pointer $pointerCollection
        }
    }
}
