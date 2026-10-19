@echo off
setlocal
pushd "%~dp0" || exit /b 1

if exist "%~dp0.tools\flutter\bin\flutter.bat" (
  set "WALLET_FLUTTER=%~dp0.tools\flutter\bin\flutter.bat"
  set "PUB_CACHE=%~dp0.tools\pub-cache"
) else (
  where flutter >nul 2>&1
  if errorlevel 1 goto missing_sdk
  set "WALLET_FLUTTER=flutter"
)

echo Preparing development dependencies...
call "%WALLET_FLUTTER%" pub get
if errorlevel 1 goto failed

echo Starting Local Wallet for Windows. Press r for hot reload or q to quit.
call "%WALLET_FLUTTER%" run --no-pub -d windows
set "WALLET_EXIT_CODE=%ERRORLEVEL%"
goto finished

:missing_sdk
echo Flutter was not found in .tools\flutter or PATH.
echo Install the Flutter SDK and add its bin directory to PATH, then try again.
set "WALLET_EXIT_CODE=1"
goto finished

:failed
set "WALLET_EXIT_CODE=%ERRORLEVEL%"
echo Dependency preparation failed. Review the error above.

:finished
popd
echo.
echo Development session finished with exit code %WALLET_EXIT_CODE%.
pause
endlocal & exit /b %WALLET_EXIT_CODE%
