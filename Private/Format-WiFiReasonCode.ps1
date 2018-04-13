<#
    .SYNOPSIS
        An internal function to format the reason code returned by WlanSetProfile
    .PARAMETER ReasonCode
        A vlaue that indicates why the profile failed.
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
    [WiFi.ProfileManagement]::WlanReasonCodeToString($ReasonCode.ToInt32(),$stringBuilder.Capacity,$stringBuilder,[IntPtr]::zero) | Out-Null

    return $stringBuilder.ToString()
}
