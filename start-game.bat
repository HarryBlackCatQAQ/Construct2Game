@echo off
setlocal
cd /d %~dp0

if exist ".\wails3-go\bin\Construct2Game.exe" (
  start "" ".\wails3-go\bin\Construct2Game.exe"
  exit /b 0
)

if exist ".\wails3-go\run-dev.bat" (
  call ".\wails3-go\run-dev.bat"
  exit /b %errorlevel%
)

echo 找不到可启动的新版本程序。
exit /b 1
