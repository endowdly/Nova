# Note: This file has been modified from the basic function included in Version 5.
#       It includes the ability to pass paths via pipeline.

# - 12  [Parameter(ParameterSetName = "ByPath", Position = 0)]
# + 12  [Parameter(ParameterSetName = "ByPath", Position = 0, ValueFromPipeline = $true)]

function Import-PowerShellDataFile2 {
    [CmdletBinding(DefaultParameterSetName = "ByPath", HelpUri = "https://go.microsoft.com/fwlink/?LinkID=623621")]
    [OutputType("System.Collections.Hashtable")]
    param(
        [Parameter(ParameterSetName = "ByPath", Position = 0, ValueFromPipeline = $true)]
        [String[]] $Path,
        
        [Parameter(ParameterSetName = "ByLiteralPath", ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [String[]] $LiteralPath
    )
    
    begin
    {
        function ThrowInvalidDataFile
        {
            param($resolvedPath, $extraError)
            
            $errorId = "CouldNotParseAsPowerShellDataFile$extraError"
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidData
            $errorMessage = [Microsoft.PowerShell.Commands.UtilityResources]::CouldNotParseAsPowerShellDataFile -f $resolvedPath
            $exception = [System.InvalidOperationException]::New($errorMessage)
            $errorRecord = [System.Management.Automation.ErrorRecord]::New($exception, $errorId, $errorCategory, $null)
            $PSCmdlet.WriteError($errorRecord)   
        }
    }
 
    process
    {
        foreach($resolvedPath in (Resolve-Path @PSBoundParameters))
        {
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(($resolvedPath.ProviderPath), [ref] $null, [ref] $parseErrors)
            if ($parseErrors.Length -gt 0)
            {
                ThrowInvalidDataFile $resolvedPath
            }
            else
            {
                $data = $ast.Find( { $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $false )
                if($data)
                {
                    $data.SafeGetValue()
                }
                else
                {
                    ThrowInvalidDataFile $resolvedPath "NoHashtableRoot"
                }
            }
        }
    }

}