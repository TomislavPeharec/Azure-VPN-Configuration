<#

.SYNOPSIS
Import VPN configuration from rasphone.pbk file into Azure VPN Client

.DESCRIPTION
Script is used to create rasphone.pbk file with VPN configuration used in Azure VPN Client and create a new VPN connection ready to be used. Code should determine whether the folder with installation already
exists and create it if it's missing. Additionally, if you run the script multiple times, old rasphone.pbk file should be just renamed in case it's required later or as a backup. Log / transcript will track all
actions which were performed by the script and capture possible errors.
In case your machines are using W10 1909 and higher, VPN connection for Azure VPN can be imported using Configuration Profile in Intune.

* HOW TO USE SCRIPT WITH INTUNE? *

1. Take file "azurvpnconfig.xml" containing your custom VPN configuration and import it manually to your Azure VPN Client using the command "AzureVpn.exe -i azurevpnconfig.xml" run from CMD
2. When you run the command, file rasphone.pbk will be created in "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState" - this file contains the actual configuration used by VPN client
3. Open rasphone.pbk file with notepad and copy the whole content (CTRL + A) to variable $PBKFileDetails
4. Save the script
5. Run it from Powershell ISE, it should create two files in "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState":

NewAzureVPNConnectionLog_$Date - Log/Transcript of the processed steps in the script (for example "NewAzureVPNConnectionLog_05-05-2020_12_23_05.log")
rasphone.pbk - File serving as a "bridge" for VPN configuration, configuration is not visible in Azure VPN Client without this file

6. When you determine that VPN connection is working successfully, upload the script to Intune and insert your clients in the scope (choose "Yes" when determining "Run this script using the logged on credentials")

.LINK
https://github.com/TomislavPeharec

#>


# DEFINE DETAILS WHICH WILL BE INJECTED TO PBK FILE

$PBKFileDetails = 'PASTE BETWEEN THE QUOTATION MARKS CONTENT OF YOUR RASPHONE.PBK FILE'


#========================#
#==== LOAD FUNCTIONS ====#
#========================#


# CREATE DATE/TIME FUNCTION

function GetCurrentTime 
{
$(Get-Date -Format 'dd-MM-yyyy_HH:mm:ss')
}

# CREATE FUNCTION FOR CREATING REGISTRY KEY

function CreateRegistryKey 
{

    $Key = "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState\rasphone.pbk"
    $CheckConfigKey = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config" -ErrorAction SilentlyContinue

    if ($CheckConfigKey -eq $null)
    {
        Write-Output "[$(GetCurrentTime)] Config key not found in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\."
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\" -Name Config | Out-Null
        Write-Output "[$(GetCurrentTime)] Config key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\."

        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config" -Name Phonebooks | Out-Null
        Write-Output "[$(GetCurrentTime)] Phonebooks key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config."

        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks" -Name $Key -PropertyType String -Force | Out-Null
        Write-Output "[$(GetCurrentTime)] Subkey $Key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks."
    }
    elseif ($CheckConfigKey -ne $null)
    {
        Write-Output "[$(GetCurrentTime)] HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config exists."
        $CheckPhonebooksKey = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks" -ErrorAction SilentlyContinue

        if ($CheckPhonebooksKey -eq $null)
        {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config" -Name Phonebooks | Out-Null
        Write-Output "[$(GetCurrentTime)] Phonebooks key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config."

        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks" -Name $Key -PropertyType String -Force | Out-Null
        Write-Output "[$(GetCurrentTime)] Subkey $Key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks."
        }
        elseif ($CheckPhonebooksKey -ne $null)
        {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks" -Name $Key -PropertyType String -Force | Out-Null
        Write-Output "[$(GetCurrentTime)] Subkey $Key created in HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters\Config\Phonebooks."
        }

    }

}


# OBTAIN USERNAME OF THE LOGGED IN USER
$UserName = (Get-WmiObject -Class Win32_Process -Filter 'Name="explorer.exe"').GetOwner().User | Select-Object -First 1

# CLEAR VARIABLE
$SecondFolderLog = $Null


#========================================#
# === FIRST FOLDER PROCESSING START ==== #
#========================================#


# CREATE FOLDER IF IT DOESN'T EXISTS

