#!/system/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v4 (20200306)

BASEDIR="$(dirname "$0")"
. $BASEDIR/libcommon.sh
. $BASEDIR/libpowercfg.sh
. $BASEDIR/powercfg_modes.sh

# $1: power_mode
apply_power_mode()
{
    perfhal_stop
    apply_common
    eval apply_$1
    perfhal_update "$1"
    perfhal_start
    echo "Applying $1 done."
}

# $1: power_mode
verify_power_mode()
{
    case "$1" in
        "powersave"|"balance"|"performance"|"fast") echo "$1";;
        *) echo "balance" ;;
    esac
}

save_panel()
{
    clear_panel
    write_panel ""
    write_panel "Perfd-opt"
    write_panel "https://github.com/yc9559/perfd-opt/"
    write_panel "Author: Matt Yang"
    write_panel "Platform: $PLATFORM_NAME"
    write_panel "Version: v4 (20200306)"
    write_panel "Last performed: $(date '+%Y-%m-%d %H:%M:%S')"
    write_panel ""
    write_panel "[Perfhal status]"
    write_panel "$(perfhal_status)"
    write_panel ""
    write_panel "[Settings]"
    write_panel "# The default mode applied at boot"
    write_panel "# Available mode: balance powersave performance fast"
    write_panel "default_mode=$default_mode"
}

wait_until_login

# 1. target from exec parameter
action="$1"
# 2. target from panel
default_mode="$(read_cfg_value default_mode)"
[ "$action" == "" ] && action="$default_mode"
# 3. target from default(=balance)
action="$(verify_power_mode "$action")"
default_mode="$(verify_power_mode "$default_mode")"

# perform hotfix
apply_power_mode "$action"

# save mode for automatic applying mode after reboot
save_panel

exit 0
