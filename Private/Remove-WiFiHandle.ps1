<#
    .SYNOPSIS
        Closes an open WiFi handle
    .Parameter ClientHandle
        Specifies the object that represents the open WiFi handle.
#>
function Remove-WiFiHandle
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.IntPtr]
        $ClientHandle
    )

    $result = [WiFi.ProfileManagement]::WlanCloseHandle($ClientHandle, [IntPtr]::zero)

    if ($result -eq 0)
    {
        Write-Verbose -Message ($script:localizedData.HandleClosed)
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorClosingHandle -f $errorMessage)
    }
}
