@echo off
setlocal
pushd "%~dp0"
where MSBuild.exe >nul 2>&1
if errorlevel 1 (
  echo Bitte dieses Skript in der RAD-Studio-Eingabeaufforderung starten.
  popd
  exit /b 1
)
if not defined BDS (
  echo Die RAD-Studio-Umgebung ist nicht initialisiert.
  popd
  exit /b 1
)
MSBuild.exe MacOSTest.dproj /t:Build /p:Platform=Win64 /p:Config=Release /v:minimal
set "MACOSTEST_BUILD_EXIT=%ERRORLEVEL%"
popd
exit /b %MACOSTEST_BUILD_EXIT%
