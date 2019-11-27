# Perfd opt

The previous [Project WIPE](https://github.com/yc9559/cpufreq-interactive-opt), automatically adjust the `interactive` parameters via simulation and heuristic optimization algorithms, and working on all mainstream devices which use `interactive` as default governor. The recent [WIPE v2](https://github.com/yc9559/wipe-v2), improved simulation supports more features of the kernel and focuses on rendering performance requirements, automatically adjusting the `interactive`+`HMP`+`input boost` parameters. However, after the EAS is merged into the mainline, the simulation difficulty of auto-tuning depends on raise. It is difficult to simulate the logic of the EAS scheduler. In addition, EAS is designed to avoid parameterization at the beginning of design, so for example, the adjustment of schedutil has no obvious effect.  

[WIPE v2](https://github.com/yc9559/wipe-v2) focuses on meeting performance requirements when interacting with APP, while reducing non-interactive lag weights, pushing the trade-off between fluency and power saving even further. `QTI Boost Framework`, which must be disabled before applying optimization, is able to dynamically override parameters based on perf hint. This project utilizes `QTI Boost Framework` and extends the ability of override custom parameters. When launching APPs or scrolling the screen, applying more aggressive parameters to improve response at an acceptable power penalty. When there is no interaction, use conservative parameters, use small core clusters as much as possible, and run at a higher energy efficiency OPP under heavy load.  

In addition, this project has improved memory management and enabled Android to retain more cache processes. Because the ActivityManager in the Android framework has a limit on the number of cached processes in the background. Although the default value of 32 seems to be large, in fact, because many non-user processes crowd out this quota, the process is recycled much earlier than the user expected. After the limitation of cached empty processes is removed, the system is usually under a large memory pressure. In terms of memory reclamation, setting reasonable LMK parameters avoids higher vmpressure in advance, and slightly aggressive kswapd parameters reserve more free RAM and reduce unnecessary paging. In terms of improving memory utilization, enabling larger compressed memory to move cached processes into it as much as possible, and using MEMCG to limit latency-sensitive processes using compressed memory to improve the user experience.

Details see [the lead project](https://github.com/yc9559/sdm855-tune/commits/master) & [perfd-opt commits](https://github.com/yc9559/perfd-opt/commits/master)    

## Profiles

- powersave: based on balance mode, but with lower frequency limitation
- balance: smoother than the stock config with lower power consumption
- performance: dynamic stune boost = 50 with no frequency limitation
- fast: providing stable performance capacity considering the TDP limitation of device chassis

```plain
sdm855
- powersave:    1.6+2.4g, boost 2.0+2.6g, min 0.3+0.7+0.8
- balance:      2.0+2.6g, boost 2.4+2.7g, min 0.5+0.7+0.8
- performance:  2.4+2.7g, boost 2.4+2.8g, min 0.5+0.7+0.8
- fast:         2.0+2.7g, boost 2.4+2.8g, min 0.5+1.4+1.4
```

## Requirements

1. sdm855
2. Android >= 9.0
3. Rooted
4. Magisk >= 17.0

## Installation

1. Download zip in [Release Page](https://github.com/yc9559/perfd-opt/releases)
2. Flash in Magisk manager
3. Reboot
4. Check whether `/sdcard/powercfg_panel.txt` exists

## Switch modes

### Switching on boot

1. Open `/sdcard/powercfg_panel.txt`, you will see:  
```plain

Perfd-opt https://github.com/yc9559/perfd-opt/
Author:   Matt Yang
Platform: sdm855
Version:  v2 (20191127)

[status]
Power mode:     balance
Last performed: 2019-11-27 12:03:40

[settings]
# Available mode: balance powersave performance fast
default_mode=balance

```
2. Edit line `default_mode=balance`
3. Reboot

### Switching after boot

Option 1:  
Exec `/vendor/bin/sh /vendor/bin/powercfg.sh balance`, where `balance` is the mode you want to switch.  

Option 2:  
Install [vtools](https://www.coolapk.com/apk/com.omarea.vtools) and bind APPs to power mode.  

## Credit

```plain
@屁屁痒
provide /vendor/etc & sched tunables on Snapdragon 845

@林北蓋唱秋
provide /vendor/etc on Snapdragon 675

@酪安小煸
provide /vendor/etc on Snapdragon 710

@沉迷学习日渐膨胀的小学僧
help testing on Snapdragon 855

@NeonXeon
provide information about dynamic stune

@rfigo
provide information about dynamic stune
```
