#!/system/bin/sh
# Platform Power Modes
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang
# Platform: sm6150
# Version: v3 (20200222)

BASEDIR="$(dirname "$0")"
. $BASEDIR/pathinfo.sh
. $BASEDIR/libpowercfg.sh

# "365,366"="sdmmagpie"="sdm730"
# "355,369"="msmsteppe"="sdm675"
[ -f /sys/devices/soc0/soc_id ] && SOC_ID="$(cat /sys/devices/soc0/soc_id)"
[ -f /sys/devices/system/soc/soc0/id ] && SOC_ID="$(cat /sys/devices/system/soc/soc0/id)"

case "$SOC_ID" in
    365|366) PLATFORM_NAME="sdm730" ;;
    355|369) PLATFORM_NAME="sdm675" ;;
esac
BWMON_CPU_LLC="soc:qcom,cpu-cpu-llcc-bw"
BWMON_LLC_DDR="soc:qcom,cpu-llcc-ddr-bw"
BIG_L3_LAT="soc:qcom,cpu6-cpu-l3-lat"
BIG_DDR_LAT="soc:qcom,cpu6-llcc-ddr-lat"
STUNE_BG_CPUS="0-5"
STUNE_FG_CPUS="0-7"

apply_common()
{
    set_governor_param "scaling_governor" "0:schedutil 6:schedutil"
    set_governor_param "schedutil/hispeed_load" "0:90 6:90"
    set_governor_param "schedutil/hispeed_freq" "0:1000000 6:1200000"
    set_cpufreq_max "0:9999000 6:9999000"
    set_cpufreq_dyn_max "0:9999000 6:9999000"
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
    set_cpufreq_min "0:300000 6:300000"
    case "$PLATFORM_NAME" in
        sdm730) set_cpufreq_max "0:1708800 6:1555200" ;;
        sdm675) set_cpufreq_max "0:1708800 6:1516800" ;;
    esac
    set_sched_migrate "95" "95" "140" "100"
    set_corectl_param "min_cpus" "0:4 6:1"
    set_governor_param "schedutil/pl" "0:0 6:0"
    lock_val "0:1000000 6:1000000" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "1" $ST_TOP/schedtune.sched_boost_enabled
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "13000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_balance()
{
    set_cpufreq_min "0:576000 6:652800"
    case "$SOC_ID" in
        sdm730) set_cpufreq_max "0:1708800 6:1939200" ;;
        sdm675) set_cpufreq_max "0:1708800 6:1708800" ;;
    esac
    set_sched_migrate "95" "95" "140" "100"
    set_corectl_param "min_cpus" "0:4 6:2"
    set_governor_param "schedutil/pl" "0:0 6:0"
    lock_val "0:1000000 6:1000000" $CPU_BOOST/input_boost_freq
    lock_val "800" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "1" $ST_TOP/schedtune.sched_boost_enabled
    mutate "0" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "13000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "6000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "25" $LPM/bias_hyst
}

apply_performance()
{
    set_cpufreq_min "0:576000 6:652800"
    case "$SOC_ID" in
        sdm730) set_cpufreq_max "0:1804800 6:2208000" ;;
        sdm675) set_cpufreq_max "0:1804800 6:2016000" ;;
    esac
    set_sched_migrate "80" "80" "100" "90"
    set_corectl_param "min_cpus" "0:6 6:2"
    set_governor_param "schedutil/pl" "0:0 6:1"
    lock_val "0:1000000 6:1200000" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "2" $CPU_BOOST/sched_boost_on_input
    mutate "1" $ST_TOP/schedtune.sched_boost_enabled
    mutate "10" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "15000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "7000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "100" $LPM/bias_hyst
}

apply_fast()
{
    set_cpufreq_min "0:576000 6:1209600"
    case "$SOC_ID" in
        sdm730) set_cpufreq_max "0:1804800 6:1939200" ;;
        sdm675) set_cpufreq_max "0:1804800 6:1708800" ;;
    esac
    set_sched_migrate "80" "80" "100" "90"
    set_corectl_param "min_cpus" "0:6 6:2"
    set_governor_param "schedutil/pl" "0:1 6:1"
    lock_val "0:1000000 6:1200000" $CPU_BOOST/input_boost_freq
    lock_val "2000" $CPU_BOOST/input_boost_ms
    lock_val "1" $CPU_BOOST/sched_boost_on_input
    mutate "1" $ST_TOP/schedtune.sched_boost_enabled
    mutate "30" $ST_TOP/schedtune.boost
    mutate "1" $ST_TOP/schedtune.prefer_idle
    mutate "15000" $DEVFREQ/$BWMON_CPU_LLC/max_freq
    mutate "7000" $DEVFREQ/$BWMON_LLC_DDR/max_freq
    mutate "1000" $LPM/bias_hyst
}

apply_once()
{
    mutate "$STUNE_FG_CPUS" /dev/cpuset/foreground/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/restricted/cpus
    lock_val "$STUNE_BG_CPUS" /dev/cpuset/display/cpus
    set_corectl_param "enable" "0:1 6:1"
    set_corectl_param "busy_down_thres" "0:20 6:20"
    set_corectl_param "busy_up_thres" "0:40 6:40"
    set_corectl_param "offline_delay_ms" "0:100 6:100"
}
