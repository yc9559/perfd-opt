# Perfd opt

The previous [Project WIPE](https://github.com/yc9559/cpufreq-interactive-opt), automatically adjust the `interactive` parameters via simulation and heuristic optimization algorithms, and working on all mainstream devices which use `interactive` as default governor. The recent [WIPE v2](https://github.com/yc9559/wipe-v2), improved simulation supports more features of the kernel and focuses on rendering performance requirements, automatically adjusting the `interactive`+`HMP`+`input boost` parameters. However, after the EAS is merged into the mainline, the simulation difficulty of auto-tuning depends on raise. It is difficult to simulate the logic of the EAS scheduler. In addition, EAS is designed to avoid parameterization at the beginning of design, so for example, the adjustment of schedutil has no obvious effect.  

[WIPE v2](https://github.com/yc9559/wipe-v2) focuses on meeting performance requirements when interacting with APP, while reducing non-interactive lag weights, pushing the trade-off between fluency and power saving even further. `QTI Boost Framework`, which must be disabled before applying optimization, is able to dynamically override parameters based on perf hint. This project utilizes `QTI Boost Framework` and extends the ability of override custom parameters. When launching APPs or scrolling the screen, applying more aggressive parameters to improve response at an acceptable power penalty. When there is no interaction, use conservative parameters, use small core clusters as much as possible, and run at a higher energy efficiency OPP under heavy load.  

Details see [the lead project](https://github.com/yc9559/sdm855-tune/commits/master) & [perfd-opt commits](https://github.com/yc9559/perfd-opt/commits/master)    

## Profiles

- powersave: based on balance mode, but with lower frequency limitation
- balance: smoother than the stock config with lower power consumption
- performance: dynamic stune boost = 50 with no frequency limitation
- fast: providing stable performance capacity considering the TDP limitation of device chassis

```plain
sdm855
- powersave:    1.6+2.0g, boost 2.0+2.6g, min 0.3+0.7+0.8
- balance:      1.8+2.4g, boost 2.4+2.7g, min 0.5+0.7+0.8
- performance:  2.4+2.7g, boost 2.4+2.8g, min 0.5+0.7+0.8
- fast:         1.8+2.6g, boost 2.4+2.8g, min 0.5+1.4+1.4

sdm845
- powersave:    1.8g, boost 2.2g, min 0.3+0.3
- balance:      2.3g, boost 2.5g, min 0.5+0.8
- performance:  2.8g, boost 2.8g, min 0.5+0.8
- fast:         2.3g, boost 2.8g, min 0.5+1.6

sdm730
- powersave:    1.5g, boost 1.9g, min 0.3+0.3
- balance:      1.9g, boost 2.1g, min 0.3+0.3
- performance:  2.2g, boost 2.2g, min 0.5+0.6
- fast:         1.9g, boost 2.2g, min 0.5+1.5

sdm675
- powersave:    1.5g, boost 1.7g, min 0.3+0.3
- balance:      1.7g, boost 1.9g, min 0.3+0.3
- performance:  2.0g, boost 2.0g, min 0.5+0.6
- fast:         1.5g, boost 2.0g, min 0.5+1.5

sdm710
- powersave:    1.7g, boost 1.9g, min 0.3+0.3
- balance:      2.0g, boost 2.1g, min 0.3+0.3
- performance:  2.2g, boost 2.2g, min 0.5+0.6
- fast:         2.0g, boost 2.2g, min 0.5+1.8
```

## Requirements

1. sdm855 or sdm845 or sdm730 or sdm675 or sdm710
2. Rooted
3. Magisk >= 17.0

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
Version:  v1 (20190721)

[status]
Power mode:     balance
Last performed: 2019-07-27 10:33:28

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
