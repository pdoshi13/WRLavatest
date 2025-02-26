#!/bin/sh

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

create_out_dir "${OUTPUT}"
info_msg "Output directory: ${OUTPUT}"

pkgs="systemd python3-setuptools python3-setuptools python3-yaml"
install_deps "${pkgs}" "${SKIP_INSTALL}"

info_msg "check which /proc/meminfo"
[ -e /proc/meminfo ] || error_msg "/proc/meminfo not found on test target!"

cat /proc/meminfo > ${RESULT_LOG}
unit=$(cat /proc/meminfo| awk '/^MemTotal:/{print $3}')
memTotal=$(cat /proc/meminfo| awk '/^MemTotal:/{print $2}')
memFree=$(cat /proc/meminfo| awk '/^MemFree:/{print $2}')
cached=$(cat /proc/meminfo| awk '/^Cached:/{print $2}')
anonpages=$(cat /proc/meminfo| awk '/^AnonPages:/{print $2}')
buffers=$(cat /proc/meminfo| awk '/^Buffers:/{print $2}')
[ -z "${unit}" ] && { echo "Not found unit."; exit 1; }
[ -z "${memTotal}" ] && { echo "Not found memTotal."; exit 1; }
[ -z "${memFree}" ] && { echo "Not found memFree."; exit 1; }
[ -z "${cached}" ] && { echo "Not found Cached."; exit 1; }
[ -z "${anonpages}" ] && { echo "Not found AnonPages."; exit 1; }
[ -z "${buffers}" ] && { echo "Not found Buffers."; exit 1; }
MemoryUsed=$(echo "${memTotal} ${memFree}" | awk '{printf ("%d", ($1-$2))}')
UserspaceUsed=$(echo "${cached} ${anonpages} ${buffers}" | awk '{printf ("%d", ($1+$2+$3))}')
KernelUsed=$(echo "${memTotal} ${memFree} ${cached} ${anonpages} ${buffers}" | awk '{printf ("%d", ($1-$2-$3-$4-$5))}')

cat "${RESULT_LOG}"

echo "| ${KernelUsed} ${unit} | ${UserspaceUsed} ${unit} | ${MemoryUsed} ${unit} | ${memFree} ${unit} | ${memTotal} ${unit} |"> ${RESULT_STAT}

TCID="MemoryUsed"
if [ -n "${MemoryUsed}" ]; then
    add_metric "${TCID}" "pass" "${MemoryUsed}" "${unit}"
else
    report_fail "${TCID}"
fi

TCID="UserspaceUsed"
if [ -n "${UserspaceUsed}" ]; then
    add_metric "${TCID}" "pass" "${UserspaceUsed}" "${unit}"
else
    report_fail "${TCID}"
fi

TCID="KernelUsed"
if [ -n "${KernelUsed}" ]; then
    add_metric "${TCID}" "pass" "${KernelUsed}" "${unit}"
else
    report_fail "${TCID}"
fi
