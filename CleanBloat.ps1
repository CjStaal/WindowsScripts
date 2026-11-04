#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    throw 'Run this script in 64-bit PowerShell to inspect both registry views.'
}

function New-UninstallResult {
    param(
        [string]$Application,
        [string]$Phase,
        [string]$Status,
        [string]$Detail = '',
        [Nullable[int]]$ExitCode
    )

    [pscustomobject]@{
        Application = $Application
        Phase = $Phase
        Status = $Status
        ExitCode = $ExitCode
        Detail = $Detail
    }
}

function Get-UninstallEntries {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DisplayNamePattern)

    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    $entries = foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -ErrorAction Stop |
                Get-ItemProperty -ErrorAction Stop |
                Select-Object DisplayName, UninstallString, QuietUninstallString, WindowsInstaller, PSChildName, PSPath |
                Where-Object { $_.DisplayName -and $_.DisplayName -like $DisplayNamePattern }
        }
    }

    $entries | Sort-Object PSPath -Unique
}

function Split-UninstallCommand {
    param([Parameter(Mandatory)][string]$CommandLine)

    $expandedCommand = [Environment]::ExpandEnvironmentVariables($CommandLine).Trim()
    # Match the complete .exe path, including spaces in an unquoted registry value.
    $commandMatch = [regex]::Match($expandedCommand, '^(?:"(?<path>[^"]+\.exe)"|(?<path>.+?\.exe))(?=\s|$)\s*(?<arguments>.*)$', 'IgnoreCase')
    if (-not $commandMatch.Success) {
        $commandMatch = [regex]::Match($expandedCommand, '^"?(?<path>msiexec)"?(?=\s|$)\s*(?<arguments>.*)$', 'IgnoreCase')
    }
    if (-not $commandMatch.Success) {
        throw "Cannot parse executable and arguments from '$CommandLine'."
    }

    [pscustomobject]@{
        FilePath = $commandMatch.Groups['path'].Value
        Arguments = $commandMatch.Groups['arguments'].Value.Trim()
    }
}

