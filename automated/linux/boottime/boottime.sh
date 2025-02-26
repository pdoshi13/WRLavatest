#!/bin/bash

# shellcheck disable=SC1091
. ../../lib/sh-test-lib

OUTPUT="$(pwd)/output"
RESULT_LOG="${OUTPUT}/result.log"
RESULT_FILE="${OUTPUT}/result.txt"
RESULT_STAT="${OUTPUT}/result.stat"
export RESULT_FILE

SKIP_INSTALL="false"

usage() {
    echo "Usage: $0 [-s <true|false>]" 1>&2
    exit 1
}

while getopts "s:h" arg; do
   case "$arg" in
     s) SKIP_INSTALL="${OPTARG}";;
     h|*) usage ;;
   esac
done

# Assume systemd-analyze pre-installed on test target.
command -v systemd-analyze || error_msg "systemd-analyze not found on test target!"

create_out_dir "${OUTPUT}"
info_msg "Output directory: ${OUTPUT}"

pkgs="systemd python3-setuptools python3-setuptools python3-yaml"
install_deps "${pkgs}" "${SKIP_INSTALL}"

info_msg "check which systemd-analyze"
systemd-analyze > "${RESULT_LOG}"
cat "${RESULT_LOG}"
cat ${RESULT_LOG} | grep 'Startup finished' | sed 's/.* \(.*\) (kernel) + \(.*\) (userspace) = \(.*\)$/| \1 | \2 | \3 |/g' > ${RESULT_STAT}

# Parse test results
parse_test_results() {
    t_m="00"
    t_s="00"
    t_ms="00"
    [[ "$1" =~ "h" ]] && { echo "Need to calculate hours for total time." && exit 1; }
    [[ "$1" =~ "min" ]] && t_m=$(echo $1 | sed 's/min .*//g')
    [[ "$1" =~ [1-90]s ]] && t_s=$(echo $1 | sed -e 's/.* //g' -e 's/s.*//g')
    [[ "$1" =~ [1-90]ms ]] && t_ms=$(echo $1 | sed -e 's/.* //g' -e 's/ms.*//g')
    boot_time_ms=$(echo "00:$t_m:$t_s:$t_ms" | awk -F: '{print ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4}')
}

boot_time_ms=""
boot_time=$(cat ${RESULT_STAT} | awk -F'|' '{print $2}' | sed -e 's/ //g')
parse_test_results ${boot_time}
TCID="kernel_boot_time"
if [ -n "${boot_time_ms}" ]; then
    add_metric "${TCID}" "pass" "${boot_time_ms}" "ms"
else
    report_fail "${TCID}"
fi

boot_time_ms=""
t_user=$(cat ${RESULT_STAT} | awk -F'|' '{print $3}' | sed -e 's/ //g')
parse_test_results ${t_user}
TCID="userspace_boot_time"
if [ -n "${boot_time_ms}" ]; then
    add_metric "${TCID}" "pass" "${boot_time_ms}" "ms"
else
    report_fail "${TCID}"
fi

boot_time_ms=""
t_total=$(cat ${RESULT_STAT} | awk -F'|' '{print $4}' | sed -e 's/ //g')
parse_test_results ${t_total}
TCID="total_boot_time"
if [ -n "${boot_time_ms}" ]; then
    add_metric "${TCID}" "pass" "${boot_time_ms}" "ms"
else
    report_fail "${TCID}"
fi

cat "${RESULT_STAT}"
