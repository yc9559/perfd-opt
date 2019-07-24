#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v1 (20190721)

module_dir="/data/adb/modules/perfd-opt"
panel_path="/sdcard/powercfg_panel.txt"

# target power mode
action=$1

# $1:value $2:file path
lock_val() 
{
    if [ -f ${2} ]; then
        chmod 0666 ${2}
        echo ${1} > ${2}
        chmod 0444 ${2}
    fi
}

# $1:value $2:file path
mutate() 
{
    if [ -f ${2} ]; then
        chmod 0666 ${2}
        echo ${1} > ${2}
    fi
}

# stop before updating cfg
stop_qti_perfd()
{
    stop perf-hal-1-0
}

# start after updating cfg
start_qti_perfd()
{
    start perf-hal-1-0
}

# $1:mode(such as balance)
update_qti_perfd()
{
    rm /data/vendor/perfd/default_values
    cp ${module_dir}/system/vendor/etc/perf/perfd_profiles/${1}/* ${module_dir}/system/vendor/etc/perf/
}

# $1:key $return:value(string)
read_cfg_value()
{
    value=""
    if [ -f ${panel_path} ]; then
        value=`grep "^${1}=" "${panel_path}" | tr -d ' ' | cut -d= -f2`
    fi
    echo ${value}
}

apply_common()
{
    # task_util(p) = p->ravg.demand_scaled <= sysctl_sched_min_task_util_for_boost
    mutate "16" /proc/sys/kernel/sched_min_task_util_for_boost
    mutate "96" /proc/sys/kernel/sched_min_task_util_for_colocation
    # normal colocation util report
    mutate "1000000" /proc/sys/kernel/sched_little_cluster_coloc_fmin_khz

    # turn off hotplug to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu0/core_ctl/enable
    # tend to online more cores to balance parallel tasks
    mutate "15" /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
    mutate "5" /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
    mutate "3" /sys/devices/system/cpu/cpu4/core_ctl/task_thres
    # task usually doesn't run on cpu7
    mutate "15" /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
    mutate "10" /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms

    # unify scaling_min_freq, may be override
    mutate "576000" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    mutate "710400" /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
    mutate "825600" /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

    # unify scaling_max_freq, may be override
    mutate "1785600" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
    mutate "2419100" /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
    mutate "2841600" /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq

    # unify group_migrate, may be override
	mutate "110" /proc/sys/kernel/sched_group_upmigrate
	mutate "100" /proc/sys/kernel/sched_group_downmigrate
}

apply_powersave()
{
    # may be override
    mutate "300000" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    mutate "710400" /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
    mutate "825600" /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "90 85" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1632000 4:0 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "300" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    # task usually doesn't run on cpu7
    lock_val "1" /sys/devices/system/cpu/cpu7/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
}

apply_balance()
{
    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "90 85" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1632000 4:0 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "300" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "2" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    # task usually doesn't run on cpu7
    lock_val "1" /sys/devices/system/cpu/cpu7/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
}

apply_performance()
{
    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90 60" /proc/sys/kernel/sched_downmigrate
    mutate "90 85" /proc/sys/kernel/sched_upmigrate
    mutate "90 60" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "10" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1209600 4:1612800 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "3" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    # task usually doesn't run on cpu7
    lock_val "1" /sys/devices/system/cpu/cpu7/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
}

apply_fast()
{
    # may be override
    mutate "576000" /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    mutate "1401600" /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
    mutate "1401600" /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

    # easier to boost
    mutate "16" /proc/sys/kernel/sched_min_task_util_for_boost
    mutate "16" /proc/sys/kernel/sched_min_task_util_for_colocation
    mutate "40 40" /proc/sys/kernel/sched_downmigrate
    mutate "40 60" /proc/sys/kernel/sched_upmigrate
    mutate "40 40" /proc/sys/kernel/sched_downmigrate

    # avoid being the bottleneck
    mutate "1440000000" /sys/class/devfreq/soc:qcom,cpu0-cpu-l3-lat/min_freq
    mutate "1440000000" /sys/class/devfreq/soc:qcom,cpu4-cpu-l3-lat/min_freq
    mutate "1440000000" /sys/class/devfreq/soc:qcom,cpu7-cpu-l3-lat/min_freq

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "20" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:0 4:1804800 7:1612800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "1" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "3" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu7/core_ctl/enable
    mutate "1" /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
}

# $1: power_mode
apply_power_mode()
{
    case "${1}" in
    "powersave") 
        stop_qti_perfd
        apply_common
        apply_powersave
        update_qti_perfd powersave
        start_qti_perfd
        echo "Applying powersave done."
    ;;
    "balance")
        stop_qti_perfd
        apply_common
        apply_balance
        update_qti_perfd balance
        start_qti_perfd
        echo "Applying balance done."
    ;;
    "performance") 
        stop_qti_perfd
        apply_common
        apply_performance
        update_qti_perfd performance
        start_qti_perfd
        echo "Applying performance done."
    ;;
    "fast") 
        stop_qti_perfd
        apply_common
        apply_fast
        update_qti_perfd fast
        start_qti_perfd
        echo "Applying fast done."
    ;;
    *) 
        action="balance"
        stop_qti_perfd
        apply_common
        apply_balance
        update_qti_perfd balance
        start_qti_perfd
        echo "Applying balance done."
    ;;
    esac
}

# suppress stderr
(

echo ""

# we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
while [ ! -e ${panel_path} ] 
do
    touch ${panel_path}
    sleep 2
done

if [ ! -n "$action" ]; then
    # default option is balance
    action="balance"
    # load default mode from file
    default_action=`read_cfg_value default_mode`
    if [ "${default_action}" != "" ]; then
        action=${default_action}
    fi
fi

# perform hotfix
apply_power_mode ${action}

# save mode for automatic applying mode after reboot
echo ""                                                     >  ${panel_path}
echo "Perfd-opt https://github.com/yc9559/perfd-opt/"       >> ${panel_path}
echo "Author:   Matt Yang"                                  >> ${panel_path}
echo "Platform: sdm855"                                     >> ${panel_path}
echo "Version:  v1 (20190721)"                              >> ${panel_path}
echo ""                                                     >> ${panel_path}
echo "[status]"                                             >> ${panel_path}
echo "Power mode:     ${action}"                            >> ${panel_path}
echo "Last performed: `date '+%Y-%m-%d %H:%M:%S'`"          >> ${panel_path}
echo ""                                                     >> ${panel_path}
echo "[settings]"                                           >> ${panel_path}
echo "# Available mode: balance powersave performance fast" >> ${panel_path}
echo "default_mode=${action}"                               >> ${panel_path}

echo "${panel_path} has been updated."

echo ""

# suppress stderr
) 2> /dev/null

exit 0
