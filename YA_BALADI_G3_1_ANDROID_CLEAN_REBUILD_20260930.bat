@echo off
setlocal EnableExtensions
cd /d C:\ya_baladi_rebuild
if errorlevel 1 exit /b 1

echo ==================================================
echo YA BALADI - G3-001 CLEAN ANDROID REBUILD
echo ==================================================
echo This rebuilds ONLY the Android foundation.
echo lib/ and pubspec.yaml are NOT intentionally replaced.
echo.

set "STAMP=20260930"
set "REC=_recovery\G3_1_android_clean_rebuild_%STAMP%"

if exist "%REC%" (
  echo FAILED: Recovery folder already exists:
  echo %REC%
  exit /b 1
)

mkdir "%REC%" || exit /b 1

echo [1/7] Saving current Android foundation...
if exist android (
  xcopy /e /i /h /y android "%REC%\android" >nul || exit /b 1
)
if exist pubspec.yaml copy /y pubspec.yaml "%REC%\pubspec.yaml" >nul
if exist lib\main.dart copy /y lib\main.dart "%REC%\main.dart" >nul

echo Recovery created:
echo %REC%
echo.

echo [2/7] Removing ONLY the current Android directory...
if exist android rmdir /s /q android
if exist android (
  echo FAILED: android directory could not be removed.
  exit /b 1
)

echo [3/7] Generating a fresh Flutter Android template...
call flutter create --platforms=android --org com.egypt --project-name yabaladi_rebuild .
if errorlevel 1 (
  echo FAILED: Flutter Android template generation.
  exit /b 1
)

echo.
echo [4/7] Verifying package identity...
findstr /n /c:"namespace =" android\app\build.gradle.kts
findstr /n /c:"applicationId =" android\app\build.gradle.kts
findstr /n /c:"com.egypt.yabaladi_rebuild" android\app\build.gradle.kts
if errorlevel 1 (
  echo FAILED: Expected package identity not found.
  exit /b 1
)

echo.
echo [5/7] Getting dependencies...
call flutter pub get
if errorlevel 1 (
  echo FAILED: flutter pub get.
  exit /b 1
)

echo.
echo [6/7] Dart analysis...
call flutter analyze lib
echo ANALYZE_EXITCODE=%ERRORLEVEL%
echo Note: info/warning messages are not build errors.
if errorlevel 1 (
  echo RESULT: ANALYZE COMMAND RETURNED NONZERO.
  echo STOPPING BEFORE APK. Recovery remains available.
  exit /b 1
)

echo.
echo [7/7] Android Debug APK...
call flutter build apk --debug
if errorlevel 1 (
  echo RESULT: APK BUILD FAILED.
  echo Recovery remains available at:
  echo %REC%
  exit /b 1
)

echo.
echo ==================================================
echo G3-001 CLEAN ANDROID FOUNDATION VERIFIED
echo ==================================================
echo Fresh Android template: PASS
echo Package identity: PASS
echo flutter pub get: PASS
echo flutter analyze lib: PASS
echo flutter build apk --debug: PASS
echo Recovery: %REC%
echo ==================================================
exit /b 0
