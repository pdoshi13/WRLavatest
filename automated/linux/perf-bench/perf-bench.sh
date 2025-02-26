#!/bin/sh

. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
RESULT_LOG="${OUTPUT}/result.log"
RESULT_STAT="${OUTPUT}/result.stat"
export RESULT_FILE
SKIP_INSTALL="false"
# List of test cases
TEST="sched syscall mem futex epoll internals breakpoint"
# PERF version
PERF_VERSION="$(uname -r | cut -d . -f 1-2)"

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

# Run perf bench sched tests
run_perf_bench_sched() {

    TCID="sched_messaging_pipe_process"
    val=""
    if perf bench sched messaging -p; then
        perf bench sched messaging -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="sched_messaging_pipe_thread"
    val=""
    if perf bench sched messaging -t -p; then
        perf bench sched messaging -t -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="sched_messaging_socketpair_process"
    val=""
    if perf bench sched messaging; then
        perf bench sched messaging 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="sched_messaging_socketpair_thread"
    val=""
    if perf bench sched messaging -t; then
        perf bench sched messaging -t 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="sched_pipe_process"
    val=""
    val1=""
    val2=""
    if perf bench sched pipe; then
        perf bench sched pipe 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        add_metric "${TCID}" "pass" "$val"
        val1=$(grep -o "[0-9]\\+.[0-9]\\+ usecs/op" ${OUTPUT}/${TCID}.log)
        val2=$(grep -o "[0-9]\\+.[0-9]\\+ ops/sec" ${OUTPUT}/${TCID}.log)
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|${val1}|${val2}|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="sched_pipe_thread"
    val=""
    val1=""
    val2=""
    if perf bench sched pipe -T; then
        perf bench sched pipe -T 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        val1=$(grep -o "[0-9]\\+.[0-9]\\+ usecs/op" ${OUTPUT}/${TCID}.log)
        val2=$(grep -o "[0-9]\\+.[0-9]\\+ ops/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|${val1}|${val2}|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench syscall tests
run_perf_bench_syscall() {
    TCID="syscall_basic"
    val=""
    val1=""
    val2=""
    if perf bench syscall basic; then
        perf bench syscall basic 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        val1=$(grep -o "[0-9]\\+.*[0-9]\\+ usecs/op" ${OUTPUT}/${TCID}.log)
        val2=$(grep -o "[0-9]\\+.*[0-9]\\+ ops/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|${val1}|${val2}|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench mem tests
run_perf_bench_mem() {
    TCID="mem_memcpy"
    val=""
    if perf bench mem memcpy; then
        perf bench mem memcpy 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(sed -n '/Default memcpy/,+3p' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ GB/sec")
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="mem_memset"
    val=""
    if perf bench mem memset; then
        perf bench mem memset 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(sed -n '/Default memset/,+3p' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ GB/sec")
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench futex tests
run_perf_bench_futex() {
    TCID="futex_hash_private"
    val=""
    if perf bench futex hash -m -s; then
        perf bench futex hash -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_hash_shared"
    val=""
    if perf bench futex hash -m -s -S; then
        perf bench futex hash -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_wake_private"
    val=""
    if perf bench futex wake -m -s; then
        perf bench futex wake -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_wake_shared"
    val=""
    if perf bench futex wake -m -s -S; then
        perf bench futex wake -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_wake_parallel_private"
    val=""
    if perf bench futex wake-parallel -m -s; then
        perf bench futex wake-parallel -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_wake_parallel_shared"
    val=""
    if perf bench futex wake-parallel -m -s -S; then
        perf bench futex wake-parallel -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_private_broadcast"
    val=""
    if perf bench futex requeue -B -m -s; then
        perf bench futex requeue -B -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_shared_broadcast"
    val=""
    if perf bench futex requeue -B -m -s -S; then
        perf bench futex requeue -B -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_private"
    val=""
    if perf bench futex requeue -m -s; then
        perf bench futex requeue -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_shared"
    val=""
    if perf bench futex requeue -m -s -S; then
        perf bench futex requeue -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_private_broadcast_variants"
    val=""
    if perf bench futex requeue -B -m -s -p; then
        perf bench futex requeue -B -m -s -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_shared_broadcast_variants"
    val=""
    if perf bench futex requeue -B -m -s -S -p; then
        perf bench futex requeue -B -m -s -S -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_private_variants"
    val=""
    if perf bench futex requeue -m -s -p; then
        perf bench futex requeue -m -s -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_requeue_shared_variants"
    val=""
    if perf bench futex requeue -m -s -S -p; then
        perf bench futex requeue -m -s -S -p 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+\.*[0-9]\\+ ms" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_lock_pi_private_multiple"
    val=""
    if perf bench futex lock-pi -M -m -s; then
        perf bench futex lock-pi -M -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_lock_pi_shared_multiple"
    val=""
    if perf bench futex lock-pi -M -m -s -S; then
        perf bench futex lock-pi -M -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_lock_pi_private"
    val=""
    if perf bench futex lock-pi -m -s; then
        perf bench futex lock-pi -m -s 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="futex_lock_pi_shared"
    val=""
    if perf bench futex lock-pi -m -s -S; then
        perf bench futex lock-pi -m -s -S 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench epoll tests
run_perf_bench_epoll() {

    TCID="epoll_wait_edge_multiq_randomize_oneshot"
    val=""
    if perf bench epoll wait --edge --multiq --randomize --oneshot; then
        perf bench epoll wait --edge --multiq --randomize --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_multiq_randomize"
    val=""
    if perf bench epoll wait --edge --multiq --randomize; then
        perf bench epoll wait --edge --multiq --randomize 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_multiq_oneshot"
    val=""
    if perf bench epoll wait --edge --multiq --oneshot; then
        perf bench epoll wait --edge --multiq --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_multiq"
    val=""
    if perf bench epoll wait --edge --multiq; then
        perf bench epoll wait --edge --multiq 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_randomize_oneshot"
    val=""
    if perf bench epoll wait --edge --randomize --oneshot; then
        perf bench epoll wait --edge --randomize --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_randomize"
    val=""
    if perf bench epoll wait --edge --randomize; then
        perf bench epoll wait --edge --randomize 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge_oneshot"
    val=""
    if perf bench epoll wait --edge --oneshot; then
        perf bench epoll wait --edge --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_edge"
    val=""
    if perf bench epoll wait --edge; then
        perf bench epoll wait --edge 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_multiq_randomize_oneshot"
    val=""
    if perf bench epoll wait --multiq --randomize --oneshot; then
        perf bench epoll wait --multiq --randomize --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_multiq_randomize"
    val=""
    if perf bench epoll wait --multiq --randomize; then
        perf bench epoll wait --multiq --randomize 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_multiq_oneshot"
    val=""
    if perf bench epoll wait --multiq --oneshot; then
        perf bench epoll wait --multiq --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_multiq"
    val=""
    if perf bench epoll wait --multiq; then
        perf bench epoll wait --multiq 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_randomize_oneshot"
    val=""
    if perf bench epoll wait --randomize --oneshot; then
        perf bench epoll wait --randomize --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_randomize"
    val=""
    if perf bench epoll wait --randomize; then
        perf bench epoll wait --randomize 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait_oneshot"
    val=""
    if perf bench epoll wait --oneshot; then
        perf bench epoll wait --oneshot 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_wait"
    val=""
    if perf bench epoll wait; then
        perf bench epoll wait 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ operations/sec" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_ctl_randomize"
    val=""
    val1=""
    val2=""
    if perf bench epoll ctl --randomize; then
        perf bench epoll ctl --randomize 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o '[0-9]\+.*[0-9]\+ ADD operations' ${OUTPUT}/${TCID}.log | sed 's/ADD//g')
        val1=$(grep -o '[0-9]\+.*[0-9]\+ MOD operations' ${OUTPUT}/${TCID}.log | sed 's/MOD//g')
        val2=$(grep -o '[0-9]\+.*[0-9]\+ DEL operations' ${OUTPUT}/${TCID}.log | sed 's/DEL//g')
        add_metric "${TCID}_add" "pass" "$val"
        add_metric "${TCID}_mod" "pass" "$val1"
        add_metric "${TCID}_del" "pass" "$val2"
    else
        report_fail "${TCID}_add"
        report_fail "${TCID}_mod"
        report_fail "${TCID}_del"
    fi
    echo "|${TCID}|$val|$val1|$val2|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="epoll_ctl"
    val=""
    val1=""
    val2=""
    if perf bench epoll ctl; then
        perf bench epoll ctl 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o '[0-9]\+.*[0-9]\+ ADD operations' ${OUTPUT}/${TCID}.log | sed 's/ADD //g')
        val1=$(grep -o '[0-9]\+.*[0-9]\+ MOD operations' ${OUTPUT}/${TCID}.log | sed 's/MOD //g')
        val2=$(grep -o '[0-9]\+.*[0-9]\+ DEL operations' ${OUTPUT}/${TCID}.log | sed 's/DEL //g')
        add_metric "${TCID}_add" "pass" "$val"
        add_metric "${TCID}_mod" "pass" "$val1"
        add_metric "${TCID}_del" "pass" "$val2"
    else
        report_fail "${TCID}_add"
        report_fail "${TCID}_mod"
        report_fail "${TCID}_del"
    fi
    echo "|${TCID}|$val|$val1|$val2|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench internals tests
run_perf_bench_internals() {

    TCID="internals_synthesize_single_threaded"
    val=""
    val1=""
    val2=""
    val3=""
    val4=""
    val5=""
    if perf bench internals synthesize --st; then
        perf bench internals synthesize --st 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep 'Average synthesis took:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec ")
        add_metric "${TCID}" "pass" "$val"
        val1=$(grep 'Average num. events:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ " | head -n 1)
        val2=$(grep 'Average time per event' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec" | head -n 1)
        val3=$(grep 'Average data synthesis took:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec ")
        val4=$(grep 'Average num. events:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ " | tail -n 1)
        val5=$(grep 'Average time per event' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec" | tail -n 1)
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|$val1|$val2|$val3|$val4|$val5|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="internals_synthesize_multi_threaded"
    val=""
    val1=""
    val2=""
    if perf bench internals synthesize --mt --max-threads $(nproc) --min-threads $(nproc); then
        perf bench internals synthesize --mt --max-threads $(nproc) --min-threads $(nproc) 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep 'Average synthesis took:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec ")
        add_metric "${TCID}" "pass" "$val"
        val1=$(grep 'Average num. events:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ ")
        val2=$(grep 'Average time per event' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec")
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|$val1|$val2|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="internals_kallsyms_parse"
    val=""
    if perf bench internals kallsyms-parse; then
        perf bench internals kallsyms-parse 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ ms " ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="internals_inject_build_id"
    val=""
    val1=""
    val2=""
    val3=""
    val4=""
    val5=""
    if perf bench internals inject-build-id; then
        perf bench internals inject-build-id 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep 'Average build-id injection took:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ msec ")
        val1=$(grep 'Average build-id-all injection took:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ msec ")
        add_metric "${TCID}" "pass" "$val"
        val2=$(grep 'Average time per event:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec " | head -n 1)
        val3=$(grep 'Average memory usage:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ KB " | head -n 1)
        val4=$(grep 'Average time per event:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ usec " | tail -n 1)
        val5=$(grep 'Average memory usage:' ${OUTPUT}/${TCID}.log | grep -o "[0-9]\\+.*[0-9]\\+ KB " | tail -n 1)
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|$val2|$val3|$val1|$val4|$val5|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="internals_evlist_open_close"
    val=""
    if perf bench internals evlist-open-close -a; then
        perf bench internals evlist-open-close -a 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ usec " ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Run perf bench breakpoint tests
run_perf_bench_breakpoint() {
    TCID="breakpoint_thread"
    val=""
    val1=""
    val2=""
    if perf bench breakpoint thread; then
        perf bench breakpoint thread 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        val1=$(grep -o "[0-9]\\+.*[0-9]\\+ usecs/op$" ${OUTPUT}/${TCID}.log)
        val2=$(grep -o "[0-9]\\+.*[0-9]\\+ usecs/op/cpu" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|$val1|$val2|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}

    TCID="breakpoint_enable"
    val=""
    val1=""
    if perf bench breakpoint enable; then
        perf bench breakpoint enable 2>&1 | tee ${OUTPUT}/${TCID}.log
        val=$(grep -o "[0-9]\\+.*[0-9]\\+ \\[sec\\]" ${OUTPUT}/${TCID}.log | sed 's/[][]//g')
        val1=$(grep -o "[0-9]\\+.*[0-9]\\+ usecs/op" ${OUTPUT}/${TCID}.log)
        add_metric "${TCID}" "pass" "$val"
    else
        report_fail "${TCID}"
    fi
    echo "|${TCID}|$val|$val1|" >> ${RESULT_STAT}
    cat ${OUTPUT}/${TCID}.log >> ${RESULT_LOG}
}

# Test run.
! check_root && error_msg "This script must be run as root"
create_out_dir "${OUTPUT}"

info_msg "About to run perf test..."
info_msg "Output directory: ${OUTPUT}"

if [ "${SKIP_INSTALL}" = "True" ] || [ "${SKIP_INSTALL}" = "true" ]; then
    info_msg "install perf skipped"
else
    dist_name
    case "${dist}" in
      elxr)
        pkgs="linux-perf"
        install_deps "${pkgs}" "${SKIP_INSTALL}"
        ;;
      *)
        warn_msg "Unsupported distribution: package install skipped"
    esac
fi

# List of test cases "sched syscall mem futex epoll internals breakpoint"
for tests in ${TEST}; do
    run_perf_bench_"${tests}"
done
