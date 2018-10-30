#Requires -Version 2

<# ============================================================================
 [   Author   ] endowdly@gmail.com
 [   Created  ] 24 Aug 2017
 [   Modified ] 10 Jun 2018
    
 I would've used Psake, but for such a small simple build, why add
 a dependency?
 
 To change verbosity or affect other preferences, see ./build.config.psd1. 
 Otherwise, just run build.bat and enjoy. 
 
 If you want to change or extend this build, you can! Just change or build your
 own nebula file. Nebulas must include a Nebula hashtable with each task being
 a hasthable holding task (scriptblock) and order (int) values:
 
 $Nebula = @{
    FirstTask = @{
        Task = { "Hello world!" } 
        Order = 1
    }

    SecondTask = @{
        Task = { "Depends on FirstTask" }
        Order = 2 
    }
 }

 Nebula files also optionally hold a Properties ScriptBlock:

 $Properties = {
    $FileWide = "This can be accessed by every task"
 }
 
 For any build more complicated than this, or if you'd like to to use
 PowerShell to use MSBuild or VisualStudio solutions, take a look at Psake, 
 a much more complete build DSL in the vein of Make, Cake, Rake, Fake, and so 
 forth: https://github.com/psake/psake 
 ============================================================================#>

# Welcome to Nova, a Custom Build Script

Write-Verbose "Starting Nova"

#region Startup 
$Nova = @{   
    RunningNova = "Running Nova Build"
    ScriptRoot  = Split-Path $script:MyInvocation.MyCommand.Path
    Nebula = Split-Path $script:MyInvocation.MyCommand.Path | Join-Path -ChildPath build.nebula.ps1   
}

$Progress = @{ 
    Activity         = $Nova.RunningNova
    Status           = $null
    CurrentOperation = $null
    PercentComplete  = $null
}

$Diagnostics = @{
    StopWatch    = New-Object System.Diagnostics.StopWatch
    Report       = @{}
    ErrorCount   = 0
    WarningCount = 0
}
#endregion

# Using Nebula
. $Nova.Nebula 

Write-Verbose 'Nova Initialized'

# Start the build!
$Nova.RunningNova;

#region Build Logic
$Nebula.GetEnumerator() |
    Sort-Object { $_.Value.Order } | 
    Foreach-Object -Begin { $Count = 1 } -Process {
        # using Nebula.Properties
        if ($Properties) { . $Properties }
        
        $Diagnostics.StopWatch.Start()
        
        $CurrentTask = $_.Key        
        $Progress.Status = $CurrentTask
        $Progress.CurrentOperation = 'Running Task'
        $Progress.PercentComplete = $Count / $Nebula.Count * 100
        
        Write-Progress @Progress
        Write-Verbose "Task: $CurrentTask"
        
        try {
            $_.Value.Task.Invoke()
            $Progress.CurrentOperation = 'Done'
        }
        catch {
            $Diagnostics.ErrorCount++
            $Progress.CurrentOperation = 'Fail'
            
            Write-Error $_.Exception.InnerException
        }
        finally {            
            $Diagnostics.Report.Add($CurrentTask, $Diagnostics.StopWatch.Elapsed)
            $Diagnostics.StopWatch.Reset()
            $Count++
            
            Write-Progress @Progress
            Write-Verbose ('{0}: {1}' -f $Progress.CurrentOperation, $CurrentTask)
        }
    }
#endregion
    
#region Report
Write-Progress @Progress -Completed

$TotalTime = $Diagnostics.Report.GetEnumerator() | 
    ForEach-Object { $_.Value } | 
    Measure-Object -Sum Ticks | 
    Select-Object -ExpandProperty Sum
      
$Diagnostics.Report.GetEnumerator() | Foreach-Object { 
    Write-Verbose ('{0}: {1}' -f $_.Key, ($_.Value | Select-Object -ExpandProperty TotalSeconds)) 
}

function Pluralizer ($int) {
    if ($int -ne 1) { 's' };
}
#endregion

# Write-Output 
'Nova {7}. {0} task{1}, {2} error{3}, {4} warning{5} in {6:c}' -f `
    $Nebula.Count,
    (Pluralizer $Task.Count),
    $Diagnostics.ErrorCount,
    (Pluralizer $Diagnostics.ErrorCount),
    $Diagnostics.WarningCount,
    (Pluralizer $Diagnostics.WarningCount),
    (New-Object TimeSpan $TotalTime),
    $( if ($Diagnostics.ErrorCount -gt 0) { 'Failed' } else { 'Succeeded' } )