del /q /f c:\windows\system32\sysprep\unattend.xml
del /q /f c:\windows\panther\unattend.xml
wmic useraccount where name='Administrator' call rename name='admin.server'
