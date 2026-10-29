@echo off
REM ----------------------------------------
REM  YaBaladi - FlutLab to Local Sync Helper
REM  Version: 1.1 (quiet mode)
REM  Usage:  sync_from_flutlab.bat <path-to-zip>
REM  Example: sync_from_flutlab.bat "C:\Users\mohto\Downloads\YaBaladi.zip"
REM ----------------------------------------

setlocal
set REPO=D:\ya_baladi_rebuild
set STAGE=D:\flutlab_export_latest
set GIT="C:\Program Files\Git\bin\git.exe"
set QUIET=-c core.safecrlf=false -c core.autocrlf=false

if "%~1"=="" goto usage
set ZIP=%~1
if not exist "%ZIP%" goto notfound

if exist "%STAGE%" rmdir /S /Q "%STAGE%"
powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%STAGE%' -Force"

echo.
echo === Differences (ignoring EOL) ===
%GIT% %QUIET% diff --no-index --ignore-cr-at-eol --stat "%REPO%\lib" "%STAGE%\lib" 2>nul

echo.
echo === Modified files (full list) ===
%GIT% %QUIET% diff --no-index --ignore-cr-at-eol --name-only "%REPO%\lib" "%STAGE%\lib" 2>nul

echo.
echo === Extracted to: %STAGE% ===
echo.
echo Next: review the diff, then copy files manually and commit.
goto end

:usage
echo Usage: sync_from_flutlab.bat ^<path-to-zip^>
exit /b 1

:notfound
echo Not found: %ZIP%
exit /b 1

:end
endlocal