#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang
# Platform: sdm845
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

# $1:task_name $2:cgroup_name $3:"cpuset"/"stune"
change_task_cgroup()
{
    temp_pids=`ps -Ao pid,cmd | grep "${1}" | awk '{print $1}'`
    for temp_pid in ${temp_pids}
    do
        for temp_tid in `ls /proc/${temp_pid}/task/`
        do
            echo ${temp_tid} > /dev/${3}/${2}/tasks
        done
    done
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
    # 580M for empty apps
    lock_val "18432,23040,27648,51256,122880,150296" /sys/module/lowmemorykiller/parameters/minfree

    # move all task not in any cgroup to system_background
    for non_tid in `cat /dev/cpuset/tasks`
    do
        echo ${non_tid} > /dev/cpuset/foreground/tasks
        echo ${non_tid} > /dev/stune/background/tasks
    done

    # prevent foreground using big cluster, may be override
    mutate "0-3" /dev/cpuset/foreground/cpus

    # treat crtc_commit as display
    change_task_cgroup "crtc_commit" "display" "cpuset"

    # avoid display preemption on big
    lock_val "0-3" /dev/cpuset/display/cpus

    # fix laggy bilibili feed scrolling
    change_task_cgroup "servicemanager" "top-app" "cpuset"
    change_task_cgroup "servicemanager" "foreground" "stune"
    change_task_cgroup "android.phone" "top-app" "cpuset"
    change_task_cgroup "android.phone" "foreground" "stune"

    # fix laggy home gesture
    change_task_cgroup "system_server" "top-app" "cpuset"
    change_task_cgroup "system_server" "foreground" "stune"

    # reduce render thread waiting time
    change_task_cgroup "surfaceflinger" "top-app" "cpuset"
    change_task_cgroup "surfaceflinger" "foreground" "stune"

    # unify schedtune misc
    lock_val "0" /dev/stune/background/schedtune.sched_boost_enabled
    lock_val "1" /dev/stune/background/schedtune.sched_boost_no_override
    lock_val "0" /dev/stune/background/schedtune.boost
    lock_val "0" /dev/stune/background/schedtune.prefer_idle
    lock_val "0" /dev/stune/foreground/schedtune.sched_boost_enabled
    lock_val "1" /dev/stune/foreground/schedtune.sched_boost_no_override
    lock_val "0" /dev/stune/foreground/schedtune.boost
    lock_val "0" /dev/stune/foreground/schedtune.prefer_idle
    lock_val "0" /dev/stune/top-app/schedtune.sched_boost_no_override

    # CFQ io scheduler takes cgroup into consideration
    lock_val "cfq" /sys/block/sda/queue/scheduler
    # Flash doesn't have back seek problem, so penalty is as low as possible
    lock_val "1" /sys/block/sda/queue/iosched/back_seek_penalty
    # slice_idle = 0 means CFQ IOP mode, https://lore.kernel.org/patchwork/patch/944972/
    lock_val "0" /sys/block/sda/queue/iosched/slice_idle
    # UFS 2.0+ hardware queue depth is 32
    lock_val "16" /sys/block/sda/queue/iosched/quantum
    # lower read_ahead_kb to reduce random access overhead
    lock_val "128" /sys/block/sda/queue/read_ahead_kb

    # turn off hotplug to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu0/core_ctl/enable
    # tend to online more cores to balance parallel tasks
    mutate "15" /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
    mutate "5" /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
    mutate "100" /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms

    # zram doesn't need much read ahead(random read)
    lock_val "4" /sys/block/zram0/queue/read_ahead_kb

    # unify scaling_min_freq, may be override
    mutate "576000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "825600" /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq

    # unify scaling_max_freq, may be override
    mutate "1766400" /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    mutate "2803200" /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq

    # unify group_migrate, may be override
	mutate "110" /proc/sys/kernel/sched_group_upmigrate
	mutate "100" /proc/sys/kernel/sched_group_downmigrate

    # adreno default settings
    lock_val "0" /sys/class/kgsl/kgsl-3d0/force_no_nap
    lock_val "1" /sys/class/kgsl/kgsl-3d0/bus_split
    lock_val "0" /sys/class/kgsl/kgsl-3d0/force_bus_on
    lock_val "0" /sys/class/kgsl/kgsl-3d0/force_clk_on
    lock_val "0" /sys/class/kgsl/kgsl-3d0/force_rail_on
}

apply_powersave()
{
    # may be override
    mutate "300000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "300000" /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq

    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90" /proc/sys/kernel/sched_downmigrate
    mutate "90" /proc/sys/kernel/sched_upmigrate
    mutate "90" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1612800 4:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "300" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "0" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
}

apply_balance()
{
    # 1708 * 0.95 / 1785 = 90.9
    # higher sched_downmigrate to use little cluster more
    mutate "90" /proc/sys/kernel/sched_downmigrate
    mutate "90" /proc/sys/kernel/sched_upmigrate
    mutate "90" /proc/sys/kernel/sched_downmigrate

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "0" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "0" /dev/stune/top-app/schedtune.boost
    mutate "0" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:1612800 4:0" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "300" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "0" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # limit the usage of big cluster
    lock_val "1" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "2" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
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

    lock_val "0:1228800 4:1612800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "2" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "4" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
}

apply_fast()
{
    # may be override
    mutate "576000" /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    mutate "1612800" /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq

    # easier to boost
    mutate "40" /proc/sys/kernel/sched_downmigrate
    mutate "60" /proc/sys/kernel/sched_upmigrate
    mutate "40" /proc/sys/kernel/sched_downmigrate

    # avoid being the bottleneck
    mutate "1401600000" /sys/class/devfreq/soc:qcom,l3-cpu0/min_freq
    mutate "1401600000" /sys/class/devfreq/soc:qcom,l3-cpu4/min_freq

    # do not use lock_val(), libqti-perfd-client.so will fail to override it
    mutate "1" /dev/stune/top-app/schedtune.sched_boost_enabled
    mutate "20" /dev/stune/top-app/schedtune.boost
    mutate "1" /dev/stune/top-app/schedtune.prefer_idle

    lock_val "0:0 4:1612800" /sys/module/cpu_boost/parameters/input_boost_freq
    lock_val "2000" /sys/module/cpu_boost/parameters/input_boost_ms
    lock_val "1" /sys/module/cpu_boost/parameters/sched_boost_on_input

    # turn off core_ctl to reduce latency
    lock_val "0" /sys/devices/system/cpu/cpu4/core_ctl/enable
    mutate "4" /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
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
echo "Platform: sdm845"                                     >> ${panel_path}
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
