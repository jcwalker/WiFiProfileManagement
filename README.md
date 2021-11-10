[![Build Status](https://ci.appveyor.com/api/projects/status/github/jcwalker/wifiprofilemanagement?branch=master&svg=true)](https://ci.appveyor.com/project/jcwalker/wifiprofilemanagement/branch/master)

# WiFiProfileManagement
Module used for management of wireless profiles.

This module leverages the native WiFi functions.  I wanted to learn more about interoperability and have a PowerShell (not using netsh.exe) way to view passwords of WiFi profiles so I decided to work
on this in my free time.  Any feedback on how this module can be improved is welcome.

## How to use 
Drop the root folder in your PSModulePath, remove the branch name (ex. -dev )from the folder, and PowerShell should find the module.

## Functions
* **Get-WiFiProfile** Retrieves the information of a WiFi profile.
* **Set-WiFiProfile** Overwrites a existent WiFi profile.
* **New-WiFiProfile** Creates a new WiFi profile.
* **Remove-WiFiProfile** Deletes a WiFi profile.
* **Get-WiFiAvailableNetwork** Retrieves the list of available networks on a wireless LAN interface.
* **Connect-WiFiProfile** Attempts to connect to a specific network.

### Get-WiFiProfile
* **ProfileName**: The name of the WiFi profile. If not specified, The function will return all profiles.
* **WiFiAdapterName**: Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface. The default value is 'Wi-Fi'
* **ClearKey**: Specifies if the password of the profile is to be returned.

### Set-WiFiProfile
* **ProfileName**: The name of the WiFi profile to modify.
* **ConnectionMode**: Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user. The default is "auto".
* **Authentication**: Specifies the authentication method to be used to connect to the wireless LAN. ('open', 'shared', 'WPA', 'WPAPSK', 'WPA2', 'WPA2PSK', 'WPA3SAE', 'WPA3ENT192', 'OWE')
* **Encryption**: Sets the data encryption to use to connect to the wireless LAN. ('none', 'WEP', 'TKIP', 'AES', 'GCMP256')
* **Password**: The network key or passpharse of the wireless profile in the form of a secure string.
* **ConnectHiddenSSID**: Specifies whether the profile can connect to networks which does not broadcast SSID. The default is false.
* **EAPType**: (Only 802.1X) Specifies the type of 802.1X EAP. You can select "PEAP"(aka MSCHAPv2) or "TLS".
* **ServerNames**: (Only 802.1X) Specifies the server that will be connect to validate certification.
* **TrustedRootCA**: (Only 802.1X) Specifies the certificate thumbprint of the Trusted Root CA.
* **XmlProfile**: The XML representation of the profile.

### New-WiFiProfile
* **ProfileName**: The name of the new WiFi profile.
* **ConnectionMode**: Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user. The default is "auto".
* **Authentication**: Specifies the authentication method to be used to connect to the wireless LAN. ('open', 'shared', 'WPA', 'WPAPSK', 'WPA2', 'WPA2PSK', 'WPA3SAE', 'WPA3ENT192', 'OWE')
* **Encryption**: Sets the data encryption to use to connect to the wireless LAN. ('none', 'WEP', 'TKIP', 'AES', 'GCMP256')
* **Password**: The network key or passpharse of the wireless profile in the form of a secure string.
* **XmlProfile**: The XML representation of the profile. 

## Examples

### Get the WiFi profile information on wireless profile TestWifi
```PowerShell
PS C:\>Get-WiFiProfile -ProfileName TestWiFi

        ProfileName    : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       :
```

### Obtaining the password for wireless profile TestWifi
```PowerShell
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi -ClearKey

        ProfileName    : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       : password1
```

### Deleting a WiFi profile
```PowerShell
PS C:\>Remove-WiFiProfile -ProfileName FreeWifi
```

### Updating a wireless profile
```PowerShell
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>Set-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password
```

### Updating a wireless profile using the XmlProfile parameter.
```PowerShell
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>Set-WiFiProfile -XmlProfile $templateProfileXML
```

### Creating a wireless profile
```PowerShell
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password
```

### Creating a wireless profile (Use 802.1X)
```PowerShell
        PS C:\>New-WiFiProfile -ProfileName OneXNetwork -ConnectionMode auto -Authentication WPA2 -Encryption AES -EAPType PEAP -TrustedRootCA '041101cca5b336a9c6e50d173489f5929e1b4b00'
```

### List available WiFi networks
```PowerShell
        PS C:\>Get-WiFiAvailableNetwork

        SSID         SignalStength SecurityEnabled  dot11DefaultAuthAlgorithm dot11DefaultCipherAlgorithm
        ----         ------------- ---------------  ------------------------- ---------------------------
                                63            True   DOT11_AUTH_ALGO_RSNA_PSK      DOT11_CIPHER_ALGO_CCMP
        gogoinflight            63           False DOT11_AUTH_ALGO_80211_OPEN      DOT11_CIPHER_ALGO_NONE
```

### Connect to a WiFi profile
```PowerShell
        PS C:\> $password = Read-Host -AsSecureString
        ************

        PS C:\> New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password

        The operation was successful.
        PS C:\> Connect-WiFiProfile -ProfileName MyNetwork
```

## Versions

### Unreleased
*   Added support for WPA3-Personal (WPA3SAE), WPA3-Enterprise (WPA3ENT192) and Wi-Fi Enhanced Open (OWE).

### 0.5.0.0
*   Added support for create IEEE 802.1X EAP network profile.

### 0.4.0.1
*   Added Connect-WiFiProfile.  Add new scaffolding.

### 0.4.0.0
*    Added Get-WiFiAvailableNetwork.  Moved code that enables Windows 7 compatibility to a function.

### 0.3.0.0
*    Added New-WiFiProfile

### 0.2.1.0
*    Added Set-WiFiProfile

### 0.1.1.0
*    Added formating

### 0.1.0.0
*    Initial released with the following functions
     * Get-WiFiProfile
     * Remove-WiFiProfile
