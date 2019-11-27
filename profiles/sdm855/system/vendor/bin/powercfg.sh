#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v2 (20191127)

# target power mode
action=$1

# load lib
module_dir="/data/adb/modules/perfd-opt"
script_rel=/system/vendor/bin
. $module_dir/$script_rel/powercfg_lib.sh

apply_common()
{
    # upmigrate for top-app, LITTLE cluster capacity: (1785*1024)/(2841*1740)*1024 = 378
    mutate "51" /proc/sys/kernel/sched_min_task_util_for_boost
    mutate "31" /proc/sys/kernel/sched_min_task_util_for_colocation

    # prefer non-top-app running on little cluster
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "99 80" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
	mutate "120" /proc/sys/kernel/sched_group_upmigrate
	mutate "100" /proc/sys/kernel/sched_group_downmigrate

    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0" /sys/devices/system/cpu/cpu0/core_ctl/enable
    lock_val "1" /sys/devices/system/cpu/cpu4/core_ctl/enable
    lock_val "1" /sys/devices/system/cpu/cpu7/core_ctl/enable

    mutate "2" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    mutate "20" /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
    mutate "5" /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms

    mutate "0" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
    mutate "20" /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
    mutate "10" /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms

    mutate "576000" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    mutate "710400" /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
    mutate "825600" /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

    mutate "1785600" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
    mutate "2419100" /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
    mutate "2841600" /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq

    mutate "0" /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
    mutate "0" /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
    mutate "0" /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

    lock_val "0:1036800 4:1056000 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "400" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # kernel reclaim thread cannot run on the prime core
    change_task_cgroup "kswapd" "foreground" "cpuset"
    change_task_affinity "kswapd" "7f"
}

apply_powersave()
{
    mutate "321" /proc/sys/kernel/sched_min_task_util_for_colocation
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "90 80" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled

    mutate "1" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    mutate "300000" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

    # kernel reclaim thread cannot run on big cores
    change_task_cgroup "kswapd" "background" "cpuset"
    change_task_affinity "kswapd" "0f"
}

apply_balance()
{
    mutate "321" /proc/sys/kernel/sched_min_task_util_for_colocation
    mutate "1" /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl
}

apply_performance()
{
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "90 70" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
	mutate "100" /proc/sys/kernel/sched_group_upmigrate
	mutate "80" /proc/sys/kernel/sched_group_downmigrate

    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "10" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1209600 4:1612800 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    mutate "1" /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
    mutate "1" /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "3" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
}

apply_fast()
{
    mutate "40 40" /proc/sys/kernel/sched_downmigrate
    mutate "40 70" /proc/sys/kernel/sched_upmigrate
    mutate "40 40" /proc/sys/kernel/sched_downmigrate
	mutate "100" /proc/sys/kernel/sched_group_upmigrate
	mutate "80" /proc/sys/kernel/sched_group_downmigrate

    mutate "1401600" /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
    mutate "1401600" /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "20" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:0 4:1804800 7:1804800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    mutate "1" /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
    mutate "1" /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
    mutate "1" /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "3" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    lock_val "0" /sys/devices/system/cpu/cpu7/core_ctl/enable
    mutate "1" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
}

# $1: power_mode
apply_power_mode()
{
    stop_qti_perfd
    apply_common
    eval apply_$1
    update_qti_perfd $1
    start_qti_perfd
    echo "Applying $1 done."
}

# suppress stderr
(

echo ""

# we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
while [ ! -e $panel_path ] 
do
    touch $panel_path
    sleep 2
done

if [ ! -n "$action" ]; then
    # default option is balance
    action="balance"
    # load default mode from file
    default_action=`read_cfg_value default_mode`
    if [ "$default_action" != "" ]; then
        action=$default_action
    fi
fi

# perform hotfix
case "$action" in
"powersave"|"balance"|"performance"|"fast") 
;;
*) 
    action="balance"
;;
esac
apply_power_mode $action

# save mode for automatic applying mode after reboot
echo ""                                                     >  $panel_path
echo "Perfd-opt https://github.com/yc9559/perfd-opt/"       >> $panel_path
echo "Author:   Matt Yang"                                  >> $panel_path
echo "Platform: sdm855"                                     >> $panel_path
echo "Version:  v2 (20191127)"                              >> $panel_path
echo ""                                                     >> $panel_path
echo "[status]"                                             >> $panel_path
echo "Power mode:     $action"                              >> $panel_path
echo "Last performed: `date '+%Y-%m-%d %H:%M:%S'`"          >> $panel_path
echo ""                                                     >> $panel_path
echo "[settings]"                                           >> $panel_path
echo "# Available mode: balance powersave performance fast" >> $panel_path
echo "default_mode=$action"                                 >> $panel_path

echo "$panel_path has been updated."

echo ""

# suppress stderr
) 2> /dev/null

exit 0
