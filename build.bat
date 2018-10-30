@ECHO OFF
ECHO Running custom build. . . 
TIMEOUT /T 1 /NOBREAK >NUL
PowerShell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File .\build.ps1