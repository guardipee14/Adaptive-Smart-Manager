# Adaptive Smart Manager

Adaptive Smart Manager (ASM) is a unified replacement for **Smart Thread Manager** and **Smart GPU Manager** for Upload Labs.

It keeps the familiar player-facing manager workflow while sharing one implementation underneath, fixing allocation/runtime issues found during testing, and exposing a read-only compatibility surface for Adaptive Auto Connector (AAC).

> **Current public build:** `v0.1.0-test20` — release-candidate testing build.

**Reconstructed candidate:** `v0.1.0-test21` (not released; fresh in-game validation pending). It preserves the original test20 manager logic, restores a compiled English translation generated from the CSV, and corrects the stale GPU description in the original binary. GitHub's test20 download differs from the original tested archive; see [recovery provenance](RECOVERY.md).

## What it keeps

- Smart Thread Manager window id: `smart_thread_manager`
- Smart GPU Manager window id: `smart_gpu_manager`
- CPU resource: `clock_speed`
- GPU resource: `gpu_speed`
- Ratio, Demand, and Graph modes
- Manager chaining
- Base `count` / `count/s` toggle
- Existing CPU/GPU unlock requirements and categories
- Existing save-facing manager ids so saved manager windows can migrate

## What ASM improves

- One shared Thread/GPU manager implementation instead of duplicated code.
- Demand-mode shortage handling no longer creates a GHz → MHz → kHz → Hz starvation ladder across later consumers.
- Demand mode can redistribute surplus supply after calculated finite demand is satisfied, so available CPU/GPU does not sit unused when finite targets can accept more.
- Compact Need/Supply presentation using a common promoted Upload Labs unit.
- Thread and GPU managers use the same compact visual language.
- Uncapped GPU targets remain visible in Demand mode without hiding the actual Supply value.
- Graph filters and signal subscriptions are cleaned up when topology/mode ownership changes.
- Defensive handling for transient topology and zero-value states.
- Registration/version handling and compatibility metadata are more robust.
- Read-only `window_binds` / `get_aac_manager_snapshot()` compatibility surface for AAC.

## Current validation

`v0.1.0-test20` has been runtime-tested with:

- Upload Labs `2.2.12`
- Mod Loader `7.0.1`
- Godot `4.6.1`
- 59 finite Smart Thread Manager consumers
- Smart GPU Manager finite + uncapped consumers
- Ratio / Demand / Graph mode switching
- Base `count` / `count/s` switching
- large topology changes while AAC graph validation remained structurally clean

The original test20 package also passed AAC test7's targeted integration checks on September 11, 2026. Those results do not establish that the different GitHub test20 download or reconstructed test21 package has passed a fresh game run. See [test21 verification and build instructions](tests/README.md).

## Installation

1. Remove/disable the original `kuuk-SmartThreadManager` and `kuuk-SmartGPUManager` mods. ASM registers the same window ids and must not run alongside them.
2. Download the current public-test package `guardipee14-AdaptiveSmartManager-v0.1.0-test20.zip` from the public-test announcement/Discord attachment.
3. Verify SHA-256: `b3b8aad369e28ce19874dee6bceec0e07d84de9c3914ac05ed708f7fe66c7dfc`.
4. Place the ZIP in your Upload Labs `mods` folder.
5. Start Upload Labs and verify both Smart Thread Manager and Smart GPU Manager appear normally in your existing save.

Public-test notes and feedback thread: [Issue #1](https://github.com/guardipee14/Adaptive-Smart-Manager/issues/1).

For the default Steam location used during development, the mod folder was:

```text
E:\SteamLibrary\steamapps\common\Upload Labs\mods
```

Your Steam library path may be different.

## Adaptive Auto Connector compatibility

ASM preserves the manager ids/resources AAC expects and exposes a read-only manager snapshot. AAC does **not** receive ownership of manager distribution or automatic connection mutation through this interface.

AAC `v0.1.15-test7` explicitly detects ASM. Its three targeted game checks passed with the original test20 archive in Demand mode (Thread count/s, GPU count); the reconstructed test21 package still needs a load/UI/integration smoke test. AAC does not require manager allocation changes for this package recovery.

## Attribution

Adaptive Smart Manager combines and modifies the Smart Thread Manager / Smart GPU Manager work originally published by **kuuk / Omisse** in [`Omisse/ul-stmmod`](https://github.com/Omisse/ul-stmmod).

The original project is MIT licensed. See [`LICENSE`](LICENSE) and [`NOTICE.md`](NOTICE.md).

## Status

ASM is currently a **release-candidate test build**, not the final `v0.1.0` release. Bug reports should include the Godot log and, when relevant, a screenshot showing the affected manager and connected nodes.
