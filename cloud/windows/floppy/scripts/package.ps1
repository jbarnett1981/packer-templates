Enable-RemoteDesktop
Set-NetFirewallRule -Name RemoteDesktop-UserMode-In-TCP -Enabled True

Write-BoxstarterMessage "Removing page file"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

Update-ExecutionPolicy Unrestricted
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar
Disable-InternetExplorerESC
Disable-UAC

Write-BoxstarterMessage "Removing unused features..."
Remove-WindowsFeature -Name 'Powershell-ISE'
Get-WindowsFeature | 
? { $_.InstallState -eq 'Available' } | 
Uninstall-WindowsFeature -Remove

Write-BoxstarterMessage "Adding REG config for TSI.LAN WSUS server..."
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate  /v WUServer /t REG_SZ /d http://1krkdvvwwsus01.tsi.lan:8530 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate  /v WUStatusServer /t REG_SZ /d http://1krkdvvwwsus01.tsi.lan:8530 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate  /v TargetGroup /t REG_SZ /d TSI_DevIT_General /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate  /v TargetGroupEnabled /t REG_DWORD /d 00000001 /f
 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  /v NoAutoUpdate /t REG_DWORD /d 00000000 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  /v AUOptions /t REG_DWORD /d 00000004 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  /v ScheduledInstallDay /t REG_DWORD /d 00000000 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  /v ScheduledInstallTime /t REG_DWORD /d 00000003 /f 
REG ADD HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  /v UseWUServer /t REG_DWORD /d 00000001 /f

Install-WindowsUpdate -AcceptEula
if(Test-PendingReboot){ Invoke-Reboot }

Write-BoxstarterMessage "Cleaning SxS..."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
    "$env:localappdata\Nuget",
    "$env:localappdata\temp\*",
    "$env:windir\logs",
    "$env:windir\panther",
    "$env:windir\temp\*",
    "$env:windir\winsxs\manifestcache"
) | % {
        if(Test-Path $_) {
            Write-BoxstarterMessage "Removing $_"
            Takeown /d Y /R /f $_
            Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
            Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

Write-BoxstarterMessage "defragging..."
Optimize-Volume -DriveLetter C

Write-BoxstarterMessage "0ing out empty space..."
wget http://download.sysinternals.com/files/SDelete.zip -OutFile sdelete.zip
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
[System.IO.Compression.ZipFile]::ExtractToDirectory("sdelete.zip", ".") 
./sdelete.exe /accepteula -z c:

mkdir C:\Windows\Panther\Unattend
copy-item a:\postunattend.xml C:\Windows\Panther\Unattend\unattend.xml

Write-BoxstarterMessage "Recreate pagefile after sysprep"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
$System.AutomaticManagedPagefile = $true
$System.Put()

Write-BoxstarterMessage "Setting up winrm"
Set-NetFirewallRule -Name WINRM-HTTP-In-TCP-PUBLIC -RemoteAddress Any
Enable-WSManCredSSP -Force -Role Server

Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"} '

netsh advfirewall firewall set rule group="remote administration" new enable=yes
netsh firewall add portopening TCP 5985 "Port 5985"
net stop winrm
sc.exe config winrm start= auto
net start winrm

#Rename Local Admin Account
$admin=[adsi]"WinNT://./Administrator,user"
$admin.psbase.rename("admin.server")
