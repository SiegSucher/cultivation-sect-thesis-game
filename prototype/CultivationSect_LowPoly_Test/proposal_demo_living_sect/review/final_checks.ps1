param([string]$Only='')
$ErrorActionPreference='Stop'
$passes=@(
    @{Script='test_code_runner.gd';Name='Runner';Headless=$true},
    @{Script='verify_refinement.gd';Name='Quest';Headless=$true},
    @{Script='check_layout.gd';Name='Layout720';Headless=$false},
    @{Script='check_layout.gd';Name='Layout1080';Headless=$false;Resolution='1920x1080'},
    @{Script='verify_life.gd';Name='Life720';Headless=$false},
    @{Script='verify_life.gd';Name='Life1080';Headless=$false;Resolution='1920x1080'},
    @{Script='check_routes.gd';Name='Routes';Headless=$true},
    @{Script='verify_living.gd';Name='LivingRendered';Headless=$false},
    @{Script='verify_extras.gd';Name='Extras';Headless=$true}
)
foreach ($pass in $passes) {
    if ($Only -and $pass.Name -notin $Only.Split(',')) {continue}
    $resolution=if ($pass.Resolution) {$pass.Resolution} else {'1280x720'}
    $json=Join-Path $PSScriptRoot ($pass.Name+'.json')
    $log=Join-Path $PSScriptRoot ($pass.Name+'-final-console.txt')
    Write-Output ('Starting '+$pass.Name)
    $started=Get-Date
    # Each process exits before the next starts. Rendered passes use real native resolution.
    $ErrorActionPreference='Continue'
    & $PSScriptRoot\run.ps1 -Script $pass.Script -Argument ('res://proposal_demo_living_sect/review/'+$pass.Name+'.json') -Resolution $resolution -Headless:$pass.Headless -Fixed *> $log
    $ErrorActionPreference='Stop'
    if (!(Test-Path -LiteralPath $json)) {throw ('Missing result: '+$pass.Name)}
    if ((Get-Item -LiteralPath $json).LastWriteTime -lt $started) {throw ('Stale result: '+$pass.Name)}
    $result=Get-Content -LiteralPath $json -Raw | ConvertFrom-Json
    if ($result.failures -gt 0) {throw ('Failed assertions: '+$pass.Name)}
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR|Parse Error|Failed to load' -Quiet) {throw ('Script error: '+$pass.Name)}
    Write-Output ('Finished '+$pass.Name+' without failed assertions or script errors.')
}
