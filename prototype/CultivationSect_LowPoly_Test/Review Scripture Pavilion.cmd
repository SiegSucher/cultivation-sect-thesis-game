@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Open project.godot in Godot 4.7.2 and run scenes/review/scripture_walkthrough.tscn.
  pause
  exit /b 1
)
start "Scripture Pavilion" "%GODOT_EXE%" --path "%~dp0." res://scenes/review/scripture_walkthrough.tscn
