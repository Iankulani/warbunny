@echo off
:: WARBUNNY v2.0.0 Installation Script for Windows

setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "MAGENTA=[95m"
set "CYAN=[96m"
set "RESET=[0m"

echo %MAGENTA%
echo ╔══════════════════════════════════════════════════════════════════╗
echo ║         🐇 WARBUNNY v2.0.0 - Installation Script                ║
echo ╚══════════════════════════════════════════════════════════════════╝
echo %RESET%

:: Check for Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo %RED%❌ Python not found. Please install Python 3.7+ from python.org%RESET%
    pause
    exit /b 1
)

:: Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PY_VERSION=%%i
echo %GREEN%✅ Python %PY_VERSION% found%RESET%

:: Install pip packages
echo.
echo %BLUE%📦 Installing Python packages...%RESET%
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo %RED%❌ Failed to install packages%RESET%
    pause
    exit /b 1
)
echo %GREEN%✅ Python packages installed%RESET%

:: Create configuration directory
echo.
echo %BLUE%⚙️  Creating configuration...%RESET%
if not exist ".warbunny" mkdir ".warbunny"
if not exist "warbunny_reports" mkdir "warbunny_reports"

:: Generate secret key
python -c "import secrets; print(secrets.token_hex(32))" > .warbunny\secret.key
set /p SECRET_KEY=<.warbunny\secret.key

:: Create config.json
(
echo {
echo     "version": "2.0.0",
echo     "auto_start": false,
echo     "auto_block_enabled": false,
echo     "auto_block_threshold": 5,
echo     "scan_timeout": 30,
echo     "report_format": "html",
echo     "generate_graphics": true,
echo     "web": {
echo         "enabled": false,
echo         "port": 5000,
echo         "host": "0.0.0.0",
echo         "secret_key": "%SECRET_KEY%",
echo         "require_auth": true,
echo         "username": "admin",
echo         "password_hash": ""
echo     },
echo     "monitoring": {
echo         "enabled": true,
echo         "port_scan_threshold": 10,
echo         "syn_flood_threshold": 100,
echo         "http_flood_threshold": 200
echo     }
echo }
) > .warbunny\config.json

echo %GREEN%✅ Configuration created%RESET%

:: Run requirements check
echo.
echo %BLUE%🔍 Checking requirements...%RESET%
python requirements_check.py

:: Create shortcut
echo.
echo %BLUE%🔗 Creating desktop shortcut...%RESET%
set "SCRIPT_PATH=%CD%\warbunny.py"
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\WARBUNNY.lnk"

powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%SHORTCUT_PATH%'); $SC.TargetPath = 'python.exe'; $SC.Arguments = '%SCRIPT_PATH%'; $SC.WorkingDirectory = '%CD%'; $SC.Save()"
echo %GREEN%✅ Desktop shortcut created%RESET%

:: Final message
echo.
echo %GREEN%══════════════════════════════════════════════════════════════════%RESET%
echo %MAGENTA%🐇 WARBUNNY v2.0.0 Installation Complete!%RESET%
echo %GREEN%══════════════════════════════════════════════════════════════════%RESET%
echo.
echo %BLUE%Next steps:%RESET%
echo   1. Run WARBUNNY: %CYAN%python warbunny.py%RESET%
echo   2. Type %CYAN%help%RESET% to see available commands
echo.
echo %YELLOW%For security testing only. Use responsibly.%RESET%

pause