extends Node

const MOD_DIR := "guardipee14-AdaptiveSmartManager"
const MOD_ID := "guardipee14-AdaptiveSmartManager"
const MOD_VERSION := "0.1.0"
const LOG_NAME := "guardipee14:ASM:Main"
const RUNTIME_PREFLIGHT_PATHS := [
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/global/asm_utils.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/global/window_graph.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/global/smart_window_graph.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/global/smart_window_data.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/global/distribution_modes.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/smart_resource_container.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/option_desktop_button.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scripts/toggle_desktop_button.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scenes/windows/window_adaptive_smart_manager.gd",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scenes/windows/window_smart_thread_manager.tscn",
    "res://mods-unpacked/guardipee14-AdaptiveSmartManager/scenes/windows/window_smart_gpu_manager.tscn"
]

var mod_dir_path := ""
var translations_dir_path := ""


static func _normalized_versions(value) -> Array[String]:
    var result: Array[String] = []

    if value is Array:
        for item in value:
            var version := str(item).strip_edges()
            if not version.is_empty():
                result.append(version)
        return result

    if value is String:
        for item in str(value).split(",", false):
            var version := str(item).strip_edges()
            if not version.is_empty():
                result.append(version)

    return result


static func _get_compat_array(manifest: Dictionary) -> Array[String]:
    var godot: Dictionary = manifest.get("extra", {}).get("godot", {})
    return _normalized_versions(godot.get("compatible_game_version", []))


static func is_good_version(manifest: Dictionary) -> bool:
    var project_version := str(
        ProjectSettings.get_setting("application/config/version", "0.0.0")
    )
    return _get_compat_array(manifest).has(project_version)


func _init() -> void:
    mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)

    var manifest := _read_json_dictionary(
        mod_dir_path.path_join("manifest.json"),
        "manifest"
    )

    if manifest.is_empty():
        ModLoaderLog.error(
            "Manifest could not be loaded. Initialization stopped.",
            LOG_NAME
        )
        return

    if not is_good_version(manifest):
        ModLoaderLog.warning(
            "Game version '%s' is not in tested versions %s. Loading is allowed for compatibility testing." % [
                ProjectSettings.get_setting("application/config/version", "0.0.0"),
                str(_get_compat_array(manifest))
            ],
            LOG_NAME
        )

    _add_translations()

    ModLoaderLog.success(
        "Adaptive Smart Manager initialized, version: %s (test20 compact unified Demand layout)" % MOD_VERSION,
        LOG_NAME
    )
    ModLoaderLog.info(
        "Preserving window ids: smart_thread_manager + smart_gpu_manager; AAC compatibility surface enabled.",
        LOG_NAME
    )


func _ready() -> void:
    ModLoaderLog.info("Unified window registration started...", LOG_NAME)

    if not has_node("/root/Data"):
        ModLoaderLog.error(
            "No Data singleton found. Window registration stopped.",
            LOG_NAME
        )
        return

    if not _validate_runtime_resources():
        ModLoaderLog.error(
            "Runtime preflight failed. No Adaptive Smart Manager windows were registered.",
            LOG_NAME
        )
        return

    _add_to_data()


func _validate_runtime_resources() -> bool:
    var success := true

    for raw_path in RUNTIME_PREFLIGHT_PATHS:
        var path := str(raw_path)

        if not ResourceLoader.exists(path):
            ModLoaderLog.error(
                "Runtime preflight resource does not exist: %s" % path,
                LOG_NAME
            )
            success = false
            continue

        var loaded_resource = load(path)
        if loaded_resource == null:
            ModLoaderLog.error(
                "Runtime preflight could not load: %s" % path,
                LOG_NAME
            )
            success = false
            continue

        if loaded_resource is Script:
            var script_resource: Script = loaded_resource
            if not script_resource.can_instantiate():
                ModLoaderLog.error(
                    "Runtime preflight script cannot instantiate: %s" % path,
                    LOG_NAME
                )
                success = false

    if success:
        ModLoaderLog.success(
            "Runtime preflight passed for unified manager scripts/scenes.",
            LOG_NAME
        )

    return success


