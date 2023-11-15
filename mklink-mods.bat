@echo off
:: Need this so our local variables don't pollute the main session.
setlocal EnableDelayedExpansion

set "dst_install=%ProgramFiles(x86)%\Steam\steamapps\common\Don't Starve Together\mods"
rem set "here=%~dp0."
rem set "modname=%1"

:: The `/D` flag limits wildcard to directories. Does not include subdirectories.
for /D %%f in (*) do (
    set "target=%dst_install%\%%~nf"
    if exist "!target!" (
        echo "!target!" is an existing directory or symlink.
    ) else (
        rem Use the `~f` flag to get the fully qualified path 
        rem (drive, path, filename, extenstion)
        mklink /D "!target!" "%%~ff"
    )
)

exit /b 0

