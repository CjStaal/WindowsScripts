<#
  Software deployment script
  Created by Charles Staal on 08/27/2024
  For MSI's that support /quiet
#>

##$VerbosePreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

$repoHost = "dl.dell.com"
$arguments = "/silent"
$dlDir = "C:\HIT\Downloads"
$dlURL = "https://downloads.dell.com/FOLDER06019899M/1/OM-SrvAdmin-Dell-Web-WINX64-9.4.0-3787_A00.exe"
$filename = "OM-SrvAdmin-Dell-Web-WINX64-9.4.0-3787_A00.exe"

<# Checks software #>
Function Check-Software {
  Write-Verbose "Checking if software is installed"
  if(Test-Path "C:\Program Files\Dell\SysMgt\omsa"){
    Write-Verbose "Software is installed"
    Ninja-Property-Set openmanageInstalled "Installed"
    return $true
  } else {
    if (((Get-WmiObject -Class Win32_bios).Manufacturer -Match "Dell") -and
    ((Get-WmiObject -Class Win32_ComputerSystem).Model -notlike "*Virtual*") -and
    ((Get-WmiObject -Class win32_OperatingSystem).Caption -Match "Server")){
      Write-Verbose "Software is not installed"
      Ninja-Property-Set openmanageInstalled "Not Installed"
      return $false
    } else {
      Write-Verbose "Software is not applicable"
      Ninja-Property-Set openmanageInstalled "Not Applicable"
      return $true
    }
  }
}
<# Downloads Software #>
Function Download-Software {
  Write-Verbose "Downloading Software"

  if(Test-Connection $repoHost -Count 3 -Quiet) {
    if( ((Get-WmiObject -Class win32_OperatingSystem).Caption -Match "2019") -or ((Get-WmiObject -Class win32_OperatingSystem).Caption -Match "2022")){
      $dlURL = "https://downloads.dell.com/FOLDER10653510M/1/OM-SrvAdmin-Dell-Web-WINX64-11.0.1.0-5494_A00.exe"
    } else {
      $dlURL = "https://downloads.dell.com/FOLDER06019899M/1/OM-SrvAdmin-Dell-Web-WINX64-9.4.0-3787_A00.exe"
    }
    if(Test-Path "$dlDir\$filename"){
      taskkill /f /im $filename
      Remove-Item "$dlDir\$filename" -ErrorAction SilentlyContinue
    }
    try {
      if(Test-Path "$dlDir\$filename"){
        Stop-Process -Name $filename -Force
        Remove-Item "$dlDir\$filename"
      }
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
  $args = "/auto"
  Start-Process -filepath $softwareMSI -argumentList $args -Wait
  Write-Verbose "Installing from: $softwareMSI"
  $args = "/i C:\OpenManage\windows\SystemsManagementx64\SysMgmtx64.msi /quiet"
  Start-Process -filepath msiexec -argumentlist $args -Wait
  
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
    Write-Verbose "Unable to delete installer. Please delete from $dlDir manually"
  }
}


if(-not (Check-Software)) {
  Download-Software
  Install-Software
}
