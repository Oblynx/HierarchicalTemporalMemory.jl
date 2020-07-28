# Benchmark result

* Pull request commit: [`f15c9b3c56b2a7deec169192d3890902b44452f2`](https://github.com/Oblynx/HierarchicalTemporalMemory.jl/commit/f15c9b3c56b2a7deec169192d3890902b44452f2)
* Pull request: <https://github.com/Oblynx/HierarchicalTemporalMemory.jl/pull/46> (Better tiebreaker)

# Judge result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmarks:
    - Target: 28 Jul 2020 - 22:16
    - Baseline: 28 Jul 2020 - 22:18
* Package commits:
    - Target: b0f856
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
| `["SP", "1 iteration, global inhibit"]` | 0.93 (5%) :white_check_mark: |                1.19 (1%) :x: |
| `["SP", "1 iteration, local inhibit"]`  | 0.01 (5%) :white_check_mark: | 0.00 (1%) :white_check_mark: |
| `["TM", "first 100 steps"]`             | 0.93 (5%) :white_check_mark: | 0.97 (1%) :white_check_mark: |
| `["TM", "last 100 steps"]`              |                   0.96 (5%)  | 0.98 (1%) :white_check_mark: |

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
       #1  2095 MHz      21462 s          0 s       1464 s      13344 s          0 s
       #2  2095 MHz      10949 s          0 s       1744 s      24439 s          0 s
       
  Memory: 6.764884948730469 GB (2661.53515625 MB free)
  Uptime: 385.0 sec
  Load Avg:  1.05517578125  0.9150390625  0.4658203125
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
       #1  2095 MHz      34019 s          0 s       1570 s      14956 s          0 s
       #2  2095 MHz      12590 s          0 s       1788 s      37055 s          0 s
       
  Memory: 6.764884948730469 GB (2639.79296875 MB free)
  Uptime: 528.0 sec
  Load Avg:  1.0126953125  0.96337890625  0.5546875
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
```

---
# Target result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 28 Jul 2020 - 22:16
* Package commit: b0f856
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
| `["SP", "1 iteration, global inhibit"]` | 684.014 μs (5%) |           | 112.83 KiB (1%) |          74 |
| `["SP", "1 iteration, local inhibit"]`  |  84.073 ms (5%) |           | 615.27 KiB (1%) |         320 |
| `["TM", "first 100 steps"]`             | 466.645 ms (5%) | 32.366 ms | 586.87 MiB (1%) |     1471027 |
| `["TM", "last 100 steps"]`              | 427.828 ms (5%) | 28.429 ms | 509.66 MiB (1%) |     1224000 |

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
       #1  2095 MHz      21462 s          0 s       1464 s      13344 s          0 s
       #2  2095 MHz      10949 s          0 s       1744 s      24439 s          0 s
       
  Memory: 6.764884948730469 GB (2661.53515625 MB free)
  Uptime: 385.0 sec
  Load Avg:  1.05517578125  0.9150390625  0.4658203125
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-8.0.1 (ORCJIT, skylake)
```

---
# Baseline result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 28 Jul 2020 - 22:18
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
| `["SP", "1 iteration, global inhibit"]` | 734.853 μs (5%) |            |  94.84 KiB (1%) |          73 |
| `["SP", "1 iteration, local inhibit"]`  |    6.327 s (5%) | 207.141 ms | 727.39 MiB (1%) |    13987485 |
| `["TM", "first 100 steps"]`             | 500.169 ms (5%) |  36.669 ms | 605.14 MiB (1%) |     1506047 |
| `["TM", "last 100 steps"]`              | 444.289 ms (5%) |  29.813 ms | 522.14 MiB (1%) |     1239778 |

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
       #1  2095 MHz      34019 s          0 s       1570 s      14956 s          0 s
       #2  2095 MHz      12590 s          0 s       1788 s      37055 s          0 s
       
  Memory: 6.764884948730469 GB (2639.79296875 MB free)
  Uptime: 528.0 sec
  Load Avg:  1.0126953125  0.96337890625  0.5546875
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
    CPU MHz:             2095.195
    BogoMIPS:            4190.39
    Hypervisor vendor:   Microsoft
    Virtualization type: full
    L1d cache:           32K
    L1i cache:           32K
    L2 cache:            1024K
    L3 cache:            36608K
    NUMA node0 CPU(s):   0,1
    Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology cpuid pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single pti fsgsbase bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx avx512f avx512dq rdseed adx smap clflushopt avx512cd avx512bw avx512vl xsaveopt xsavec xsaves
    

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

