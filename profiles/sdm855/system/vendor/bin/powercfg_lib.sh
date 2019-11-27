#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v2 (20191127)

module_dir="/data/adb/modules/perfd-opt"
script_rel=/system/vendor/bin
perfcfg_rel=/system/vendor/etc/perf
panel_path="/sdcard/powercfg_panel.txt"

# $1:value $2:file path
lock_val() 
{
    if [ -f $2 ]; then
        chmod 0666 $2
        echo $1 > $2
        chmod 0444 $2
    fi
}

# $1:value $2:file path
mutate() 
{
    if [ -f $2 ]; then
        chmod 0666 $2
        echo $1 > $2
    fi
}

# $1:task_name $2:cgroup_name $3:"cpuset"/"stune"
change_task_cgroup()
{
    temp_pids=`ps -Ao pid,cmd | grep "$1" | awk '{print $1}'`
    for temp_pid in $temp_pids
    do
        for temp_tid in `ls /proc/$temp_pid/task/`
        do
            echo $temp_tid > /dev/$3/$2/tasks
        done
    done
}

# $1:task_name $2:hex_mask(0x00000003 is CPU0 and CPU1)
change_task_affinity()
{
    temp_pids=`ps -Ao pid,cmd | grep "$1" | awk '{print $1}'`
    for temp_pid in $temp_pids
    do
        for temp_tid in `ls /proc/$temp_pid/task/`
        do
            taskset -p $2 $temp_tid
        done
    done
}

# stop before updating cfg
stop_qti_perfd()
{
    stop perf-hal-1-0
    stop perf-hal-2-0
}

# start after updating cfg
start_qti_perfd()
{
    start perf-hal-1-0
    start perf-hal-2-0
}

# $1:mode(such as balance)
update_qti_perfd()
{
    rm /data/vendor/perfd/default_values
    cp -af $module_dir/$perfcfg_rel/perfd_profiles/$1/* $module_dir/$perfcfg_rel/
}

# $1:key $return:value(string)
read_cfg_value()
{
    value=""
    if [ -f $panel_path ]; then
        value=`grep "^$1=" "$panel_path" | tr -d ' ' | cut -d= -f2`
    fi
    echo $value
}
