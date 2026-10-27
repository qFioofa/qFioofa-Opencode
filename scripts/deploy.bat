@echo off
REM Deploy the qFioofa opencode configuration on Windows.
REM
REM Default mode is a directory symlink. mklink usually needs Developer Mode
REM or an elevated shell; if it fails the script falls back to copying files.
REM The Unix equivalent is scripts/deploy.sh.

setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "REPO_DIR=%%~fI"
set "SRC_DIR=%REPO_DIR%\src"

if defined XDG_CONFIG_HOME (
    set "TARGET=%XDG_CONFIG_HOME%\opencode"
) else (
    set "TARGET=%USERPROFILE%\.config\opencode"
)

set "MODE=link"
set "DO_BACKUP=0"
set "DO_REMOVE=0"
set "DO_DEPS=0"
set "DO_DRY_RUN=0"

:parse
if "%~1"=="" goto after_parse
if /I "%~1"=="-t" goto arg_target
if /I "%~1"=="--target" goto arg_target
if /I "%~1"=="-c" goto arg_copy
if /I "%~1"=="--copy" goto arg_copy
if /I "%~1"=="-l" goto arg_link
if /I "%~1"=="--link" goto arg_link
if /I "%~1"=="-b" goto arg_backup
if /I "%~1"=="--backup" goto arg_backup
if /I "%~1"=="-r" goto arg_remove
if /I "%~1"=="--remove" goto arg_remove
if /I "%~1"=="-d" goto arg_deps
if /I "%~1"=="--deps" goto arg_deps
if /I "%~1"=="-n" goto arg_dry
if /I "%~1"=="--dry-run" goto arg_dry
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage
echo Unknown option: %~1
goto usage_error

:arg_target
if "%~2"=="" (echo Missing value for %~1 & goto usage_error)
set "TARGET=%~2"
shift
shift
goto parse
:arg_copy
set "MODE=copy"
shift
goto parse
:arg_link
set "MODE=link"
shift
goto parse
:arg_backup
set "DO_BACKUP=1"
shift
goto parse
:arg_remove
set "DO_REMOVE=1"
shift
goto parse
:arg_deps
set "DO_DEPS=1"
shift
goto parse
:arg_dry
set "DO_DRY_RUN=1"
shift
goto parse

:after_parse
if not exist "%SRC_DIR%" (
    echo Source directory not found: %SRC_DIR%
    exit /b 1
)

echo   Target: %TARGET%
echo   Mode:   %MODE%

if exist "%TARGET%" (
    if "%DO_REMOVE%"=="1" (
        echo   Removing %TARGET%
        if "%DO_DRY_RUN%"=="1" (echo   [dry-run] rmdir /S /Q "%TARGET%") else (rmdir /S /Q "%TARGET%")
    ) else if "%DO_BACKUP%"=="1" (
        call :backup_target
    ) else (
        echo Target already exists: %TARGET%
        echo Pass -b ^(backup^) or -r ^(remove^) to continue.
        exit /b 1
    )
)

if not exist "%TARGET%" (
    if "%DO_DRY_RUN%"=="1" (
        echo   [dry-run] mkdir "%TARGET%"
    ) else (
        mkdir "%TARGET%" >nul 2>&1
    )
)

if /I "%MODE%"=="link" (
    echo   Linking %SRC_DIR% -^> %TARGET%
    if "%DO_DRY_RUN%"=="1" (
        echo   [dry-run] mklink /D "%TARGET%" "%SRC_DIR%"
    ) else (
        rmdir "%TARGET%" >nul 2>&1
        mklink /D "%TARGET%" "%SRC_DIR%" >nul 2>&1
        if errorlevel 1 (
            echo   Symlink failed ^(enable Developer Mode or run elevated^).
            echo   Falling back to copy mode.
            set "MODE=copy"
            mkdir "%TARGET%" >nul 2>&1
        )
    )
)

if /I "%MODE%"=="copy" (
    echo   Copying %SRC_DIR%\ -^> %TARGET%\
    if "%DO_DRY_RUN%"=="1" (
        echo   [dry-run] xcopy "%SRC_DIR%" "%TARGET%\" /E /I /Y
    ) else (
        xcopy "%SRC_DIR%" "%TARGET%\" /E /I /Y >nul
    )
)

if "%DO_DEPS%"=="1" (
    if exist "%TARGET%\package.json" (
        where npm >nul 2>&1
        if errorlevel 1 (
            echo   npm not found; skipping dependency install
        ) else (
            echo   Installing optional dependencies in %TARGET%
            if "%DO_DRY_RUN%"=="1" (
                echo   [dry-run] npm install --omit=dev
            ) else (
                pushd "%TARGET%" >nul
                call npm install --omit=dev
                popd >nul
            )
        )
    )
)

echo.
where opencode >nul 2>&1
if errorlevel 1 (
    echo   opencode is not in PATH; install it before starting a session
) else (
    for /f "delims=" %%V in ('opencode --version 2^>nul') do echo   opencode %%V
)
echo   Config: %TARGET%
echo   Restart opencode for changes to take effect.
echo   Verify: opencode debug config ^&^& opencode debug skill ^&^& opencode mcp list
exit /b 0

:backup_target
set "TS="
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "TS=%%I"
if not defined TS set "TS=%RANDOM%%RANDOM%"
set "TS=%TS:~0,8%-%TS:~8,6%"
set "BACKUP=%TARGET%.backup.%TS%"
echo   Backing up %TARGET% -^> %BACKUP%
if "%DO_DRY_RUN%"=="1" (
    echo   [dry-run] move "%TARGET%" "%BACKUP%"
) else (
    move "%TARGET%" "%BACKUP%" >nul
)
exit /b 0

:usage
echo Deploy the opencode configuration.
echo.
echo Usage: %~nx0 [options]
echo.
echo Options:
echo   -t, --target DIR   Target config directory (default: %TARGET%)
echo   -c, --copy         Copy files instead of symlinking (default: symlink)
echo   -l, --link         Symlink src into the target (default)
echo   -b, --backup       Move an existing target to .backup.TIMESTAMP
echo   -r, --remove       Remove an existing target before installing
echo   -d, --deps         Run npm install --omit=dev in the target
echo   -n, --dry-run      Print what would happen, change nothing
echo   -h, --help         Show this help
exit /b 0

:usage_error
echo.
call :usage >&2
exit /b 2
