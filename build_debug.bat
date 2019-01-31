@echo off
cls

REM - Set PROJ_NAME to the name of the RTC Stream.
set PROJ_NAME=Charlie_ACU_B_Dev

REM - Set GESE_FOLDER to the name of the folder where the setting files are generated.
REM - To disable the setting file auto-update, do not set the GESE_FOLDER value.
REM - The GESE_FOLDER value should not have a terminating backslash (\).
REM set GESE_FOLDER=C:\GESE_Cooking_Integration\Application
set GESE_FOLDER=C:\Data\Nucleus_Dev\Hill_ACU_A_Dev\exe\GESE

set PROJECT_DIR=%cd%

REM if not exist tools\Log\LogPreprocessor.exe (
REM    @echo.
REM    @echo Please share the "Log" folder from the GENERIC_TOOLS component in the _COMPILERS_AND_TOOLS stream
REM    @echo  from the Nucleus project area into the tools folder.
REM    goto end
REM )
REMtools\Log\LogPreprocessor.exe

cd exe
    if exist %PROJ_NAME%.s19 copy /y %PROJ_NAME%.s19 %PROJ_NAME%.previous > nul
    attrib -r *.s19 > nul
    attrib -r *.out > nul
    attrib -r *.map > nul
    attrib -r *.bin > nul

    if not exist "%GESE_FOLDER%" goto :EEP_Done
    if not exist "%GESE_FOLDER%\*.eep" goto :EEP_Done
    xcopy "%GESE_FOLDER%\*.eep" settingfile.bin /Y
    del "%GESE_FOLDER%\*.eep.used" /F >nul 2>&1
    rename "%GESE_FOLDER%\*.eep" "*.eep.used"
:EEP_Done

    if exist LintProjectErrors.txt del /f LintProjectErrors.txt > nul
cd ..

ren source\ClassB_Signature.h B.txt 1>nul

cd tools
    cd Utilities
        Regenerate.exe 1>nul
        PathBuilder.exe 1>nul
    cd ..
cd ..


cd source

fc ClassB_Signature.h B.txt 1>nul
if %errorlevel% equ 0 (
    del ClassB_Signature.h 1>nul
    ren B.txt ClassB_Signature.h 1>nul
) else (
    del B.txt 1>nul
)

if exist ..\exe\LintProjectErrors.txt attrib -r ..\exe\LintProjectErrors.txt
if exist ..\exe\LintProjectErrors.txt del ..\exe\LintProjectErrors.txt

REM - Expose to build for use with IAP
REM set DBUG_OPTION=

REM - Expose to build for use without IAP
set DBUG_OPTION=-D ENABLE_JUMP_TO_APPLICATION_WITHOUT_IAP_FIRMWARE

if "%2"=="V" goto Verbose1
goto No_verb1

:Verbose1
make %1 -DARG0=%1 -DMAKESTARTUP=../tools/startup.mk -S -f source_makefile -D VERBOSE=1
if ERRORLEVEL 1 goto end
goto Next1

:No_verb1
make %1 -DARG0=%1 -DMAKESTARTUP=../tools/startup.mk -S -f source_makefile
if ERRORLEVEL 1 goto end

:Next1
cd ..

REM Generate list of all object files
cd obj
..\tools\echo "OBJECTS =" *.obj > ..\object_file_list
cd ..

REM Generate the H05, S19, MAP, and 695 files
if "%2"=="V" goto Verbose2
goto No_Verb2

:Verbose2
make -DMAKESTARTUP=tools/startup.mk -s -f makefile.dat -D VERBOSE=1
if ERRORLEVEL 1 goto end
goto Next2

:No_Verb2
make -DMAKESTARTUP=tools/startup.mk -s -f makefile.dat
if ERRORLEVEL 1 goto end

:Next2
if "%1"=="-U" goto LintProject
if "%1"=="-u" goto LintProject
goto CheckS19

:LintProject
cd source

if exist ..\Linted\*.lnt attrib -r ..\Linted\*.lnt
if exist ..\Linted\*.lnt del ..\Linted\*.lnt

make -DMAKESTARTUP=../tools/startup.mk -DARG0=%1 -f ..\tools\Lint_Dynamic\LintProject.mak
move /Y LintProjectErrors.txt ..\Exe
type ..\Exe\LintProjectErrors.txt
cd..

:CheckS19
if not exist exe\%PROJ_NAME%.previous goto :end
fc exe\%PROJ_NAME%.s19 exe\%PROJ_NAME%.previous > nul
if %errorlevel% == 0 echo.
if %errorlevel% == 0 echo No S19 Differences Encountered

:end
