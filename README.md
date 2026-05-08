# Entropy Depletion RNG Stress Tests

This repository contains bash stress-test harnesses, raw experiment logs, and a Jupyter notebook analysis for evaluating entropy depletion in Linux random number generation under cryptographic workloads.

The project compares `/dev/random`, `/dev/urandom`, and OpenSSL RSA key generation across Ubuntu 18.04.5 LTS, Ubuntu 19.10, and Fedora 40. It measures whether entropy depletion causes delays, how those delays differ across kernels and operating systems, and how much the HAVEGED entropy daemon helps under increasing load.

## Research Goals

- Measure entropy availability through `/proc/sys/kernel/random/entropy_avail`.
- Measure key generation latency for `/dev/random`, `/dev/urandom`, and OpenSSL RSA.
- Compare Linux distributions and kernel generations under the same workload.
- Compare systems with and without HAVEGED.
- Identify whether entropy availability correlates with key generation time.
- Model latency variability and determine whether the timing data follows common distributions.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `analysis/analysis-entropy-depletion-rng.ipynb` | Main notebook containing the full analysis, charts, statistical summaries, interpretation, and conclusion. |
| `analysis/data/` | Raw logs and cleaned CPU metrics for each OS and HAVEGED experiment run. |
| `rng_stress_main_mk.sh` | Main multi-source stress harness. It tests `/dev/random`, `/dev/urandom`, and RSA, records entropy and wait times, and waits between test phases. |
| `rng_stress_main.sh` | Earlier single-workload harness for repeated random generation and entropy logging. |
| `rng_stress_test_basic.sh` | Basic OpenSSL random key generation test with entropy logging. |
| `rng_stress_test_prl_keylog.sh` | Parallel OpenSSL test that logs keys and drains `/dev/random`. |
| `rng_stress_prl_manualwait_RSA.sh` | Experimental version with manual waiting for entropy before generation. The script notes that this is unnecessary because `/dev/random` already blocks when required. |
| `entropy_recovery.sh` | Tracks entropy recovery once per second for 10 minutes. |
| `helpers.sh` | Setup notes for installing `rng-tools`, `haveged`, and `sysstat`, starting entropy services, checking duplicate keys, and collecting CPU metrics with `sar`. |
| `csv_cleaner.py` | Utility used to convert whitespace-delimited `sar` output into CSV. |
| `RNG REF.txt` | Reference links used during the research. |

## Experimental Design

Each experiment runs parallel key-generation workloads and records:

- Wait time per key generation attempt in milliseconds.
- Entropy before and after generation.
- Execution duration for each source.
- OpenSSL stderr output for RSA generation.
- CPU utilization from `sar` where available.

The main harness tests three generation paths:

- `random`: reads `KEY_SIZE` bytes from `/dev/random` and base64 encodes them with OpenSSL.
- `urandom`: reads `KEY_SIZE` bytes from `/dev/urandom` and base64 encodes them with OpenSSL.
- `rsa`: runs `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$KEY_SIZE`.

Important implementation note: `KEY_SIZE` is used as a byte count for `/dev/random` and `/dev/urandom`, but as a bit count for OpenSSL RSA. For example, `KEY_SIZE=2048` means 2048 bytes for raw random reads and 2048-bit RSA keys.

## Tested Systems

| System | Kernel | CPU | Memory |
| --- | --- | --- | --- |
| Ubuntu 18.04.5 LTS | Linux 5.4.0-42 | Intel Core i5-8400 @ 2.80 GHz, 6 cores | 62.7 GB |
| Ubuntu 19.10 | Linux 5.3.0-18 | Intel Core i7-11700K @ 3.60 GHz, 16 cores | 62.4 GB |
| Fedora 40 | Linux 6.11.8-200 | Intel Core i7-11700K @ 3.60 GHz, 16 cores | 64 GB |

## Workloads

| Dataset group | HAVEGED | Calls per process | Parallel processes | Configured `KEY_SIZE` |
| --- | --- | ---: | ---: | ---: |
| `01.*` baseline runs | No | 100 | 10 | 512 |
| `02.* - Haveged - 1` | Yes | 100 | 10 | 512 |
| `03.* - Haveged - 2` | Yes | 100 | 10 | 2048 |
| `04.* - Haveged - 3` | Yes | 1000 | 1000 | 2048 |

The Run 3 workload generates up to 1,000,000 observations per source per OS and is intentionally extreme.

## Main Findings

