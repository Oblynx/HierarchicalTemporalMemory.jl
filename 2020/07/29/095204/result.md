# Benchmark result

* Pull request commit: [`9ad4f95f1f080e68c558fa4387c5cdcf24fbb0a1`](https://github.com/Oblynx/HierarchicalTemporalMemory.jl/commit/9ad4f95f1f080e68c558fa4387c5cdcf24fbb0a1)
* Pull request: <https://github.com/Oblynx/HierarchicalTemporalMemory.jl/pull/46> (Better tiebreaker)

# Judge result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmarks:
    - Target: 29 Jul 2020 - 09:48
    - Baseline: 29 Jul 2020 - 09:50
* Package commits:
    - Target: 168a31
    - Baseline: a3bb03
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

| ID                                      | time ratio                   | memory ratio                 |
|-----------------------------------------|------------------------------|------------------------------|
| `["SP", "1 iteration, global inhibit"]` | 0.92 (5%) :white_check_mark: |                1.19 (1%) :x: |
| `["SP", "1 iteration, local inhibit"]`  | 0.01 (5%) :white_check_mark: | 0.00 (1%) :white_check_mark: |
| `["TM", "first 100 steps"]`             | 0.91 (5%) :white_check_mark: | 0.97 (1%) :white_check_mark: |
| `["TM", "last 100 steps"]`              |                   0.95 (5%)  | 0.98 (1%) :white_check_mark: |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo

### Target
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      26355 s          0 s       1598 s      12386 s          0 s
       #2  2095 MHz       9125 s          0 s       1582 s      30145 s          0 s
       
  Memory: 6.764884948730469 GB (2653.87109375 MB free)
  Uptime: 421.0 sec
  Load Avg:  1.0  0.84912109375  0.44189453125
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
```

### Baseline
```
Julia Version 1.4.2
Commit 44fa15b150* (2020-05-23 18:35 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      28311 s          0 s       1626 s      26328 s          0 s
       #2  2095 MHz      23010 s          0 s       1714 s      32033 s          0 s
       
  Memory: 6.764884948730469 GB (2625.27734375 MB free)
  Uptime: 581.0 sec
  Load Avg:  1.02490234375  0.93017578125  0.54296875
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
```

---
# Target result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 29 Jul 2020 - 9:48
* Package commit: 168a31
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
| `["SP", "1 iteration, global inhibit"]` | 927.409 μs (5%) |           | 112.70 KiB (1%) |          74 |
| `["SP", "1 iteration, local inhibit"]`  |  97.255 ms (5%) |           | 615.14 KiB (1%) |         320 |
| `["TM", "first 100 steps"]`             | 538.189 ms (5%) | 31.351 ms | 586.92 MiB (1%) |     1470816 |
| `["TM", "last 100 steps"]`              | 495.236 ms (5%) | 27.510 ms | 509.52 MiB (1%) |     1223918 |

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
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      26355 s          0 s       1598 s      12386 s          0 s
       #2  2095 MHz       9125 s          0 s       1582 s      30145 s          0 s
       
  Memory: 6.764884948730469 GB (2653.87109375 MB free)
  Uptime: 421.0 sec
  Load Avg:  1.0  0.84912109375  0.44189453125
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
```

---
# Baseline result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 29 Jul 2020 - 9:50
* Package commit: a3bb03
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

| ID                                      | time            | GC time    | memory          | allocations |
|-----------------------------------------|----------------:|-----------:|----------------:|------------:|
| `["SP", "1 iteration, global inhibit"]` |   1.005 ms (5%) |            |  94.84 KiB (1%) |          73 |
| `["SP", "1 iteration, local inhibit"]`  |    7.052 s (5%) | 296.483 ms | 726.36 MiB (1%) |    13990535 |
| `["TM", "first 100 steps"]`             | 590.049 ms (5%) |  36.263 ms | 604.57 MiB (1%) |     1503711 |
| `["TM", "last 100 steps"]`              | 519.095 ms (5%) |  27.288 ms | 522.27 MiB (1%) |     1239969 |

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
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      28311 s          0 s       1626 s      26328 s          0 s
       #2  2095 MHz      23010 s          0 s       1714 s      32033 s          0 s
       
  Memory: 6.764884948730469 GB (2625.27734375 MB free)
  Uptime: 581.0 sec
  Load Avg:  1.02490234375  0.93017578125  0.54296875
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
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
    Model:               85
    Model name:          Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz
    Stepping:            4
    CPU MHz:             2095.077
    BogoMIPS:            4190.15
    Hypervisor vendor:   Microsoft
    Virtualization type: full
    L1d cache:           32K
    L1i cache:           32K
    L2 cache:            1024K
    L3 cache:            36608K
    NUMA node0 CPU(s):   0,1
    Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology cpuid pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single pti fsgsbase bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx avx512f avx512dq rdseed adx smap clflushopt avx512cd avx512bw avx512vl xsaveopt xsavec xsaves md_clear
    

| Cpu Property       | Value                                                   |
|:------------------ |:------------------------------------------------------- |
| Brand              | Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz           |
| Vendor             | :Intel                                                  |
| Architecture       | :Skylake                                                |
| Model              | Family: 0x06, Model: 0x55, Stepping: 0x04, Type: 0x00   |
| Cores              | 2 physical cores, 2 logical cores (on executing CPU)    |
|                    | No Hyperthreading detected                              |
| Clock Frequencies  | Not supported by CPU                                    |
| Data Cache         | Level 1:3 : (32, 1024, 36608) kbytes                    |
|                    | 64 byte cache line size                                 |
| Address Size       | 48 bits virtual, 44 bits physical                       |
| SIMD               | 512 bit = 64 byte max. SIMD vector size                 |
| Time Stamp Counter | TSC is accessible via `rdtsc`                           |
|                    | TSC increased at every clock cycle (non-invariant TSC)  |
| Perf. Monitoring   | Performance Monitoring Counters (PMC) are not supported |
| Hypervisor         | Yes, Microsoft                                          |

