<#
    .SYNOPSIS
        An internal function to format the reason code returned by WlanSetProfile
    .PARAMETER ReasonCode
        A value that indicates why the profile failed.
#>
function Format-WiFiReasonCode
{
    [OutputType([System.String])]
    [Cmdletbinding()]
    param
    (
        [Parameter()]
        [System.IntPtr]
        $ReasonCode
    )

    $stringBuilder = New-Object -TypeName Text.StringBuilder
    $stringBuilder.Capacity = 1024

    $result = [WiFi.ProfileManagement]::WlanReasonCodeToString(
        $ReasonCode.ToInt32(),
        $stringBuilder.Capacity,
        $stringBuilder,
        [IntPtr]::zero
    )

    if ($result -ne 0)
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        Write-Error -Message ($script:localizedData.ErrorReasonCode -f $errorMessage)
    }

    return $stringBuilder.ToString()
}
