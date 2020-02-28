function Build {
    [DependsOn(('Init', 'Clean'))]
    param()

    Write-Host "I do da build!"
}