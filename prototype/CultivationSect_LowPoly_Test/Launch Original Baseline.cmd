@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Open project.godot with Godot 4.7.2 and pass --baseline as a user argument.
  pause
  exit /b 1
)
start "Original Hall Baseline" "%GODOT_EXE%" --path "%~dp0." -- --baseline
