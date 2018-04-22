<#
    .SYNOPSIS
        Creates a WLAN_CONNECTION_PARAMETERS structure that contains the requried parameters when using the WlanConnect function
    .PARAMETER ProfileName
        The name of the profile to connect to. Profile names are case-sensitive.
    .PARAMETER ConnectionMode
        Specifies the mode of connection. Valid values are 'Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto'
    .PARAMETER Dot11BssType
        A value that indicates the BSS type of the network. If a profile is provided, this BSS type must be the same as the one in the profile.
    .NOTES
        https://msdn.microsoft.com/en-us/library/windows/desktop/ms706851(v=vs.85).aspx
#>
function New-WiFiConnectionParameter
{
    [OutputType([WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('Profile', 'TemporaryProfile', 'DiscoverySecure', 'DiscoveryUnsecure', 'Auto')]
        [System.String]
        $ConnectionMode = 'Profile',

        [Parameter()]
        [ValidateSet('Any','Independent','Infrastructure')]
        [WiFi.ProfileManagement+DOT11_BSS_TYPE]
        $Dot11BssType = 'Any',

        [Parameter()]
        [WiFi.ProfileManagement+WlanConnectionFlag]
        $Flag = 'Default'
    )

    try
    {
        #region resolvers
        $connectionModeResolver = @{
            Profile           = 'wlan_connection_mode_profile'
            TemporaryProfile  = 'wlan_connection_mode_temporary_profile'
            DiscoverySecure   = 'wlan_connection_mode_discovery_secure'
            DiscoveryUnsecure = 'wlan_connection_mode_discovery_unsecure'
            Auto              = 'wlan_connection_mode_auto'
        }
        #endregion

        $connectionParameters = [WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS]::new()
        $connectionParameters.strProfile = $ProfileName
        $connectionParameters.wlanConnectionMode = [WiFi.ProfileManagement+WLAN_CONNECTION_MODE]::$($connectionModeResolver[$ConnectionMode])
        $connectionParameters.dot11BssType = [WiFi.ProfileManagement+DOT11_BSS_TYPE]::$Dot11BssType
        $connectionParameters.dwFlags = [WiFi.ProfileManagement+WlanConnectionFlag]::$Flag
    }
    catch
    {
        throw $_
    }

    return $connectionParameters
}