$RequiredFolder = "C:\Users\$UserName\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState"
$CheckRequiredFolder = Test-Path $RequiredFolder
if ($CheckRequiredFolder -eq $false)
{

  # CREATE REQUIRED FOLDER
  New-Item $RequiredFolder -ItemType Directory | Out-Null

  # SET LOG LOCATION
  $LogLocation = "$RequiredFolder\NewAzureVPNConnectionLog_$(Get-Date -Format 'dd-MM-yyyy_HH_mm_ss').log"

  # START TRANSCRIPT
  Start-Transcript -Path $LogLocation -Force -Append

  # WRITE TO LOG
  Write-Output "[$(GetCurrentTime)] Required folder $RequiredFolder was created on the machine since it wasn't found."

  # CREATE EMPTY PBK FILE
  New-Item "$RequiredFolder\rasphone.pbk" -ItemType File | Out-Null

  # WRITE TO LOG
  Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been created in $RequiredFolder."

  # POPULATE PBK FILE WITH CONFIGURATION DATA
  Set-Content "$RequiredFolder\rasphone.pbk" $PBKFileDetails

  # WRITE TO LOG
  Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

  # INVOKE REGISTRY FUNCTION
  CreateRegistryKey

  # STOP TRANSCRIPT
  Stop-Transcript | Out-Null

}

# IN CASE THE FOLDER ALREADY EXISTS

else 
{
  # SET LOG LOCATION
  $LogLocation = "$RequiredFolder\NewAzureVPNConnectionLog_$(Get-Date -Format 'dd-MM-yyyy_HH_mm_ss').log"

  # START TRANSCRIPT
  Start-Transcript -Path $LogLocation -Force -Append

  # WRITE TO LOG
  Write-Output "[$(GetCurrentTime)] Folder $RequiredFolder already exists, that means that Azure VPN Client is already installed."

  # CHECK IF RASPHONE.PBK FILE ALREADY EXISTS
  $CheckRasphoneFile = Test-Path "$RequiredFolder\rasphone.pbk"

  if ($CheckRasphoneFile -eq $false)
  {
    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk doesn't exist in $RequiredFolder."

    # CREATE EMPTY PBK FILE
    New-Item "$RequiredFolder\rasphone.pbk" -ItemType File | Out-Null

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been created in $RequiredFolder."

    # POPULATE PBK FILE WITH CONFIGURATION DATA
    Set-Content "$RequiredFolder\rasphone.pbk" $PBKFileDetails

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

    # INVOKE REGISTRY FUNCTION
    CreateRegistryKey

    # STOP TRANSCRIPT
    Stop-Transcript | Out-Null
  }
  else
  {
    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk already exists in $RequiredFolder."

    # REMOVE RASPHONE.PBK FILE
    Rename-Item -Path "$RequiredFolder\rasphone.pbk" -NewName "$RequiredFolder\rasphone.pbk_$(Get-Date -Format 'ddMMyyyy-HHmmss')"
    
    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been renamed to rasphone.pbk_$(Get-Date -Format 'ddMMyyyy-HHmmss'). This file contains old configuration if it will be required in the future (in case it is, just rename it back to rasphone.pbk)."

    # CREATE NEW RASPHONE.PBK FILE
    New-Item "$RequiredFolder\rasphone.pbk" -ItemType File | Out-Null

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] New rasphone.pbk file has been created in $RequiredFolder."

    # POPULATE PBK FILE WITH CONFIGURATION DATA
    Set-Content "$RequiredFolder\rasphone.pbk" $PBKFileDetails

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

    # INVOKE REGISTRY FUNCTION
    CreateRegistryKey

    # STOP TRANSCRIPT
    Stop-Transcript | Out-Null

  }

}

#========================================#
# === FIRST FOLDER PROCESSING STOP ===== #
#========================================#


#========================================#
# === SECOND FOLDER PROCESSING START === #
#========================================#

$SecondUserFolder = "C:\Users\$UserName.$env:userdomain"
$CheckSecondFolder = Test-Path $SecondUserFolder

# CHECK IF SECOND USER FOLDER EXISTS - IF NO

if ($CheckSecondFolder -eq $false)
{

  # START TRANSCRIPT
  Start-Transcript -Path $LogLocation -Force -Append -IncludeInvocationHeader

  # WRITE TO LOG
  Write-Output "[$(GetCurrentTime)] Folder $SecondUserFolder doesn't exist."

  # STOP TRANSCRIPT
  Stop-Transcript | Out-Null
   
}

