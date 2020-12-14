# Azure-VPN

Use Import-AzureVPNConnection.ps1 script in case your machines are still not updated to W10 1909. In case they are 1909 and higher, VPN connection can be imported using the Configuration Profiles in Intune / MEM (https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-profile-intune).

Script is used to create rasphone.pbk file with VPN configuration used in Azure VPN Client and create a new VPN connection ready to be used. Code should determine whether the folder with installation already exists and create it if it's missing. Additionally, if you run the script multiple times, old rasphone.pbk file should be just renamed in case it's required later or as a backup. Log / transcript will track all actions which were performed by the script and capture possible errors.

HOW TO USE SCRIPT WITH INTUNE?

1. Take file "azurvpnconfig.xml" containing your custom VPN configuration and import it manually to your Azure VPN Client using the command "AzureVpn.exe -i azurevpnconfig.xml" run from CMD
2. When you run the command, file rasphone.pbk will be created in "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState" - this file contains the actual configuration used by VPN client
3. Open rasphone.pbk file with notepad and copy the whole content (CTRL + A) to variable $PBKFileDetails
4. Save the script
5. Run it from Powershell ISE, it should create two files in "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState":

NewAzureVPNConnectionLog_$Date - Log/Transcript of the processed steps in the script (for example "NewAzureVPNConnectionLog_05-05-2020_12_23_05.log")
rasphone.pbk - File serving as a "bridge" for VPN configuration, configuration is not visible in Azure VPN Client without this file

6. When you determine that VPN connection is working successfully, upload the script to Intune and insert your clients / users in the scope
7. Latest functionality being added is adding the key in Registry which will show the VPN connection in native VPN settings in Windows 10 (otherwise connection would just appear in Azure VPN client application)
