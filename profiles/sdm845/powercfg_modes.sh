#!/system/bin/sh
# Platform Power Modes
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang
# Platform: sdm845
# Version: v4 (20200306)

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libpowercfg.sh

PLATFORM_NAME="sdm845"
BWMON_CPU_LLC="soc:qcom,cpubw"
BWMON_LLC_DDR="soc:qcom,llccbw"
BIG_L3_LAT="soc:qcom,l3-cpu4"
BIG_DDR_LAT="soc:qcom,memlat-cpu4"
STUNE_BG_CPUS="0-3"
STUNE_FG_CPUS="0-6"

apply_common()
{
    set_governor_param "scaling_governor" "0:schedutil 4:schedutil"
    set_governor_param "schedutil/hispeed_load" "0:90 4:90"
    set_governor_param "schedutil/hispeed_freq" "0:1132800 4:1612800"
    set_cpufreq_max "0:9999000 4:9999000"
    set_cpufreq_dyn_max "0:9999000 4:9999000"
    lock_val "bw_hwmon" $DEVFREQ/$BWMON_CPU_LLC/governor
    lock_val "bw_hwmon" $DEVFREQ/$BWMON_LLC_DDR/governor
    mutate "0" $DEVFREQ/$BWMON_CPU_LLC/min_freq
    mutate "0" $DEVFREQ/$BWMON_LLC_DDR/min_freq
    lock_val "8000" $DEVFREQ/$BIG_L3_LAT/mem_latency/ratio_ceil
    lock_val "800" $DEVFREQ/$BIG_DDR_LAT/mem_latency/ratio_ceil
    mutate "0" $LPM/lpm_prediction
    mutate "0" $LPM/sleep_disabled
}

apply_powersave()
{
    set_cpufreq_min "0:300000 4:300000"
    set_cpufreq_max "0:1766400 4:1996800"
    set_sched_migrate "95" "95" "140" "100"
    set_corectl_param "min_cpus" "0:4 4:1"
    set_governor_param "schedutil/pl" "0:0 4:0"
    lock_val "0:1132800 4:1286400" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "9500" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_balance()
{
    set_cpufreq_min "0:576000 4:825600"
    set_cpufreq_max "0:1766400 4:2476800"
    set_sched_migrate "95" "95" "140" "100"
    set_corectl_param "min_cpus" "0:4 4:2"
    set_governor_param "schedutil/pl" "0:0 4:1"
    lock_val "0:1132800 4:1286400" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "9500" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_performance()
{
    set_cpufreq_min "0:576000 4:825600"
    set_cpufreq_max "0:1766400 4:2803200"
    set_sched_migrate "80" "80" "100" "90"
    set_corectl_param "min_cpus" "0:4 4:4"
    set_governor_param "schedutil/pl" "0:0 4:1"
    lock_val "0:1132800 4:1612800" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "10" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "11000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "7000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "100" $LPM/bias_hyst
}

apply_fast()
{
    set_cpufreq_min "0:576000 4:1612800"
    set_cpufreq_max "0:1766400 4:2476800"
    set_sched_migrate "80" "80" "100" "90"
    set_corectl_param "min_cpus" "0:4 4:4"
    set_governor_param "schedutil/pl" "0:1 4:1"
    lock_val "0:1132800 4:1612800" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "1" $CPU_BOOST/sched_boost_on_input
    mutate "30" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "11000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "7000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "1000" $LPM/bias_hyst
}

apply_once()
{
    mutate "$STUNE_FG_CPUS" /dev/cpuset/foreground/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/background/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/restricted/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/display/cpus
    set_corectl_param "enable" "0:1 4:1"
    set_corectl_param "busy_down_thres" "0:20 4:20"
    set_corectl_param "busy_up_thres" "0:40 4:40"
    set_corectl_param "offline_delay_ms" "0:100 4:100"
}
