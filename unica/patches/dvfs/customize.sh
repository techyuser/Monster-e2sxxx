source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"


# ADD_TO_WORK_DIR "dm3q" "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" 0 0 644 "u:object_r:system_file:s0"

SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_default"
TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_r9s_exynos2100"
TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_exynos2100_xx"

# s25fe
# SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_r13s_s5e9945"
SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_m1s_s5e9965"
TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_r9s_exynos2100"

LOG "SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME=$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"
LOG "TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME=$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"

MODPATH="$SRC_DIR/unica/patches/dvfs"

if [[ "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" == "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" ]] && \
    [[ "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" == "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" ]]; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi

_LOG() { if $DEBUG; then LOGW "$1"; else ABORT "$1"; fi }

# SEC_PRODUCT_FEATURE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME
if [[ "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" != "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" ]]; then
    SMALI_PATCH "system" "system/framework/ssrm.jar" \
        "smali/com/android/server/ssrm/Feature.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME," \
        "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"

    DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

    if [ -f "$SRC_DIR/target/$TARGET_CODENAME/dvfs/$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME.xml" ]; then
        LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/res/raw/$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME.xml"
        EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/dvfs/$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/res/raw/$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME.xml\""
    elif [ ! -f "$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/res/raw/$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME.xml" ]; then
        _LOG "\"$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME\" does not exist in SDHMS app"
    fi

    # com/sec/android/sdhms/performance/PerformanceFeature
    SMALI_PATCH "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" \
        "smali/c4/c.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" \
        "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"
    # com/sec/android/sdhms/performance/settings/PerformanceProperties
    SMALI_PATCH "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" \
        "smali/k4/e.smali" "replace" \
        "<init>(Landroid/content/Context;)V" \
        "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" \
        "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME"
fi

# SEC_PRODUCT_FEATURE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME
if [[ "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" != "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SYSTEM_CONFIG_SIOP_POLICY_FILENAME" "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"

    SMALI_PATCH "system" "system/framework/ssrm.jar" \
        "smali/com/android/server/ssrm/Feature.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" \
        "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"

    DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

    if [[ "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" != "ssrm_default" ]] && \
            [[ "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" == "ssrm_default" ]]; then
        LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default"
        EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default\""
        LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model"
        EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model\""
        LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default"
        EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default\""
        LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default.xml"
        EVAL "cp -a \"$MODPATH/assets/siop_default.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default.xml\""
        LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default.xml"
        EVAL "cp -a \"$MODPATH/assets/siop_default.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default.xml\""
    fi

    # com/sec/android/sdhms/util/Feature
    SMALI_PATCH "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" \
        "smali/o5/w.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" \
        "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME"
fi

if [ -f "$SRC_DIR/target/$TARGET_CODENAME/dvfs/siop_model.xml" ]; then
    DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

    LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default"
    EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default\""
    LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model"
    EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model\""
    LOG "- Deleting /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default"
    EVAL "rm \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default\""

    LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default.xml"
    EVAL "cp -a \"$MODPATH/assets/siop_default.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_default.xml\""
    LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model.xml"
    EVAL "cp -a \"$SRC_DIR/target/$TARGET_CODENAME/dvfs/siop_model.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/siop_model.xml\""
    LOG "- Adding /system/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default.xml"
    EVAL "cp -a \"$MODPATH/assets/siop_default.xml\" \"$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk/assets/ssrm_default.xml\""
else
    if [[ "$SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" != "$TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME" ]] && \
            [[ "$TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME" != "ssrm_default" ]]; then
        _LOG "File not found: $SRC_DIR/target/$TARGET_CODENAME/dvfs/siop_model.xml"
    fi
fi

unset -f _LOG
