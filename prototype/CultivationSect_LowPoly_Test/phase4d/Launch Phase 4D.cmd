@echo off
setlocal
set "PROJECT_DIR=%~dp0.."
set "ENGINE=%~dp0..\..\reedwell-3d\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" set "ENGINE=%~dp0..\..\..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" (
    echo Open the test project and run phase4d/phase4d_valley.tscn with F6.
    pause
    exit /b 1
)
start "" "%ENGINE%" --path "%PROJECT_DIR%" res://phase4d/phase4d_valley.tscn
