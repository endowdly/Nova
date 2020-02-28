# -----------------------------------------------------------------------------------------------------------------
# Nova
# -----------------------------------------------------------------------------------------------------------------

#Requires -Version 5.0

<#PSScriptInfo 
.Version 3.1.1 
.Guid 2c5925d3-ba47-4664-8da7-acff9474b141 
.Author endowdly 
.Companyname 
.Copyright 2020
.Tags Build 
.Licenseuri https://github.com/endowdly/nova/license
.Projecturi https://github.com/endowdly/nova 
.Iconuri 
.Externalmoduledependencies 
.Requiredscripts 
.Externalscriptdependencies 
.Releasenotes 
#>

<# 
.Synopsis
  Nova Build System.
.Description 
  The Nova build system is a modular build system incorporating linearly dependent tasking. 

  Nova has four main components:

  1. Nova, or this script, which validates and controls the build system. Path: ./nova.ps1

  2. The Nursery, or the Build Directory. This directory contains the Task files invoked by Nova, the tools script,
     and the config file. Path: ./nebula/

  3. Nebula, or the tool script. This script initialzes a PowerShell attribute used in Task files that enable
     PowerShell functions to depend on another, a command called `Invoke-Task` that uses the attribute, and it
     imports all the task files into the build environment. Path ./nebula/nebula.ps1

  4. The configuration file. This file allows for properties to be incorporated into the build environment in an 
     easily editable, human readable format that is safe from script injection. The config file is left to the user
     to populate and implement, but its contents are imported by Nebula and available environment wide as a
     hashtable stored in the `$Nebula` variable. If the Launcher is present, it expects a Key name 
     `LauncherOptions` to be available. See `Get-Help ./nova.launcher.ps1 -Full` for more information. 
     Path: ./nebula/nebula.config.psd1

  Nova has two optional components:

  1. The Launcher.
     This script has a corresponding command file that launches it named nova.bat.
     It's a simplified command-line interface that prompts the user for a select number of executable tasks
     controlled by the config file.
     Once selected, the launcher will invoke Nova to execute the task.
     Path: ./nova.launcher.ps1

  2. The Batch File. 
     Easily launch the launcher? 
     Path: ./nova.bat

  This script is the overall control for the build.

  Nova validates available tasks for the build and allows for both testing and logging.
  Testing sets the WhatIfPreference to true; most, if not all, commands will be skipped.
  Logging sets the VerbosePreference to Continue; tasks should use `Write-Verbose` for logging.

    Capture the verbose stream by redirecting Nova output to a file or the output stream:
      ./nova.ps1 -Log 4> nova.log
      $log = ./nova.ps1 -Log 4>&1 

  Nova sources Nebula and its nursery, or task, files and tasks are invoked from Nebula in a linearly dependent nature.
  Nova cannot be sourced and can only be invoked. 
.Notes
  Version: 3.1.1
  Author: endowdly
#> 


[CmdletBinding()] 
param (
    # Outputs the summary of the result of the build.
    [switch] $Summary,

    # Sets the Verbose Stream to 'Continue' for visibility or redirection.
    [switch] $Log,

    # Does not perform altering actions; add -WhatIf where possible.
    [switch] $Test
)

dynamicParam {   # No dependencies 
    $name = 'Task'
    $type = [System.String]

    # New parameter attribute
    $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute] 
    $taskAttribute = New-Object System.Management.Automation.ParameterAttribute
    $taskAttribute.Position = 0

    # New validation set attribute
    $nurseryPath = Join-Path $PSScriptRoot nebula
    $nurseryFiles = Get-ChildItem $nurseryPath -Filter *Task.ps1 
    $tasks = $nurseryFiles.BaseName -replace '.Task*', '' 
    $validationSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute $tasks

    # Add our custom attributes to attribute collection
    $attributeCollection.Add($taskAttribute)
    $attributeCollection.Add($validationSetAttribute)

    # Add our paramater using collection
    $paramArgs = $name, $type, $attributeCollection
    $taskParam = New-Object System.Management.Automation.RuntimeDefinedParameter $paramArgs

    # Expose the parameter to the runtime
    $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $dictionary.Add($name, $taskParam)

    $dictionary
}

begin {

    # Forbid Sourcing
    if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.Line -eq '') {
        Write-Warning 'Nova was sourced! This is verboten to prevent session pollution!' 
        Write-Host 'Nova Aborts' -ForegroundColor Red

        exit
    } 

    Push-Location $PSScriptRoot

    if ($Log) { 
        $VerbosePreference = 'Continue'
    }

    if ($Test) {
        $WhatIfPreference = $true
    }

    $Task = 
        if ($PSBoundParameters.ContainsKey('Task')) {
            $PSBoundParameters.Task
        } 
        else {
            'Default'
        } 

    . $PSScriptRoot/nebula/nebula.ps1 -Task $Task
}

end {
    Pop-Location
    
    if ($Result.Errors) {
        Write-Host 'Nova Fail' -ForegroundColor Red

        exit 1
    }

    if ($Summary) {
        $Result
    }

    Write-Host 'Nova Done' -ForegroundColor Green
    exit 0
}