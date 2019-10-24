@echo off
:: BEGIN Set Variables

REM set nameVersion=_1.0.0.0
for %%i in (%CD%) do set thisFolder=%%~ni

set thisFolder=%thisFolder%
set namePrefix=%thisFolder%

set fileList=%thisFolder%.ini
REM set nameVersion=%date:~10,4%%date:~4,2%%date:~7,2%

:: Indicate where the SQL Source files are relative to the current directory
set "sqlDir=%~dp0"
call :resolve "%sqlDir%" resolvedsqlDir

:: Target File Name
call :SetVersion nameVersion

set "publishDir=%~dp0..\published\"
call :resolve "%publishDir%" resolvedpublishDir

IF NOT EXIST "%resolvedpublishDir%%nameVersion%" (
md %resolvedpublishDir%%nameVersion%
)
call :resolve "%publishDir%%nameVersion%\" resolvedpublishDir

set "logDir=%~dp0..\publish\logs\"
call :resolve "%logDir%" resolvedlogDir



set filename=%resolvedpublishDir%%namePrefix%_%nameVersion%.sql
set logname=%resolvedlogDir%%namePrefix%_%nameVersion%.log

echo.
:: END Set Variables
REM call :resolve "%sqlDir%" resolvedDir

echo ----------------------------------------------------------
echo Source	: %fileList%
echo Log	: %logname%
echo SQLDir : %resolvedsqlDir% 
echo Publish: %filename%
echo Version: %nameVersion%
echo ----------------------------------------------------------

if exist "%filename%" del "%filename%"
if exist "%logname%" del "%logname%"

echo.
echo ---------------------------------------------------------- >>"%logname%"
echo Source	: %fileList% >>"%logname%"
echo Publish: %filename% >>"%logname%"
echo SQLDir	: %resolvedsqlDir% >>"%logname%"
echo ---------------------------------------------------------- >>"%logname%"
echo. >>"%logname%"
echo -- -------------------------------------------------------- >>"%filename%"
echo -- SourceDir: %resolvedsqlDir% >>"%filename%"
echo -- -------------------------------------------------------- >>"%filename%"

:: Replace the line below with: for /r %%a in (*.sql) do (
:: to also seek out and merge .sql files in nearby, recursive directories.
for /F "eol=; tokens=*" %%a in (%fileList%) do (
IF NOT EXIST "%resolvedsqlDir%%%a" (
echo ************************************************************************
echo *** FILE NOT FOUND:  %resolvedsqlDir%%%a
echo ************************************************************************
echo FAILED: %%a >> "%logname%"
goto FileNotFound
) ELSE (
echo PRINT '**********************************************************************' >>"%filename%"
echo PRINT 'SCRIPT FILE: %%a' >>"%filename%"
echo PRINT '**********************************************************************'>>"%filename%"

:: merges soure files into target file
copy "%filename%" + "%resolvedsqlDir%%%a" "%filename%" 


:: Add a go statement at the end of each sql file
echo. >>"%filename%"
echo. >>"%filename%"
echo GO >>"%filename%"
echo SUCCESS: %%a >> "%logname%"
)  
)
pause
exit

:resolve file/folder returnVarName
    rem Set the second argument (variable name) 
    rem to the full path to the first argument (file/folder)
    set "%~2=%~f1"
    goto :EOF
	
:SetVersion returnVersion
	for /F "eol=; tokens=*" %%a in (..\publish\_version.ini) do (
	set "%~1=%%a"
	)
	goto :EOF

:SetFolderName returnFolderName
	call set PARENT_DIR=%CD%
	set PARENT_DIR=%PARENT_DIR:\= %
	set FOLDER_NAME=
		for %%i in (%PARENT_DIR%) do set FOLDER_NAME=%%i

	
:FileNotFound
if exist %filename% del %filename%
pause
	
