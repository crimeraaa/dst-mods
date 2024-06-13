@echo off
:: Need this so our local variables don't pollute the main session.
setlocal EnableDelayedExpansion

set "dst_server=C:\steamcmd\steamapps\common\Don't Starve Together Dedicated Server"
set "dst_install=%PROGRAMFILES(x86)%\Steam\steamapps\common\Don't Starve Together"

rem set "here=%~dp0."
rem set "modname=%1"

:: The `/D` flag limits wildcard to directories. Does not include subdirectories.
for /D %%f in (*) do (
    set "target_user=%dst_install%\mods\%%~nf"
    set "target_dedi=%dst_server%\mods\%%~nf"
    rem Use the `~f` flag to get the fully qualified path
    rem (drive, path, filename, extenstion)
    mklink /D "!target_user!" "%%~ff"
    mklink /D "!target_dedi!" "%%~ff"
)

exit /b 0

