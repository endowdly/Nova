# -----------------------------------------------------------------------------------------------------------------
# Init Task
# -----------------------------------------------------------------------------------------------------------------

# This is the startup task.
# Initialize variables, functions, and aliases and load them into the script scope.


function Init {

    function New-ScriptVariable ($k, $v) {
        #   Creates a script variable from a key and value pair and logs the result to the verbose stream 
        #   string -> obj -> unit
        New-Variable $k $v -Scope Script -Force -WhatIf:$false
        Write-Verbose "$k <- $v"
    }

    $asPathVariable = { 
        # DictionaryEntry -> unit
        $k = $_.Key
        $v = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_.Value)

        New-ScriptVariable $k $v 
    } 

    Write-Verbose 'Setting install path variables...' 
    Write-Verbose 'You can do this a different way!'

    $Nebula.Paths.GetEnumerator().Foreach($asPathVariable)
}

