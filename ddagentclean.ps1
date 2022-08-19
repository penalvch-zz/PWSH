<#
 .SYNOPSIS

 Collects the status of a Datadog Agent installation, and performs a clean uninstall.

 .DESCRIPTION

 Collects the status of the Datadog Agent installation. Returns status of the MSI installer database, as well as the existence of the datadog user and required registry keys. Uninstalls agent. Performs cleanup of prior installs.

 .INPUTS

 None

#>

# Establish logging 
$fn=-join((get-date -format yyyymmddHHmm).tostring(),'ddoglog.txt')
new-item -path . -name $fn -itemtype 'file'

# Confirm running on Windows
if([environment]::OSVersion.tostring().startswith('Microsoft') -eq $false){
    Write-Host -ForegroundColor Red 'OS not Windows.'
    add-content -path $fn -value 'Not using Windows. Exiting.'
    exit 1
}

# Get the ID and security principal of the current user account to confirm if admin
$usradminchk_1=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if($usradminchk_1 -eq $false){
    Write-Host -ForegroundColor Red 'This script requires an elevated shell'
    add-content -path $fn -value 'User not an administrator. Exiting.'
    exit 1
}

# Get Execution Policy
$gepl=get-executionpolicy -list
add-content -path $fn -value 'Scope ExecutionPolicy'
foreach($item in $gepl){
    add-content -path $fn -value "$item.scope.tostring() $item.ExecutionPolicy.tostring()"
}

# Get PowerShell version
$psv=$PSversionTable
add-content -path $fn -value "$psv.PSVersion.Major $psv.PSVersion.Minor $psv.PSVersion.Patch"

# Get Windows version and patch level
$gcvb=(get-ciminstance -class win32_OperatingSystem | select-object Version,BuildNumber).tostring()
add-content -path $fn -value "Windows Version and Patch: $gcvb"

$product_name='Datadog Agent'
$ddagentuser_name='ddagentuser'
$dd_reg_root='HKLM:\Software\Datadog\Datadog Agent'
$query="Select Name,IdentifyingNumber,InstallDate,InstallLocation,ProductID,Version FROM Win32_Product where Name like '$product_name%'"
$userfilter="name = '$ddagentuser_name'"

function getRegistryInstallKeys{
    $ErrorActionPreference='stop'
    Write-Host -ForegroundColor Green 'Checking for Datadog Registry Entries'
    add-content -path $fn -value 'Checking for Datadog Registry Entries'
    Try{
        $rroot=Get-ItemProperty -Path "$dd_reg_root\uninstallStatus"
    } Catch [System.Management.Automation.ItemNotFoundException]{
        Write-Host -ForegroundColor Yellow 'Registry install root not found'
        add-content -path $fn -value 'Registry install root not found'
    }

    if($rroot){
        Try{
            $croot=(Get-ItemProperty -Path "$dd_reg_root\uninstallStatus" -Name 'CreatedDDUser').CreatedDDUser
        } Catch [System.Management.Automation.ItemNotFoundException]{
            # DO NOTHING
        } Catch [System.Management.Automation.PSArgumentException]{
            # DO NOTHING
        }
        Try{
            $isvcs=(Get-ItemProperty -Path "$dd_reg_root\uninstallStatus" -Name 'Installed Services').'Installed Services'
        } Catch [System.Management.Automation.ItemNotFoundException]{
            # DO NOTHING
        } Catch [System.Management.Automation.PSArgumentException]{
            # DO NOTHING
        }
    }
    return $croot, $isvcs
}

function getRegistryKeys{
    $ErrorActionPreference='stop'
    Write-Host -ForegroundColor Green 'Checking for Datadog Registry Entries'
    add-content -path $fn -value 'Checking for Datadog Registry Entries'
    Try{
        $rroot=Get-ItemProperty -Path $dd_reg_root
    } Catch [System.Management.Automation.ItemNotFoundException]{
        Write-Host -ForegroundColor Yellow 'Registry root not found'
        add-content -path $fn -value 'Registry root not found'
    }

    if($rroot){
        Try{
            $croot=(Get-ItemProperty -Path $dd_reg_root -Name 'ConfigRoot').ConfigRoot
        } Catch [System.Management.Automation.ItemNotFoundException]{
            # DO NOTHING
        } Catch [System.Management.Automation.PSArgumentException]{
            # DO NOTHING
        }
        Try{
            $ipath=(Get-ItemProperty -Path $dd_reg_root -Name 'InstallPath').InstallPath
        } Catch [System.Management.Automation.ItemNotFoundException]{
            # DO NOTHING
        } Catch [System.Management.Automation.PSArgumentException]{
            # DO NOTHING
        }
    }
    return $croot, $ipath
}