Fedora 40 showed the most stable entropy behavior. In every Fedora dataset, entropy stayed fixed at `256`, and `/dev/random` and `/dev/urandom` behaved nearly identically. The notebook attributes this to newer Linux RNG behavior, including changes around Linux 5.17 and 5.18 that reduce the older practical distinction between `/dev/random` and `/dev/urandom` after initialization.

Ubuntu 18.04.5 LTS and Ubuntu 19.10 showed severe `/dev/random` delays without HAVEGED. Baseline `/dev/random` generation averaged roughly 3 to 4 hours per operation in the collected logs, while `/dev/urandom` and RSA remained in the millisecond range.

HAVEGED dramatically improved Ubuntu `/dev/random` performance in normal workloads. On Ubuntu 18.04.5, `/dev/random` improved from about 11,073,650 ms average without HAVEGED to 10.14 ms in HAVEGED Run 1. On Ubuntu 19.10, it improved from about 14,776,278 ms to 4.33 ms.

Fedora 40 remained strong with or without HAVEGED. HAVEGED did not materially change Fedora entropy readings because the entropy value was already constant and stable.

Under the extreme Run 3 workload, CPU and scheduling pressure became important. Ubuntu 19.10 had the best average RSA time in the successful Run 3 data, while Fedora 40 kept `/dev/random` and `/dev/urandom` almost identical. Ubuntu 18.04.5 degraded the most.

The first Ubuntu 19.10 Run 3 attempt crashed during RSA generation with a segmentation fault. The rerun completed successfully and is stored separately from the crashed dataset.

## Baseline Results Without HAVEGED

Mean wait time in milliseconds:

| OS | `/dev/urandom` | `/dev/random` | RSA | Entropy behavior |
| --- | ---: | ---: | ---: | --- |
| Ubuntu 18.04.5 LTS | 7.02 | 11,073,650 | 14.59 | `/dev/random` entropy collapsed near zero, causing multi-hour waits. |
| Ubuntu 19.10 | 4.65 | 14,776,278 | 7.69 | `/dev/random` also suffered extreme entropy starvation. |
| Fedora 40 | 3.82 | 3.85 | 9.15 | Entropy stayed fixed at 256; `/dev/random` and `/dev/urandom` performed similarly. |

Key baseline conclusions:

- `/dev/urandom` stayed fast on all systems.
- `/dev/random` was impractical on the Ubuntu baseline systems during this workload.
- Fedora 40 did not show the same blocking behavior for `/dev/random`.
- RSA timing was slower than `/dev/urandom` but far less affected than Ubuntu `/dev/random` in the baseline tests.

## HAVEGED Run 1: 100 Calls, 10 Processes, `KEY_SIZE=512`

Mean wait time in milliseconds:

| OS | `/dev/urandom` | `/dev/random` | RSA | Summary |
| --- | ---: | ---: | ---: | --- |
| Ubuntu 18.04.5 LTS | 6.44 | 10.14 | 12.19 | HAVEGED removed the multi-hour `/dev/random` delay, but variability remained higher than Fedora. |
| Ubuntu 19.10 | 4.38 | 4.33 | 7.69 | Faster and more stable than Ubuntu 18.04.5. |
| Fedora 40 | 3.74 | 3.80 | 8.34 | Fastest for raw random sources and lowest variability. |

## HAVEGED Run 2: 100 Calls, 10 Processes, `KEY_SIZE=2048`

Mean wait time in milliseconds:

| OS | `/dev/urandom` | `/dev/random` | RSA | Summary |
| --- | ---: | ---: | ---: | --- |
| Ubuntu 18.04.5 LTS | 6.45 | 25.48 | 112.45 | RSA and `/dev/random` became much more variable with larger keys. |
| Ubuntu 19.10 | 3.98 | 5.96 | 67.50 | Better than Ubuntu 18.04.5, especially for `/dev/random` and RSA. |
| Fedora 40 | 3.72 | 3.82 | 61.00 | Fastest overall and most stable for this workload. |

## HAVEGED Run 3: 1000 Calls, 1000 Processes, `KEY_SIZE=2048`

Mean wait time in milliseconds:

| OS | `/dev/urandom` | `/dev/random` | RSA | Summary |
| --- | ---: | ---: | ---: | --- |
| Ubuntu 18.04.5 LTS | 542.44 | 4,294.44 | 12,498.47 | Slowest and most variable, with extreme RSA outliers up to 132,438 ms. |
| Ubuntu 19.10 | 368.05 | 3,845.83 | 4,689.10 | Best successful RSA average and much better scalability than Ubuntu 18.04.5. |
| Fedora 40 | 442.53 | 449.58 | 5,441.01 | `/dev/random` and `/dev/urandom` stayed nearly identical; RSA was slower than Ubuntu 19.10 but much better than Ubuntu 18.04.5. |