function Invoke-Uninstall {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$AppName,
        [ValidateSet('Auto', 'MSI', 'EXE')][string]$Type = 'Auto',
        # Supply the vendor's actual arguments. Each supplied item is used.
        [string[]]$ExeSilentArgs = @(),
        [string[]]$ExeNoRestartArgs = @(),
        [switch]$NoRestart = $true
    )

    try {
        $entries = @(Get-UninstallEntries -DisplayNamePattern $AppName)
    }
    catch {
        New-UninstallResult $AppName 'Regular' 'Failed' $_.Exception.Message
        return
    }
    if ($entries.Count -eq 0) {
        New-UninstallResult $AppName 'Regular' 'Absent'
        return
    }

    foreach ($entry in $entries) {
        try {
            $commandLine = [string]$entry.UninstallString
            if (-not [string]::IsNullOrWhiteSpace($entry.QuietUninstallString)) {
                $commandLine = [string]$entry.QuietUninstallString
            }
            $command = Split-UninstallCommand -CommandLine $commandLine
            $isMsiCommand = [IO.Path]::GetFileName($command.FilePath) -match '^msiexec(?:\.exe)?$'
            $isMsi = $Type -eq 'MSI' -or ($Type -eq 'Auto' -and ($entry.WindowsInstaller -eq 1 -or $isMsiCommand))
            $detail = ''

            if ($isMsi) {
                $filePath = Join-Path $env:SystemRoot 'System32\msiexec.exe'
                # Keep quoted properties and paths intact while editing MSI switches.
                $argumentTokens = @([regex]::Matches($command.Arguments, '(?:[^\s"]+|"[^"]*")+') | ForEach-Object { $_.Value })
                if (-not $isMsiCommand) {
                    if ($entry.PSChildName -notmatch '^\{[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}\}$') {
                        throw 'MSI entry has no usable msiexec command or product code.'
                    }
                    # Wrapper arguments belong to the EXE, so use the registered MSI product code.
                    $argumentTokens = @('/x', $entry.PSChildName)
                }
                $operationCount = 0
                $normalizedTokens = foreach ($token in $argumentTokens) {
                    if ($token -match '^/(?:[ix](?:\{[^}]+\}|"[^"]+\.msi"|[^\s]+\.msi)?|package|uninstall)$') {
                        $operationCount++
                        $token -replace '^/i', '/x' -replace '^/package$', '/uninstall'
                    }
                    elseif ($token -match '^/(?:q[nbrf]?[+!-]*|quiet|passive)$') {
                        continue
                    }
                    elseif ($NoRestart -and $token -match '^(?:/(?:norestart|forcerestart|promptrestart)|REBOOT=.*|REBOOTPROMPT=.*)$') {
                        continue
                    }
                    else {
                        $token
                    }
                }
                if ($operationCount -ne 1) {
                    throw 'MSI command must contain one install or uninstall operation to normalize safely.'
                }
                $finalArguments = (@($normalizedTokens) + '/qn') -join ' '
                if ($NoRestart) {
                    $finalArguments += ' /norestart'
                }
            }
            else {
                if ([string]::IsNullOrWhiteSpace($entry.QuietUninstallString) -and $ExeSilentArgs.Count -eq 0) {
                    New-UninstallResult $entry.DisplayName 'Regular' 'Skipped' 'No registered quiet command. Configure vendor-specific ExeSilentArgs in the regularApps list.'
                    continue
                }
                $filePath = $command.FilePath
                $finalArguments = $command.Arguments
                $additionalArguments = @($ExeSilentArgs)
                if ($NoRestart) {
                    $additionalArguments += $ExeNoRestartArgs
                    if ($ExeNoRestartArgs.Count -eq 0) {
                        $detail = 'EXE restart behavior follows the vendor command. Set ExeNoRestartArgs when required.'
                    }
                }
                foreach ($argument in $additionalArguments) {
                    $argumentPattern = '(?:^|\s)' + [regex]::Escape($argument) + '(?=\s|$)'
                    if ($finalArguments -cnotmatch $argumentPattern) {
                        $finalArguments = ($finalArguments + ' ' + $argument).Trim()
                    }
                }
            }

            if (-not $PSCmdlet.ShouldProcess($entry.DisplayName, "Run $filePath $finalArguments")) {
                $status = 'Skipped'
                if ($WhatIfPreference) { $status = 'WhatIf' }
                New-UninstallResult $entry.DisplayName 'Regular' $status "$filePath $finalArguments"
                continue
            }

            $processParameters = @{
                FilePath = $filePath
                Wait = $true
                PassThru = $true
                WindowStyle = 'Hidden'
                ErrorAction = 'Stop'
                Confirm = $false
            }
            if (-not [string]::IsNullOrWhiteSpace($finalArguments)) {
                $processParameters.ArgumentList = $finalArguments
            }
            $process = Start-Process @processParameters
            $exitCode = $process.ExitCode
            $status = 'Removed'
            if ($isMsi -and $exitCode -eq 3010) {
                $status = 'Restart required'
            }
            elseif ($isMsi -and $exitCode -eq 1641) {
                $status = 'Restart initiated'
            }
            elseif ($exitCode -ne 0) {
                $status = 'Failed'
                $detail = "Uninstaller returned exit code $exitCode. $detail".Trim()
            }
            New-UninstallResult $entry.DisplayName 'Regular' $status $detail $exitCode
        }
        catch {
            New-UninstallResult $entry.DisplayName 'Regular' 'Failed' $_.Exception.Message
        }
    }
}

