@{
    # Use either absolute paths or paths relative to nebula.ps1
    Paths = @{
        Source = '../src/'
        Extras = '../extras/'
        Temp = '../temp'
    }
    LauncherMessages = @(
        'Example!'
    )
    LauncherOptions = @(
        @{
            Task = 'Default'
            HelpMessage = 'Executes the default task'
            Order = 0
            Default = $true
        }
        @{
            Task = 'Clean'
            HelpMessage = 'Do the clean'
            Order = 1
        }
        @{
            Task = 'Build'
            HelpMessage = 'Build da thing'
            Order = 2
        }
    )

    # Add other variables as necessary below. Use in tasks with $Nebula.Key
}