Run 3 changed the dominant bottleneck. Entropy still mattered, especially for Ubuntu `/dev/random`, but CPU contention and process scheduling also shaped the results.

## Statistical and Distribution Analysis

The notebook compares entropy and key generation time across operating systems using summary statistics and ANOVA. The differences across OSes were large for both entropy levels and key generation times, especially for `/dev/random`.

The notebook also fits Exponential, Pareto, and Lognormal distributions to key generation times:

- Lognormal was the best fit for most datasets.
- Ubuntu 18.04.5 and Ubuntu 19.10 `/dev/random` baseline timing fit Lognormal especially well.
- Exponential was consistently a poor fit, so the delays do not look like a memoryless process.
- Pareto generally failed to fit the observations, suggesting the data is heavy-tailed but not well described by a simple Pareto model.
- Fedora 40 timing distributions were stable but did not fit the tested distributions cleanly, implying the timing behavior is influenced by system-level scheduling and kernel behavior rather than a simple random process.

## Interpretation

The experiments support four broad conclusions:

1. Entropy depletion can make `/dev/random` unusably slow on older or differently configured Linux systems under concurrent cryptographic load.
2. `/dev/urandom` remains consistently fast in these tests and was not materially affected by entropy depletion in the same way.
3. HAVEGED is highly effective for Ubuntu systems in normal and medium workloads, reducing `/dev/random` waits from hours to milliseconds.
4. Newer kernel RNG behavior, represented here by Fedora 40, makes `/dev/random` and `/dev/urandom` behave similarly after initialization and keeps entropy readings stable under load.

For cryptographic workloads, this means entropy management is both a security and performance concern. Systems with poor entropy replenishment can suffer severe latency spikes, while systems with stable RNG behavior are far more predictable under load.

## Reproducing the Experiments

Use a dedicated test machine or VM. The high-concurrency workloads can consume substantial CPU, block for long periods, and in one recorded Ubuntu 19.10 run caused a segmentation fault during RSA generation.

Install dependencies:

```bash
# Ubuntu
sudo apt update
sudo apt install rng-tools haveged sysstat -y

# Fedora
sudo dnf install rng-tools haveged sysstat -y
```

Start entropy services when testing HAVEGED:

```bash
sudo rngd -r /dev/urandom
sudo systemctl start haveged
```

Collect CPU metrics in another terminal:

```bash
sar -u 1 > performance_metrics.txt
```

Run the main harness:

```bash
chmod +x rng_stress_main_mk.sh
./rng_stress_main_mk.sh
```

The script writes these logs for each source:

- `*_wait_log.txt`: generation duration in milliseconds.
- `*_entropy_log.txt`: entropy readings.
- `*_error_log.txt`: stderr and errors. RSA logs include OpenSSL progress characters such as `.` and `+`; those are not necessarily failures.
- `*_key_log.txt`: generated key material for duplicate checks.
- `execution_time_log.txt`: total duration for each source function.

To check duplicate generated keys:

```bash
sort key_log.txt | uniq -d > duplicate_keys.txt
```

To inspect entropy recovery:

```bash
chmod +x entropy_recovery.sh
./entropy_recovery.sh
```

## Data Notes and Caveats

- The datasets include both successful and crashed runs. `analysis/data/04. Ubuntu 19.10 - Haveged - 3 - Crashed/exception_terminal.txt` records the segmentation fault during RSA generation.
- RSA stderr logs contain OpenSSL progress output and should not be interpreted as one error per line.
- Baseline Ubuntu `/dev/random` runs produced extremely long wait times, so running those tests as-is can take hours.
- Fedora 40 reports entropy as a constant 256 in these logs. This is treated as a kernel RNG behavior observation, not as evidence that Fedora has less usable randomness.
- The raw key logs contain generated cryptographic material from experiments. Treat them as test artifacts only.

## References

The research notes in `RNG REF.txt` include background reading on Linux entropy, `/dev/random` versus `/dev/urandom`, entropy starvation, key generation, and CSPRNG behavior. The notebook also references Linux RNG changes discussed at:

- https://www.zx2c4.com/projects/linux-rng-5.17-5.18/

## License

This project is released under the MIT License. See `LICENSE`.
