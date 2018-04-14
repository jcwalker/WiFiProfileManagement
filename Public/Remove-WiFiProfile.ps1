<#
    .SYNOPSIS
        Deletes a WiFi profile.
    .PARAMETER ProfileName
        The name of the profile to be deleted. Profile names are case-sensitive.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
    C:\>Remove-WiFiProfile -ProfileName FreeWiFi

    This examples deletes the FreeWiFi profile.
#>
function Remove-WiFiProfile
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    Param 
    (
        [Parameter(Position = 0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [System.String[]]
        $ProfileName,

        [Parameter(Position = 1,Mandatory=$false)]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    begin
    {
        $interfaceGUID = Get-WiFiInterfaceGuid
        $clientHandle = New-WiFiHandle
    }
    process
    {
        foreach ($wiFiProfile in $ProfileName)
        {
            if ($PSCmdlet.ShouldProcess("$($script:localizedData.ShouldProcessDelete -f $WiFiProfile)"))
            {
                $deleteProfileResult = [WiFi.ProfileManagement]::WlanDeleteProfile($clientHandle,$interfaceGUID,$wiFiProfile,[IntPtr]::zero)            

                if ($deleteProfileResult -ne 0)
                {
                    throw $($script:localizedData.ErrorDeletingProfile -f $deleteProfileResult)
                }
            }
        }
    }
    end
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}
