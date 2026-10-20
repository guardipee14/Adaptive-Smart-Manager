extends RefCounted


static func synchronize(data: Dictionary, base_windows: Dictionary) -> void:
    for base_id: String in ["thread_manager", "gpu_manager"]:
        var smart_id := "smart_" + base_id
        var base_definition: Dictionary = base_windows.get(base_id, {})
        if not base_definition.has("requirement"):
            continue

        var requirement = base_definition.requirement
        if not requirement is String and not requirement is Array:
            continue

        var destinations: Array = [data.windows[smart_id]]
        destinations.append_array(data.guides["window_" + smart_id].entries)
        for destination: Dictionary in destinations:
            # Do not share mutable arrays with Data or between guide entries.
            destination.requirement = requirement.duplicate(true) if requirement is Array else requirement
            if base_definition.has("requirement_mode"):
                destination.requirement_mode = base_definition.requirement_mode
            else:
                destination.erase("requirement_mode")
