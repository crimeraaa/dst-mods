@echo off
set directories=0
set modname=%1

:: Counts how many directories there are in the current directory.
:: Does not include subdirectories, so you get a face-value count.
:: Adapted from: https://superuser.com/a/942123
for /D %%f in (*) do (
    set /A directories+=1
)

echo %directories% folders found.

if "%modname%"=="" (
    echo Usage: %0 ^<modname^>
    set /P modname="Please enter a mod name: "
)

echo Linking %modname%...

