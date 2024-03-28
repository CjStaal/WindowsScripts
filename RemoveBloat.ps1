$appArray=@( 'Dell Peripheral Manager',
              'Dell Optimizer',
              'Dell Optimizer Core',
              'Dell Trusted Device Agent',
              'Dell SupportAssist Remediation',
              'Dell SupportAssist OS Recovery Plugin for Dell Update',
              'Dell SupportAssist',
              'Dell Display Manager 2.1',
              'Dell Digital Delivery Services',
              'Dell Digital Delivery',
              'Microsoft 365 - es-es',
              'Microsoft 365 - fr-fr',
              'Microsoft 365 - pt-br',
              'Microsoft OneNote - es-es',
              'Microsoft OneNote - fr-fr',
              'Microsoft OneNote - pt-br',
              'Xbox',
              'Xbox Live'
            )


foreach ($id in $appArray)
{
  $appcheck = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $id } | Select-Object -Property DisplayName,UninstallString
  if($appcheck -ne $null){
    $uninst = $appcheck.UninstallString
    $uninst = (($uninst -split ' ')[1] -replace '/I','/X ') + ' /quiet'
    Write-Host "Removing $id with $uninst"
    Start-Process msiexec.exe -ArgumentList $uninst -NoNewWindow -PassThru -Wait
  }
  else{
    Write-Host "$id is not installed on this computer"
  }
}