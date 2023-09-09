function Get-WiFiInterfaceInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter()]
        [ValidateSet('RSSI','ConnectionAttributes')]
        [string]
        $InfoType = 'ConnectionAttributes'
    )

    try
    {
        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        {
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        $opCodeMap = @{
            RSSI = [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_rssi
            ConnectionAttributes = [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_current_connection
        }

        $outData = [System.IntPtr]::zero
        $dataSize = [System.Runtime.InteropServices.Marshal]::SizeOf($outData)
        #$dataSize = [System.UInt32]::new()
        $opCode = $opCodeMap[$InfoType]

        foreach ($interfaceGuid in $interfaceGuids)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanQueryInterface(
                $clientHandle, # handle
                [ref] $interfaceGuid, #interfaceGuid
                $opCode, # opcode
                [IntPtr]::zero, # resrved
                [ref]$dataSize, # out pdwDataSize
                [ref]$outData, # out ppData
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                return $resultCode
            }

            if ($InfoType -eq 'ConnectionAttributes')
            {
                [System.Runtime.InteropServices.Marshal]::ptrToStructure($outData, [System.Type]([WiFi.ProfileManagement+WLAN_CONNECTION_ATTRIBUTES]))
            }
        }
    }
    catch
    {
        Write-Error -Exception $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }

        if ($outData)
        {
            Invoke-WlanFreeMemory -Pointer $outData
        }
    }
}

#https://social.msdn.microsoft.com/forums/windowsdesktop/en-us/a2daf71e-b0f2-4d0d-bbf0-54518881cafd/use-native-wlan-api-in-managed-code
#https://github.com/coolshou/WlanQuery/blob/fa61dd63fbab250818fd94bb44b24ef8b9149588/src/WlanQuery.cpp#L358
