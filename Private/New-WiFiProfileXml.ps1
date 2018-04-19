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
        [Parameter(Mandatory=$true,Position=0)]
        [System.String]
        $ProfileName,
        
        [Parameter()]
        [ValidateSet('manual','auto')]
        [System.String]
        $ConnectionMode = 'auto',
        
        [Parameter()]
        [System.String]
        $Authentication = 'WPA2PSK',
        
        [Parameter()]
        [System.String]
        $Encryption = 'AES',
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $Password   
    )
    
    process
    {
        $stringWriter = [System.IO.StringWriter]::new()
        $xmlWriter    = [System.Xml.XmlTextWriter]::new($stringWriter)

        $xmlWriter.WriteStartDocument()
        $xmlWriter.WriteStartElement("WLANProfile","http://www.microsoft.com/networking/WLAN/profile/v1");
        $xmlWriter.WriteElementString("name", "$profileName");
        $xmlWriter.WriteStartElement("SSIDConfig");
        $xmlWriter.WriteStartElement("SSID");
        $xmlWriter.WriteElementString("name", "$profileName");
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteElementString("connectionType", "ESS");
        $xmlWriter.WriteElementString("connectionMode", $ConnectionMode);
        $xmlWriter.WriteStartElement("MSM");
        $xmlWriter.WriteStartElement("security");
        $xmlWriter.WriteStartElement("authEncryption");
        $xmlWriter.WriteElementString("authentication", $Authentication);
        $xmlWriter.WriteElementString("encryption", "$Encryption");
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteStartElement("sharedKey");
        $xmlWriter.WriteElementString("keyType", "passPhrase");
        $xmlWriter.WriteElementString("protected", "false");
        $xmlWriter.WriteElementString("keyMaterial", $plainPassword);
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndElement();
        $xmlWriter.WriteEndDocument();

        $xmlWriter.Close()
        $stringWriter.ToString()
    }
}
