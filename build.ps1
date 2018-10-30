#Requires -Version 2

# [ Config]

. ./ImportPowerShellDataFile.ps1
Split-Path $script:MyInvocation.MyCommand.Path | 
    Join-Path -ChildPath build.config.psd1 | 
    Import-PowerShellDataFile2 |
    Foreach-Object {
        $_.Preference.GetEnumerator() | Foreach-Object { Set-Variable -Name $_.Key -Value $_.Value }
        $_.PrivateData.GetEnumerator() | ForEach-Object { $Host.PrivateData.($_.Key) = $_.Value }
    }

# [ Execute ]

& ./build.nova.ps1
Write-Host -NoNewLine 'Press any key to exit...'
$Host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown') > $null