function checkService{
    Param($svcName)
    Write-host -ForegroundColor Green "Checking service $svcName installation"
    add-content -path $fn -value "Checking service $svcName installation"
    $svc=Get-Service $svcName -ErrorAction SilentlyContinue
    $svc_found=($svc.length -gt 0)
    if($svc_found){
        Write-Host -ForegroundColor Green "Found $svcName installed"
        add-content -path $fn -value "Found $svcName installed"
    }else{
        Write-Host -ForegroundColor Green "Didn't find $svcName service"
        add-content -path $fn -value "Didn't find $svcName service"
    }
    return $svc_found
}

function checkAndDelete{
    Param($svcName)
    $svc_found_after_uninstall=checkService($svcName)
    if($svc_found_after_uninstall){
        Write-Host -ForegroundColor Yellow 'Service still present after uninstall, removing'
        add-content -path $fn -value 'Service still present after uninstall, removing'
        Stop-Service -Force $svcName
        $scdelete = & sc.exe delete $svcName
        Write-Host -ForegroundColor Green "Service delete code (for $svcName) $scdelete"
        add-content -path $fn -value "Service delete code (for $svcName) $scdelete"
    }
    else{
        Write-Host -ForegroundColor Green "Service $svcName deleted by uninstall"
        add-content -path $fn -value "Service $svcName deleted by uninstall"
    }
}


function checkForLogFiles{
    # This fails on certain unrelated files as they are in use, even after immediate restart.
    $files=(get-childitem -path $Env:TEMP\..\*.log -recurse | select-string -pattern datadog -List | sort-object lastwritetime | select path).path
    foreach($file in $files){
        Write-Host -ForegroundColor Green "Found install log file: $file"
        add-content -path $fn -value "Found install log file: $file"
    }
}
Write-Host -ForegroundColor Green "Checking for Datadog Agent Installs (may take a while)..."
add-content -path $fn -value "Checking for Datadog Agent Installs (may take a while)..."
$installs = Get-ciminstance -query $query

if($installs.Count -eq 0){
    Write-Host -ForegroundColor Green 'No installations of Datadog Agent found in install database'
    add-content -path $fn -value 'No installations of Datadog Agent found in install database'
}elseif($installs.Count -gt 1){
    Write-Host -ForegroundColor Yellow  'Found more than one installation of the Datadog Agent.'
    add-content -path $fn -value 'Found more than one installation of the Datadog Agent.'
}else{
    Write-Host -ForegroundColor Green 'Found 1 Datadog agent install'
    add-content -path $fn -value 'Found 1 Datadog agent install'
}
foreach($package in $installs){
    Write-Host -ForegroundColor Green "Found installed $($package.Name)"
    add-content -path $fn -value "Found installed $($package.Name)"
    Write-Host -ForegroundColor Green "                $($package.IdentifyingNumber)"
    add-content -path $fn -value "                $($package.IdentifyingNumber)"
    Write-Host -ForegroundColor Green "                $($package.InstallDate)"
    add-content -path $fn -value "                $($package.InstallDate)"
    Write-Host -ForegroundColor Green "                $($package.Version)"
    add-content -path $fn -value "                $($package.Version)"
}

Write-Host -ForegroundColor Green 'Checking for log files'
add-content -path $fn -value 'Checking for log files'
checkForLogFiles

Write-Host -ForegroundColor Green 'Checking for ddagentuser'
add-content -path $fn -value 'Checking for ddagentuser'
$user=get-ciminstance win32_useraccount -Filter $userfilter
if($user){
    Write-Host -ForegroundColor Green 'Found ddagentuser'
    add-content -path $fn -value 'Found ddagentuser'
}else{
    Write-Host -ForegroundColor Green "Didn't find ddagentuser"
    add-content -path $fn -value "Didn't find ddagentuser"
}

Write-host -ForegroundColor Green 'Checking service installation'
add-content -path $fn -value 'Checking service installation'
$svc_found=checkService -svcName 'datadogagent'
$apm_found=checkService -svcName 'datadog-trace-agent'
$process_found=checkService -svcName 'datadog-process-agent'
$npm_driver_found=checkService -svcName 'ddnpm'
$sysprobe_found=checkService -svcName 'datadog-system-probe'

$regpaths=getRegistryKeys
$configroot=$regpaths[0]
$installpath=$regpaths[1]

if(!$configroot){
    Write-Host -ForegroundColor Yellow 'ConfigRoot property not found'
    add-content -path $fn -value 'ConfigRoot property not found'
}else{
    Write-Host -ForegroundColor Green "ConfigRoot property $configroot"
    add-content -path $fn -value "ConfigRoot property $configroot"
}
if(!$installpath){
    Write-Host -ForegroundColor Yellow 'InstallPath property not found'
    add-content -path $fn -value 'InstallPath property not found'
}else{
    Write-Host -ForegroundColor Green "Install path property $installpath"
    add-content -path $fn -value "Install path property $installpath"
}

