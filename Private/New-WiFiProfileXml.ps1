$script:WiFiProfileXmlPersonal = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>{5}</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
</WLANProfile>
"@

$script:WiFiProfileXmlEapPeap = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>true</useOneX>
      </authEncryption>
      <PMKCacheMode>enabled</PMKCacheMode>
      <PMKCacheTTL>720</PMKCacheTTL>
      <PMKCacheSize>128</PMKCacheSize>
      <preAuthMode>disabled</preAuthMode>
      <OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
        <authMode>machineOrUser</authMode>
        <EAPConfig>
          <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
            <EapMethod>
              <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">25</Type>
              <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
              <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
              <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
            </EapMethod>
            <Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
              <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                <Type>25</Type>
                <EapType xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1">
                  <ServerValidation>
                    <DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation>
                    <ServerNames></ServerNames>
                    <TrustedRootCA></TrustedRootCA>
                  </ServerValidation>
                  <FastReconnect>true</FastReconnect>
                  <InnerEapOptional>false</InnerEapOptional>
                  <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                    <Type>26</Type>
                    <EapType xmlns="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1">
                      <UseWinLogonCredentials>false</UseWinLogonCredentials>
                    </EapType>
                  </Eap>
                  <EnableQuarantineChecks>false</EnableQuarantineChecks>
                  <RequireCryptoBinding>false</RequireCryptoBinding>
                  <PeapExtensions>
                    <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</PerformServerValidation>
                    <AcceptServerName xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</AcceptServerName>
                    <PeapExtensionsV2 xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">
                      <AllowPromptingWhenServerCANotFound xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV3">true</AllowPromptingWhenServerCANotFound>
                    </PeapExtensionsV2>
                  </PeapExtensions>
                </EapType>
              </Eap>
            </Config>
          </EapHostConfig>
        </EAPConfig>
      </OneX>
    </security>
  </MSM>
</WLANProfile>
"@

$script:WiFiProfileXmlEapTls = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>{0}</name>
  <SSIDConfig>
    <SSID>
      <name>{0}</name>
    </SSID>
    <nonBroadcast>{1}</nonBroadcast>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>{2}</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>{3}</authentication>
        <encryption>{4}</encryption>
        <useOneX>true</useOneX>
      </authEncryption>
      <PMKCacheMode>enabled</PMKCacheMode>
      <PMKCacheTTL>720</PMKCacheTTL>
      <PMKCacheSize>128</PMKCacheSize>
      <preAuthMode>disabled</preAuthMode>
      <OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
        <authMode>machineOrUser</authMode>
        <EAPConfig>
          <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
            <EapMethod>
              <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type>
              <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
              <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
              <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
            </EapMethod>
            <Config xmlns:baseEap="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1" xmlns:eapTls="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
              <baseEap:Eap>
                <baseEap:Type>13</baseEap:Type>
                <eapTls:EapType>
                  <eapTls:CredentialsSource>
                    <eapTls:CertificateStore />
                  </eapTls:CredentialsSource>
                  <eapTls:ServerValidation>
                    <eapTls:DisableUserPromptForServerValidation>false</eapTls:DisableUserPromptForServerValidation>
                    <eapTls:ServerNames></eapTls:ServerNames>
                    <eapTls:TrustedRootCA></eapTls:TrustedRootCA>
                  </eapTls:ServerValidation>
                  <eapTls:DifferentUsername>false</eapTls:DifferentUsername>
                </eapTls:EapType>
              </baseEap:Eap>
            </Config>
          </EapHostConfig>
        </EAPConfig>
      </OneX>
    </security>
  </MSM>
</WLANProfile>
"@


<#
    .SYNOPSIS
        Create a string of XML that represents the wireless profile.
    .PARAMETER ProfileName
        The name of the wireless profile to be updated.  Profile names are case sensitive.
    .PARAMETER ConnectionMode
        Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
    .PARAMETER Authentication
        Specifies the authentication method to be used to connect to the wireless LAN.
    .PARAMETER Encryption
        Sets the data encryption to use to connect to the wireless LAN.
#>
function New-WiFiProfileXml
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $ProfileName,

        [Parameter()]
        [ValidateSet('manual', 'auto')]
        [System.String]
        $ConnectionMode = 'auto',

        [Parameter()]
        [System.String]
        $Authentication = 'WPA2PSK',

        [Parameter()]
        [System.String]
        $Encryption = 'AES',

        [Parameter()]
        [System.Security.SecureString]
        $Password,

        [Parameter()]
        [System.Boolean]
        $ConnectHiddenSSID = $false,

        [Parameter()]
        [System.String]
        $EAPType,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $ServerNames = '',

        [Parameter()]
        [System.String]
        $TrustedRootCA
    )

    try
    {
        if ($Password)
        {
            $secureStringToBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secureStringToBstr) 
        }

        if ($EAPType -eq 'PEAP')
        {
            $profileXml = [xml]($script:WiFiProfileXmlEapPeap -f $ProfileName, ([string]$ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption)

            if ($ServerNames)
            {
                $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.ServerNames = $ServerNames
            }

            if ($TrustedRootCA)
            {
                [string]$formattedCaHash = $TrustedRootCA -replace '..', '$& '
                $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.TrustedRootCA = $formattedCaHash
            }
        }
        elseif ($EAPType -eq 'TLS')
        {
            $profileXml = [xml]($script:WiFiProfileXmlEapTls -f $ProfileName, ([string]$ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption)

            if ($ServerNames)
            {
                $node = $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='ServerNames']")
                $node[0].InnerText = $ServerNames
            }

            if ($TrustedRootCA)
            {
                [string]$formattedCaHash = $TrustedRootCA -replace '..', '$& '
                $node = $profileXml.WLANProfile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.SelectNodes("//*[local-name()='TrustedRootCA']")
                $node[0].InnerText = $formattedCaHash
            }
        }
        else
        {
            $profileXml = [xml]($script:WiFiProfileXmlPersonal -f $ProfileName, ([string]$ConnectHiddenSSID).ToLower(), $ConnectionMode, $Authentication, $Encryption, $plainPassword)
            if (-not $plainPassword)
            {
                $null = $profileXml.WLANProfile.MSM.security.RemoveChild($profileXml.WLANProfile.MSM.security.sharedKey)
            }

            if ($Authentication -eq 'WPA3SAE'){
              # Set transition mode as true for WPA3-SAE
              $nsmg = [System.Xml.XmlNamespaceManager]::new($profileXml.NameTable)
              $nsmg.AddNamespace('WLANProfile', $profileXml.DocumentElement.GetAttribute('xmlns'))
              $refNode = $profileXml.SelectSingleNode('//WLANProfile:authEncryption', $nsmg)
              $xmlnode = $profileXml.CreateElement('transitionMode', 'http://www.microsoft.com/networking/WLAN/profile/v4')
              $xmlnode.InnerText = 'true'
              $null = $refNode.AppendChild($xmlnode)
            }
        }

        $profileXml.OuterXml
    }
    catch
    {
        throw $_
    }
}
