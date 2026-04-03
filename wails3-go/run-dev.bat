@echo off
setlocal
cd /d %~dp0

if not exist frontend\node_modules (
  call npm --prefix frontend install
  if errorlevel 1 exit /b 1
)

set "WAILS_BIN=wails3"
where %WAILS_BIN% >nul 2>nul
if errorlevel 1 (
  if exist "%USERPROFILE%\go\bin\wails3.exe" (
    set "WAILS_BIN=%USERPROFILE%\go\bin\wails3.exe"
  ) else (
    echo 找不到 wails3，请先安装 Wails 3 CLI，或把 %%USERPROFILE%%\go\bin 加到 PATH。
    exit /b 1
  )
)

for %%I in ("%WAILS_BIN%") do set "WAILS_DIR=%%~dpI"
set "PATH=%WAILS_DIR%;%PATH%"

"%WAILS_BIN%" dev -config .\build\config.yml
