#!/usr/bin/env bash

clear
echo "================================================================================"
echo "============================ Welcome to Android Debloater ======================"
echo "================================================================================"
echo ""


BLOATWARE_FILE=bloatware_list/android_google.txt
DEVICE_PACKAGE_FILE=packages.pkg
UNINSTALL_PACKAGE_FILE=uninstall.pkg


function print() {
    echo ""
	now=$(date +"%I:%M:%S")
	echo -e "${BOLD}[$now]  $1 ${RESET}"
}


function exists_in_list() {
    echo "$1" | grep -F -q -x "$2"
}


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


function uninstall-packages() {
    UNINSTALL_PACKAGES=$1
    while read -r package <&3
    do
        print "Processing: $package"
        echo "Trying to uninstall for all users"
        adb shell pm uninstall $package > /dev/null

        if [ $? -ne 0 ]; then
            echo "Failed"
            echo "Trying uninstall for current user"

            adb shell pm uninstall --user 0 $package > /dev/null

            if [ $? -ne 0 ]; then
                echo "Failed"
                echo "Trying to disable the app for current user"

                adb shell pm clear $package > /dev/null
                adb shell pm disable-user $package > /dev/null
            else
                echo "Success"
            fi
        else
            echo "Success"
        fi
    done 3< $UNINSTALL_PACKAGES
}


echo "Select bloatware list to use depending on the OS:"
echo "[1] Stock Android with Google Bloatware"
echo "[2] MIUI/HyperOs"
echo -n ": "
read option


if [ "$option" -eq 1 ]; then
    BLOATWARE_FILE=bloatware_list/android_google.txt
elif [ "$option" -eq 2 ]; then
    BLOATWARE_FILE=bloatware_list/xiaomi.txt
else
    echo "Invalid selection"
    exit
fi
print "Using bloatware file: $BLOATWARE_FILE"


print "Getting Device list..."
adb devices | grep -F -w "device"
if [ $? -ne 0 ]; then
    print "No devices found"
    exit
fi


print "Gathering list of installed packages..."
adb shell pm list packages -e > $DEVICE_PACKAGE_FILE
sed -i 's/package://' $DEVICE_PACKAGE_FILE


print "Preparing list of packages to uninstall..."
check_bloatware_packages $DEVICE_PACKAGE_FILE $BLOATWARE_FILE $UNINSTALL_PACKAGE_FILE


print "Uninstalling packages..."
uninstall-packages $UNINSTALL_PACKAGE_FILE


print "Uninstall completed"
print "Performing Cleanup..."
rm -f $DEVICE_PACKAGE_FILE
rm -f $UNINSTALL_PACKAGE_FILE
adb kill-server