@echo off
setlocal EnableExtensions
cd /d C:\ya_baladi_rebuild
if errorlevel 1 (
  echo FAILED: C:\ya_baladi_rebuild not found.
  exit /b 1
)

set "REC=_recovery\G3_1_builtin_kotlin_migration_20260930"
if exist "%REC%" (
  echo FAILED: Recovery folder already exists: %REC%
  exit /b 1
)

echo ===== G3-001 / AGP 9 Built-in Kotlin migration =====
echo This is one controlled experiment. Firebase/packages are not changed.
echo.

mkdir "%REC%" || exit /b 1
copy /y "android\gradle.properties" "%REC%\gradle.properties" >nul || exit /b 1
copy /y "android\settings.gradle.kts" "%REC%\settings.gradle.kts" >nul || exit /b 1
copy /y "android\app\build.gradle.kts" "%REC%\app_build.gradle.kts" >nul || exit /b 1

echo Recovery point created: %REC%
echo.

powershell -NoProfile -Command ^
  "$p='android\gradle.properties';" ^
  "$lines=Get-Content -LiteralPath $p;" ^
  "$lines=$lines | Where-Object {$_ -notmatch '^\s*android\.newDsl\s*=' -and $_ -notmatch '^\s*android\.builtInKotlin\s*='};" ^
  "Set-Content -LiteralPath $p -Value $lines -Encoding utf8"

if errorlevel 1 (
  echo FAILED: gradle.properties migration.
  exit /b 1
)

powershell -NoProfile -Command ^
  "$p='android\settings.gradle.kts';" ^
  "$lines=Get-Content -LiteralPath $p;" ^
  "$lines=$lines | Where-Object {$_ -notmatch '^\s*id\("org\.jetbrains\.kotlin\.android"\)'};" ^
  "Set-Content -LiteralPath $p -Value $lines -Encoding utf8"

if errorlevel 1 (
  echo FAILED: settings.gradle.kts migration.
  exit /b 1
)

powershell -NoProfile -Command ^
  "$p='android\app\build.gradle.kts';" ^
  "$s=Get-Content -LiteralPath $p -Raw;" ^
  "$s=[regex]::Replace($s,'(?ms)^\s*kotlin\s*\{\s*compilerOptions\s*\{\s*jvmTarget\s*=\s*org\.jetbrains\.kotlin\.gradle\.dsl\.JvmTarget\.JVM_17\s*\}\s*\}\s*','`r`n');" ^
  "Set-Content -LiteralPath $p -Value $s -Encoding utf8"

if errorlevel 1 (
  echo FAILED: app/build.gradle.kts migration.
  exit /b 1
)

echo.
echo ===== VERIFY CONFIGURATION =====
echo --- gradle.properties ---
type android\gradle.properties
echo.
echo --- settings.gradle.kts Kotlin plugin search ---
findstr /n /c:"org.jetbrains.kotlin.android" android\settings.gradle.kts
if errorlevel 1 echo Kotlin Android plugin declaration: NOT FOUND (expected)
echo.
echo --- app Kotlin compiler block search ---
findstr /n /c:"compilerOptions" android\app\build.gradle.kts
if errorlevel 1 echo compilerOptions block: NOT FOUND (expected)
echo.

echo ===== FLUTTER ANALYZE =====
call flutter analyze lib
if errorlevel 1 (
  echo.
  echo RESULT: ANALYZE FAILED.
  echo Recovery point remains at %REC%
  exit /b 1
)

echo.
echo ===== APK DEBUG BUILD =====
call flutter build apk --debug
if errorlevel 1 (
  echo.
  echo RESULT: APK BUILD FAILED.
  echo Recovery point remains at %REC%
  exit /b 1
)

echo.
echo ===== SUCCESS =====
echo RESULT: AGP 9 Built-in Kotlin migration + Flutter analyze + APK debug build PASSED.
echo Recovery point: %REC%
exit /b 0
