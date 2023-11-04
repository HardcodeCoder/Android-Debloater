@echo off
setlocal enabledelayedexpansion

echo ========================================================================================
echo ============================= Welcome to Android Debloater =============================
echo ========================================================================================
echo.

adb devices
pause

set bloats=miui_bloatware_packages.txt
set pkg_list_file=packages.pkg
set uninstall_list_file=uninstall.pkg

echo Gathering list of installed packages...
adb shell pm list packages -e > %pkg_list_file%

for /f "tokens=*" %%A in (%bloats%) do call :FindPackage %%A

for /f "tokens=*" %%A in (%uninstall_list_file%) do call :Uninstall %%A


del %pkg_list_file%
del %uninstall_list_file%
adb kill-server

pause
EXIT /B %errorlevel%


:FindPackage
	find "%~1" %pkg_list_file%  > nul && ( echo %~1 >> %uninstall_list_file% )
	exit /b 0


:Uninstall
	set pkg_name=%~1
	echo Processing: %pkg_name%
	
	echo Trying uninstall for all users
	adb shell pm uninstall %pkg_name% > nul

	if %errorlevel% neq 0 (
		echo Failed

		echo Trying uninstall for current user
		adb shell pm uninstall --user 0 %pkg_name% > nul

		if %errorlevel% neq 0 (
			echo Failed

			echo Trying to disable the app for current user
			adb shell pm disable-user %pkg_name%
		)
	)
	echo.
	echo.
	exit /b 0