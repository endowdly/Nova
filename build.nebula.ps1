$Properties = {
    $ScriptPath = Split-Path $Profile
    $ModulePath = Join-Path $ScriptPath Modules
    $ScriptRoot = $Nova.ScriptRoot
    $Desktop    = Join-Path $env:USERPROFILE Desktop
}

$Nebula = @{  

    # ! Tasks should be written in order. The last scriptblock should depend on
    #   all and the first should depend on none.
    
    Example = @{
        Order = 1
        Task  = { 
            Set-Location $Desktop
            "Hello From Nova, the simple linear PowerShell build tool!" > hello.txt 
        }
    }

    Clean = @{
        Order = 2
        Task = { }
    }
    Init = @{
        Order = 3
        Task = { }
    }
    Build = @{
        Order = 4
        Task = { }
    }
}
