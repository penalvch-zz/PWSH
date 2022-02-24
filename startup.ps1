# STARTUP SCRIPT START
<# 
For Windows 10+ run as scheduled task with admin user:
pwsh.exe -nologo -windowstyle hidden -ExecutionPolicy Bypass -command ". c:\scripts\startup.ps1; exit $LASTEXITCODE"
#>
# DEFAULT
if([environment]::OSVersion.tostring().startswith('Microsoft') -eq $false){
    exit 1
}
if([environment]::OSVersion.tostring().startswith('Microsoft')){
    $ErrorActionPreference='Continue'
    $ProgressPreference='Continue'
    $warningPreference='Continue'
    # DEBUG $ErrorActionPreference='Stop'
    $usradminchk_1=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if($usradminchk_1 -eq $false){
        exit 1
    }else{
        $null=(Set-MpPreference -DisableRealtimeMonitoring $true)
        #https://github.com/powershell/powershell
        [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','yes','User')
        [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','yes','Machine')
        #https://docs.microsoft.com/en-us/dotnet/core/tools/telemetry#collected-options
        [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','User')
        [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT','1','Machine')
        # CHOCOLATEY START
        $chocochk_1=choco -v
        if($chocochk_1.count -eq 0 -and $usradminchk_1 -eq $false){
            # 'Chocolatey not installed and not admin.'
            exit 1
        }elseif($chocochk_1.count -eq 0 -and $usradminchk_1 -eq $true){
            # Install chocolatey
            $executionpolicy_1=get-executionpolicy
            Set-ExecutionPolicy -scope Process Bypass
            $secprotcol_1=[System.Net.ServicePointManager]::SecurityProtocol
            [System.Net.ServicePointManager]::SecurityProtocol=[System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            set-executionpolicy -scope Process $executionpolicy_1
            [System.Net.ServicePointManager]::SecurityProtocol=$secprotcol_1
        }
        $chocolist_1=choco list --localonly
        $mysqlclichk_1=$chocolist_1|where-object{$_ -match '^mysql-cli'}
        if($mysqlclichk_1.count -eq 0 -and $usradminchk_1 -eq $false){
            # Choco mysql-cli not installed and not admin
            exit 1
        }elseif($mysqlclichk_1.count -eq 0 -and $usradminchk_1 -eq $true){
            $null=choco install mysql-cli -y
        }
        $mysqlconnectorchk_1=$chocolist_1|where-object{$_ -match '^mysql-connector'}
        if($mysqlconnectorchk_1.count -eq 0 -and $usradminchk_1 -eq $false){
            # Choco mysql-connector not installed and not admin
            exit 1
        }elseif($mysqlconnectorchk_1.count -eq 0 -and $usradminchk_1 -eq $true){
            $null=choco install mysql-connector -y
        }
        $python3chk_1=$chocolist_1|where-object{$_ -match '^python3'}
        if($python3chk_1.count -eq 0 -and $usradminchk_1 -eq $false){
            # Choco python3 not installed and not admin
            exit 1
        }elseif($python3chk_1.count -eq 0 -and $usradminchk_1 -eq $true){
            $null=choco install python3 -y
        }
        $vs2019chk_1=$chocolist_1|where-object{$_ -match '^visualstudio2019community'}
        if($vs2019chk_1.count -eq 0 -and $usradminchk_1 -eq $false){
            # Choco visualstudio2019community not installed and not admin
            exit 1
        }elseif($vs2019chk_1.count -eq 0 -and $usradminchk_1 -eq $true){
            $null=choco install visualstudio2019community -y
        }
        
        $null=choco upgrade all
        # CHOCOLATEY END
        # PIP START
        $null=pip install --upgrade pip --user $env:username
        # requests dependencies certifi, urllib3, idna, charset-normalizer, requests
        $null=pip install requests
        $pipchk_s=pip list --outdated --format=freeze
        if($pipchk_s.count -gt 0){
            $null=$pipchk_s | ForEach-Object {$_.split('==')[0]} | ForEach-Object {pip install --upgrade $_}
        }
        # PIP END

        #WSL START
        <#
        wsl --install
        wsl --update
        wsl --shutdown
        wsl echo PASSWORD |wsl sudo -S apt-get update
        wsl echo PASSWORD |wsl sudo -S apt-get -y upgrade
        #> 
        # WSL END
        # POWER SETTINGS
        powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        #$p_s=(get-ciminstance -namespace root\cimv2\power -Class win32_PowerPlan -Filter "ElementName='High Performance'")
        #$null=Invoke-CimMethod -InputObject $p_s -method Activate

        $plan_s=get-ciminstance -Class win32_powerplan -Namespace root\cimv2\power -Filter "isActive='true'"
        $regex=[regex]"{(.*?)}$"
        $planGuid_s=$regex.Match($plan_s.instanceID.Tostring()).groups[1].value
        #100% Maximum Processor State on AC
        powercfg /setacvalueindex $planGuid_s SUB_PROCESSOR PROCTHROTTLEMAX 100
        #100% Minimum Processor State
        powercfg /setacvalueindex $planGuid_s SUB_PROCESSOR PROCTHROTTLEMIN 100
        #Disable Adaptive Brightness
        powercfg /setacvalueindex $planGuid_s SUB_VIDEO ADAPTBRIGHT 0
        #Disable Allow Wake Timers on AC
        powercfg /setacvalueindex $planGuid_s SUB_SLEEP RTCWAKE 0
        #Disable Allow Wake Timers on battery
        powercfg /setdcvalueindex $planGuid_s SUB_SLEEP RTCWAKE 0
        #Disable critical battery action when on AC
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY BATACTIONCRIT 0
        #Disable Hard Disk timeout on AC
        powercfg /change disk-timeout-ac 0
        #Disable hibernate on AC
        powercfg /change hibernate-timeout-ac 0
        #Disable PCIe Link state Power Management on AC
        powercfg /setacvalueindex $planGuid_s SUB_PCIEXPRESS ASPM 0
        #Disable suspend on AC
        powercfg /change standby-timeout-ac 0
        #Disable USB Selective Suspend on AC
        powercfg /setacvalueindex $planGuid_s 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
        #Disable Wireless Adapter Settings power management
        powercfg /setacvalueindex $planGuid_s 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
        #Enable critical battery action when on DC/battery
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY BATACTIONCRIT 2
        #Enable System Cooling Policy on AC
        powercfg /setacvalueindex $planGuid_s SUB_PROCESSOR SYSCOOLPOL 1
        #Max Video Playback Performance bias
        powercfg /setacvalueindex $planGuid_s 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1
        #Turn Off Display after 15 Minutes
        powercfg /setacvalueindex $planGuid_s SUB_VIDEO VIDEOIDLE 900
        #powercfg /setacvalueindex $planGuid_s 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0
        powercfg /setacvalueindex $planGuid_s 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY BATACTIONLOW 0
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY BATFLAGSLOW 1
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY BATLEVELCRIT 5
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY BATLEVELLOW 10
        powercfg /setacvalueindex $planGuid_s SUB_BATTERY f3c5027d-cd16-4930-aa6b-90db844a8f00 7
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY BATACTIONLOW 0
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY BATFLAGSLOW 1
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY BATLEVELCRIT 5
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY BATLEVELLOW 10
        powercfg /setdcvalueindex $planGuid_s SUB_BATTERY f3c5027d-cd16-4930-aa6b-90db844a8f00 7
        
        # get-appxpackage
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
        
        # Get-AppxProvisionedPackage
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
        
        # SERVICES
        #Connected User Experiences and Telemetry disable
        set-service -name diagtrack -startuptype disabled
        stop-service -name diagtrack -force
        #Diagnostic Execution Service disable
        set-service -name diagsvc -startuptype disabled
        stop-service -name diagsvc -force
        #Diagnostic Policy Service disable https://docs.microsoft.com/en-us/previous-versions/aa905076(v=msdn.10)?redirectedfrom=MSDN
        start-process powershell.exe -argumentlist 'set-service -name dps -startuptype disabled ; stop-service -name dps -force' -windowstyle hidden -verb runas
        #set-service -name dps -startuptype disabled ; stop-service -name dps -force
        #Diagnostic Service Host disable
        start-process powershell.exe -argumentlist 'set-service -name WdiServiceHost -startuptype disabled ; stop-service -name WdiServiceHost -force' -windowstyle hidden -verb runas
        #set-service -name WdiServiceHost -startuptype disabled ; stop-service -name WdiServiceHost -force
        #Diagnostic System Host disable
        start-process powershell.exe -argumentlist 'set-service -name WdiSystemHost -startuptype disabled ; stop-service -name WdiSystemHost -force' -windowstyle hidden -verb runas
        #set-service -name WdiSystemHost -startuptype disabled ; stop-service -name WdiSystemHost -force
        #Downloaded Maps Manager disable
        set-service -name MapsBroker -startuptype disabled
        stop-service -name MapsBroker -force
        #Geolocation Service disable
        set-service -name lfsvc -startuptype disabled
        stop-service -name lfsvc -force
        #Mobile Hotspot Service disable
        set-service -name icssvc -startuptype disabled
        stop-service -name icssvc -force
        #Parental Controls disable
        set-service -name WpcMonSvc -startuptype disabled
        stop-service -name WpcMonSvc -force
        #Payments and NFC/SE Manager
        set-service -name SEMgrSvc -startuptype disabled
        stop-service -name SEMgrSvc -force
        #Phone Service disable
        set-service -name phonesvc -startuptype disabled
        stop-service -name phonesvc -force
        #Problem Reports and Solutions Control Panel Support disable
        #https://docs.microsoft.com/en-us/previous-versions/cc441602(v%3dtechnet.10)
        set-service -name wercplsupport -startuptype disabled
        stop-service -name wercplsupport -force
        #Program Compatibility Assistant Service disable
        set-service -name PcaSvc -startuptype disabled
        stop-service -name PcaSvc -force
        #Retail Demo Service disable
        set-service -name RetailDemo -startuptype disabled
        stop-service -name RetailDemo -force
        #Smart Card Device Enumeration Service disable
        start-process powershell.exe -argumentlist 'set-service -name ScDeviceEnum -startuptype disabled ; stop-service -name ScDeviceEnum -force' -windowstyle hidden -verb runas
        #set-service -name ScDeviceEnum -startuptype disabled ; stop-service -name ScDeviceEnum -force
        #Smart Card disable
        start-process powershell.exe -argumentlist 'set-service -name SCardSvr -startuptype disabled ; stop-service -name SCardSvr -force' -windowstyle hidden -verb runas
        #set-service -name SCardSvr -startuptype disabled ; stop-service -name SCardSvr -force
        #Smart Card Removal Policy disable
        start-process powershell.exe -argumentlist 'set-service -name SCPolicySvc -startuptype disabled ; stop-service -name SCPolicySvc -force' -windowstyle hidden -verb runas
        #set-service -name SCPolicySvc -startuptype disabled ; stop-service -name SCPolicySvc -force
        #Spatial Data Service disable
        set-service -name SharedRealitySvc -startuptype disabled
        stop-service -name SharedRealitySvc -force
        #Telephony disable
        set-service -name TapiSrv -startuptype disabled
        stop-service -name TapiSrv -force
        #Windows Biometric Service disable
        set-service -name WbioSrvc -startuptype disabled
        stop-service -name WbioSrvc -force
        # Windows Error Reporting disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name Disabled -Value 1
        set-service -name WerSvc -startuptype disabled
        stop-service -name WerSvc -force
        #Windows Insider Service disable
        set-service -name wisvc -startuptype disabled
        stop-service -name wisvc -force
        #Windows Perception Service disable
        set-service -name spectrum -startuptype disabled
        stop-service -name spectrum -force
        #Windows Perception Simulation Service disable
        set-service -name perceptionsimulation -startuptype disabled
        stop-service -name perceptionsimulation -force
        #Xbox Accessory Management Service disable
        set-service -name XboxGipSvc -startuptype disabled
        stop-service -name XboxGipSvc -force
        #Xbox Live Auth Manager disable
        set-service -name XblAuthManager -startuptype disabled
        stop-service -name XblAuthManager -force
        #Xbox Live Game Save disable
        set-service -name XblGameSave -startuptype disabled
        stop-service -name XblGameSave -force
        #Xbox Live Networking Service disable
        set-service -name XboxNetApiSvc -startuptype disabled
        stop-service -name XboxNetApiSvc -force
        
        # add-WindowsCapability
        # OpenSSH Client install
        #https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
        add-WindowsCapability -online -Name "OpenSSH.Client~~~~0.0.1.0"
        
        # Remove-WindowsCapability
        # IE11 remove
        Get-windowscapability -online | where-object name -match '^App\.StepsRecorder' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^App\.Support\.QuickAssist' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Browser\.InternetExplorer' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Hello\.Face' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Microsoft\.Windows\.MSPaint' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Microsoft\.Windows\.Notepad' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Microsoft\.Windows\.PowerShell\.ISE' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Microsoft\.Windows\.Wordpad' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^Microsoft\.Windows\.Paint' | Remove-WindowsCapability -online
        Get-windowscapability -online | where-object name -match '^XPS\.\.Viewer' | Remove-WindowsCapability -online

        # WINDOWS OPTIONAL FEATURES
        <# Might be legacy from either earlier W10 or W10 Home?!
        FaxServicesClientPackage
        Internet-Explorer-Optional-amd64
        Microsoft-Windows-Printing-XPSServices-Package
        WindowsMediaPlayer
        Xps-Foundation-Xps-Viewer
        #>

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'SearchEngine-Client-Package' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'TFTP' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'FaxServicesClientPackage' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'Internet-Explorer-Optional-amd64' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'Microsoft-Windows-Printing-XPSServices-Package' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'MicrosoftWindowsPowerShellV2' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'MicrosoftWindowsPowerShellV2Root' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'NetFx3' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'Printing-Foundation-InternetPrinting-Client' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'Printing-XPSServices-Features' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'SMB1Protocol' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'SMB1Protocol-Client' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'SMB1Protocol-Deprecation' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'SMB1Protocol-Server' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'WindowsMediaPlayer' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }

        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'WorkFolders-Client' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        $wofchk_s=get-windowsoptionalfeature -online -FeatureName 'Xps-Foundation-Xps-Viewer' | Where-Object {$_.State -eq 'Enabled'}
        $fn_s=$wofchk_s.FeatureName
        if($wofchk_s.count -gt 0){
            Disable-WindowsOptionalFeature -Online -Featurename $fn_s -NoRestart
        }
        
        # REGISTRY
        <# NO
        # Camera breaks 
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessCamera -Value 2=
        # Microphone breaks
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessMicrophone -Value 2
        # Microsoft Account supposedly breaks getting feature updates
        new-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoConnectedUser" -Value 3
        set-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoConnectedUser" -Value 3
        set-itemproperty -path "HKLM:\System\CurrentControlSet\Services\wlidsvc" -Name "Start" -Value 4
        #> # NO END
        <#TODO
        # Windows Spotlight
        Set-ItemProperty -Path HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent -Name DisableWindowsSpotlightFeatures -Value 1
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Name NoLockScreen -Value 1
        Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Name LockScreenImage -Value C:\windows\web\screen\lockscreen.jpg
        Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Name LockScreenOverlaysDisabled -Value 1
        Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent -Name DisableSoftLanding -Value 1

        C:\Windows\System32\drivers\etc\hosts
        127.0.0.1 bing.com
        127.0.0.1 www.bing.com
        127.0.0.1 https://www.bing.com
        127.0.0.1 http://www.bing.com
        127.0.0.1 about:blank
        #>
        # TODO Windows Update Limit https://www.tenforums.com/tutorials/88607-limit-bandwidth-windows-update-store-app-updates-windows-10-a.html#option2
        # BITS https://docs.microsoft.com/en-us/windows/win32/bits/group-policies
        New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -ea 0
        Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -Name EnableBITSMaxBandwidth -Value 1
        Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -Name MaxBandwidthValidFrom -Value 4
        Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -Name MaxBandwidthValidTo -Value 20
        Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -Name MaxTransferRateOffSchedule -Value 10000
        Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\BITS' -Name MaxTransferRateOnSchedule -Value 0

        # Myricom
        $PhysicalAdapter=get-ciminstance -query "select Name from Win32_NetworkAdapter where name like 'Myricom%'"
        if($null -ne $PhysicalAdapter){
            $netadname=(get-netadapter -InterfaceDescription $PhysicalAdapter.Name).Name
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Adaptive Interrupt Moderation (AIM)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'AIM: Max Idle Time (msec)' -registryvalue 10
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'AIM: Max Period (msec)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Custom RSS Hash' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Degraded PCI Express Link' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Flow Control' -registryvalue 0
            # 0-1000
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Interrupt Coalescing Delay' -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Large Send Offload v2 (IPv4)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Large Send Offload v2 (IPv6)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Log Link State Event' -registryvalue 1
            #2-16
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Maximum Number of RSS Queues' -registryvalue 4
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'MTU' -registryvalue 9000
            #1024-32768
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Receive Buffers' -registryvalue 2048
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Receive Side Scaling' -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'Strip VLAN Tags' -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'TCP Checksum Offload (IPv4)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'TCP Checksum Offload (IPv6)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'UDP Checksum Offload (IPv4)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'UDP Checksum Offload (IPv6)' -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname 'VLAN ID' -registryvalue 0
        }
        # Intel(R) Ethernet Server Adapter I210-T1 configure
        #https://docs.microsoft.com/en-us/windows-hardware/drivers/network/task-offload

        $PhysicalAdapter=get-ciminstance -query "select DeviceID,Name from Win32_NetworkAdapter where name='Intel(R) Ethernet Server Adapter I210-T1'"
        if($null -ne $PhysicalAdapter){
            $netadname=(get-netadapter -InterfaceDescription $PhysicalAdapter.Name).Name
            $DeviceID=$PhysicalAdapter.DeviceID
            $AdapterDeviceNumber="000"+$DeviceID
            $KeyPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$AdapterDeviceNumber"
            Set-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24
            
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "ARP Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "DMA Coalescing" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Enable PME" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -RegistryKeyword "EnableLLI" -allproperties  -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Energy Efficient Ethernet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Flow Control" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Gigabit Master Slave Mode" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Interrupt Moderation" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Interrupt Moderation Rate" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "IPv4 Checksum Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Jumbo Packet" -registryvalue 1514
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Large Send Offload v2 (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Large Send Offload v2 (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Log Link State Event" -registryvalue 16
            Set-itemproperty -Path $KeyPath -Name "LLIPorts" -Value ('5016','9510','7001','7002','11000','11001','11020','11030')
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Maximum Number of RSS Queues" -registryvalue 4
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "NS Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Packet Priority & VLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "PTP Hardware Timestamp" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Receive Buffers" -registryvalue 2048
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Receive Side Scaling" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Reduce Speed On Power Down" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Software Timestamp" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Speed & Duplex" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "TCP Checksum offload (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "TCP Checksum offload (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Transmit Buffers" -registryvalue 2048
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "UDP Checksum offload (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "UDP Checksum offload (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wait for Link" -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on link Settings" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Magic Packet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Pattern Match" -registryvalue 0
        }

        <# Realtek ethernet configure for performance and trading
        Compatible IDs

        Has Advanced EEE
        PCI\VEN_10EC&DEV_8168&REV_10

        Does not have Advanced EEE
        PCI\VEN_10EC&DEV_8168&REV_11
        PCI\VEN_10EC&DEV_8168&REV_0C
        #>
        $PhysicalAdapter=get-ciminstance -query "select DeviceID,Name from Win32_NetworkAdapter where name='Realtek PCIe GbE Family Controller'"
        if($null -ne $PhysicalAdapter){
            $netadname=(get-netadapter -InterfaceDescription $PhysicalAdapter.Name).Name
            $DeviceID=$PhysicalAdapter.DeviceID
            $AdapterDeviceNumber="000"+$DeviceID
            $KeyPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$AdapterDeviceNumber"
            Set-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Advanced EEE" -registryvalue 0 -ea 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "ARP Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Auto Disable Gigabit" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Energy-Efficient Ethernet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Flow Control" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Green Ethernet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Interrupt Moderation" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "IPv4 Checksum Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Jumbo Frame" -registryvalue 1514
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Large Send Offload v2 (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Large Send Offload v2 (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Maximum Number of RSS Queues" -registryvalue 4
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "NS Offload" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Power Saving Mode" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Priority & VLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Receive Buffers" -registryvalue 512
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Receive Side Scaling" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Shutdown Wake-On-Lan" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Speed & Duplex" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "TCP Checksum offload (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "TCP Checksum offload (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Transmit Buffers" -registryvalue 128
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "UDP Checksum offload (IPv4)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "UDP Checksum offload (IPv6)" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Magic Packet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on pattern match" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "WOL & Shutdown Link Speed" -registryvalue 2
        }

        #Intel(R) Dual Band Wireless-AC 3168 configure
        $PhysicalAdapter=get-ciminstance -query "select DeviceID,Name from Win32_NetworkAdapter where name='Intel(R) Dual Band Wireless-AC 3168'"
        if($null -ne $PhysicalAdapter){
            $netadname=(get-netadapter -InterfaceDescription $PhysicalAdapter.Name).Name
            $DeviceID=$PhysicalAdapter.DeviceID
            $AdapterDeviceNumber="000"+$DeviceID
            $KeyPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$AdapterDeviceNumber"
            Set-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Sleep on WoWLAN Disconnect" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Packet Coalescing" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "ARP offload for WoWLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "NS offload for WoWLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "GTK rekeying for WoWLAN" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Magic Packet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Pattern Match" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Channel Width for 2.4GHz" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Channel Width for 5GHz" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Mixed Mode Protection" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Fat Channel Intolerant" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Transmit Power" -registryvalue 100
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "802.11n/ac Wireless Mode" -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "MIMO Power Save Mode" -registryvalue 3
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Roaming Aggressiveness" -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Preferred Band" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Throughput Booster" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "U-APSD support" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "802.11a/b/g Wireless Mode" -registryvalue 34
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Preferred Band" -registryvalue 0
        }

        #Intel(R) Dual Band Wireless-AC 7265 configure
        $PhysicalAdapter=get-ciminstance -query "select DeviceID,Name from Win32_NetworkAdapter where name='Intel(R) Dual Band Wireless-AC 7265'"
        if($null -ne $PhysicalAdapter){
            $netadname=(get-netadapter -InterfaceDescription $PhysicalAdapter.Name).Name
            $DeviceID=$PhysicalAdapter.DeviceID
            $AdapterDeviceNumber="000"+$DeviceID
            $KeyPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$AdapterDeviceNumber"
            Set-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "802.11a/b/g Wireless Mode" -registryvalue 34
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "802.11n/ac Wireless Mode" -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "ARP offload for WoWLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Channel Width for 2.4GHz" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Channel Width for 5GHz" -registryvalue 1
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Fat Channel Intolerant" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "GTK rekeying for WoWLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "MIMO Power Save Mode" -registryvalue 3
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Mixed Mode Protection" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "NS offload for WoWLAN" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Packet Coalescing" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Preferred Band" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Roaming Aggressiveness" -registryvalue 2
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Sleep on WoWLAN Disconnect" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Throughput Booster" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Transmit Power" -registryvalue 100
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "U-APSD support" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Magic Packet" -registryvalue 0
            set-netadapteradvancedproperty -norestart -name $netadname -displayname "Wake on Pattern Match" -registryvalue 0
        }

        # Location
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name DisableLocation -Value 1
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessLocation -Value 2
        # Adjust for Best Performance
        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects -Name VisualFXSetting -Value 00000002
        # Settings > Privacy > Radios > Access to control radios on this device > Off
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" -Name Value -Value Deny
        # Account Info
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessAccountInfo -Value 2
        # Account Information
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" -Name Value -Value Deny
        # Account History
        #https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services#bkmk-priv-ink
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name EnableActivityFeed -Value 2
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name PublishUserActivities -Value 2
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name UploadUserActivities -Value 2
        # BingSearchEnabled
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ea 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name DisableSearchBoxSuggestions -Value 1
        # Cortana
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCortana -Value 0
        #Allow search and Cortana to use location Disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowSearchToUseLocation -Value 0
        #App diagnostic info access for this device disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" -Name Value -Value Deny
        #App Diagnostics
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsGetDiagnosticInfo -Value 2
        #Appointments disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" -Name Value -Value Deny
        #Apps for websites
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableAppUriHandlers -Value 0
        #Automatically hide scroll bars in Windows disable
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name DynamicScrollbars -Value 0
        #Calendar
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessCalendar -Value 2
        #Call history
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessCallHistory -Value 2
        # CHAT
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" -Name Value -Value Deny
        #Contacts
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessContacts -Value 2
        #Defender sending file samples to Microsoft disable
        New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet" -ea 0
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Spynet" -Name SubmitSamplesConsent -Value 2
        #Defender SmartScreen for Microsoft Store Apps disable
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name EnableWebContentEvaluation -Value 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name PreventOverride -Value 0
        #Device metadata retrieval disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name PreventDeviceMetadataFromNetwork -Value 1
        #DisallowShaking
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ea 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name DisallowShaking -value 1
        #Location disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name Value -Value Deny
        #Speech, inking, and typing / Disable updates to speech recognition and speech synthesis models
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name RestrictImplicitInkCollection -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name HarvestContacts -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences" -Name ModelDownloadAllowed -Value 0
        #Windows Cloud Search disable
        #https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-search
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name AllowCloudSearch -Value 0
        # ?
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" -Name Value -Value Deny
        #Do not allow web search Enable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name DisableWebSearch -Value 1
        #Document library access for this device disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" -Name Value -Value Deny
        #Edge Disable address bar drop-down list suggestions
        #https://docs.microsoft.com/en-us/microsoft-edge/deploy/group-policies/address-bar-settings-gp
        #https://docs.microsoft.com/en-us/microsoft-edge/deploy/group-policies/new-tab-page-settings-gp
        #Edge Disable Allow web content on New Tab page
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\ServiceUI" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\ServiceUI" -name "ShowOneBox" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\ServiceUI" -name "AllowWebContentOnNewTabPage" -Type DWORD -Value 0 -ea 0
        #Edge Disable Allow a shared books folder
        #Edge Disable Allow configuration updates for the Books Library
        #Edge Disable full diagnostic data
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\BooksLibrary" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\BooksLibrary" -name "UseSharedFolderForBooks" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\BooksLibrary" -name "AllowConfigurationUpdateForBooksLibrary" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\BooksLibrary" -name "EnableExtendedBooksTelemetry" -Type DWORD -Value 0 -ea 0
        #Edge Disable Configure search suggestions in Address bar
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\SearchScopes" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\SearchScopes" -name "ShowSearchSuggestionsGlobal" -Type DWORD -Value 0 -ea 0
        #Edge Disable Prelaunch
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge" -name "AllowPrelaunch" -Type DWORD -Value 0 -ea 0
        #Edge Disable show books library regardless of support
        #Edge Disable browsing history
        #Edge Disable Autofill
        #Edge Disable Popups
        #Edge Disable Password Manager
        #Edge Disable "Do Not Track"
        #Edge Enable Prevent Microsoft Edge from gathering Live Tile information when pinning a site to Start
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "AlwaysEnableBooksLibrary" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "AllowSavingHistory" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "Use FormSuggest" -Type String -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "AllowPopups" -Type String -Value 1 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "FormSuggest Passwords" -Type String -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "DoNotTrack" -Type DWORD -Value 0 -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\Main" -name "PreventLiveTileDataCollection" -Type DWORD -Value 1 -ea 0
        #Tab Preloading
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\TabPreloader" -ea 0
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\MicrosoftEdge\TabPreloader" -name "AllowTabPreloading" -Type DWORD -Value 0 -ea 0
        # do not sync
        new-itemproperty -path "HKLM:\Software\Policies\Microsoft\Windows\SettingSync" -name "DisableSettingSyn" -Type DWORD -Value 2 -ea 0
        #Email
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessEmail -Value 2
        #Email access for this device disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" -Name Value -Value Deny
        #Find My Device disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name AllowFindMyDevice -Value 0
        #Game Mode
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name AutoGameModeEnabled -Value 0
        #GameDVR and Broadcast User Service disable
        #https://docs.microsoft.com/en-us/windows-hardware/drivers/install/hklm-system-currentcontrolset-services-registry-tree
        #https://docs.microsoft.com/en-us/windows/application-management/per-user-services-in-windows
        $gp=get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BcastDVRUserServic*"
        $gpp=$gp.pspath
        foreach ($i in $gpp) {Set-ItemProperty -Path $i -Name Start -Value 4}
        #Inking & Typing
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\InputPersonalization" -Name RestrictImplicitTextCollection -Value 1
        #Insider Preview Builds disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name AllowBuildPreview -Value 0

        #Let apps run in the background
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsRunInBackground -Value 2
        #Let apps use advertising ID to make ads more interesting to you based on your app usage disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name DisabledByGroupPolicy -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name Enabled -Value 0
        #Let websites provide locally relevant content by accessing my language list disable
        Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name HttpAcceptLanguageOptOut -Value 1
        #Let Windows track app launches to improve Start and search results disable
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_TrackProgs -Value 0
        #Live Tiles disable
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -ea 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name NoCloudApplicationNotification -Value 1
        #Login background disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name DisableLogonBackgroundImage -Value 1
        #Mail synchronization disable
        New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows Mail" -ea 0
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Mail" -Name ManualLaunchAllowed -Value 0
        #Malicious Software Reporting Tool diagnostic data disable
        #https://support.microsoft.com/en-us/help/891716/deploy-windows-malicious-software-removal-tool-in-an-enterprise-enviro
        New-Item -Path "HKLM:\Software\Policies\Microsoft\MRT\" -ea 0
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\MRT” -Name DontReportInfectionInformation -Value 1
        #Message Sync
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Messaging" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Messaging" -Name AllowMessageSync -Value 0
        #Messaging
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessMessaging -Value 2
        #Messaging cloud sync https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services#bkmk-syncsettings
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Messaging" -Name CloudServiceSyncEnabled -Value 0 -ea 0
        # Microsoft Update Health Tools stop installing
        New-Item -Path 'HKLM:\SOFTWARE\Microsoft\PCHC' -ea 0
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PCHC' -name PreviousUninstall -value 1
        
        # GET-PACKAGE
        #Get-Package: Unable to find package providers (Programs).
        #Get-Package -Provider Programs -IncludeWindowsInstaller -Name 'Microsoft Update Health Tools' | Uninstall-Package
        start-process powershell.exe -argumentlist "Get-Package -Provider Programs -IncludeWindowsInstaller -Name 'Microsoft Update Health Tools' | Uninstall-Package" -windowstyle hidden -verb runas

        #Motion
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessMotion -Value 2
        #Network Connection Status Indicator disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" -Name NoActiveProbe -Value 1
        #Notification
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessNotifications -Value 2
        #Notifications disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name NoCloudApplicationNotification -Value 1
        #Offline maps disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name AutoDownloadAndUpdateMapData -Value 0 ; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name AllowUntriggeredNetworkTrafficOnSettingsPage -Value 0
        #OneDrive disable
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name PreventNetworkTrafficPreUserSignIn -Value 1
        #Other devices
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsSyncWithDevices -Value 2
        #Phone call
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessPhone -Value 2
        #Pictures library access for this device disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" -Name Value -Value Deny
        #Radios
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessRadio -Value 2
        
        #Seconds in taskbar
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowSecondsInSystemClock -Value 1
        #Set what information is shared in Search
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name ConnectedSearchPrivacy -Value 3
        #Speech
        new-item -path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\' -ea 0
        new-item -path 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -ea 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name HasAccepted -Value 0
        #Stop minimizing all other windows when dragging a window with mouse
        #https://answers.microsoft.com/en-us/windows/forum/windows8_1-desktop/disable-aero-shake/a1f2e81f-beb2-4541-9398-43af0c505912
        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -ea 0
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name NoWindowMinimizingShortcuts -Value 1
        #Sync your settings
        New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\SettingSync" -ea 0
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\SettingSync" -Name DisableSettingSync -Value 2
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\SettingSync" -Name DisableSettingSyncUserOverride -Value 1
        #Tailored experiences with relevant tips and recommendations by using your diagnostics data
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name DisableWindowsConsumerFeatures  -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name DisableTailoredExperiencesWithDiagnosticData -Value 1
        #Tasks
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsAccessTasks -Value 2
        #Telemetry disable
        Set-ItemProperty -Path ‘HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection’ -Name AllowTelemetry -Value 0
        #Telemetry found pre-existing disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Value 0
        #Transparency Effects disable
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0
        #Videos Library access disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" -Name Value -Value Deny
        #Voice Activation
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsActivateWithVoice -Value 2
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name LetAppsActivateWithVoiceAboveLock -Value 2
        #Web Search disable
        #Don't search the web or display web results in Search Enable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name ConnectedSearchUseWeb -Value 0
        #Window preview when hovering mouse over taskbar icons disable
        Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ExtendedUIHoverTime -Value 196608
        #Windows Defender SmartScreen Disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name EnableSmartScreen -Value 0
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -ea 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -Name ConfigureAppInstallControlEnabled -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -Name ConfigureAppInstallControl -Value Anywhere
        #Windows should ask for my feedback disable
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name DoNotShowFeedbackNotifications -Value 1
        
        #FIREWALL START
        set-netfirewallrule -displayname "Captive Portal Flow" -action block
        $rulechk=get-netfirewallrule | where-object{$_.displayname -match 'Captive Portal Flow2'}
        If($null -eq $rulechk){
            new-netfirewallrule -action block -direction outbound -displayname "Captive Portal Flow2" -group "Captive Portal Flow" -Package "Microsoft.Windows.OOBENetworkCaptivePortal_cw5n1h2txyewy" -profile Domain,Private,Public
        }
        
        <# RECHECK
        # Searching by instanceID to then do something with set-netfirewallrule
        #Get-NetFirewallApplicationFilter -All | Select * | ? { $_.AppPath -match 'Searchui'}
        # Content Delivery Manager
        new-netfirewallrule -action block -direction outbound -displayname "@{Microsoft.Windows.ContentDeliveryManager_10.0.15063.0_neutral_neutral_cw5n1h2txyewy?ms-resource://Microsoft.Windows.ContentDeliveryManager/resources/AppDisplayName}2" -group "@{Microsoft.Windows.ContentDeliveryManager_10.0.15063.0_neutral_neutral_cw5n1h2txyewy?ms-resource://Microsoft.Windows.ContentDeliveryManager/resources/AppDisplayName}" -Package "Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy" -profile Domain,Private,Public

        #get-netfirewallrule | Where-Object {$_.group -Like "*ContentDeliveryManager*"} | foreach-object {set-netfirewallrule -group $_.group -action block}
        #>
        
        $rulechk=get-netfirewallrule | where-object{$_.displayname -match 'Connected User Experiences and Telemetry2'}
        if($null -eq $rulechk){
            new-netfirewallrule -action block -direction outbound -displayname "Connected User Experiences and Telemetry2" -group "DiagTrack" -profile Domain,Private,Public -program "%SystemRoot%\system32\svchost.exe" -Protocol TCP -RemotePort 443 -service DiagTrack
        }
        get-netfirewallrule | Where-Object {$_.group -Like "*BingWeather*"} | foreach-object {set-netfirewallrule -group $_.group -action block}
        set-netfirewallrule -displayname "Connected User Experiences and Telemetry" -action block
        set-netfirewallrule -displayname "Cortana" -action block
        $rulechk=get-netfirewallrule -displayname 'Cortana1'
        if($null -eq $rulechk){
            new-netfirewallrule -action block -displayname "Cortana1" -direction inbound -group Cortana -Package "Microsoft.Windows.Cortana_cw5n1h2txyewy" -profile Domain,Private,Public
            new-netfirewallrule -action block -displayname "Cortana1" -direction outbound -group Cortana -Package "Microsoft.Windows.Cortana_cw5n1h2txyewy" -profile Domain,Private,Public
        }
        $rulechk=get-netfirewallrule -displayname 'Cortana2'
        if($null -eq $rulechk){
            new-netfirewallrule -action block -displayname "Cortana2" -direction inbound -group "Cortana" -program "%windir%\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy\SearchUI.exe" -profile Domain,Private,Public
            new-netfirewallrule -action block -displayname "Cortana2" -direction outbound -group Cortana -program "%windir%\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy\SearchUI.exe" -profile Domain,Private,Public
        }
        set-netfirewallrule -displayname "Email and Accounts" -action block
        set-netfirewallrule -displayname "Microsoft Content" -action block
        set-netfirewallrule -displayname "Mixed Reality Portal" -action block -ea 0
        get-netfirewallrule | Where-Object {$_.displayname -like "*Start*"} | foreach-object {set-netfirewallrule -group $_.group -action block}
        set-netfirewallrule -displayname "Windows Calculator" -action block -ea 0
        set-netfirewallrule -displayname "Windows Default Lock Screen" -action block
        set-netfirewallrule -displayname "Windows Search" -action block
        set-netfirewallrule -displayname "Windows Shell Experience" -action block
        $rulechk=get-netfirewallrule -displayname 'Windows Shell Experience2'
        if($null -eq $rulechk){
            new-netfirewallrule -action block -direction outbound -displayname "Windows Shell Experience2" -group "Windows Shell Experience" -Package "Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy" -profile Domain,Private,Public
        }
        
        $rulechk=get-netfirewallrule -"@{Microsoft.Windows.ShellExperienceHost_10.0.15063.0_neutral_neutral_cw5n1h2txyewy?ms-resource://Microsoft.Windows.ShellExperienceHost/resources/PkgDisplayName}2"
        if($null -eq $rulechk){
            new-netfirewallrule -action block -direction outbound -displayname "@{Microsoft.Windows.ShellExperienceHost_10.0.15063.0_neutral_neutral_cw5n1h2txyewy?ms-resource://Microsoft.Windows.ShellExperienceHost/resources/PkgDisplayName}2" -group "@{Microsoft.Windows.ShellExperienceHost_10.0.15063.0_neutral_neutral_cw5n1h2txyewy?ms-resource://Microsoft.Windows.ShellExperienceHost/resources/PkgDisplayName}" -Package "Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy" -profile Domain,Private,Public
        }
        $rulechk=get-netfirewallrule -displayname 'Xbox Game UI2'
        if($null -eq $rulechk){
            new-netfirewallrule -action block -direction outbound -displayname "Xbox Game UI2" -group "Xbox Game UI" -Package "Microsoft.XboxGameCallableUI_cw5n1h2txyewy" -profile Domain,Private,Public
        }
        get-netfirewallrule | Where-Object {$_.group -Like "*PeopleExperienceHost*"} | foreach-object {set-netfirewallrule -group $_.group -action block}
        get-netfirewallrule | Where-Object {$_.group -Like "*ShellExperienceHost*"} | foreach-object {set-netfirewallrule -group $_.group -action block}
        set-netfirewallrule -displayname "Xbox Game UI" -action block
        
        # INSIGNIA NS_CAHBT02
        #get-pnpdevice -class 'AudioEndpoint'| where {$_.friendlyname -like "Headset (INSIGNIA NS-CAHBT02 Hands-Free*"}|disable-pnpdevice -confirm:$false ; get-pnpdevice -class 'MEDIA'| where {$_.friendlyname -like "INSIGNIA NS-CAHBT02 Hands-*"}|disable-pnpdevice -confirm:$false
        
        # TASK SCHEDULER
        # Autochk This task collects and uploads autochk SQM data if opted-in to the Microsoft Customer Experience Improvement Program.
        get-scheduledtask -taskpath \Microsoft\Windows\Autochk\ | disable-scheduledtask
        
        #Customer Experience Improvement Program disable
        get-scheduledtask -taskpath '\Microsoft\Windows\Customer Experience Improvement Program\' | disable-scheduledtask
        get-scheduledtask -taskpath '\Microsoft\Windows\Feedback\Siuf\' | disable-scheduledtask
        get-scheduledtask -taskpath '\Microsoft\Windows\Windows Error Reporting\' | disable-scheduledtask
        
        #HelloFace disable
        get-scheduledtask -taskpath \Microsoft\Windows\HelloFace\ | disable-scheduledtask
        #Maps
        get-scheduledtask -taskpath \Microsoft\Windows\Maps\ | disable-scheduledtask
        # Speech
        get-scheduledtask -taskpath \Microsoft\Windows\Speech\ | disable-scheduledtask
        # Xbox
        get-scheduledtask -taskpath \Microsoft\XblGameSave\ | disable-scheduledtask
        # Webex Service remnant need to check for program install than do this
        #sc.exe delete atashost

        # WINDOWS DEFENDER EXCLUSIONS
        add-mppreference -exclusionprocess 'C:\Program Files\AutoHotkey\AutoHotkey.exe'
        add-mppreference -exclusionpath 'C:\Program Files\AutoHotkey\AutoHotkey.exe' 
        add-mppreference -exclusionprocess 'C:\Program Files\AutoHotkey\AutoHotkeyU64.exe'
        add-mppreference -exclusionpath 'C:\Program Files\AutoHotkey\AutoHotkeyU64.exe'
        add-mppreference -exclusionprocess 'C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe'
        add-mppreference -exclusionpath 'C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe'
        add-mppreference -exclusionprocess 'C:\Program Files (x86)\obs-studio\bin\64bit\obs64.exe'
        add-mppreference -exclusionpath 'C:\Program Files (x86)\obs-studio\bin\64bit\obs64.exe'
        add-mppreference -exclusionprocess 'C:\Windows\System32\dwm.exe'
        add-mppreference -exclusionpath 'C:\Windows\System32\dwm.exe'

        # NVIDIA
        RunDll32 "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage Ansel
        RunDll32 "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage NvTelemetryContainer
    }
}