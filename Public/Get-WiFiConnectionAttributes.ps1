<#
    .SYNOPSIS
        Returns the wifi connection attributes.

    .DESCRIPTION
        Returns the wifi connection attributes by calling the WlanQueryInterface function
        with the wlan_intf_opcode_current_connection opcode.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wifi adapter to retrieve the connection attributes from.

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
                return $resultCode
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

        if ($outData)
        {
            Invoke-WlanFreeMemory -Pointer $outDataCollection
        }
    }
}
