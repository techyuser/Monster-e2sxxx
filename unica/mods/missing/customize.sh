source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/helper_utils.sh"

LOG_STEP_IN "- Adding missing pieces for r9s"

ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/etc/init/rscmgr_s21fe.rc" 0 0 644 "u:object_r:system_file:s0"


ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/etc/libnfc-nci.conf" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/etc/libnfc-nci_temp.conf" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/lib64/libnfc_nci_jni.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/lib64/libnfc_prop_extn.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/lib64/libnfc_vendor_extn.so" 0 0 644 "u:object_r:system_file:s0"

# r9s sound improve by elite
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/missing" "system" "system/etc/stage_policy.conf" 0 0 644 "u:object_r:system_file:s0"


# decode services.jar
DECODE_APK "system" "system/framework/services.jar"

# decode camera
# DECODE_APK "system" "system/priv-app/SamsungCamera/SamsungCamera.apk"


# running custom smali patch
$SRC_DIR/scripts/internal/smali_patch.sh


LOG_STEP_OUT

SET_PROP "vendor" "ro.virtual_ab.enabled" "true"
SET_PROP "vendor" "ro.virtual_ab.compression.enabled" "true"
SET_PROP "vendor" "ro.virtual_ab.userspace.snapshots.enabled" "true"
SET_PROP "vendor" "ro.virtual_ab.io_uring.enabled" "false"
SET_PROP "vendor" "ro.virtual_ab.compression.xor.enabled" "true"
SET_PROP "vendor" "ro.virtual_ab.batch_writes" "true"
SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
SET_PROP "vendor" "debug.sf.use_phase_offsets_as_durations" "false"
SET_PROP "vendor" "debug.sf.enable_adpf_cpu_hint" "false"

SET_PROP "vendor" "persist.vendor.sys.dm.zip" "0"
SET_PROP "vendor" "persist.vendor.config.dm.autostart" "0"
SET_PROP "vendor" "persist.vendor.sys.dm.zip" "0"

SET_PROP "vendor" "ro.sys.kernelmemory.nandswap.quickswap" "true"
SET_PROP "vendor" "ro.slmk.chimera_strategy_6gb" "1000,19,11,2034"
SET_PROP "vendor" "dalvik.vm.heapsize" "512m"
SET_PROP "vendor" "dalvik.vm.heapminfree" "2m"
SET_PROP "vendor" "dalvik.vm.heapstartsize" "8m"
SET_PROP "vendor" "dalvik.vm.heapgrowthlimit" "256m"
SET_PROP "vendor" "dalvik.vm.heaptargetutilization" "0.75"
SET_PROP "vendor" "dalvik.vm.heapmaxfree" "8m"
SET_PROP "vendor" "ro.slmk.dha_cached_min" "8"
SET_PROP "vendor" "ro.slmk.2nd.dha_cached_min" "6"
SET_PROP "vendor" "ro.slmk.2nd.dha_empty_min" "5"
SET_PROP "vendor" "ro.slmk.freelimit_val" "16"
SET_PROP "vendor" "ro.slmk.psi_medium" "160"
SET_PROP "vendor" "ro.slmk.psi_critical" "400"
SET_PROP "vendor" "ro.slmk.2nd.swap_free_low_percentage" "20"
SET_PROP "vendor" "graphics.gpu.profiler.support" "true"
SET_PROP "vendor" "ro.slmk.dha_2ndprop_thMB" "2048"
SET_PROP "vendor" "ro.slmk.2nd.dha_empty_max" "16"
SET_PROP "vendor" "ro.slmk.bora_cached_num" "3"
SET_PROP "vendor" "ro.slmk.freelimit_val" "14"
SET_PROP "vendor" "ro.slmk.v_bonusEFK" "30000"
SET_PROP "vendor" "ro.slmk.swap_free_low_percentage" "15"
SET_PROP "vendor" "ro.slmk.dha_th_rate" "1.5"
SET_PROP "vendor" "ro.slmk.enable_killbooster_all" "false"
SET_PROP "vendor" "ro.slmk.use_bg_keeping_policy" "true"
SET_PROP "vendor" "ro.slmk.dha_lmk_scale" "1.2"
SET_PROP "vendor" "ro.slmk.2nd.dha_lmk_scale" "1.6"


# SET_PROP "vendor" "debug.hwui.renderer" "skiagl"
# SET_PROP "vendor" "debug.renderengine.backend" "skiagl"
# SET_PROP "vendor" "renderthread.skia.reduceopstasksplitting" "true"
# SET_PROP "vendor" "debug.hwui.skia_atrace_enabled" "false"
# SET_PROP "vendor" "persist.sys.fuse.passthrough.enable" "true"
# SET_PROP "vendor" "debug.hwui.use_hint_manager" "true"

SET_PROP "vendor" "khoailang.mod" "2026-05-11"


# SameerAlSahab add fullscreen AOD globally and animation mod
# https://github.com/SameerAlSahab/ProjectAstro
WMS_SMALI=$(find . -type f -path "*/com/android/server/wm/WindowManagerService.smali" | head -n 1)
# LOG "WMS_SMALI=$WMS_SMALI"
# ./out/target/r9s/apktool/system/framework/services.jar/smali_classes2/com/android/server/wm/WindowManagerService.smali
REPLACE_LINE \
    "const/high16 v3, 0x3f800000    # 1.0f" \
    "const v3, 0x3f59999a    # 0.90f" \
    "$WMS_SMALI"

