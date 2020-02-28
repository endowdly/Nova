# -----------------------------------------------------------------------------------------------------------------
# Nebula
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
.Requiredscripts nova.ps1
.Externalscriptdependencies 
.Releasenotes 
#>

<#
.Synopsis
  Build Tools.
.Description 
  This is the build startup script.
  Nebula initializes essential funtions and tasks, then invokes a task sent from Nova.
  Nebula does not return a value.
  
  Nebula creates a script variable named Result that should contain success/fail information.
.Notes
  Nova build system by endowdly, version 3.
  Cmdlets honor preference variables set by Nova.
  Some functions DO NOT. This is a dynamic scoping issue -> https://github.com/PowerShell/PowerShell/issues/4568.
  Test a function in the terminal with `(Get-Command $Command).CommandType -eq 'Cmdlet'`.
  If true, a workaround for these functions is to set -WhatIf:$Test and -Verbose:$Log.
.Link
  ../nova.ps1
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]

param (
    # The task to invoke. Validated from Nova.
    [System.String] $Task
)

#region Startup ---------------------------------------------------------------------------------------------------

# Forbid Sourcing from outside Nova
if ($MyInvocation.PSCommandPath -notlike '*nova.ps1') {
    Write-Warning 'Nebula was called from outside Nova. This is verboten!' 
    Write-Host 'ABORT' -ForegroundColor Red

    exit 1
} 

Push-Location $PSScriptRoot

# Import Config 
$Nebula = Import-PowerShellDataFile nebula.config.psd1 

<# CSharp Attribute
# Note: Keep this in case someone does not have PowerShell 5.0
$Source = @'
using System;

public class DependsOn : Attribute
{
    public string[] Task { get; set; }

    public DependsOn(string[] task) 
    {
        Task = task
    }
}
'@
Add-Type $Source
#>


# PowerShell class that creates a Custom Attribute for Dependancy
# I think I got this from Jaykul?
class DependsOn : System.Attribute {
    [System.String[]] $Task

    DependsOn([System.String[]] $task) {
        $this.Task = $task 
    }
}


# Create Output
$Result = [PSCustomObject]@{
    Warnings = 0
    Errors = 0
    Success = 0
    Invoked = @()
    Time = 0
}

# A function that uses our custom attribute to invoke functions sequentially based on linear dependency
# string -> unit
function Invoke-Task ($Task) {
    $isReset = ((Get-PSCallStack).Command -eq $MyInvocation.MyCommand.Name).Count -eq 1
    
    if ($isReset) {
        $Result.Invoked = @()
    }

    $stepCommand = Get-Command $Task 
    $dependencies = $stepCommand.ScriptBlock.Attributes.Where{ $_.TypeId.Name -eq 'DependsOn' }.Task

    foreach ($dependency in $dependencies) {
        if ($dependency -notin $script:InvokedTasks) {
            Write-Verbose "$Task Dependency <- $dependency"
            Invoke-Task $dependency
        }  
    }

    Write-Verbose "Invoking -> $Task" 

    & $stepCommand

    Write-Verbose "$Task Done"

    if ($?) { 
        $Result.Success++
    }

    $Result.Invoked += $Task
}


# Source Nursery Files
Write-Verbose 'Importing Nursery...'
Get-ChildItem $PSScriptRoot -Filter *.Task.ps1 | 
    ForEach-Object { 
        Write-Verbose "Importing <- $( $_.Name )"
        . $_.FullName
    }
Write-Verbose 'Nursery Imported' 

#endregion

<#
 
  __  __          
  \ \/ /___  __ _ 
   \  // _ \/ _` |
   /  \  __/ (_| |
  /_/\_\___|\__, |
               |_|
 
#>

$timer = New-Object System.Diagnostics.Stopwatch

$timer.Start()

Invoke-Task $Task 

$timer.Stop()

$Result.Time = $timer.Elapsed.ToString("s\.fff")

Pop-Location
