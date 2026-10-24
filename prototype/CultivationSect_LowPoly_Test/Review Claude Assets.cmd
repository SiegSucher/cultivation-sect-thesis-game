@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Open project.godot in Godot and run scenes/review/disciple_residence_walkthrough.tscn.
  pause
  exit /b 1
)
start "Claude Asset Inspection" "%GODOT_EXE%" --path "%~dp0." res://scenes/review/disciple_residence_walkthrough.tscn
