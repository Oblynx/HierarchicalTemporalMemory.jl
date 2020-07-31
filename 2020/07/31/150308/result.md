# Benchmark result

* Pull request commit: [`53bd06dd4d6a68fbdc3409b4bc65ff02ccc08c7c`](https://github.com/Oblynx/HierarchicalTemporalMemory.jl/commit/53bd06dd4d6a68fbdc3409b4bc65ff02ccc08c7c)
* Pull request: <https://github.com/Oblynx/HierarchicalTemporalMemory.jl/pull/52> (Benchmark Julia 1.5)

# Judge result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmarks:
    - Target: 31 Jul 2020 - 15:00
    - Baseline: 31 Jul 2020 - 15:02
* Package commits:
    - Target: 486227
    - Baseline: 172104
* Julia commits:
    - Target: 7f0ee1
    - Baseline: 7f0ee1
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
| `["SP", "1 iteration, global inhibit"]` | 0.86 (5%) :white_check_mark: |                   0.99 (1%)  |
| `["SP", "1 iteration, local inhibit"]`  | 0.02 (5%) :white_check_mark: | 0.00 (1%) :white_check_mark: |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo

### Target
```
Julia Version 1.5.0-rc2.0
Commit 7f0ee122d7 (2020-07-27 15:24 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      16015 s          0 s       1656 s      19184 s          0 s
       #2  2095 MHz      16802 s          0 s       1639 s      19005 s          0 s
       
  Memory: 6.764884948730469 GB (2836.4296875 MB free)
  Uptime: 390.0 sec
  Load Avg:  1.0009765625  0.77490234375  0.38037109375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, skylake)
```

### Baseline
```
Julia Version 1.5.0-rc2.0
Commit 7f0ee122d7 (2020-07-27 15:24 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      17350 s          0 s       1698 s      31178 s          0 s
       #2  2095 MHz      28742 s          0 s       1722 s      20304 s          0 s
       
  Memory: 6.764884948730469 GB (2818.94921875 MB free)
  Uptime: 524.0 sec
  Load Avg:  1.0  0.86181640625  0.47021484375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, skylake)
```

---
# Target result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 31 Jul 2020 - 15:0
* Package commit: 486227
* Julia commit: 7f0ee1
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
| `["SP", "1 iteration, global inhibit"]` |   5.708 ms (5%) |           | 113.50 KiB (1%) |          67 |
| `["SP", "1 iteration, local inhibit"]`  |  99.501 ms (5%) |           | 615.23 KiB (1%) |         254 |
| `["TM", "first 100 steps"]`             | 400.198 ms (5%) | 26.155 ms | 424.58 MiB (1%) |      728839 |
| `["TM", "last 100 steps"]`              | 372.621 ms (5%) | 23.060 ms | 407.25 MiB (1%) |      607438 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo
```
Julia Version 1.5.0-rc2.0
Commit 7f0ee122d7 (2020-07-27 15:24 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      16015 s          0 s       1656 s      19184 s          0 s
       #2  2095 MHz      16802 s          0 s       1639 s      19005 s          0 s
       
  Memory: 6.764884948730469 GB (2836.4296875 MB free)
  Uptime: 390.0 sec
  Load Avg:  1.0009765625  0.77490234375  0.38037109375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, skylake)
```

---
# Baseline result
# Benchmark Report for */home/runner/work/HierarchicalTemporalMemory.jl/HierarchicalTemporalMemory.jl*

## Job Properties
* Time of benchmark: 31 Jul 2020 - 15:2
* Package commit: 172104
* Julia commit: 7f0ee1
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
| `["SP", "1 iteration, global inhibit"]` |   6.660 ms (5%) |            | 114.22 KiB (1%) |          67 |
| `["SP", "1 iteration, local inhibit"]`  |    6.505 s (5%) | 247.156 ms | 624.86 MiB (1%) |    12194979 |
| `["TM", "first 100 steps"]`             | 400.989 ms (5%) |  26.506 ms | 424.85 MiB (1%) |      729318 |
| `["TM", "last 100 steps"]`              | 372.262 ms (5%) |  23.281 ms | 407.11 MiB (1%) |      607670 |

## Benchmark Group List
Here's a list of all the benchmark groups executed by this job:

- `["SP"]`
- `["TM"]`

## Julia versioninfo
```
Julia Version 1.5.0-rc2.0
Commit 7f0ee122d7 (2020-07-27 15:24 UTC)
Platform Info:
  OS: Linux (x86_64-pc-linux-gnu)
      Ubuntu 18.04.4 LTS
  uname: Linux 5.3.0-1032-azure #33~18.04.1-Ubuntu SMP Fri Jun 26 15:01:15 UTC 2020 x86_64 x86_64
  CPU: Intel(R) Xeon(R) Platinum 8171M CPU @ 2.60GHz: 
              speed         user         nice          sys         idle          irq
       #1  2095 MHz      17350 s          0 s       1698 s      31178 s          0 s
       #2  2095 MHz      28742 s          0 s       1722 s      20304 s          0 s
       
  Memory: 6.764884948730469 GB (2818.94921875 MB free)
  Uptime: 524.0 sec
  Load Avg:  1.0  0.86181640625  0.47021484375
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-9.0.1 (ORCJIT, skylake)
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
    CPU MHz:             2095.078
    BogoMIPS:            4190.15
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

