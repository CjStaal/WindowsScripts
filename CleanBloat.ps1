Function Remove-App([String]$AppName){
    $PackageFullName = (Get-AppxPackage $AppName).PackageFullName
    $ProPackageFullName = (Get-AppxProvisionedPackage -Online | where {$_.Displayname -eq $AppName}).PackageName
    Remove-AppxPackage -package $PackageFullName | Out-Null
    Remove-AppxProvisionedPackage -online -packagename $ProPackageFullName | Out-Null
}

Function Remove-App-Registry([String]$AppName)
{
    $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $AppName } | Select-Object -Property DisplayName,UninstallString
    if($appcheck -ne $null){
        Write-Host $appcheck
        $uninst = "$appcheck".split("=")[2].replace("}","")
        $uninst ="`""+$uninst+"`"" + " /quiet"
        Write-Host $uninst
        cmd /c $uninst
    }
    else{
        Write-Host "$id is not installed on this computer"
    }
}

Function Remove-App-Registry2([String]$AppName)
{
    $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $AppName } | Select-Object -Property DisplayName,UninstallString
    if($appcheck -ne $null){
        $uninst = "$appcheck ".split("=")[2].replace("}","") + " /VERYSILENT"
        cmd /c $uninst
    }
    else{
        Write-Host "$id is not installed on this computer"
    }
}

Function Remove-App-Registry3([String]$AppName)
{
    $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $AppName } | Select-Object -Property DisplayName,UninstallString
    if($appcheck -ne $null){
        $uninst = "$appcheck".split("=")[2]
        $uninst = $uninst.Substring(0,$uninst.length-1) + " -silent"
        Write-Host $uninst
        cmd /c $uninst
    }
    else{
        Write-Host "$id is not installed on this computer"
    }
}

Function Remove-App-Registry4([String]$AppName)
{
    $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $AppName } | Select-Object -Property DisplayName,UninstallString
    if($appcheck -ne $null){
        Write-Host $appcheck
        $uninst = "$appcheck".split("=")[2].replace("}","")
        $uninst ="`""+$uninst+"`"" + " /S"
        Write-Host ""
        Write-Host $uninst
        cmd /c $uninst
    }
    else{
        Write-Host "$id is not installed on this computer"
    }
}

Function Remove-App-Registry5([String]$AppName)
{
    $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $AppName } | Select-Object -Property DisplayName,UninstallString
    if($appcheck -ne $null){

        $uninst = $appcheck.UninstallString[1] + " /quiet"
	cmd /c $uninst
    }
    else{
        Write-Host "$id is not installed on this computer"
    }
}

Function Remove-M365([String]$AppName)
{
    $Uninstall = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where {$_.DisplayName -like $appName} | Select UninstallString)
    $Uninstall = $Uninstall.UninstallString + " DisplayLevel=False"
    cmd /c $Uninstall
}

###########
# EXECUTE #
###########
# Active identifiers
Remove-App "Microsoft.GetHelp"							# MS support chat bot
Remove-App "Microsoft.Getstarted"						# 'Get Started' link
Remove-App "Microsoft.Messaging"						# SMS app. Requires a phone link.
Remove-App "Microsoft.MicrosoftOfficeHub"				# Office 365. Interferes with Office ProPlus
Remove-App "Microsoft.MicrosoftSolitaireCollection"		# Game
Remove-App "Microsoft.OneConnect"						# Paid WiFi and Cellular App
Remove-App "Microsoft.SkypeApp"							# Skype
Remove-App "Microsoft.Wallet"							# Mobile payment storage
Remove-App "microsoft.windowscommunicationsapps"		# MS Calendar and Mail apps. Interferes with Office ProPlus
Remove-App "Microsoft.WindowsFeedbackHub"				# MS Beta test opt-in app
Remove-App "Microsoft.YourPhone"						# Links an Android phone to the PC
Remove-App "ZuneMusic"
Remove-App "DellInc.DellDigitalDelivery"

Remove-App-Registry "Dell SupportAssist Remediation"
Remove-App-Registry "Dell Optimizer"
Remove-App-Registry "Dell Trusted Device Agent"
Remove-App-Registry "Dell SupportAssist"
Remove-App-Registry "Dell Digital Delivery Services"
Remove-App-Registry "Dell Digital Delivery"
Remove-App-Registry "Xbox"
Remove-App-Registry "Xbox Live"
Remove-App-Registry2 "DELLOSD"
Remove-App-Registry3 "Dell SupportAssist OS Recovery Plugin for Dell Update"
Remove-App-Registry3 "Dell Optimizer Core"
Remove-App-Registry4 "Dell Display Manager 2.1"
Remove-App-Registry4 "Dell Peripheral Manager"
Remove-App-Registry5 "Dell SupportAssist Remediation"

Remove-M365 "Microsoft 365 - fr-fr"
Remove-M365 "Microsoft 365 - es-es"
Remove-M365 "Microsoft 365 - pt-br"
Remove-M365 "Microsoft OneNote - fr-fr"
Remove-M365 "Microsoft OneNote - es-es"
Remove-M365 "Microsoft OneNote - pt-br"