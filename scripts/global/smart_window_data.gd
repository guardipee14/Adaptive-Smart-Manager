extends RefCounted

enum SmartWindowRoles {
    ARTIFACT,
    CONSUMER,
    STORAGE,
    MANAGER,
}

var window: WindowBase
var inputs: Dictionary[String, ResourceContainer]
var role: SmartWindowRoles = SmartWindowRoles.ARTIFACT

var provided: Array = []
var dependent: Array = []
var container_data: Dictionary[String, SmartContainerData]

# Read-only compatibility alias used by Adaptive Auto Connector's validator.
# It intentionally exposes the live ResourceContainer objects that correspond
# to this manager's own supplied inputs without giving AAC mutation authority.
var own_sources: Array:
    get:
        var result: Array = []
        for name in provided:
            if inputs.has(name):
                result.append(inputs[name])
        return result


func _init(target_window: WindowBase) -> void:
    window = target_window

    for container: ResourceContainer in window.containers.filter(
        func(c): return c.is_in_group("input")
    ):
        inputs.set(container.id, container)

    set_containers()

    if "demand" in window:
        role = SmartWindowRoles.MANAGER
    elif window.has_method("get_goal") and not dependent.is_empty():
        role = SmartWindowRoles.CONSUMER
    elif window.is_in_group("window"):
        role = SmartWindowRoles.STORAGE
    else:
        role = SmartWindowRoles.ARTIFACT


func set_containers(sources: Array = []) -> void:
    provided = inputs.keys().filter(sources.has)
    dependent = inputs.keys().filter(
        func(name):
            return (
                not provided.has(name)
                and _is_material(inputs[name])
            )
    )

    for name in provided:
        container_data.erase(name)

    for name in dependent:
        if not container_data.has(name):
            container_data[name] = SmartContainerData.new(inputs[name])


func get_demand() -> float:
    if provided.is_empty():
        return 0.0

    if role == SmartWindowRoles.MANAGER:
        return float(window.demand)

    return get_min_production_ratio() * get_goal()


func get_count_demand() -> float:
    if provided.is_empty():
        return 0.0

    if role == SmartWindowRoles.MANAGER:
        return float(window.demand)

    return get_min_count_ratio() * get_goal()


func set_count(value: float) -> void:
    var size := provided.size()

    # Defensive fix for transient topology updates.
    if size <= 0:
        return

    var split_value := value / float(size)
    for container in provided.map(
        func(name): return inputs[name]
    ):
        container.count = split_value


func get_min_production_ratio() -> float:
    if dependent.is_empty():
        return 0.0

    if dependent.size() == 1:
        return container_data[dependent[0]].get_production_ratio()

    return dependent.map(
        func(name): return container_data[name].get_production_ratio()
    ).reduce(minf)


func get_min_count_ratio() -> float:
    if dependent.is_empty():
        return 0.0

    if dependent.size() == 1:
        return container_data[dependent[0]].get_count_ratio()

    return dependent.map(
        func(name): return container_data[name].get_count_ratio()
    ).reduce(minf)


func get_goal() -> float:
    if role == SmartWindowRoles.CONSUMER:
        return float(window.get_goal())
    return 0.0


func update() -> void:
    # Kept for compatibility with the original Smart Manager data object.
    # Runtime demand normalization intentionally remains cached after binding,
    # matching the original 3.0.0 behavior validated during ASM testing.
    for data in container_data.values():
        data.update()


func _is_material(container: ResourceContainer) -> bool:
    return (
        container.type == Utils.resource_types.MATERIAL
        or container.type == Utils.resource_types.MATERIAL_LIMITED
    )


class SmartContainerData extends RefCounted:
    var container: ResourceContainer
    var multiplier: float = 0.0

    func _init(target: ResourceContainer) -> void:
        container = target
        multiplier = _get_multiplier()

    func get_production_ratio() -> float:
        return multiplier * float(container.production)

    func get_count_ratio() -> float:
        return multiplier * float(container.count)

    func _get_multiplier() -> float:
        var divisor := (
            float(container.required)
            if not is_zero_approx(float(container.required))
            else 1.0
        )
        return 1.0 / divisor

    func update() -> void:
        multiplier = _get_multiplier()
