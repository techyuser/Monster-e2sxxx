#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# [
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1

FIRMWARES=()
MODEL="SM-S942B"
CSC="XXV"

TMP_DIR="$(mktemp -d)"

EXTRACT_OS_PARTITIONS()
{
    # LOG "- Unpacking at TMP_DIR=$TMP_DIR, TMP_DIR=$FW_DIR"
    # https://android.googlesource.com/platform/build/+/refs/tags/android-15.0.0_r1/tools/releasetools/common.py#131
    # local FILES="system.img vendor.img product.img system_ext.img odm.img vendor_dlkm.img odm_dlkm.img system_dlkm.img optics.img prism.img"
    local FILES="optics.img"

    LOG_STEP_IN "- Extracting OS partitions"

    local PARTITION
    for f in $FILES; do
        PARTITION="${f%.img}"

        [ -f "$FW_DIR/${MODEL}_${CSC}/$f" ] || continue

        if ! sudo -n -v &> /dev/null; then
            LOG "\033[0;33m! Asking user for sudo password\033[0m"
            if ! sudo -v 2> /dev/null; then
                LOGE "Root permissions are required to unpack OS partitions"
                exit 1
            fi
        fi

        LOG "- Unpacking $(basename "$f")...  $TMP_DIR"

        mkdir -p "$FW_DIR/${MODEL}_${CSC}/$PARTITION"
        sudo umount "$FW_DIR/${MODEL}_${CSC}/$f" &> /dev/null
        if [[ "$(GET_IMAGE_FILE_SYSTEM "$FW_DIR/${MODEL}_${CSC}/$f")" == "erofs" ]]; then
            EVAL "sudo env \"PATH=$PATH\" fuse.erofs \"$FW_DIR/${MODEL}_${CSC}/$f\" \"$TMP_DIR\"" || exit 1
        else
            EVAL "sudo mount -o ro \"$FW_DIR/${MODEL}_${CSC}/$f\" \"$TMP_DIR\"" || exit 1
        fi
        EVAL "sudo cp -a -T \"$TMP_DIR\" \"$FW_DIR/${MODEL}_${CSC}/$PARTITION\"" || exit 1
        sudo chown -hR "$(whoami):$(whoami)" "$FW_DIR/${MODEL}_${CSC}/$PARTITION"
        [ -d "$FW_DIR/${MODEL}_${CSC}/$PARTITION/lost+found" ] && rm -rf "$FW_DIR/${MODEL}_${CSC}/$PARTITION/lost+found"

        LOG "- Generating fs_config/file_context for $(basename "$f")..."

        EVAL "sudo find \"$TMP_DIR\" | sudo xargs -I \"{}\" -P \"$(nproc)\" stat -c \"%n %u %g %a capabilities=0x0\" \"{}\" > \"$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION\"" || exit 1
        EVAL "sudo find \"$TMP_DIR\" | sudo xargs -I \"{}\" -P \"$(nproc)\" sh -c 'echo \"\$1 \$(getfattr -n security.selinux --only-values -h --absolute-names \"\$1\")\"' \"sh\" \"{}\" > \"$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION\"" || exit 1
        sort -o "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION" "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        sort -o "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
        # https://source.android.com/docs/core/architecture/partitions/system-as-root
        if [[ "$PARTITION" == "system" ]] && [ -d "$FW_DIR/${MODEL}_${CSC}/system/system" ]; then
            sed -i -e "s|$TMP_DIR |/ |g" -e "s|$TMP_DIR||g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
            sed -i -e "s|$TMP_DIR | |g" -e "s|$TMP_DIR/||g" "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        else
            sed -i "s|$TMP_DIR|/$PARTITION|g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"
            sed -i -e "s|$TMP_DIR | |g" -e "s|$TMP_DIR|$PARTITION|g" "$FW_DIR/${MODEL}_${CSC}/fs_config-$PARTITION"
        fi
        sed -i -e "s|\.|\\\.|g" -e "s|\+|\\\+|g" -e "s|\[|\\\[|g" \
            -e "s|\]|\\\]|g" -e "s|\*|\\\*|g" "$FW_DIR/${MODEL}_${CSC}/file_context-$PARTITION"

        # TODO a way to determine file capabilities has yet to be found, for now let's set it for the only known files
        if [ -f "$FW_DIR/${MODEL}_${CSC}/fs_config-system" ]; then
            grep -q "run-as" "$FW_DIR/${MODEL}_${CSC}/fs_config-system" && \
                sed -i "$(sed -n "/run-as/=" "$FW_DIR/${MODEL}_${CSC}/fs_config-system") s/0x0/0xc0/g" "$FW_DIR/${MODEL}_${CSC}/fs_config-system"
            grep -q "simpleperf_app_runner" "$FW_DIR/${MODEL}_${CSC}/fs_config-system" && \
                sed -i "$(sed -n "/simpleperf_app_runner/=" "$FW_DIR/${MODEL}_${CSC}/fs_config-system") s/0x0/0xc0/g" "$FW_DIR/${MODEL}_${CSC}/fs_config-system"
        fi

        EVAL "sudo umount \"$TMP_DIR\"" || exit 1
        # rm -f "$FW_DIR/${MODEL}_${CSC}/$f"
    done

    LOG_STEP_OUT
}

GET_IMAGE_FILE_SYSTEM()
{
    # https://android.googlesource.com/platform/external/e2fsprogs/+/refs/tags/android-15.0.0_r1/lib/ext2fs/ext2_fs.h#83
    if [[ "$(READ_BYTES_AT "$1" "1080" "2")" == "ef53" ]]; then
        echo "ext4"
    # https://android.googlesource.com/platform/external/f2fs-tools/+/refs/tags/android-15.0.0_r1/include/f2fs_fs.h#395
    elif [[ "$(READ_BYTES_AT "$1" "1024" "4")" == "f2f52010" ]]; then
        echo "f2fs"
    # https://android.googlesource.com/platform/external/erofs-utils/+/refs/tags/android-15.0.0_r1/include/erofs_fs.h#12
    elif [[ "$(READ_BYTES_AT "$1" "1024" "4")" == "e0f5e1e2" ]]; then
        echo "erofs"
    fi
}




    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"

    LOG_STEP_IN

    EXTRACT_OS_PARTITIONS

    LOG_STEP_OUT; LOG_STEP_OUT

rm -rf "$TMP_DIR"

exit 0
