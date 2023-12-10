@echo off
setlocal enabledelayedexpansion

cls
echo ========================================================================================
echo ============================= Welcome to Android Debloater =============================
echo ========================================================================================
echo.


SET BLOATWARE_FILE=bloatware_list/android_google.txt
SET DEVICE_PACKAGE_FILE=packages.pkg
SET UNINSTALL_PACKAGE_FILE=uninstall.pkg


echo Select bloatware list to use depending on the OS:
echo [1] Stock Android with Google Bloatware
echo [2] MIUI
set /p option= ": "


IF "%option%" EQU "1" (
	SET BLOATWARE_FILE=bloatware_list/android_google.txt
) ELSE (
	IF "%option%" EQU "2" (
		SET BLOATWARE_FILE=bloatware_list/miui.txt
	) ELSE (
		call :Println "Invalid selection"
		exit /b 1
	)
)
call :Println "Using bloatware file: %BLOATWARE_FILE%"


call :Println "Getting Device list..."
adb devices -l | find "device product:" > nul
IF "%errorlevel%" EQU "1" (
    echo No devices found
	exit /b 0
)


call :Println "Gathering list of installed packages..."
adb shell pm list packages -e > %DEVICE_PACKAGE_FILE%


call :Println "Preparing list of packages to uninstall..."
call :CheckBloatwarePackages %DEVICE_PACKAGE_FILE%, %BLOATWARE_FILE%, %UNINSTALL_PACKAGE_FILE%


call :Println "Uninstalling packages..."
call :UninstallPackages %UNINSTALL_PACKAGE_FILE%


call :Println "Uninstall completed"
call :Println "Performing Cleanup..."
del %DEVICE_PACKAGE_FILE%
del %UNINSTALL_PACKAGE_FILE%
adb kill-server


:Println
	echo %~1
	echo.
	exit /b 0
	

:CheckBloatwarePackages
	set DEVICE_PACKAGES=%~1
    set BLOATWARE_PACKAGES=%~2
    set OUTPUT_FILE=%~3
	
	FOR /f "tokens=*" %%A in (%BLOATWARE_PACKAGES%) do (
		find "%%A" %DEVICE_PACKAGES%  > nul && ( echo %%A >> %OUTPUT_FILE% )
	)
	exit /b 0
	

:UninstallPackages
	SET UNINSTALL_PACKAGES=%~1
	FOR /f "tokens=*" %%A in (%UNINSTALL_PACKAGES%) do (

		echo Processing: %%A
		echo Trying uninstall for all users
		adb shell pm uninstall %%A > nul

		IF %errorlevel% NEQ 0 (
			echo Failed
			echo Trying uninstall for current user

			adb shell pm uninstall --user 0 %%A > nul

			IF %errorlevel% NEQ 0 (
				echo Failed
				echo Trying to disable the app for current user
				
				adb shell pm clear %%A > nul
				adb shell pm disable-user %%A > nul
			) ELSE (
				echo Success
			)
		) ELSE (
			echo Success
		)
	)
	exit /b 0