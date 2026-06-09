EVAL "uniq \"$WORK_DIR/system/system/build.prop\" \"$WORK_DIR/system/system/tmp\" && mv -f \"$WORK_DIR/system/system/tmp\" \"$WORK_DIR/system/system/build.prop\""
LOG "- Adding \"debug.codec2.stop_hal_before_surface\" prop with \"1\" in /system/system/build.prop"
EVAL "sed -i \"/spatializer_enabled=true/a debug.codec2.stop_hal_before_surface=1\" \"$WORK_DIR/system/system/build.prop\""
EVAL "sed -i \"/stop_hal_before_surface/i ro.audio.spatializer_enabled=true\" \"$WORK_DIR/system/system/build.prop\""
EVAL "sed -i \"/PRODUCT_SYSTEM_DEFAULT_PROPERTIES/a ####################################\" \"$WORK_DIR/system/system/build.prop\""

# S25 FE OneUI 8 -> SoundBooster 2080
# S21 Series -> SoundBooster 1050
# S21 FE -> SoundBooster 1070

LOG_STEP_IN "- Replacing SoundBooster"
#DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2080.so"
#DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2080.so"
#DELETE_FROM_WORK_DIR "system" "system/lib64/libsoundboostereq_legacy.so"
if [[ "$TARGET_CODENAME" != "r9s"  ]]; then
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
else 
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1070.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX2100/GameDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX2100/DevGPUDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT
