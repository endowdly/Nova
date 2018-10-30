# Nova Build

## Background

This is simple linear build logic I made to complete simple builds. Things like deploying PowerShell modules, compiling simple CSharp and FSharp DLLs and command line apps.

It's very lightweight and works really well for those purposes. For more complicated builds, look into Psake, Invoke-Build, Fake or Cake.

I wrote Nova really fast a year and a half ago to make a couple different builds to deploy modules onto machines via CDs (remember those?). The machines only had Version 2 on them and they were air-gapped. I could have locally copied Psake, but for such simple builds, I didn't want to go through the trouble of all the data transfer that would've been needed.

## Files

This build has two necessary files:

- build.nova.ps1
- build.nebula.ps1

### Nebula

Nebula is the _data_ stored as scriptblocks. This is your list of actions and what you want the build to do. Because I made this rapidly, there is no DSL, just hashtables that Nova expects. Nebulas must include a Nebula hashtable with each task being
 a hasthable holding task (scriptblock) and order (int) values:

```powershell


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
```

Nebula files also optionally hold a Properties ScriptBlock:

```powershell
 $Properties = {
    $FileWide = "This can be accessed by every task"
 }
```

### Nova

Nova is the _logic_. It calls up the actions. It has diagnostic logic that reports success, failures, and time taken overall and for each task. It spits has a Verbose stream that enumerates each action, its result, and its time. It has a Progress stream as well. You can of course, use your own Progress stream in your tasks. **This file should not be altered**.

## Optional Files

I also have included the following optional files:

- build.ps1
- ImportPowerShellDataFile.ps1
- build.config.psd1
- build.bat

### build.ps1

A simple bootstrap. Loads `Import-PowerShellDataFile2`, imports the config settings, sets the config for the build, and then executes the Nova file.

### ImportPowerShellDataFile.ps1

PowerShell 5.0 included this nifty function that safely imports psd1 files easily. What it doesn't do is accept paths via pipeline. This is my slight mod that includes that ability. It runs in Version 2.0, and so it is included here.

### build.config.psd1

A settings file, that is human-readable, and code-safe. Sets how the build will appear and what output streams will be show.

### build.bat

I had to deploy on Enterprise machines I did not have Admin access too. So, this is a shortcut to run build.ps1. It originally included a `-Version 2` parameter when calling PowerShell.