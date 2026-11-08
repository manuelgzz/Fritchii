// SPDX-License-Identifier: GPL-3.0-or-later

#include <catch2/catch_test_macros.hpp>

#if defined(__linux__) && !defined(__ANDROID__)
#include <sched.h>
#include <thread>

#include "common/thread.h"

TEST_CASE("Linux worker affinity can be restricted and restored", "[common][thread][pinning]") {
    cpu_set_t original;
    CPU_ZERO(&original);
    REQUIRE(sched_getaffinity(0, sizeof(original), &original) == 0);
    int selected = -1;
    for (int cpu = 0; cpu < 64 && cpu < CPU_SETSIZE; ++cpu) {
        if (CPU_ISSET(cpu, &original)) {
            selected = cpu;
            break;
        }
    }
    if (selected < 0) {
        SKIP("No allowed CPU in the supported 0-63 range");
    }

    int restricted_result = -1;
    int restored_result = -1;
    bool restricted = false;
    bool restored = false;
    std::jthread worker([&] {
        Common::SetCurrentThreadCpuMask(u64{1} << selected);
        cpu_set_t current;
        CPU_ZERO(&current);
        restricted_result = sched_getaffinity(0, sizeof(current), &current);
        restricted = CPU_COUNT(&current) == 1 && CPU_ISSET(selected, &current);
        Common::SetCurrentThreadCpuMask(0);
        CPU_ZERO(&current);
        restored_result = sched_getaffinity(0, sizeof(current), &current);
        restored = CPU_EQUAL(&current, &original) != 0;
    });
    worker.join();
    CAPTURE(selected);
    REQUIRE(restricted_result == 0);
    REQUIRE(restricted);
    REQUIRE(restored_result == 0);
    REQUIRE(restored);
}
#endif
