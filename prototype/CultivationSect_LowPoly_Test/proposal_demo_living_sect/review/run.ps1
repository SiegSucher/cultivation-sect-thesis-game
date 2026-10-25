param([string]$Script='capture_views.gd',[string]$Argument='after',[string]$Resolution='1280x720',[switch]$Headless,[switch]$Fixed,[string]$Extra='')
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$engine=[IO.Path]::GetFullPath((Join-Path $project '../reedwell-3d/tools/godot/Godot_v4.7.2-stable_win64_console.exe'))
if (Get-Process 'Godot*' -ErrorAction SilentlyContinue) { throw 'A Godot instance is already running.' }
$argsList=@('--path',$project,'--resolution',$Resolution,'--script',"res://proposal_demo_living_sect/review/$Script",'--log-file',(Join-Path $PSScriptRoot ($Script.Replace('.gd','')+'-'+($Argument.Split('/')[-1])+'.log')))
if ($Headless) {$argsList+='--headless'}
elseif ($Resolution -eq '1920x1080') {$argsList+='--fullscreen'}
if ($Fixed) {$argsList+=@('--fixed-fps','60')}
$argsList+=@('--',$Argument)
if ($Extra) {$argsList+=$Extra}
$argsList+='--review-layout'
$ErrorActionPreference='Continue' # Godot sends host certificate/cache diagnostics to stderr.
& $engine @argsList
exit $LASTEXITCODE
