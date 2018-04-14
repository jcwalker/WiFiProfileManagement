<#
    .SYNOPSIS
        Closes an open WiFi handle
    .Parameter ClientHandle
        Specifies the object that represents the open WiFi handle.
#>
function Remove-WiFiHandle
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [IntPtr]$ClientHandle
    )

    $closeHandle = [WiFi.ProfileManagement]::WlanCloseHandle($ClientHandle,[IntPtr]::zero)

    if ($closeHandle -eq 0)
    {
        Write-Verbose -Message $script:localizedData.HandleClosed
    }
    else
    {
        throw $($script:localizedData.ErrorClosingHandle)
    }
}
