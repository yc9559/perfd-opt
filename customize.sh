#!/sbin/sh

# If you need even more customization and prefer to
# do everything on your own, declare SKIPUNZIP=1
SKIPUNZIP=0

# List all directories you want to directly replace in the system
# Construct your list in the following format
# This is an example
# REPLACE_EXAMPLE="
# /system/app/Youtube
# /system/priv-app/SystemUI
# /system/framework
# "
REPLACE=""

# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.

# Available variables:
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device

# Availible functions:
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
# set_perm <platform_name> <owner> <group> <permission> [context]
#     if [context] is not set, the default is "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands:
#        chown owner.group platform_name
#        chmod permission platform_name
#        chcon context platform_name
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is not set, the default is "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#        set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#        set_perm dir owner group dirpermission context

# $1:platform_name
_extract_platform_file() {
    ui_print "- Extracting platform module files"
    mv $MODPATH/profiles/$1/system $MODPATH/
    mv $MODPATH/profiles/$1/powercfg_modes.sh $MODPATH/script/
    rm -rf $MODPATH/profiles
}


ui_print ""
ui_print "* Perfd-opt https://github.com/yc9559/perfd-opt/"
ui_print "* Author: Matt Yang"
ui_print "* Version: v4 (20200306)"
ui_print ""

platform_name="$(getprop ro.board.platform)"
case "$(getprop ro.board.platform)" in
"kona")
    ui_print "- The platform of this device is sdm865($platform_name)"
    _extract_platform_file "sdm865"
    ;;
"msmnile")
    ui_print "- The platform of this device is sdm855/855+($platform_name)"
    _extract_platform_file "sdm855"
    ;;
"sdm845")
    ui_print "- The platform of this device is sdm845($platform_name)"
    _extract_platform_file "sdm845"
    ;;
"lito")
    ui_print "- The platform of this device is sdm765/sdm765g($platform_name)"
    _extract_platform_file "sdm765"
    ;;
"sm6150")
    [ -f /sys/devices/soc0/soc_id ] && SOC_ID="$(cat /sys/devices/soc0/soc_id)"
    [ -f /sys/devices/system/soc/soc0/id ] && SOC_ID="$(cat /sys/devices/system/soc/soc0/id)"
    case "$SOC_ID" in
    365 | 366) PLATFORM_NAME="sdm730" ;;
    355 | 369) PLATFORM_NAME="sdm675" ;;
    esac
    ui_print "- The platform of this device is $PLATFORM_NAME($platform_name)"
    _extract_platform_file "sdm675_730"
    ;;
"sdm710")
    ui_print "- The platform of this device is sdm710/sdm712($platform_name)"
    _extract_platform_file "sdm710"
    ;;
*)
    abort "- [$platform_name] not supported, terminated."
    ;;
esac

# Only some special files require specific permissions
# The default permissions should be good enough for most cases
# set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
# set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
# set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
# set_perm  $MODPATH/system/lib/libart.so       0     0       0644