# IF SECOND USER FOLDER EXISTS, CREATE NECESSARY FOLDER

else 
    
{

  $SecondUserFolderPath = "$SecondUserFolder\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState"
  $CatchSecondFolderPath = Test-Path $SecondUserFolderPath
  if ($CatchSecondFolderPath -eq $true)
  {

    # SET LOG LOCATION
    $LogLocationSecondFolder = "$SecondUserFolderPath\NewAzureVPNConnectionLog_$(Get-Date -Format 'dd-MM-yyyy_HH_mm_ss').log"

    # START TRANSCRIPT
    Start-Transcript -Path $LogLocationSecondFolder -Force -Append

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] Folder $SecondUserFolder exists."

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] Folder $SecondUserFolderPath already exists."

    # CHECK IF RASPHONE.PBK FILE ALREADY EXISTS
    $CheckRasphoneFileSecondUserFolderPath = Test-Path "$SecondUserFolderPath\rasphone.pbk"

    if ($CheckRasphoneFileSecondUserFolderPath -eq $true)
    {
      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] File rasphone.pbk already exists in $SecondUserFolderPath."

      # REMOVE RASPHONE.PBK FILE
      Rename-Item -Path "$SecondUserFolderPath\rasphone.pbk" -NewName "$SecondUserFolderPath\rasphone.pbk_$(Get-Date -Format 'ddMMyyyy-HHmmss')"

      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been renamed to rasphone.pbk_$(Get-Date -Format 'ddMMyyyy-HHmmss'). This file contains old configuration if it will be required in the future (in case it is, just rename it back to rasphone.pbk)."

      # CREATE EMPTY PBK FILE
      New-Item "$SecondUserFolderPath\rasphone.pbk" -ItemType File | Out-Null

      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] New rasphone.pbk file has been created in $SecondUserFolderPath."

      # POPULATE PBK FILE WITH CONFIGURATION DATA
      Set-Content "$SecondUserFolderPath\rasphone.pbk" $PBKFileDetails

      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

      # INVOKE REGISTRY FUNCTION
      CreateRegistryKey

      # STOP TRANSCRIPT
      Stop-Transcript | Out-Null

    }
    else
    {
      # CREATE EMPTY PBK FILE
      New-Item "$SecondUserFolderPath\rasphone.pbk" -ItemType File | Out-Null

      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] New rasphone.pbk file has been created in $SecondUserFolderPath."

      # POPULATE PBK FILE WITH CONFIGURATION DATA
      Set-Content "$SecondUserFolderPath\rasphone.pbk" $PBKFileDetails

      # WRITE TO LOG
      Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

      # INVOKE REGISTRY FUNCTION
      CreateRegistryKey

      # STOP TRANSCRIPT
      Stop-Transcript | Out-Null
    }

  }
  else
  {
    # SET LOG LOCATION
    $LogLocationSecondFolder = "$SecondUserFolderPath\NewAzureVPNConnectionLog_$(Get-Date -Format 'dd-MM-yyyy_HH_mm_ss').log"

    # START TRANSCRIPT
    Start-Transcript -Path $LogLocationSecondFolder -Force -Append

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] Folder $SecondUserFolder exists."

    # CREATE NEW FOLDER
    New-Item $SecondUserFolder\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState -ItemType Directory | Out-Null
    $CatchSecondFolderPath = "$SecondUserFolder\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState"

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] Path $SecondUserFolderPath doesn't exist, we will create one."

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] Folder $CatchSecondFolderPath has been created."

    # CREATE EMPTY PBK FILE
    New-Item "$SecondUserFolder\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState\rasphone.pbk" -ItemType File | Out-Null

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] New rasphone.pbk file has been created in $SecondUserFolderPath."

    # POPULATE PBK FILE WITH CONFIGURATION DATA
    Set-Content "$SecondUserFolder\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState\rasphone.pbk" $PBKFileDetails

    # WRITE TO LOG
    Write-Output "[$(GetCurrentTime)] File rasphone.pbk has been populated with configuration details."

    # INVOKE REGISTRY FUNCTION
    CreateRegistryKey

    # STOP TRANSCRIPT
    Stop-Transcript | Out-Null
    
  }
    
}

#========================================#
# === SECOND FOLDER PROCESSING STOP ==== #
#========================================#
