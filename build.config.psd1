@{
    # Verbose output; set to 'SilentlyContinue' for less output
    Preference = @{
        VerbosePreference = 'Continue'
        WarningPreference = 'Continue'
        ErrorActionPreference = 'SilentlyContinue'
        ErrorView = 'NormalView'
    }

    # Color output; use .NET ConsoleColors
    PrivateData = @{
        ErrorForegroundColor = "DarkRed"
        ErrorBackgroundColor = "Black"
        WarningForegroundColor = "DarkYellow"
        WarningBackgroundColor = "Black"
        DebugForegroundColor = "Magenta"
        DebugBackgroundColor = "Black"
        VerboseForegroundColor = "DarkCyan"
        VerboseBackgroundColor = "Black"
        ProgressForegroundColor = "Black" 
        ProgressBackgroundColor = "Gray"
    }
}