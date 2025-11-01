@echo off
setlocal enabledelayedexpansion

cls
echo ========================================================================================
echo ============================= Welcome to Android Debloater =============================
echo ========================================================================================
echo.


:: Initialize variables and package files
SET BLOATWARE_FILE=bloatware_list/android_google.txt
SET DEVICE_PACKAGE_FILE=packages.pkg
SET UNINSTALL_PACKAGE_FILE=uninstall.pkg


:: Option for the user to determine bloatware list to use
echo Select bloatware list to use depending on the OS:
echo [1] Stock Android with Google Bloatware
echo [2] MIUI/HyperOs
set /p option= ": "


:: Configure correct bloatware list to use based on user selection
IF "%option%" EQU "1" (
	SET BLOATWARE_FILE=bloatware_list/android_google.txt
) ELSE (
	IF "%option%" EQU "2" (
		SET BLOATWARE_FILE=bloatware_list/xiaomi.txt
	) ELSE (
		call :Println "Invalid selection"
		exit /b 1
	)
)
call :Println "Using bloatware file: %BLOATWARE_FILE%"


:: Check if we have any connected devices
call :Println "Getting Device list..."
adb devices -l | find "device product:" > nul
IF "%errorlevel%" EQU "1" (
    echo No devices found
	exit /b 0
)


:: Fetch list of enabled packages from current device
call :Println "Gathering list of installed packages..."
adb shell pm list packages -e > %DEVICE_PACKAGE_FILE%


:: Find bloatware packages installed in the current device
call :Println "Preparing list of packages to uninstall..."
call :CheckBloatwarePackages %DEVICE_PACKAGE_FILE%, %BLOATWARE_FILE%, %UNINSTALL_PACKAGE_FILE%


:: Unintsall detected bloatware packages
call :Println "Uninstalling packages..."
call :UninstallPackages %UNINSTALL_PACKAGE_FILE%
call :Println "Uninstall completed"


:: Perform cleanup and exit
call :Println "Performing Cleanup..."
del %DEVICE_PACKAGE_FILE%
del %UNINSTALL_PACKAGE_FILE%


:: Stop adb server
adb kill-server 1>nul 2>nul


:: Helper to preety print headers
:Println
	echo %~1
	echo.
	exit /b 0
	

:: Utility to find bloatware packages currently installed in the device
:CheckBloatwarePackages
	set DEVICE_PACKAGES=%~1
    set BLOATWARE_PACKAGES=%~2
    set OUTPUT_FILE=%~3
	
	FOR /f "tokens=*" %%A in (%BLOATWARE_PACKAGES%) do (
		find "%%A" %DEVICE_PACKAGES%  > nul && ( echo %%A >> %OUTPUT_FILE% )
	)
	exit /b 0
	

:: Utility to perform uninstallation of packages
:UninstallPackages
	SET UNINSTALL_PACKAGES=%~1
	FOR /f "tokens=*" %%A in (%UNINSTALL_PACKAGES%) do (

		echo Processing package: %%A
		
		:: Trying to uninstall package system-wide
		adb shell pm uninstall %%A 1>nul 2>nul && (
			echo Successfully uninstalled
		) || (

			:: Trying to uninstall package for current user
			adb shell pm uninstall --user 0 %%A 1>nul 2>nul && (
				echo Successfully uninstalled for current user
			) || (

				:: Uninstalling failed, try to disable package
				adb shell pm clear %%A 1>nul 2>nul
				adb shell pm disable-user %%A 1>nul 2>nul && (
					echo Successfully disabled for current user
				) || (
					echo Failed to process package
				)

			)
		)
	)
	exit /b 0