$installkeys=getRegistryInstallKeys
$created_dd_user=$installkeys[0]
$installed_services=$installkeys[1]

if(!$created_dd_user){
    Write-Host -ForegroundColor Green 'ddagentuser was not created on this machine, will not be removed'
    add-content -path $fn -value 'ddagentuser was not created on this machine, will not be removed'
}else{
    Write-Host -ForegroundColor Green "ddagentuser $created_dd_user was created, would be removed by install"
    add-content -path $fn -value "ddagentuser $created_dd_user was created, would be removed by install"
}

if(!$installed_services){
    Write-Host -ForegroundColor Green 'Datadog services were not registered by this install'
    add-content -path $fn -value 'Datadog services were not registered by this install'
}else{
    Write-Host -ForegroundColor Green 'Datadog services were registered by this install'
    add-content -path $fn -value 'Datadog services were registered by this install'
}

Write-Host -ForegroundColor Green 'Checking for driver files'
add-content -path $fn -value 'Checking for driver files'
if($installpath){
	$driverpath="$installpath\bin\agent\driver"
}else{
	$driverpath='C:\Program Files\Datadog\Datadog Agent\bin\agent\driver'
}
add-content -path $fn -value "Driver path: $driverpath"

if(test-path $driverpath){
    $driverFiles=(get-childitem -path $driverpath -recurse | select name).name
    foreach($file in $driverFiles){
        Write-Host -ForegroundColor Green "Found driver file: $file"
        add-content -path $fn -value "Found driver file: $file"
    }
}

Write-Host -ForegroundColor Green 'Agent check complete'
add-content -path $fn -value 'Agent check complete'
Write-Host -ForegroundColor Green "`n=====================================================================================`n`n"
add-content -path $fn -value "`n=====================================================================================`n`n"

if($created_dd_user){
    Write-Host -ForegroundColor Yellow 'Removing installed user registry key, user may be left behind'
    add-content -path $fn -value 'Removing installed user registry key, user may be left behind'
    Remove-ItemProperty -Path "$dd_reg_root\uninstallStatus" -Name 'CreatedDDUser'
}

Write-Host -ForegroundColor Yellow 'Attempting cleanup/uninstalls'
add-content -path $fn -value 'Attempting cleanup/uninstalls'
foreach($package in $installs) {
    Write-Host -ForegroundColor Green 'Uninstalling existing agent'
    add-content -path $fn -value 'Uninstalling existing agent'
    Write-Host -ForegroundColor Green "Found installed $($package.Name)"
    add-content -path $fn -value "Found installed $($package.Name)"
    Write-Host -ForegroundColor Green "                $($package.IdentifyingNumber)"
    add-content -path $fn -value "                $($package.IdentifyingNumber)"
    Write-Host -ForegroundColor Green "                $($package.InstallDate)"
    add-content -path $fn -value "                $($package.InstallDate)"
    Write-Host -ForegroundColor Green "                $($package.Version)"
    add-content -path $fn -value "                $($package.Version)"
    $process=(Start-Process -FilePath msiexec -ArgumentList "/log dduninst.log /q /x $($package.IdentifyingNumber)" -PassThru -Wait)
    if($($process.ExitCode) -eq 0){
        Write-Host -ForegroundColor Green 'Uninstalled successfully'
        add-content -path $fn -value 'Uninstalled successfully'
    }else{
        Write-Host -ForegroundColor Yellow "Uninstall returned code $($process.ExitCode)"
        add-content -path $fn -value "Uninstall returned code $($process.ExitCode)"
    }
}

if($user){
    $user_after_uninstall=get-wmiobject win32_useraccount -Filter $userfilter
    if($user_after_uninstall){
        Write-Host -ForegroundColor Yellow 'Ddagentuser still present; removing'
        add-content -path $fn -value 'Ddagentuser still present; removing'
        $netuser=& net user ddagentuser /DELETE
        Write-Host -ForegroundColor Green "User delete: $netuser"
        add-content -path $fn -value "User delete: $netuser"
    }else{
        Write-Host -ForegroundColor Green 'ddagentuser deleted by uninstall'
        add-content -path $fn -value 'ddagentuser deleted by uninstall'
    }
}

if($sysprobe_found){
    checkAndDelete -svcName 'datadog-system-probe'
    add-content -path $fn -value "checkAndDelete -svcName 'datadog-system-probe'"
}
if($npm_driver_found){
	checkAndDelete -svcName 'ddnpm'
    add-content -path $fn -value "checkAndDelete -svcName 'ddnpm'"
}
if($apm_found){
    checkAndDelete -svcName 'datadog-trace-agent'
    add-content -path $fn -value "checkAndDelete -svcName 'datadog-trace-agent'"
}
if($process_found){
    checkAndDelete -svcName 'datadog-process-agent'
    add-content -path $fn -value "checkAndDelete -svcName 'datadog-process-agent'"
}
if($svc_found){
    checkAndDelete -svcName 'datadogagent'
    add-content -path $fn -value "checkAndDelete -svcName 'datadogagent'"
}

