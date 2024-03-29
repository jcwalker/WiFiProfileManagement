<#
    .SYNOPSIS
        Toggles the software wifi radio state on/off.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .PARAMETER State
        Specifies the state of the wifi radio.  Valid values are on/off.

    .EXAMPLE
        Set-WiFiInterface -State On

        In this example the wifi radio is being turned on.

    .EXAMPLE
        Set-WiFiInterface -State Off

        In this example the wifi radio is being turned off.
#>
function Set-WiFiInterface
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('On','Off')]
        [string]
        $State
    )

    try
    {
        $interfaceInfo = Get-InterfaceInfo -WiFiAdapterName $WiFiAdapterName

        $clientHandle = New-WiFiHandle

        $radioStatePtr = [System.IntPtr]::new(0L)
        $radioState = [WiFi.ProfileManagement+WlanPhyRadioState]::new()
        $radioState.dot11SoftwareRadioState = [WiFi.ProfileManagement+Dot11RadioState]::$State
        $radioState.dot11HardwareRadioState = [WiFi.ProfileManagement+Dot11RadioState]::$State
        $opCode = [WiFi.ProfileManagement+WLAN_INTF_OPCODE]::wlan_intf_opcode_radio_state
        $radioStateSize = [System.Runtime.InteropServices.Marshal]::SizeOf($radioState)
        $radioStatePtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($radioStateSize)

        [System.Runtime.InteropServices.Marshal]::StructureToPtr($radioState, $radioStatePtr, $false)

        foreach ($interface in $interfaceInfo)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanSetInterface(
                $clientHandle,
                [ref] $interface.InterfaceGuid,
                $opCode,
                [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type]([WiFi.ProfileManagement+WlanPhyRadioState])),
                $radioStatePtr,
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                $resultCode
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
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($radioStatePtr)
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}
