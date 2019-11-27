#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v2 (20191127)

# Runonce after boot, to speed up the transition of power modes in powercfg

# load lib
module_dir="/data/adb/modules/perfd-opt"
script_rel=/system/vendor/bin
. $module_dir/$script_rel/powercfg_lib.sh

# suppress stderr
(

# dexopt
setprop pm.dexopt.install speed
setprop pm.dexopt.shared speed
setprop dalvik.vm.boot-dex2oat-threads 8
setprop ro.sys.fw.dex2oat_thread_count 8
setprop dalvik.vm.dex2oat-threads 8
setprop dalvik.vm.image-dex2oat-threads 8

# OPHD(OnePlusHighPowerDetector) may kill more apps
# leave OPBF(OnePlusBackgroundFrozen) untouched
setprop persist.sys.ohpd.flags 0
setprop persist.sys.ohpd.kcheck false

# unify schedtune misc
# android 10 doesn't have schedtune.sched_boost_enabled exposed, default = true
lock_val "0" /dev/stune/background/schedtune.sched_boost_enabled
lock_val "0" /dev/stune/background/schedtune.sched_boost_no_override
lock_val "0" /dev/stune/background/schedtune.boost
lock_val "0" /dev/stune/background/schedtune.prefer_idle
lock_val "0" /dev/stune/foreground/schedtune.sched_boost_enabled
lock_val "0" /dev/stune/foreground/schedtune.sched_boost_no_override
lock_val "0" /dev/stune/foreground/schedtune.boost
lock_val "0" /dev/stune/foreground/schedtune.prefer_idle
lock_val "1" /dev/stune/top-app/schedtune.sched_boost_no_override

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

# save ~100mw under light 3D workload
lock_val "0" /sys/class/kgsl/kgsl-3d0/force_no_nap
lock_val "1" /sys/class/kgsl/kgsl-3d0/bus_split
lock_val "0" /sys/class/kgsl/kgsl-3d0/force_bus_on
lock_val "0" /sys/class/kgsl/kgsl-3d0/force_clk_on
lock_val "0" /sys/class/kgsl/kgsl-3d0/force_rail_on

# ~2.8x compression ratio, higher disksize result in larger space-inefficient SwapCache
# bigger zram means more blocked IO caused by the zram block device swapping out
swapoff /dev/block/zram0
lock_val "1" /sys/block/zram0/reset
lock_val "lz4" /sys/block/zram0/comp_algorithm
lock_val "1536M" /sys/block/zram0/disksize
lock_val "540M" /sys/block/zram0/mem_limit
mkswap /dev/block/zram0
swapon /dev/block/zram0 -p 23333
# zram doesn't need much read ahead(random read)
lock_val "0" /sys/block/zram0/queue/read_ahead_kb
lock_val "0" /proc/sys/vm/page-cluster

# 512M backup swap file
# swapfile=/data/vendor/swap/swapfile
# rm $swapfile
# dd if=/dev/zero of=$swapfile seek=0 bs=1m count=512
# if [ $? -eq 0 ]; then
#     mkswap $swapfile
#     swapon $swapfile -p 2333
# fi

# minfree unit(page size): 4K
lock_val "19200,25600,51200,76800,128000,179200" /sys/module/lowmemorykiller/parameters/minfree
lock_val "0,200,920,930,940,950" /sys/module/lowmemorykiller/parameters/adj
# enable automatic kill when vmpressure >= 90
lock_val "1" /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
# please kill all the processes we really don't want when vmpressure >= 90
lock_val "960" /sys/module/lowmemorykiller/parameters/adj_max_shift
# larger shrinker(LMK) calling interval
lock_val "48" /sys/module/lowmemorykiller/parameters/cost
# disable oneplus mods which kill apps fast
lock_val "0" /sys/module/lowmemorykiller/parameters/batch_kill
lock_val "0" /sys/module/lowmemorykiller/parameters/quick_select
lock_val "0" /sys/module/lowmemorykiller/parameters/time_measure
lock_val "N" /sys/module/lowmemorykiller/parameters/trust_adj_chain
# disable memplus prefetcher which ram-boost relying on, use traditional swapping
setprop persist.vendor.sys.memplus.enable 0
lock_val "0" /sys/module/memplus_core/parameters/memory_plus_enabled
# 7477M, watermark mid = 289M
lock_val "32768" /proc/sys/vm/min_free_kbytes
lock_val "262144" /proc/sys/vm/extra_free_kbytes
# lower to reduce useless page swapping
# scrolling coolapk with the same watermark mid for 8000ms, kswapd took 900ms when wsf=10, took 1200ms when wsf=300
lock_val "20" /proc/sys/vm/watermark_scale_factor

# kernel reclaim thread cannot run on the big cores
change_task_affinity "reclaimd" "0f"
change_task_affinity "oom" "0f"

# treat crtc_commit as display, avoid display preemption on big
lock_val "0-3" /dev/cpuset/display/cpus
change_task_cgroup "crtc_commit" "display" "cpuset"

# fix laggy bilibili feed scrolling
change_task_cgroup "servicemanager" "top-app" "cpuset"
change_task_cgroup "servicemanager" "foreground" "stune"
change_task_cgroup "android.phone" "top-app" "cpuset"
change_task_cgroup "android.phone" "foreground" "stune"

# fix laggy home gesture
change_task_cgroup "system_server" "top-app" "cpuset"
change_task_cgroup "system_server" "top-app" "stune"

# reduce render thread waiting time
change_task_cgroup "surfaceflinger" "top-app" "cpuset"
change_task_cgroup "surfaceflinger" "foreground" "stune"

# avoid swapping of latency intensive processes
mkdir /dev/memcg/lowlat
lock_val "1" /dev/memcg/memory.use_hierarchy
lock_val "1" /dev/memcg/memory.move_charge_at_immigrate
lock_val "1" /dev/memcg/lowlat/memory.move_charge_at_immigrate
lock_val "0" /dev/memcg/lowlat/memory.swappiness

# move latency intensive processes to memcg/lowlat
change_task_cgroup "system_server" "lowlat" "memcg"
change_task_cgroup "surfaceflinger" "lowlat" "memcg"
change_task_cgroup "composer" "lowlat" "memcg"
change_task_cgroup "allocator" "lowlat" "memcg"
change_task_cgroup "systemui" "lowlat" "memcg"

# wait for the launcher to start up
sleep 15
change_task_cgroup "launcher" "lowlat" "memcg"

# suppress stderr
) 2> /dev/null
