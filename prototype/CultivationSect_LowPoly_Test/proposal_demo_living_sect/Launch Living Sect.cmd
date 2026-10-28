@echo off
setlocal
set "PROJECT_DIR=%~dp0.."
set "ENGINE=%~dp0..\..\reedwell-3d\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" set "ENGINE=%~dp0..\..\..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" set "ENGINE=%~dp0..\..\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ENGINE%" (
    echo Open the test project, select proposal_demo_living_sect/proposal_demo.tscn and press F6.
    pause
    exit /b 1
)
powershell -NoProfile -Command "if (Get-Process 'Godot*' -ErrorAction SilentlyContinue) { exit 1 }"
if errorlevel 1 (
    echo Close the other Godot game or editor first. This launcher keeps only one Godot instance running.
    pause
    exit /b 1
)
start "" "%ENGINE%" --path "%PROJECT_DIR%" %* res://proposal_demo_living_sect/proposal_demo.tscn
