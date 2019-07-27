#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang
# Platform: sdm710
# Version: v1 (20190727)

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
    # prevent foreground using big cluster, may be override
    mutate "0-5" /dev/cpuset/foreground/cpus

    # tend to online more cores to balance parallel tasks
    mutate "15" /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
    mutate "5" /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms

    # unify scaling_min_freq, may be override
    mutate "576000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "652800" /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

    # unify scaling_max_freq, may be override
    mutate "1708800" /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    mutate "2208000" /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq

    # unify group_migrate, may be override
	mutate "110" /proc/sys/kernel/sched_group_upmigrate
	mutate "100" /proc/sys/kernel/sched_group_downmigrate
}

apply_powersave()
{
    # may be override
    mutate "300000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "300000" /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90" /proc/sys/kernel/sched_downmigrate
    mutate "90" /proc/sys/kernel/sched_upmigrate
    mutate "90" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1209660 6:1132800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "400" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu6/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
}

apply_balance()
{
    # may be override
    mutate "300000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "300000" /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90" /proc/sys/kernel/sched_downmigrate
    mutate "90" /proc/sys/kernel/sched_upmigrate
    mutate "90" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1209660 6:1132800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "400" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu6/core_ctl/enable
    mutate "1" /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
}

apply_performance()
{
    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90" /proc/sys/kernel/sched_downmigrate
    mutate "90" /proc/sys/kernel/sched_upmigrate
    mutate "90" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "10" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1209600 6:1843200" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu0/core_ctl/enable
    lock_val "0" /sys/devices/system/cpu/cpu6/core_ctl/enable
    mutate "2" /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
}

apply_fast()
{
    # may be override
    mutate "576000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "1843200" /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

    # easier to boost
    mutate "40" /proc/sys/kernel/sched_downmigrate
    mutate "60" /proc/sys/kernel/sched_upmigrate
    mutate "40" /proc/sys/kernel/sched_downmigrate

    # avoid being the bottleneck
    mutate "1344000000" /sys/class/devfreq/soc:qcom,cpu0-cpu-l3-lat/min_freq
    mutate "1344000000" /sys/class/devfreq/soc:qcom,cpu6-cpu-l3-lat/min_freq

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "20" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:0 6:1843200" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "1" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu0/core_ctl/enable
    lock_val "0" /sys/devices/system/cpu/cpu6/core_ctl/enable
    mutate "2" /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
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
echo "Platform: sdm710"                                     >> ${panel_path}
echo "Version:  v1 (20190727)"                              >> ${panel_path}
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
