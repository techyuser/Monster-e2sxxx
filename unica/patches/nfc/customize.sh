source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

LOG_STEP_IN "- Patching NFC"

SET_PROP "vendor" "ro.vendor.nfc.info.antpos" "27"

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

FTP="
system/priv-app/SecSettings/SecSettings.apk/smali_classes5/com/samsung/android/settings/nfc/NfcAntennaGuideDialog.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes5/com/samsung/android/settings/nfc/NfcSettings.smali
"
for f in $FTP; do
   sed -i "s/\"27\"/\"1\"/g" "$APKTOOL_DIR/$f"
done

LOG_STEP_OUT