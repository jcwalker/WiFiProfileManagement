<#
    .SYNOPSIS
        Retrieves the information of a WiFi profile.
    .PARAMETER ProfileName
        The name of the WiFi profile. Profile names are case-sensitive.
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the native WiFi functions.
    .PARAMETER WlanProfileFlags
        A pointer to the address location used to provide additional information about the request.
#>
function Get-WiFiProfileInfo
{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ProfileName,

        [Parameter()]
        [System.Guid]
        $InterfaceGuid,

        [Parameter()]
        [System.IntPtr]
        $ClientHandle,

        [System.Int16]
        $WlanProfileFlags
    )
    
    begin
    {
        [String]$pstrProfileXml = $null
        $wlanAccess = 0
        $WlanProfileFlagsInput = $WlanProfileFlags
    }
    process
    {
        $result = [WiFi.ProfileManagement]::WlanGetProfile(
            $ClientHandle,
            $InterfaceGuid,
            $ProfileName,
            [IntPtr]::Zero,
            [ref]$pstrProfileXml,
            [ref]$WlanProfileFlags,
            [ref]$wlanAccess
        )

        if ($result -ne 0)
        {
            $errorMessage = Format-Win32Exception -ReturnCode $result
            throw $($script:localizedData.ErrorGettingProfile -f $errorMessage)
        }

        $wlanProfile = [xml]$pstrProfileXml

        #Parse password
        if ($WlanProfileFlagsInput -eq 13)
        {
            $password = $wlanProfile.WLANProfile.MSM.security.sharedKey.keyMaterial
        }
        else
        {
            $password = $null
        }

        # Parse nonBroadcast flag
        if ([bool]::TryParse($wlanProfile.WLANProfile.SSIDConfig.nonBroadcast, [ref]$null))
        {
            $connectHiddenSSID = [bool]::Parse($wlanProfile.WLANProfile.SSIDConfig.nonBroadcast)
        }
        else
        {
            $connectHiddenSSID = $false
        }

        # Parse EAP type
        if ($wlanProfile.WLANProfile.MSM.security.authEncryption.useOneX -eq 'true')
        {
            switch ($wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.EapMethod.Type.InnerText)
            {
                '25'    #EAP-PEAP (MSCHAPv2)
                {
                    $eapType = 'PEAP'
                }

                '13'    #EAP-TLS
                {
                    $eapType = 'TLS'
                }

                Default
                {
                    $eapType = 'Unknown'
                }
            }
        }
        else
        {
            $eapType = $null
        }

        # Parse Validation Server Name
        if ($null -ne $eapType)
        {
            switch ($eapType)
            {
                'PEAP'
                { 
                    $serverNames = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.ServerNames
                }

                'TLS'
                {
                    $node = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='ServerNames']")
                    $serverNames = $node[0].InnerText
                }
            }
        }

        # Parse Validation TrustedRootCA
        if ($null -ne $eapType)
        {
            switch ($eapType)
            {
                'PEAP'
                { 
                    $trustedRootCa = ([string]($wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.TrustedRootCA -replace ' ', [string]::Empty)).ToLower()
                }

                'TLS'
                {
                    $node = $wlanProfile.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='TrustedRootCA']")
                    $trustedRootCa = ([string]($node[0].InnerText -replace ' ', [string]::Empty)).ToLower()
                }
            }
        }


        [WiFi.ProfileManagement+ProfileInfo]@{
            ProfileName       = $wlanProfile.WLANProfile.SSIDConfig.SSID.name
            ConnectionMode    = $wlanProfile.WLANProfile.connectionMode
            Authentication    = $wlanProfile.WLANProfile.MSM.security.authEncryption.authentication
            Encryption        = $wlanProfile.WLANProfile.MSM.security.authEncryption.encryption
            Password          = $password
            ConnectHiddenSSID = $connectHiddenSSID
            EAPType           = $eapType
            ServerNames       = $serverNames
            TrustedRootCA     = $trustedRootCa
            Xml               = $pstrProfileXml
        }
    }
    end
    {
        $xmlPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAuto($pstrProfileXml)
        Invoke-WlanFreeMemory -Pointer $xmlPtr
    }
}
