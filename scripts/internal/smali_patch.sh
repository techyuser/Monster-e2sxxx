#!/usr/bin/env bash

source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"


# Sources:
# https://github.com/iBotPeaches/Apktool/issues/3775
# https://github.com/iBotPeaches/Apktool/pull/3879
# https://github.com/SameerAlSahab/smali_patch/blob/main/smali_patch.py
# https://github.com/iBotPeaches/Apktool/issues/1775

# remove eSIM
BLOBS_LIST+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml
system/etc/permissions/privapp-permissions-com.samsung.euicc.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml
system/priv-app/EsimKeyString
system/priv-app/EuiccService
"
for blob in $BLOBS_LIST
do
    rm -rf "$WORK_DIR/system/$blob" &
done

# ADD_TO_WORK_DIR "dm3q" "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" 0 0 644 "u:object_r:system_file:s0"
DECODE_APK "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"
DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
DECODE_APK "system" "system/priv-app/KmxService/KmxService.apk"
DECODE_APK "system" "system/framework/samsungkeystoreutils.jar"
DECODE_APK "system" "system/framework/knoxsdk.jar"

_SMALI_PATCH_ONLY() {

    local FILE_EXTEND=$1
    LOG "Finding *$FILE_EXTEND"

    local BASE_DIR="$SRC_DIR"
    local TARGET_BASE="$BASE_DIR/out/target/r9s/apktool"

    local SMALI_BIN="$SRC_DIR/scripts/internal/smali_patch.py"

    declare -A TARGET_MAP
    local TARGETS=()

    # 1. Scan mod + patch folders
    for ROOT in "$BASE_DIR/unica/smali_patch"; do
        [[ ! -d "$ROOT" ]] && continue

        while IFS= read -r -d '' DIR; do
            APK_NAME=$(basename "$DIR")

            [[ -z "${TARGET_MAP[$APK_NAME]}" ]] && TARGETS+=("$APK_NAME")
            TARGET_MAP[$APK_NAME]+="$DIR "
        done < <(find "$ROOT" -type d -name "*$FILE_EXTEND" -print0)
    done

    # 2. Loop targets
    # LOG "working with: ${TARGETS[@]}"
    for TARGET in "${TARGETS[@]}"; do

        # LOG "[INFO] Processing $TARGET with TARGET_BASE=$TARGET_BASE"

        local TARGET_SMALI_DIR="$TARGET_BASE/${TARGET%$FILE_EXTEND}/$TARGET"
        # LOG "[INFO] to $TARGET_SMALI_DIR"

        local PATCH_DIRS=(${TARGET_MAP[$TARGET]})

        local PATCHES=()

        # 3. Collect smalipatch files
        for P_DIR in "${PATCH_DIRS[@]}"; do
            while IFS= read -r -d '' P; do
                PATCHES+=("$P")
            done < <(find "$P_DIR" -maxdepth 1 -name "*.smalipatch" -type f -print0)
        done

        # Sort patches (important)
        IFS=$'\n' PATCHES=($(sort -V <<<"${PATCHES[*]}")); unset IFS

        # 4. Apply patches
        for P in "${PATCHES[@]}"; do
            LOG "[INFO] Applying $(basename "$P")"

            RELATIVE_PATH=$(echo "$P" | grep -oE "(system|vendor|product|system_ext)/[^ ]+\\${FILE_EXTEND}")
            # RELATIVE_PATH="${P#*mod_*/}"
            # RELATIVE_PATH="${RELATIVE_PATH#*patch_*/}"
            # RELATIVE_PATH="${RELATIVE_PATH%%.apk/*}.apk"
            # RELATIVE_PATH="${RELATIVE_PATH%%.jar/*}.jar"
            # LOG "[INFO] RELATIVE_PATH=$RELATIVE_PATH"

            python3 "$SMALI_BIN" "$TARGET_BASE/$RELATIVE_PATH" "$P" || {
                LOG "[ERROR] Failed patch: $P"
                exit 1
            }
        done

        # LOG "[DONE] $TARGET patched"
    done
}


_SMALI_PATCH_ONLY ".apk"
_SMALI_PATCH_ONLY ".jar"