# --------------------------------------------------------------------------------------------------
# Nova Launcher
# --------------------------------------------------------------------------------------------------

#Requires -Version 5.0

<#PSScriptInfo 
.Version 1.3.0
.Guid c642caad-e22c-45c3-922b-ec341592242c
.Author endowdly 
.Companyname 
.Copyright 2020
.Tags Build 
.Licenseuri https://github.com/endowdly/nova/license
.Projecturi https://github.com/endowdly/nova 
.Iconuri 
.Externalmoduledependencies 
.Requiredscripts nova.ps1
.Externalscriptdependencies 
.Releasenotes 
#>

<#
.Synopsis
  Launcher that uses Nova.
.Description
  Launcher that uses Nova. This script does not let you source it. It can only be invoked.

  Control what the Launcher allows you to select by changing the config file located in the Nursery.
  The Launcher expects an array of hashtables with the Key 'LauncherOptions'. The hashtables in the
  array should have the following structure:

  @{ 
      Task = 'Init'
      HelpMessage = 'A brief description of what the init task will accomplish.'
      Order = 2   
      Default = $false 
  }

  The task name must match a task function exactly.
  The help message must be a string, but it can be empty.
  The order will be the position of the task in the menu prompt; it is 0 indexed.
  The default option must be a boolean with value `$true` or `$false`.
  Only one task can have a default flag set to `$true`. 
  Any task that is not default can omit the line altogether. 
  
.Link
  ./nova.ps1
.Link 
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-4.0
  
#>

#region Startup ---------------------------------------------------------------------------------------------------

# Forbid Sourcing
if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
    Write-Warning $Messages.Warning.Sourced
    Write-Host $Messages.Information.Abort.Object -ForegroundColor $Messages.Information.Abort.ForegroundColor

    exit
} 

$NurseryPath = Join-Path $PSScriptRoot nebula
$ConfigPath = Join-Path $NurseryPath nebula.config.psd1
$Options = (Microsoft.PowerShell.Utility\Import-PowerShellDataFile $ConfigPath).LauncherOptions
$Messages = (Microsoft.PowerShell.Utility\Import-PowerShellDataFile $ConfigPath).LauncherMessages


function Oops {
    # .Synopsis 
    #   Dangit!
    #   unit -> unit

    exit
}


function Invoke-Task ($s) {
    # .Synopsis 
    #   Invokes a task
    #   string -> unit

    & $PSScriptRoot/nova.ps1 -Task $s
}


function New-Choice {
    # .Synopsis
    #   Creates a new Host.ChoiceDescription object
    #   string -> char -> hashtable -> ChoiceDescription
    #   string -> char -> string -> ChoiceDescription

    param (
        [string] $Name,
        [char] $Token,
        [hashtable] $Dictionary,
        [string] $Message = ''
    )

    $label = $Name.Insert($Name.IndexOf($Token), '&')
    $msg =
        if ($null -ne $Dictionary) {
            $Dictionary.$Name
        }
        else {
            $Message
        }

    [System.Management.Automation.Host.ChoiceDescription]::new($label, $msg)
}


function Read-Prompt {
    # .Synopsis
    #   Prompts the host for choices
    #   string -> string -> ChoiceDescription[] -> int -> int

    param (
        [string] $Title = '',
        [string] $Prompt,
        [System.Management.Automation.Host.ChoiceDescription[]] $Choices,
        [int] $DefaultChoice = 0
    )

    $Host.UI.PromptForChoice($Title, $Prompt, $Choices, $DefaultChoice)
}

function ConvertTo-ChoiceDictionary ($a) {
    # .Synopsis
    #   Converts an array into an ordered dictionary
    #   hashtable[] -> OrderedDictionary

    $hash = [ordered] @{}

    $a | 
        Sort-Object { $_.Order } |
        Foreach-Object {
            [void] $hash.Add($_.Task, $_.HelpMessage)
        }

    $hash
}

function ConvertTo-List ($a) {
    # .Synopsis
    #   Converts an array into a list
    #   obj[] -> ArrayList

    $list = New-Object System.Collections.ArrayList

    $a | 
        Sort-Object { $_.Order } | 
        ForEach-Object {
            [void] $list.Add($_.Task)
        }

    $list
} 


function Get-DefaultTask ($a) {
    # .Synopsis
    #   Finds the default task in the list.

   foreach ($item in $a) {
       
       if ($item.Default) {
           return $item.Order
       }
   } 
}

function Get-Choice ($x) {
    # .Synopsis
    #   Converts a hashtable into a choicedescription array
    #   hashtable -> ChoiceDescription[]

    $tokens = @{
        Key             = ''
        TokenIndex      = 0
        Token           = ''
        TokenCollection = [System.Collections.ArrayList]::new()
    } 


    foreach ($k in $x.Keys) {
        $tokens |
            Set-Key $k |
            Set-TokenIndex 0 |
            Add-Token

        New-Choice -Name $k -Token $tokens.Token -Dictionary $x
    } 
}


filter Set-TokenIndex ($i) {
    # .Synopsis
    #   Set the TokenIndex property on a token obj
    #   obj -> obj

    $_.TokenIndex = $i
    $_
}


filter Set-Key ($s) {
    # .Synopsis
    #   Set the Key property on a token obj
    #   obj -> obj

    $_.Key = $s
    $_
}


filter Add-Token ($s) {
    # .Synopsis
    #   Add a Token property to a collection on a token obj
    #   Tries not to allow repeat tokens
    #   * This isn't super smart yet and could potentially break.
    #   obj -> obj

    $_.Token = $_.Key.Substring($_.TokenIndex, 1)

    if ($_.Token -in $_.TokenCollection) {
        $_.TokenIndex++
        $_ | Add-Token
    }

    [void] $_.TokenCollection.Add($_.Token)
}


function Add-ExitChoice {
    # .Synopsis
    #   A huge hack until I can think of something else.
    
    try {
        $input + (New-Choice -Name Exit -Token x -Message 'Abort this process')
    }
    catch { 
        # Just bail. I can't believe you took x! The user can always close the console window or Ctrl-C
        $input
    }
}


#endregion

#region Exeq ------------------------------------------------------------------------------------------------------

@"

            _
           ' )    )
           //   /'
         /'/  /' ____   .     ,   ____
       /' / /' /'    )--|    /  /'    )
     /'  //' /'    /'   |  /' /'    /'
 (,/'    (_,(___,/'    _|/(__(___,/(__

Running Nova Version 3.1.0
$Messages 

"@

$Choices = ConvertTo-ChoiceDictionary $Options
$Do = ConvertTo-List $Options
$ContinueChoices = [Ordered] @{
    Yes = 'Continue to complete another Action'
    No  = 'End this Process'
}
$Actions = @{
    Prompt  = 'Choose Action'
    Choices = Get-Choice $Choices | Add-ExitChoice
    DefaultChoice = Get-DefaultTask $Options
}
$Continue = @{
    Prompt  = 'Would you like to run another Action?'
    Choices = Get-Choice $ContinueChoices
    DefaultChoice = 1
}

do {
    $result = Read-Prompt @Actions

    if ($result -gt $Do.Count - 1) {
        Oops
    }
    else {
        Invoke-Task $Do[$result]
    }

    $canContinue = Read-Prompt @Continue
} until ($canContinue -eq 1)

#endregion
