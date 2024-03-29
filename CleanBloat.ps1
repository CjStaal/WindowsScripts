Function Remove-App-MSI-QN([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst = $appCheck.UninstallString + " /qn /norestart"
        cmd /c $uninst
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Remove-App-EXE-SILENT([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst = $appCheck.UninstallString + " -silent"
        cmd /c $uninst
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Remove-App-MSI_EXE-Quiet([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst = $appCheck.UninstallString[1] +  " /qn /restart"
        cmd /c $uninst

    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}
Function Remove-App-MSI_EXE-S([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst = $appCheck.UninstallString[1] +  " /S"
        cmd /c $uninst

    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Remove-App-MSI-I-QN([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst = $appCheck.UninstallString.Replace("/I","/X") + " /qn /norestart"
        cmd /c $uninst
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}


Function Remove-App([String]$appName){
    $app = Get-AppxPackage -AllUsers $appName
    if($app -ne $null){
        $packageFullName = $app.PackageFullName
        Write-Host "Uninstalling $appName"
        Remove-AppxPackage -package $packageFullName -AllUsers
        $provApp = Get-AppxProvisionedPackage -Online 
        $proPackageFullName = (Get-AppxProvisionedPackage -Online | where {$_.Displayname -eq $appName}).DisplayName
        if($proPackageFillName -ne $null){
            Write-Host "Uninstalling provisioned $appName"
            Remove-AppxProvisionedPackage -online -packagename $proPackageFullName -AllUsers
        }
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Remove-M365([String]$appName)
{
    $uninstall = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where {$_.DisplayName -like $appName} | Select UninstallString)
    if($uninstall -ne $null){
        Write-Host "Uninstalling $appName"
        $uninstall = $uninstall.UninstallString + " DisplayLevel=False"
        cmd /c $uninstall
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Check-UninstallString([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host $appCheck.DisplayName $appCheck.UninstallString
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Function Remove-App-EXE-S-QUOTES([String]$appName)
{
    $appCheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName } | Select-Object -Property DisplayName,UninstallString
    if($appCheck -ne $null){
        Write-host "Uninstalling "$appCheck.DisplayName
        $uninst ="`""+$appCheck.UninstallString+"`"" + " /S"
        cmd /c $uninst
    }
    else{
        Write-Host "$appName is not installed on this computer"
    }
}

Remove-App-MSI-QN "Dell SupportAssist"                                             #working
Remove-App-MSI-QN "Dell Digital Delivery Services"                                 #working
Remove-App-EXE-SILENT "Dell Optimizer Core"                                        #working
Remove-App-MSI_EXE-S "Dell SupportAssist OS Recovery Plugin for Dell Update"       #working
Remove-App-MSI_EXE-S "Dell SupportAssist Remediation"                              #working
Remove-App-EXE-S-QUOTES "Dell Display Manager 2.1"                                 #working
Remove-App-EXE-S-QUOTES "Dell Peripheral Manager"                                  #working
Remove-App-MSI-I-QN "Dell Core Services"                                           #working
Remove-App-MSI-I-QN "Dell Trusted Device Agent"                                    #working
Remove-App-MSI-I-QN "Dell Optimizer"                                               #working
Remove-App "Microsoft.GamingApp"                                                   #working
Remove-App "Microsoft.MicrosoftOfficeHub"                                          #working
Remove-App "DellInc.DellDigitalDelivery"                                           #working 
Remove-App "Microsoft.GetHelp"                                                     #working
Remove-App "Microsoft.Getstarted"                                                  #working
Remove-App "Microsoft.Messaging"                                                   #working
Remove-App "Microsoft.MicrosoftSolitaireCollection"                                #working
Remove-App "Microsoft.OneConnect"                                                  #working
Remove-App "Microsoft.SkypeApp"                                                    #working
Remove-App "Microsoft.Wallet"                                                      #working
Remove-App "microsoft.windowscommunicationsapps"                                   #working
Remove-App "Microsoft.WindowsFeedbackHub"                                          #working
Remove-App "Microsoft.YourPhone"                                                   #working
Remove-App "ZuneMusic"                                                             #working        
Remove-M365 "Microsoft 365 - fr-fr"                                                #working
Remove-M365 "Microsoft 365 - es-es"                                                #working                                            
Remove-M365 "Microsoft 365 - pt-br"                                                #working
Remove-M365 "Microsoft OneNote - fr-fr"                                            #working
Remove-M365 "Microsoft OneNote - es-es"                                            #working
Remove-M365 "Microsoft OneNote - pt-br"                                            #working
Check-UninstallString "DELLOSD"
