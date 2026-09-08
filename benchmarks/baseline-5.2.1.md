# Untis+ performance baseline — 5.2.1

Recorded: 2026-09-08

## Reproducible environment

- Flutter 3.47.0 stable
- Dart 3.13.0
- Windows host, Android debug build
- fllama pinned to `18a8baf67e4e93d8f835bdf1da36a0895be6692b`

## Build baseline

| Artifact | Bytes | Notes |
| --- | ---: | --- |
| Android universal debug APK | 276,085,152 | Includes debug runtime and all ABIs; not a release-size target |

## Device measurements still required

The following numbers cannot be represented honestly without profiling on the
target hardware. Record them before declaring the corresponding performance
goal complete:

| Metric | Mid-range Android | Current iOS | Method |
| --- | ---: | ---: | --- |
| Process start to first interactive screen | pending | pending | Flutter DevTools startup trace |
| First frame to cached timetable | pending | pending | `TimelineTask` around cache hydration |
| Manual timetable refresh | pending | pending | request trace ID and stopwatch |
| Requests per week change | pending | pending | debug transport log |
| 99th-percentile timetable frame time | pending | pending | profile-mode frame chart |
| Memory, animations enabled/disabled | pending | pending | DevTools memory snapshots |
| Universal release package size | pending | n/a | signed release artifact |
| ABI-specific release size | pending | n/a | `--split-per-abi` artifacts |

The local split-release measurement is pending because Windows Application
Control blocked Flutter's trusted `gen_snapshot.exe` before AOT compilation.
The debug build and web release build succeed; CI/Linux should produce the
release-size artifacts without weakening the host policy.

## Comparison rules

- Use the same accounts, cached weeks, animation settings, device power mode,
  and build mode for before/after comparisons.
- Never record credentials, session IDs, school names, teacher names, or raw
  WebUntis payloads in benchmark output.
- A failed refresh must retain cached data and is measured separately from a
  successful live refresh.
