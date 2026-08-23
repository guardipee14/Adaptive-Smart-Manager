# Changelog

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
