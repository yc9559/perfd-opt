#! /vendor/bin/sh
# Perfd-opt https://github.com/yc9559/perfd-opt/
# Author: Matt Yang

# powercfg wrapper for com.omarea.vtools
# MAKE SURE THAT THE MAGISK MODULE "Perfd-opt" HAS BEEN INSTALLED

powercfg_path="/vendor/bin/powercfg.sh"

# suppress stderr
(

/vendor/bin/sh ${powercfg_path} $1

# suppress stderr
) 2>/dev/null

exit 0