function Remove-AppxPackageEverywhere {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$AppName)

    # Inventory/removal and deprovisioning have separate error handling so both are attempted.
    try {
        $installed = @(Get-AppxPackage -AllUsers -PackageTypeFilter Bundle, Main, Framework -ErrorAction Stop |
            Where-Object { $_.Name -eq $AppName -or $_.PackageFamilyName -eq $AppName } |
            Sort-Object PackageFullName -Unique)
        $targets = @(foreach ($group in ($installed | Group-Object PackageFamilyName, Version)) {
            $bundles = @($group.Group | Where-Object { $_.IsBundle })
            if ($bundles.Count -gt 0) { $bundles } else { $group.Group }
        })
        if ($targets.Count -eq 0) {
            New-UninstallResult $AppName 'Appx installed' 'Absent'
        }
        foreach ($package in $targets) {
            try {
                if ($PSCmdlet.ShouldProcess($package.PackageFullName, 'Remove Appx for all users')) {
                    Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                    New-UninstallResult $AppName 'Appx installed' 'Removed' $package.PackageFullName
                }
                else {
                    $status = 'Skipped'
                    if ($WhatIfPreference) { $status = 'WhatIf' }
                    New-UninstallResult $AppName 'Appx installed' $status $package.PackageFullName
                }
            }
            catch {
                New-UninstallResult $AppName 'Appx installed' 'Failed' $_.Exception.Message
            }
        }
    }
    catch {
        New-UninstallResult $AppName 'Appx installed' 'Failed' $_.Exception.Message
    }

    try {
        $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object {
            $nameParts = $_.PackageName -split '_'
            $familyName = $nameParts[0] + '_' + $nameParts[-1]
            $_.DisplayName -eq $AppName -or $familyName -eq $AppName
        })
        if ($provisioned.Count -eq 0) {
            New-UninstallResult $AppName 'Appx provisioned' 'Absent'
        }
        foreach ($package in $provisioned) {
            try {
                if ($PSCmdlet.ShouldProcess($package.PackageName, 'Deprovision Appx for future users')) {
                    $removal = Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
                    $status = 'Removed'
                    if ($removal.RestartNeeded) { $status = 'Restart required' }
                    New-UninstallResult $AppName 'Appx provisioned' $status $package.PackageName
                }
                else {
                    $status = 'Skipped'
                    if ($WhatIfPreference) { $status = 'WhatIf' }
                    New-UninstallResult $AppName 'Appx provisioned' $status $package.PackageName
                }
            }
            catch {
                New-UninstallResult $AppName 'Appx provisioned' 'Failed' $_.Exception.Message
            }
        }
    }
    catch {
        New-UninstallResult $AppName 'Appx provisioned' 'Failed' $_.Exception.Message
    }
}

function Show-UninstallString {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$AppName)

    $entries = @(Get-UninstallEntries -DisplayNamePattern $AppName)
    if ($entries.Count -gt 0) {
        $entries | Select-Object DisplayName, UninstallString, QuietUninstallString | Format-Table -Wrap | Out-Host
    }
    else {
        Write-Host "$AppName is not installed on this computer"
    }
}

# MSI uninstalls default to NoRestart. EXE arguments must match the vendor's documentation.
# Add ExeSilentArgs and, when needed, ExeNoRestartArgs to an application's hashtable.
# HKCU covers the account running the script, including SYSTEM when run through an RMM.
$regularApps = @(
    @{ AppName = 'Dell SupportAssist'; NoRestart = $true }
    @{ AppName = 'Dell Digital Delivery Services'; NoRestart = $true }
    @{ AppName = 'Dell Optimizer Core' }
    @{ AppName = 'Dell SupportAssist OS Recovery Plugin for Dell Update' }
    @{ AppName = 'Dell SupportAssist Remediation' }
    @{ AppName = 'Dell Display Manager 2.1' }
    @{ AppName = 'Dell Peripheral Manager' }
    @{ AppName = 'Dell Core Services'; NoRestart = $true }
    @{ AppName = 'Dell Trusted Device Agent'; NoRestart = $true }
    @{ AppName = 'Dell Optimizer'; NoRestart = $true }
)

$appxPackages = @(
    'Microsoft.GamingApp'
    'Microsoft.MicrosoftOfficeHub'
    'DellInc.DellDigitalDelivery'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.Messaging'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.OneConnect'
    'Microsoft.SkypeApp'
    'Microsoft.Wallet'
    'microsoft.windowscommunicationsapps'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.YourPhone'
    'Microsoft.ZuneMusic'
)

# Preview from an elevated PowerShell window with .\Uninstall-Apps.ps1 -WhatIf
$results = @(
    foreach ($app in $regularApps) {
        Invoke-Uninstall @app -WhatIf:$WhatIfPreference
    }
    foreach ($packageName in $appxPackages) {
        Remove-AppxPackageEverywhere -AppName $packageName -WhatIf:$WhatIfPreference
    }
)

$results | Format-Table Application, Phase, Status, ExitCode, Detail -Wrap | Out-Host

# Preserve the original DELLOSD lookup as an informational step.
try { Show-UninstallString -AppName 'DELLOSD' }
catch { Write-Warning "DELLOSD lookup failed. $($_.Exception.Message)" }

$failedCount = @($results | Where-Object { $_.Status -eq 'Failed' }).Count
if ($failedCount -gt 0) {
    throw "$failedCount uninstall operation(s) failed. Review the results above."
}
