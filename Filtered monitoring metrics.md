<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Those are the wrong metrics. Please reload your previous answer with this new cgroups v2 list i'm providing:

root@device1:/\# ls sys/fs/cgroup/
cgroup.controllers      cpuset.cpus.partition     memory.events.local
cgroup.events           cpuset.mems               memory.high
cgroup.freeze           cpuset.mems.effective     memory.low
cgroup.kill             hugetlb.1GB.current       memory.max
cgroup.max.depth        hugetlb.1GB.events        memory.min
cgroup.max.descendants  hugetlb.1GB.events.local  memory.numa_stat
cgroup.procs            hugetlb.1GB.max           memory.oom.group
cgroup.stat             hugetlb.1GB.rsvd.current  memory.pressure
cgroup.subtree_control  hugetlb.1GB.rsvd.max      memory.stat
cgroup.threads          hugetlb.2MB.current       memory.swap.current
cgroup.type             hugetlb.2MB.events        memory.swap.events
cpu.idle                hugetlb.2MB.events.local  memory.swap.high
cpu.max                 hugetlb.2MB.max           memory.swap.max
cpu.max.burst           hugetlb.2MB.rsvd.current  misc.current
cpu.pressure            hugetlb.2MB.rsvd.max      misc.max
cpu.stat                io.max                    pids.current
cpu.uclamp.max          io.pressure               pids.events
cpu.uclamp.min          io.prio.class             pids.max
cpu.weight              io.stat                   rdma.current
cpu.weight.nice         io.weight                 rdma.max
cpuset.cpus             memory.current
cpuset.cpus.effective   memory.events

Here's a filtered list of **key saturation-focused metrics** from your provided cgroups v2 files, prioritized by their ability to detect resource contention and bottlenecks:

---

## Core Metrics for Saturation Monitoring

| Category | Metric Path | Monitoring Purpose | Critical Thresholds |
| :-- | :-- | :-- | :-- |
| **CPU** | `cpu.pressure` | % time tasks wait for CPU (`some`=partial stalls, `full`=total stalls) | `some &gt;10%` over 1m |
|  | `cpu.stat` (usage_usec) | Total CPU time consumed (identify over-limit groups) | Compare with `cpu.max` quota |
|  | `cpu.max` | Hard CPU limit (quota/period) | Usage nearing quota = saturation risk |
| **Memory** | `memory.current` | Total RAM + swap used | Compare with `memory.high/max` |
|  | `memory.events` (high/oom) | Count of soft/hard limit breaches | `oom &gt;0` = critical |
|  | `memory.swap.current` | Swap usage (indicates memory pressure) | Sudden spikes = thrashing |
|  | `memory.pressure` | Memory reclaim stalls (`some`=partial, `full`=complete) | `some &gt;15%` over 5m |
| **I/O** | `io.pressure` | Block I/O latency stalls | `some &gt;5%` for SSDs, `&gt;10%` for HDDs |
|  | `io.stat` (rbytes/wbytes, rios/wios) | Read/write throughput \& IOPS | Compare with `io.max` limits |
| **PID** | `pids.current` | Process/thread count | Approaching `pids.max` = fork saturation |

---

## Honorable Mentions (Niche Cases)

| Metric | Use Case |
| :-- | :-- |
| `cpuset.cpus.effective` | Detect CPU core isolation failures |
| `memory.numa_stat` | NUMA node imbalance (high latency) |
| `hugetlb.2MB.events` (max) | Huge page allocation failures |

---

## Excluded Metrics (Non-Saturation Reasons)

- `cgroup.*` (except `.events`): Hierarchy control, not resource usage
- `cpu.weight*`/`io.weight`: Priority settings, not saturation indicators
- `memory.events.local`: Redundant with parent cgroup monitoring
- `*.rsvd.*` (hugetlb): Niche reservation tracking

---

### Recommended Alerts (Prometheus Rules)

```yaml
# CPU Pressure
- alert: CGroupsCPUPressure
  expr: rate(cpu_pressure_some_ratio[2m]) &gt; 0.1 # &gt;10% stalled

# Memory Swap Thrashing
- alert: CGroupsSwapUsageSpike
  expr: deriv(memory_swap_current_bytes[5m]) &gt; 1e8 # 100MB/s increase

# I/O Saturation
- alert: CGroupsIOStalled
  expr: rate(io_pressure_some_ratio[2m]) &gt; 0.2 # &gt;20% I/O stalls

# PID Contention
- alert: CGroupsPidLimitNear
  expr: pids_current / pids_max &gt; 0.8 # 80% of PID limit
```

These metrics directly correlate with **resource starvation symptoms** (stalls, OOM kills, queue buildup). Use Telegraf's `cgroup` input plugin to scrape them, adding labels for cgroup hierarchy (e.g., container ID).

