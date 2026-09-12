# Changelog

## v0.1.0-test21

Unpublished package-reconstruction candidate; fresh in-game validation pending.

### Reconciled

- Preserve original test20 gameplay, scenes, manager ids/resources and CSV text.
- Include a compiled English translation, previously absent from the GitHub source package. All 15 messages now match the CSV; the original binary's GPU description incorrectly said "clock-consumers" and now uses the existing CSV's "GPU-speed consumers" wording.
- Identify test21 in the startup log and manifest description while retaining manifest version `0.1.0` and the repository website URL.
- Include README alongside LICENSE and NOTICE in the package.
- Add isolated translation compile/verify tooling and exact 19-file package/source verification, with optional original-test20 gameplay comparison.
- Require release labels to match the runtime build and refuse overwriting existing local artifacts. Missing compiled translations fail packaging. Release-request automation is unchanged.

### Validation scope

- Godot 4.6.1 loads the rebuilt translation and verifies all 15 CSV messages.
- Original test20 + AAC test7 passed the earlier three targeted game checks; this is not a new test21 game result.
- No distribution logic, scene behavior, save-facing ids, AAC implementation or installed mod was changed by this packaging work.

## v0.1.0-test20

Current release-candidate test build.

### Unified manager

- Unified Smart Thread Manager and Smart GPU Manager behind one implementation.
- Preserved legacy manager window ids and CPU/GPU resource contracts.
- Preserved Ratio, Demand, Graph, manager chaining, and Base count/count-s controls.

### Allocation fixes

- Fixed the Demand shortage path that could allocate ~90% of each remaining remainder, creating a GHz → MHz → kHz → Hz → zero starvation ladder across later consumers.
- Fairly shares the unsatisfied finite-consumer tail when total demand exceeds supply.
- Redistributes surplus Demand supply after finite calculated need is satisfied so available resource remains usable.
- Retained explicit uncapped/storage handling for GPU targets.
- Added defensive zero-value and transient-topology guards.

### Graph/runtime fixes

- Rebuilds Graph filters instead of retaining stale topology entries.
- Disposes Graph signal/listener ownership when leaving Graph mode or deleting the manager.
- Improved registration/version handling and defensive compatibility metadata.

### UI

- Restored clickable Mode and Base controls.
- Added live Need/Supply status.
- Normalized Need/Supply comparisons to one naturally promoted Upload Labs unit.
- Made Smart Thread and Smart GPU Manager layouts compact and consistent.
- Shows uncapped/starved state without hiding Supply information.

### Diagnostics / compatibility

- Added compact distribution diagnostics for supply, finite demand, allocation, headroom/over-allocation, starvation, and low allocations.
- Added read-only AAC compatibility surface (`window_binds` and `get_aac_manager_snapshot()`).
- No AAC ownership of manager distribution or topology mutation.
