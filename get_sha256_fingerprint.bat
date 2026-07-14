@echo off
REM Script to get SHA256 fingerprint for Android App Links (Windows)
REM Usage: get_sha256_fingerprint.bat [keystore_path] [alias] [password]

if "%1"=="" (
    REM Default to debug keystore
    set KEYSTORE=%USERPROFILE%\.android\debug.keystore
    set ALIAS=androiddebugkey
    set PASSWORD=android
    echo Using debug keystore...
) else (
    set KEYSTORE=%1
    set ALIAS=%2
    if "%ALIAS%"=="" set ALIAS=your-alias
    set PASSWORD=%3
    if "%PASSWORD%"=="" set PASSWORD=your-password
)

if not exist "%KEYSTORE%" (
    echo Error: Keystore file not found at %KEYSTORE%
    exit /b 1
)

echo Extracting SHA256 fingerprint from: %KEYSTORE%
echo Alias: %ALIAS%
echo.

keytool -list -v -keystore "%KEYSTORE%" -alias "%ALIAS%" -storepass "%PASSWORD%" | findstr /C:"SHA256:"

echo.
echo Copy the SHA256 fingerprint (without colons) to assetlinks.json

