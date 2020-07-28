# Benchmark result

* Pull request commit: [`4802c3309c1bde1186610069807fee9db0c8eede`](https://github.com/Oblynx/HierarchicalTemporalMemory.jl/commit/4802c3309c1bde1186610069807fee9db0c8eede)
* Pull request: <https://github.com/Oblynx/HierarchicalTemporalMemory.jl/pull/44> (SP inhibition tiebreaker)

# Judge result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmarks:
    - Target: 28 Jul 2020 - 15:09
    - Baseline: 28 Jul 2020 - 15:11
* Package commits:
    - Target: ab2f18
    - Baseline: 88d6e8
* Julia commits:
    - Target: 44fa15
    - Baseline: 44fa15
* Julia command flags:
    - Target: None
    - Baseline: None
* Environment variables:
    - Target: `OMP_NUM_THREADS => 1` `JULIA_NUM_THREADS => 1`
    - Baseline: `OMP_NUM_THREADS => 1` `JULIA_NUM_THREADS => 1`

## Results
A ratio greater than `1.0` denotes a possible regression (marked with :x:), while a ratio less
than `1.0` denotes a possible improvement (marked with :white_check_mark:). Only significant results - results
that indicate possible regressions or improvements - are shown below (thus, an empty table means that all
benchmark results remained invariant between builds).

| ID | time ratio | memory ratio |
|----|------------|--------------|

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:


## Julia versioninfo

### Target
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz: 
              speed         user         nice          sys         idle          irq
       #1  2397 MHz      14380 s          0 s       1390 s      22384 s          0 s
       #2  2397 MHz      21075 s          0 s       1760 s      15805 s          0 s
       
  Memory: 6.764884948730469 GB (2703.89453125 MB free)
  Uptime: 401.0 sec
  Load Avg:  1.00439453125  0.9052734375  0.47998046875
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, haswell)
```

### Baseline
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz: 
              speed         user         nice          sys         idle          irq
       #1  2397 MHz      15138 s          0 s       1441 s      34170 s          0 s
       #2  2397 MHz      32802 s          0 s       1845 s      16527 s          0 s
       
  Memory: 6.764884948730469 GB (2667.83984375 MB free)
  Uptime: 528.0 sec
  Load Avg:  1.0  0.943359375  0.55224609375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, haswell)
```

---
# Target result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 28 Jul 2020 - 15:9
* Package commit: ab2f18
* Julia commit: 44fa15
* Julia command flags: None
* Environment variables: `OMP_NUM_THREADS => 1` `JULIA_NUM_THREADS => 1`

## Results
Below is a table of this job's results, obtained by running the benchmarks.
The values listed in the `ID` column have the structure `[parent_group, child_group, ..., key]`, and can be used to
index into the BaseBenchmarks suite to retrieve the corresponding benchmarks.
The percentages accompanying time and memory values in the below table are noise tolerances. The "true"
time/memory value for a given benchmark is expected to fall within this percentage of the reported value.
An empty cell means that the value was zero.