$regpaths_after=getRegistryKeys
$configroot_after=$regpaths_after[0]
$installpath_after=$regpaths_after[1]

if($configroot){
    if($configroot_after){
        Write-Host -ForegroundColor Yellow "Deleting configroot key $configroot_after"
        add-content -path $fn -value "Deleting configroot key $configroot_after"
        Remove-ItemProperty -Path $dd_reg_root -Name ConfigRoot
    }else{
        Write-Host -ForegroundColor Green "Configroot removed by uninstall"
        add-content -path $fn -value "Configroot removed by uninstall"
    }
}
if($installpath){
    if($installpath_after){
        Write-Host -ForegroundColor Yellow "Deleting InstallPath key $installpath_after"
        add-content -path $fn -value "Deleting InstallPath key $installpath_after"
        Remove-ItemProperty -Path $dd_reg_root -Name InstallPath
    }else{
        Write-Host -ForegroundColor Green 'InstallPath removed by uninstall'
        add-content -path $fn -value 'InstallPath removed by uninstall'
    }
}

# FILE+FOLDER STUFF

$pd='C:\ProgramData\Datadog'
if(test-path -path $pd){
    remove-item $pd -recurse -force
    add-content -path $fn -value "Removed $pd"
}

$pf='C:\Program Files\Datadog'
if(test-path -path $pf){
    remove-item $pf -recurse -force
    add-content -path $fn -value "Removed $pf"
}

$dau=get-childitem -path C:\Users\ -filter ddagentuser*
if($dau.count -gt 0){
    $ddapath1='C:\Users\ddagentuser'
    $ddapath2=-join('C:\Users\ddagentuser-',$env:computername)
    if(test-path $ddapath1){
        remove-item -path $ddapath1 -recurse -force
        add-content -path $fn -value "Removed $ddapath1"
    }
    if(test-path $ddapath2){
        remove-item -path $ddapath2 -recurse -force
        add-content -path $fn -value "Removed $ddapath2"
    }
}

$aud='C:\Users\All Users\Datadog'
if(test-path -path $aud){
    remove-item -path $aud -recurse -force
    add-content -path $fn -value "Removed $aud"
}

$aumd='C:\Users\All Users\Microsoft\User Account Pictures\ddagentuser.dat'
if(test-path -path $aumd){
    remove-item $aumd -force
    add-content -path $fn -value "Removed $aumd"
}

# REGISTRY STUFF

if(test-path 'HKLM:\SOFTWARE\Datadog'){
  remove-item -path 'HKLM:\SOFTWARE\Datadog' -force -recurse
  add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Datadog'
}

# TODO REMOVE ENTRIES IN "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

$temp=get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\' -ea SilentlyContinue
if($null -ne $temp){
    remove-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\' -force
    add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders C:\ProgramData\Datadog\'
}

$temp=get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\conf.d\' -ea SilentlyContinue
if($null -ne $temp){
    remove-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\conf.d\' -force
    add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders C:\ProgramData\Datadog\conf.d\'
}

$temp=get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\conf.d\directory.d\' -ea SilentlyContinue
if($null -ne $temp){
    remove-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\conf.d\directory.d\' -force
    add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders C:\ProgramData\Datadog\conf.d\directory.d\'
}

$temp=get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\logs\' -ea SilentlyContinue
if($null -ne $temp){
    remove-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\logs\' -force
    add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders C:\ProgramData\Datadog\logs\'
}

$temp=get-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\run\' -ea SilentlyContinue
if($null -ne $temp){
    remove-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders' -name 'C:\ProgramData\Datadog\run\' -force
    add-content -path $fn -value 'Removed HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders C:\ProgramData\Datadog\run\'
}

$test=get-ciminstance -class win32_userprofile |where-object {$_.localpath -eq 'C:\Users\ddagentuser'}
if($null -ne $test){
    remove-ciminstance -inputobject $test
    add-content -path $fn -value "remove-ciminstance -inputobject $test"
}

$test=get-ciminstance -class win32_userprofile |where-object {$_.localpath -eq "C:\Users\ddagentuser.$env:computername"}
if($null -ne $test){
    remove-ciminstance -inputobject $test
    add-content -path $fn -value "remove-ciminstance -inputobject $test"
}

$finishtime=(get-date -format yyyymmddHHmm).tostring()
add-content -path $fn -value "Script finished at $finishtime"
