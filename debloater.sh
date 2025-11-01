#!/usr/bin/env bash

clear
echo "================================================================================"
echo "============================ Welcome to Android Debloater ======================"
echo "================================================================================"
echo ""


# Initialize variables and package files
BLOATWARE_FILE=bloatware_list/android_google.txt
DEVICE_PACKAGE_FILE=packages.pkg
UNINSTALL_PACKAGE_FILE=uninstall.pkg


# Helper to preety print headers
function print() {
    echo ""
	now=$(date +"%I:%M:%S")
	echo -e "${BOLD}[$now]  $1 ${RESET}"
}


# Helper to check if a line is present in the given list of lines
function exists_in_list() {
    echo "$1" | grep -F -q -x "$2"
}


# Utility to find bloatware packages currently installed in the device
function check_bloatware_packages() {
    DEVICE_PACKAGES=$1
    BLOATWARE_PACKAGES=$(<$2)
    OUTPUT_FILE=$3


    while read -r line
    do
        if exists_in_list "$BLOATWARE_PACKAGES" "$line"; then
            echo $line >> $OUTPUT_FILE
        fi
    done < $DEVICE_PACKAGES
}


# Utility to perform uninstallation of packages
function uninstall-packages() {
    UNINSTALL_PACKAGES=$1

    while read -r package <&3
    do

        print "Processing package: $package"

        # Trying to uninstall package system-wide
        adb shell pm uninstall $package > /dev/null

        if [ $? -eq 0 ]; then
            echo "Successfully uninstalled"
        else

            # Trying to uninstall package for current user
            adb shell pm uninstall --user 0 $package > /dev/null

            if [ $? -eq 0 ]; then
                echo "Successfully uninstalled for current user"
            else

                # Uninstalling failed, try to disable package
                adb shell pm clear $package > /dev/null
                adb shell pm disable-user $package > /dev/null

                if [ $? -eq 0 ]; then
                    echo "Successfully disabled for current user"
                else
                    echo "Failed to process package"
                fi
            fi
        fi

    done 3< $UNINSTALL_PACKAGES
}


# Option for the user to determine bloatware list to use
echo "Select bloatware list to use depending on the OS:"
echo "[1] Stock Android with Google Bloatware"
echo "[2] MIUI/HyperOs"
echo -n ": "
read option


# Configure correct bloatware list to use based on user selection
if [ "$option" -eq 1 ]; then
    BLOATWARE_FILE=bloatware_list/android_google.txt
elif [ "$option" -eq 2 ]; then
    BLOATWARE_FILE=bloatware_list/xiaomi.txt
else
    echo "Invalid selection"
    exit
fi
print "Using bloatware file: $BLOATWARE_FILE"


# Check if we have any connected devices
print "Getting Device list..."
adb devices | grep -F -w "device"
if [ $? -ne 0 ]; then
    print "No devices found"
    exit
fi


# Fetch list of enabled packages from current device
print "Gathering list of installed packages..."
adb shell pm list packages -e > $DEVICE_PACKAGE_FILE
sed -i 's/package://' $DEVICE_PACKAGE_FILE


# Find bloatware packages installed in the current device
print "Preparing list of packages to uninstall..."
check_bloatware_packages $DEVICE_PACKAGE_FILE $BLOATWARE_FILE $UNINSTALL_PACKAGE_FILE


# Unintsall detected bloatware packages
print "Uninstalling packages..."
uninstall-packages $UNINSTALL_PACKAGE_FILE
print "Uninstall completed"


# Perform cleanup and exit
print "Performing Cleanup..."
rm -f $DEVICE_PACKAGE_FILE
rm -f $UNINSTALL_PACKAGE_FILE


# Stop adb server
adb kill-server > /dev/null