# STARTUP SCRIPT START
<#
+ remove-appxpackage
+ Remove-AppxProvisionedPackage
+ REGISTRY HKCU

Script assumes latest PWSH already installed.
For Windows 10+ run as scheduled task with admin user:
pwsh.exe -nologo -windowstyle hidden -ExecutionPolicy Bypass -command ". c:\scripts\logon.ps1; exit $LASTEXITCODE"
#>
# DEFAULT
if([environment]::OSVersion.tostring().startswith('Microsoft') -eq $false){
    exit 1
}
if(
(($PSVersionTable.psversion.major -eq 7 -and $PSVersionTable.psversion.minor -eq 2 -and $PSVersionTable.psversion.patch -lt 2) -or
$PSVersionTable.psversion.major -eq 7 -and $PSVersionTable.psversion.minor -lt 2) -or
$PSVersionTable.psversion.major -lt 7
){
    exit 1
}

$ErrorActionPreference='Continue'
$ProgressPreference='Continue'
$warningPreference='Continue'
# DEBUG $ErrorActionPreference='Stop'
$usradminchk_1=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if($usradminchk_1 -eq $false){
    exit 1
}
$null=(Set-MpPreference -DisableRealtimeMonitoring $true)
#https://github.com/powershell/powershell
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','yes','User')
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','yes','Machine')
#https://docs.microsoft.com/en-us/dotnet/core/tools/telemetry#collected-options
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','User')
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','Machine')

# remove-appxpackage
#https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10
#https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services#bkmk-cortana
# Native import-module > remove-appxpackage broken https://github.com/PowerShell/PowerShell/issues/16652
Import-Module -Name Appx -UseWindowsPowerShell
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.3dbuilder' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Advertising.Xaml' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.BingFinance' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.BingNews' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.BingSports' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.BingWeather' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.GetHelp' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Getstarted' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Messaging' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Microsoft3DViewer' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.MicrosoftOfficeHub' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.MicrosoftSolitaireCollection' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.MicrosoftStickyNotes' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.MixedReality.Portal' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.mspaint' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Office.OneNote' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Office.Sway' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.OneConnect' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.People' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Print3D' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.ScreenSketch' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.SkypeApp' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Wallet' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
# Not uninstallable
#get-appxpackage -name 'Microsoft.Windows.PeopleExperienceHost' -allusers | remove-appxpackage -allusers
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsAlarms' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsCamera' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsMaps' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsSoundRecorder' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'microsoft.windowscommunicationsapps' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Windows.Photos' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsCalculator' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsFeedbackHub' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsMaps' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.WindowsSoundRecorder' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.Xbox.TCUI' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.XboxApp' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
# Not Uninstallable
#get-appxpackage -name 'Microsoft.XboxGameCallableUI' -allusers | remove-appxpackage -allusers
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.XboxGameOverlay' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.XboxGamingOverlay' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.XboxIdentityProvider' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.XboxSpeechToTextOverlay' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.YourPhone' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.ZuneMusic' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas
start-process powershell.exe -argumentlist "get-appxpackage -name 'Microsoft.ZuneVideo' -allusers | remove-appxpackage -allusers" -windowstyle hidden -verb runas

# Remove-AppxProvisionedPackage
#https://docs.microsoft.com/en-us/windows/security/information-protection/windows-information-protection/enlightened-microsoft-apps-and-wip
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -match 'Twitter'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.3dbuilder'} |Remove-AppxProvisionedPackage -Online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.BingFinance'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.BingNews'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.BingSports'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.BingWeather'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.GetHelp'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.GetStarted'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Microsoft3Dviewer'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.MicrosoftOfficeHub'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.MicrosoftSolitaireCollection'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.MicrosoftStickyNotes'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.MixedReality.Portal'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.MSPaint'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Print3d'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Office.OneNote'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Office.Sway'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.People'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.ScreenSketch'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Skypeapp'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Wallet'} |Remove-AppxProvisionedPackage -Online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.WindowsCamera'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Windows.Photos'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.WindowsAlarms'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.WindowsCalculator'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Windowscommunicationsapps'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Windowsfeedbackhub'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.WindowsMaps'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.WindowsSoundRecorder'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Xbox.TCUI'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.Xboxapp'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.XboxGameOverlay'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.XboxGameOverlay'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.XboxGamingOverlay'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.XboxIdentityProvider'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.XboxSpeechtotextoverlay'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.YourPhone'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.ZuneMusic'} |Remove-AppxProvisionedPackage -online
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'Microsoft.ZuneVideo'} |Remove-AppxProvisionedPackage -Online

# REGISTRY HKCU
<#TODO
cleanmgr https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cleanmgr

# Windows Spotlight
Set-ItemProperty -Path HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent -Name DisableWindowsSpotlightFeatures -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
#>
# TODO Windows Update Limit https://www.tenforums.com/tutorials/88607-limit-bandwidth-windows-update-store-app-updates-windows-10-a.html#option2
# BITS https://docs.microsoft.com/en-us/windows/win32/bits/group-policies

# Adjust for Best Performance
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -Value 00000002
# Settings > Privacy > Radios > Access to control radios on this device > Off
# BingSearchEnabled
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ea 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name DisableSearchBoxSuggestions -Value 1
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name DynamicScrollbars -Value 0
#Defender SmartScreen for Microsoft Store Apps disable
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name EnableWebContentEvaluation -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name PreventOverride -Value 0
#DisallowShaking
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ea 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name DisallowShaking -value 1
#Speech, inking, and typing / Disable updates to speech recognition and speech synthesis models
Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name HarvestContacts -Value 0
#Game Mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name AutoGameModeEnabled -Value 0
#Let websites provide locally relevant content by accessing my language list disable
Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name HttpAcceptLanguageOptOut -Value 1
#Let Windows track app launches to improve Start and search results disable
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_TrackProgs -Value 0
#Live Tiles disable
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -ea 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name NoCloudApplicationNotification -Value 1
#Messaging cloud sync https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services#bkmk-syncsettings
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Messaging" -Name CloudServiceSyncEnabled -Value 0 -ea 0
#Seconds in taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowSecondsInSystemClock -Value 1
#Speech
new-item -path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\' -ea 0
new-item -path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -ea 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name HasAccepted -Value 0
#Stop minimizing all other windows when dragging a window with mouse
#https://answers.microsoft.com/en-us/windows/forum/windows8_1-desktop/disable-aero-shake/a1f2e81f-beb2-4541-9398-43af0c505912
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -ea 0
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name NoWindowMinimizingShortcuts -Value 1
#Transparency Effects disable
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0
#Videos Library access disable
#Window preview when hovering mouse over taskbar icons disable
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ExtendedUIHoverTime -Value 196608
# REGISTRY END
