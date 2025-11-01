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
		echo Invalid selection
		echo.
		exit /b 1
	)
)
echo.


call :PrintHeader "Using bloatware file: %BLOATWARE_FILE%"
echo.


:: Check if we have any connected devices
call :PrintHeader "Getting Device list..."
set "DEVICE_ID="
for /f "delims=" %%i in ('adb shell getprop ro.serialno') do (
    set "DEVICE_ID=%%i"
)

IF DEFINED DEVICE_ID (
    call :PrintMessage "Found: %DEVICE_ID%"
) ELSE (
	echo. 
	exit /b 0
)
echo.


:: Fetch list of enabled packages from current device
call :PrintHeader "Gathering list of installed packages..."
adb shell pm list packages -e > %DEVICE_PACKAGE_FILE%
echo.


:: Find bloatware packages installed in the current device
call :PrintHeader "Preparing list of packages to uninstall..."
call :CheckBloatwarePackages %DEVICE_PACKAGE_FILE%, %BLOATWARE_FILE%, %UNINSTALL_PACKAGE_FILE%
echo.


:: Unintsall detected bloatware packages
call :PrintHeader "Uninstalling packages..."
echo.
call :UninstallPackages %UNINSTALL_PACKAGE_FILE%
call :PrintHeader "Done"
echo.


:: Perform cleanup and exit
call :PrintHeader "Performing Cleanup..."
del %DEVICE_PACKAGE_FILE%
del %UNINSTALL_PACKAGE_FILE%
echo.


:: Stop adb server
adb kill-server
GOTO :EOF


:: Helper to preety print headers
:PrintHeader
	set "NOW=%time%"
    set "TIME=%NOW:~0,8%"
    echo [%TIME%] %~1
	exit /b 0


:: Helper to preety print headers
:PrintMessage
	:: Prints 12 spaces to match indentation of the header
	:: Aligns the content to header
    echo             %~1
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

		call :PrintHeader "Processing package: %%A"

		:: Trying to uninstall package system-wide
		adb shell pm uninstall %%A 1>nul 2>nul && (
			call :PrintMessage "Successfully uninstalled"
		) || (

			:: Trying to uninstall package for current user
			adb shell pm uninstall --user 0 %%A 1>nul 2>nul && (
				call :PrintMessage "Successfully uninstalled for current user"
			) || (

				:: Uninstalling failed, try to disable package
				adb shell pm clear %%A 1>nul 2>nul
				adb shell pm disable-user %%A 1>nul 2>nul && (
					call :PrintMessage "Successfully disabled for current user"
				) || (
					call :PrintMessage "Failed to process package"
				)
			)
		)

		echo.
	)

	exit /b 0