| ID                                      | time            | GC time   | memory          | allocations |
|-----------------------------------------|----------------:|----------:|----------------:|------------:|
| `["SP", "1 iteration, global inhibit"]` |   1.000 ms (5%) |           |  94.83 KiB (1%) |          76 |
| `["SP", "1 iteration, local inhibit"]`  |  79.177 ms (5%) |           | 595.56 KiB (1%) |         323 |
| `["TM", "first 100 steps"]`             | 594.531 ms (5%) | 40.656 ms | 605.30 MiB (1%) |     1506247 |
| `["TM", "last 100 steps"]`              | 514.384 ms (5%) | 36.742 ms | 521.87 MiB (1%) |     1239166 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz: 
              speed         user         nice          sys         idle          irq
       #1  2397 MHz      14380 s          0 s       1390 s      22384 s          0 s
       #2  2397 MHz      21075 s          0 s       1760 s      15805 s          0 s
       
  Memory: 6.764884948730469 GB (2703.89453125 MB free)
  Uptime: 401.0 sec
  Load Avg:  1.00439453125  0.9052734375  0.47998046875
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, haswell)
```

---
# Baseline result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 28 Jul 2020 - 15:11
* Package commit: 88d6e8
* Julia commit: 44fa15
* Julia command flags: None
* Environment variables: `OMP_NUM_THREADS => 1` `JULIA_NUM_THREADS => 1`

## Results
Below is a table of this job's results, obtained by running the benchmarks.
The values listed in the `ID` column have the structure `[parent_group, child_group, ..., key]`, and can be used to
index into the BaseBenchmarks suite to retrieve the corresponding benchmarks.
The percentages accompanying time and memory values in the below table are noise tolerances. The "true"
time/memory value for a given benchmark is expected to fall within this percentage of the reported value.
An empty cell means that the value was zero.

| ID                              | time            | GC time   | memory          | allocations |
|---------------------------------|----------------:|----------:|----------------:|------------:|
| `["SP", "SP: 1 iteration"]`     |   1.022 ms (5%) |           |  88.25 KiB (1%) |          63 |
| `["TM", "TM: first 100 steps"]` | 631.534 ms (5%) | 38.639 ms | 606.03 MiB (1%) |     1486711 |
| `["TM", "TM: last 100 steps"]`  | 547.894 ms (5%) | 32.267 ms | 533.35 MiB (1%) |     1247807 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz: 
              speed         user         nice          sys         idle          irq
       #1  2397 MHz      15138 s          0 s       1441 s      34170 s          0 s
       #2  2397 MHz      32802 s          0 s       1845 s      16527 s          0 s
       
  Memory: 6.764884948730469 GB (2667.83984375 MB free)
  Uptime: 528.0 sec
  Load Avg:  1.0  0.943359375  0.55224609375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, haswell)
```

---
# Runtime information
| Runtime Info | |
|:--|:--|
| BLAS #threads | 2 |
| `BLAS.vendor()` | `openblas64` |
| `Sys.CPU_THREADS` | 2 |

`lscpu` output:

    Architecture:        x86_64
    CPU op-mode(s):      32-bit, 64-bit
    Byte Order:          Little Endian
    CPU(s):              2
    On-line CPU(s) list: 0,1
    Thread(s) per core:  1
    Core(s) per socket:  2
    Socket(s):           1
    NUMA node(s):        1
    Vendor ID:           GenuineIntel
    CPU family:          6
    Model:               63
    Model name:          Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz
    Stepping:            2
    CPU MHz:             2397.221
    BogoMIPS:            4794.44
    Hypervisor vendor:   Microsoft
    Virtualization type: full
    L1d cache:           32K
    L1i cache:           32K
    L2 cache:            256K
    L3 cache:            30720K
    NUMA node0 CPU(s):   0,1
    Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology cpuid pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm invpcid_single pti fsgsbase bmi1 avx2 smep bmi2 erms invpcid xsaveopt md_clear
    

| Cpu Property       | Value                                                   |
|:------------------ |:------------------------------------------------------- |
| Brand              | Intel(R) Xeon(R) CPU E5-2673 v3 @ 2.40GHz               |
| Vendor             | :Intel                                                  |
| Architecture       | :Haswell                                                |
| Model              | Family: 0x06, Model: 0x3f, Stepping: 0x02, Type: 0x00   |
| Cores              | 2 physical cores, 2 logical cores (on executing CPU)    |
|                    | No Hyperthreading detected                              |
| Clock Frequencies  | Not supported by CPU                                    |
| Data Cache         | Level 1:3 : (32, 256, 30720) kbytes                     |
|                    | 64 byte cache line size                                 |
| Address Size       | 48 bits virtual, 44 bits physical                       |
| SIMD               | 256 bit = 32 byte max. SIMD vector size                 |
| Time Stamp Counter | TSC is accessible via `rdtsc`                           |
|                    | TSC increased at every clock cycle (non-invariant TSC)  |
| Perf. Monitoring   | Performance Monitoring Counters (PMC) are not supported |
| Hypervisor         | Yes, Microsoft                                          |

