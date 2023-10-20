@ECHO OFF
SET directories=0
SET modname=%1

:: Counts how many directories there are in the current directory.
:: Does not include subdirectories, so you get a face-value count.
:: Adapted from: https://superuser.com/a/942123
FOR /D %%f IN (*) DO (
    SET /A directories+=1 >nul
)

:: ECHO %directories% folders found.

IF "%modname%"=="" (
    ECHO Usage: %0 ^<modname^>
    SET /P modname="Please enter a mod name: "
)

ECHO Creating %modname%...

