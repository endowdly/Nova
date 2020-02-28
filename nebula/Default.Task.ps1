# -----------------------------------------------------------------------------------------------------------------
# Default Task
# -----------------------------------------------------------------------------------------------------------------

# The default task will run when no other task is specified to Nova.


function Default { 
    [DependsOn('Init')]
    param()

    Write-Host "Hello, world from Nova!"
}