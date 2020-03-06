#!/system/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Original repo: https://github.com/yc9559/sdm855-tune/
# Author: Matt Yang
# Platform: sdm855
# Version: v4 (20200306)

# Runonce after boot, to speed up the transition of power modes in powercfg

BASEDIR="$(dirname "$0")"
. $BASEDIR/libcommon.sh
. $BASEDIR/libpowercfg.sh
. $BASEDIR/powercfg_modes.sh

# prefer to use prev cpu, decrease jitter from 0.5ms to 0.3ms with lpm settings
lock_val "15000000" $SCHED/sched_migration_cost_ns

# OnePlus opchain pins UX threads on the big cluster
lock_val "0" /sys/module/opchain/parameters/chain_on

# unify schedtune misc
# android 10 doesn't have schedtune.sched_boost_enabled exposed, default = true
lock_val "0" $ST_BACK/schedtune.sched_boost_enabled
lock_val "0" $ST_BACK/schedtune.sched_boost_no_override
lock_val "0" $ST_BACK/schedtune.boost
lock_val "0" $ST_BACK/schedtune.prefer_idle
lock_val "0" $ST_FORE/schedtune.sched_boost_enabled
lock_val "0" $ST_FORE/schedtune.sched_boost_no_override
lock_val "0" $ST_FORE/schedtune.boost
lock_val "1" $ST_FORE/schedtune.prefer_idle
lock_val "1" $ST_TOP/schedtune.sched_boost_enabled
lock_val "0" $ST_TOP/schedtune.sched_boost_no_override

# CFQ io scheduler takes cgroup into consideration
lock_val "cfq" $SDA_Q/scheduler
# Flash doesn't have back seek problem, so penalty is as low as possible
lock_val "1" $SDA_Q/iosched/back_seek_penalty
# slice_idle = 0 means CFQ IOP mode, https://lore.kernel.org/patchwork/patch/944972/
lock_val "0" $SDA_Q/iosched/slice_idle
# UFS 2.0+ hardware queue depth is 32
lock_val "16" $SDA_Q/iosched/quantum
# lower read_ahead_kb to reduce random access overhead
lock_val "128" $SDA_Q/read_ahead_kb

# Reserve 90% IO bandwith for foreground tasks
lock_val "1000" /dev/blkio/blkio.weight
lock_val "1000" /dev/blkio/blkio.leaf_weight
lock_val "100" /dev/blkio/background/blkio.weight
lock_val "100" /dev/blkio/background/blkio.leaf_weight

# save ~100mw under light 3D workload
lock_val "0" $KSGL/force_no_nap
lock_val "1" $KSGL/bus_split
lock_val "0" $KSGL/force_bus_on
lock_val "0" $KSGL/force_clk_on
lock_val "0" $KSGL/force_rail_on

# treat crtc_commit as background, avoid display preemption on big
change_task_cgroup "crtc_commit" "system-background" "cpuset"

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

# reduce big cluster wakeup, eg. android.hardware.sensors@1.0-service
change_task_affinity ".hardware." "0f"
# ...but exclude the fingerprint&camera service for speed
change_task_affinity ".hardware.biometrics.fingerprint" "ff"
change_task_affinity ".hardware.camera.provider" "ff"

# platform specific
apply_once
