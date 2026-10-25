$ErrorActionPreference='Continue'
foreach ($variant in @('before','after')) {
    Write-Output ('Capturing '+$variant)
    & $PSScriptRoot\run.ps1 -Argument $variant *> (Join-Path $PSScriptRoot ('capture-'+$variant+'-final-console.txt'))
}
Write-Output 'Capturing walking motion'
& $PSScriptRoot\run.ps1 -Script capture_motion.gd -Argument motion -Fixed *> (Join-Path $PSScriptRoot 'motion-console.txt')
Write-Output 'Measuring final 1080p performance'
& $PSScriptRoot\run.ps1 -Script perf_probe.gd -Argument res://proposal_demo_living_sect/review/Performance1080.json -Resolution 1920x1080 *> (Join-Path $PSScriptRoot 'performance-final-console.txt')
Write-Output 'Final visual sequence finished'