func _add_translations() -> void:
    translations_dir_path = mod_dir_path.path_join("translations")

    # Use the res:// resource path directly so this works for mounted ZIP mods,
    # not only physically unpacked directories.
    var names := Array(DirAccess.get_files_at(translations_dir_path))
    for raw_name in names:
        var name := str(raw_name)
        if name.ends_with(".translation"):
            ModLoaderMod.add_translation(
                translations_dir_path.path_join(name)
            )


func _add_to_data() -> void:
    var path := mod_dir_path.path_join("data/asm_data.json")
    var data := _read_json_dictionary(path, "data")

    if data.is_empty():
        ModLoaderLog.error(
            "Unified data registry could not be loaded.",
            LOG_NAME
        )
        return

    var success := true
    var registered_windows: Array[String] = []

    for raw_key in data.keys():
        var key := str(raw_key)
        var incoming = data[raw_key]

        if not incoming is Dictionary:
            ModLoaderLog.error(
                "Data.%s is not a dictionary. Skipping." % key,
                LOG_NAME
            )
            success = false
            continue

        var registry = Data.get(key)
        if not registry is Dictionary:
            ModLoaderLog.error(
                "Data.%s is unavailable or is not a dictionary. Skipping." % key,
                LOG_NAME
            )
            success = false
            continue

        for raw_entry in incoming.keys():
            var entry := str(raw_entry)

            # Bug fix from the original mods: check the registry KEY, not the
            # incoming dictionary VALUE. Never overwrite another registration.
            if registry.has(entry):
                ModLoaderLog.error(
                    "Data.%s.%s already exists. Adaptive Smart Manager will not overwrite it. Remove the original Smart Thread/GPU Manager mods before using ASM." % [
                        key,
                        entry
                    ],
                    LOG_NAME
                )
                success = false
                continue

            registry[entry] = incoming[raw_entry]

            if key == "windows":
                registered_windows.append(entry)

    for entry in registered_windows:
        if not Attributes.window_attributes.has(entry):
            Attributes.window_attributes[entry] = {}

        var attributes = Data.windows[entry].get("attributes", {})
        if attributes is Dictionary:
            for raw_attr_name in attributes.keys():
                var attr_name := str(raw_attr_name)
                Attributes.window_attributes[entry][attr_name] = Attribute.new(
                    attributes[raw_attr_name]
                )

    if success and registered_windows.size() == 2:
        ModLoaderLog.success(
            "Registered unified Smart Thread + Smart GPU Manager windows.",
            LOG_NAME
        )
    elif not registered_windows.is_empty():
        ModLoaderLog.warning(
            "Adaptive Smart Manager registered only %d window(s); check for conflicting legacy mods." % registered_windows.size(),
            LOG_NAME
        )
    else:
        ModLoaderLog.error(
            "No Adaptive Smart Manager windows were registered.",
            LOG_NAME
        )


func get_aac_compatibility_info() -> Dictionary:
    return {
        "provider": MOD_ID,
        "version": MOD_VERSION,
        "window_ids": [
            "smart_thread_manager",
            "smart_gpu_manager"
        ],
        "resources": [
            "clock_speed",
            "gpu_speed"
        ],
        "semantics": {
            "count": "live_manager_supply",
            "demand": "finite_bound_window_demand",
            "uncapped_target_count": "connected_targets_without_a_finite_material_derived_cap",
            "window_binds": "read_only_compatibility_view"
        },
        "topology_control": false
    }


func _read_json_dictionary(path: String, label: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        ModLoaderLog.error(
            "%s file not found: %s" % [label.capitalize(), path],
            LOG_NAME
        )
        return {}

    var text := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(text)

    if not parsed is Dictionary:
        ModLoaderLog.error(
            "%s JSON is invalid or is not a dictionary: %s" % [
                label.capitalize(),
                path
            ],
            LOG_NAME
        )
        return {}

    return parsed
