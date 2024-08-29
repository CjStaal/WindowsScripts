<#
  Software deployment script
  Created by Charles Staal on 08/27/2024
  For MSI's that support /quiet
#>

$VerbosePreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

$repoHost = "dl.dell.com"
$arguments = "/silent"
$dlDir = "C:\HIT\Downloads"
$dlURL = "https://downloads.dell.com/FOLDER09663875M/1/Systems-Management_Application_RWVV0_WN64_2.0.2.0_A00.EXE"
$filename = "Systems-Management_Application_RWVV0_WN64_2.0.2.0_A00.EXE"

<# Checks software #>
Function Check-Software {
  Write-Verbose "Checking if software is installed"
  if(Test-Path "C:\Program Files\Dell\DELL System Update"){
    Write-Verbose "Software is installed"
    Ninja-Property-Set DSUInstalled "Installed"
    return $true
  } else {
    if (((Get-WmiObject -Class Win32_bios).Manufacturer -Match "Dell") -and
    ((Get-WmiObject -Class Win32_ComputerSystem).Model -notlike "*Virtual*") -and
    ((Get-WmiObject -Class win32_OperatingSystem).Caption -Match "Server")){
      Write-Verbose "Software is not installed"
      Ninja-Property-Set DSUInstalled "Not Installed"
      return $false
    } else {
      Write-Verbose "Software is not applicable"
      Ninja-Property-Set DSUInstalled "Not Applicable"
      return $true
    }
  }
}

<# Downloads Software #>
Function Download-Software {
  Write-Verbose "Downloading Software"
  if(Test-Connection $repoHost -Count 3 -Quiet) {
    if(Test-Path "$dlDir\$filename"){
      taskkill /f /im $filename
      Remove-Item "$dlDir\$filename" -ErrorAction SilentlyContinue
    }
    try {
      New-Item -ItemType Directory "$dlDir" -Force | Out-Null
      (New-Object System.Net.WebClient).DownloadFile($dlURL, "$dlDir\$filename")
      Write-Verbose "Software downloaded!"
    } catch {
      Write-Verbose "Software failed to download"
      exit
    }
  } else {
    Write-Verbose "Could not connect to repositories servers"
    exit
  }
}

<# Installs Software #>
Function Install-Software {
  Write-Verbose "Installing Software"
  $softwareMSI = "$dlDir\$filename"
  Write-Verbose "Installing from: $softwareMSI"
  $args = "/silent"
  Start-Process -filepath $softwareMSI -argumentlist $args -Wait
  
  Check-Software
  Cleanup-Software
}

<# Cleans up #>
Function Cleanup-Software {
  Write-Verbose "Deleting installer"
  try {
    Remove-Item "$dlDir\$filename"-ErrorAction Stop
    Write-Verbose "Installer deleted successfully"
  } catch {
    Write-Verbose "Unable to delete installer. Please delete from C:\HIT\Downloads manually"
  }
}


if(-not (Check-Software)) {
  Download-Software
  Install-Software
}
