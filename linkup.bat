:: Use cmd /c to terminate on finish. Use /k to not terminate.
:: May need to call this from powershell as follows:
:: cmd /c runas /user:Administrator "cmd /k %CD%\linkup.bat"

:: Keep echo on when I want to see if we're doing things correctly.
@echo off

:: %~dp0 is the directory of the batchfile rather than the working dir.
:: Append a period instead of removing the trailing backslash so we can
:: use slashes after this variable.

set here=%~dp0.
set target=%here%\0002-custom-console-cmds
set origin=%here%\0001-count-prefabs

:: cmd.exe links are LHS===>RHS (LHS is symlink to be made!!)
:: Redirect stdout (stream 1, implied) to nul, then redirect stderr (stream 2) to stdout.
mklink "%target%\scripts\countprefabs.lua" "%origin%\scripts\countprefabs.lua" >nul 2>&1
if not %errorlevel%==0 (
   echo Symlink already exists.
) else (
   echo Successfully created symlink.
)
