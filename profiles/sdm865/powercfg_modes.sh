#!/system/bin/sh
# Platform Power Modes
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang
# Platform: sdm865
# Version: v4 (20200306)

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libpowercfg.sh

PLATFORM_NAME="sdm865"
BWMON_CPU_LLC="soc:qcom,cpu-cpu-llcc-bw"
BWMON_LLC_DDR="soc:qcom,cpu-llcc-ddr-bw"
BIG_L3_LAT="18590000.qcom,devfreq-l3:qcom,cpu4-cpu-l3-lat"
BIG_DDR_LAT="soc:qcom,cpu4-llcc-ddr-lat"
PRIME_L3_LAT="18590000.qcom,devfreq-l3:qcom,cpu7-cpu-l3-lat"
PRIME_DDR_LAT="soc:qcom,cpu7-llcc-ddr-lat"
STUNE_BG_CPUS="0-3"
STUNE_FG_CPUS="0-6"

DDR_TID="$(od -An -tx /proc/device-tree/memory/ddr_device_type)"
DDR_TID="${ddr_device_type:4:2}"
LPDDR4X_ID="07"
LPDDR5_ID="08"

apply_common()
{
    lock_val "15" $SCHED/sched_min_task_util_for_boost
    lock_val "1000" $SCHED/sched_min_task_util_for_colocation
    lock_val "700000" $SCHED/sched_little_cluster_coloc_fmin_khz
    set_governor_param "scaling_governor" "0:schedutil 4:schedutil 7:schedutil"
    set_governor_param "schedutil/hispeed_load" "0:90 4:90 7:80"
    set_governor_param "schedutil/hispeed_freq" "0:1171200 4:1286400 7:1632000"
    set_cpufreq_max "0:9999000 4:9999000 7:9999000"
    set_cpufreq_dyn_max "0:9999000 4:9999000 7:9999000"
    lock_val "bw_hwmon" $DEVFREQ/$BWMON_CPU_LLC/governor
    lock_val "bw_hwmon" $DEVFREQ/$BWMON_LLC_DDR/governor
    mutate "0" $DEVFREQ/$BWMON_CPU_LLC/min_freq
    mutate "0" $DEVFREQ/$BWMON_LLC_DDR/min_freq
    lock_val "8000" $DEVFREQ/$BIG_L3_LAT/mem_latency/ratio_ceil
    lock_val "800" $DEVFREQ/$BIG_DDR_LAT/mem_latency/ratio_ceil
    lock_val "8000" $DEVFREQ/$PRIME_L3_LAT/mem_latency/ratio_ceil
    lock_val "800" $DEVFREQ/$PRIME_DDR_LAT/mem_latency/ratio_ceil
    mutate "0" $LPM/lpm_prediction
    mutate "0" $LPM/sleep_disabled
}

apply_powersave()
{
    set_cpufreq_min "0:300000 4:710400 7:1171200"
    set_cpufreq_max "0:1804800 4:1574400 7:2419200"
    set_sched_migrate "95 85" "95 60" "140" "100"
    set_corectl_param "min_cpus" "0:4 4:1 7:0"
    set_governor_param "schedutil/pl" "0:0 4:0 7:0"
    lock_val "0:1171200 4:1056000 7:0" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "15000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    [ "$DDR_TID" == "$LPDDR4X_ID" ] && mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    [ "$DDR_TID" == "$LPDDR5_ID" ] && mutate "8000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_balance()
{
    set_cpufreq_min "0:691200 4:710400 7:1171200"
    set_cpufreq_max "0:1804800 4:2054400 7:2649600"
    set_sched_migrate "95 85" "95 60" "140" "100"
    set_corectl_param "min_cpus" "0:4 4:2 7:0"
    set_governor_param "schedutil/pl" "0:0 4:0 7:1"
    lock_val "0:1171200 4:1056000 7:0" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "15000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    [ "$DDR_TID" == "$LPDDR4X_ID" ] && mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    [ "$DDR_TID" == "$LPDDR5_ID" ] && mutate "8000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_performance()
{
    set_cpufreq_min "0:691200 4:710400 7:1171200"
    set_cpufreq_max "0:1804800 4:2419100 7:2841600"
    set_sched_migrate "80 80" "80 60" "100" "90"
    set_corectl_param "min_cpus" "0:4 4:3 7:1"
    set_governor_param "schedutil/pl" "0:0 4:1 7:1"
    lock_val "0:1171200 4:1286400 7:0" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "10" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "16000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    [ "$DDR_TID" == "$LPDDR4X_ID" ] && mutate "8000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    [ "$DDR_TID" == "$LPDDR5_ID" ] && mutate "11000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "100" $LPM/bias_hyst
}

apply_fast()
{
    set_cpufreq_min "0:691200 4:1286400 7:1286400"
    set_cpufreq_max "0:1804800 4:2054400 7:2745600"
    set_sched_migrate "80 80" "80 60" "100" "90"
    set_corectl_param "min_cpus" "0:4 4:3 7:1"
    set_governor_param "schedutil/pl" "0:1 4:1 7:1"
    lock_val "0:1171200 4:1574400 7:1632000" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "1" $CPU_BOOST/sched_boost_on_input
    mutate "30" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "16000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    [ "$DDR_TID" == "$LPDDR4X_ID" ] && mutate "8000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    [ "$DDR_TID" == "$LPDDR5_ID" ] && mutate "11000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "1000" $LPM/bias_hyst
}

apply_once()
{
    mutate "$STUNE_FG_CPUS" /dev/cpuset/foreground/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/background/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/restricted/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/display/cpus
    set_corectl_param "enable" "0:1 4:1 7:1"
    set_corectl_param "busy_down_thres" "0:20 4:20 7:20"
    set_corectl_param "busy_up_thres" "0:40 4:40 7:40"
    set_corectl_param "offline_delay_ms" "0:100 4:100 7:100"
}
