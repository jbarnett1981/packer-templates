wget https://www.cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi -OutFile $ENV:TEMP\cloudinit.msi

$p = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $ENV:TEMP\cloudinit.msi /qn /norestart" -Wait -PassThru

if($p.ExitCode -ne 0)
{
    throw "Installation process returned error code: $($p.ExitCode)"
}