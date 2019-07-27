#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

/vendor/bin/sh $MODDIR/system/vendor/bin/powercfg.sh
/vendor/bin/sh $MODDIR/system/vendor/bin/powercfg_once.sh

# support vtools
cp -af $MODDIR/vtools-powercfg.sh /data/powercfg.sh
