@echo off
set "dst_install=%ProgramFiles(x86)%\Steam\steamapps\common\Don't Starve Together\mods"
set "here=%~dp0."
rem set "dircount=0"
set "modname=%1"

:: Counts how many dircount there are in the current directory.
:: Does not include sub directory counts so you get a face-value count.
:: Adapted from: https://superuser.com/a/942123
rem for /D %%f in (*) do (
rem     set /A dircount+=1
rem     echo ^#%dircount%: '%%f'
rem )

rem echo %dircount% folders found.

if "%modname%"=="" (
    echo Usage: %0 ^<modname^>
    set /P "modname=Please enter a mod name: "
)

mklink /D "%dst_install%\%modname%" "%here%\%modname%"

:: It seems that even from a batchfile, using <set> still adds these variables 
:: to the current session's environment.
:: So I prefer to erase them else we pollute the environment with more...
set "dst_install="
set "here="
rem set "dircount="
set "modname="
