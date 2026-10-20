extends SceneTree

const WDATA := preload("res://smart_window_data.gd")
const DISTRIBUTION := preload("res://distribution_modes.gd")
var checks := 0
var failures := 0
var fixtures: Array[WindowBase] = []


class LegacyWindow extends WindowBase:
    var goal := 12.0
    func get_goal() -> float:
        return goal


class ManagerWindow extends WindowBase:
    var demand := 42.0


class WorkProcess extends Node:
    var goal_obj: Node
    var speed_obj: Node
    var resources: Array[ResourceContainer] = []
    var should_consume := true


class WorkGoal extends Node:
    var value := 12.0


class WorkSpeed extends Node:
    var resource: ResourceContainer
    var rate := 2.0
    var inf_speed := false


func _init() -> void:
    call_deferred("run")


func run() -> void:
    var modern := make_modern()
    var data = modern.data
    check(data.role == WDATA.SmartWindowRoles.CONSUMER, "3.0 process is a finite consumer")
    near(data.get_demand(), 30.0, "production / required * goal / rate")
    near(data.get_count_demand(), 24.0, "stock / required * goal / rate")
    data.set_count(300.0)
    near(modern.speed.count, 300.0, "allocation reaches managed speed input")

    # Unrelated material buffers must not cap the actual Process inputs.
    var buffer := add_input(modern.window, "unrelated-buffer", 0, 0.0, 0.0, 1.0)
    data.update()
    check(not data.dependent.has(buffer.id), "unrelated buffer excluded")
    near(data.get_demand(), 30.0, "unrelated empty buffer does not force zero demand")
    modern.material.required = 4.0
    data.update()
    near(data.get_demand(), 15.0, "required changes are refreshed")
    near(data.get_count_demand(), 12.0, "stock normalization refreshed")
    modern.goal.value = 20.0
    near(data.get_demand(), 25.0, "goal changes read live")
    modern.work_speed.rate = 4.0
    near(data.get_demand(), 12.5, "speed conversion changes read live")
    modern.window.paused = true
    near(data.get_demand(), 0.0, "paused consumer needs no CPU")
    modern.window.paused = false
    modern.work_speed.rate = 0.0
    near(data.get_demand(), 0.0, "zero speed conversion is safe")
    modern.work_speed.rate = 2.0

    var second := add_input(modern.window, "second-material", 3, 2.0, 6.0, 2.0)
    modern.process.resources.append(second)
    data.update()
    near(data.get_demand(), 10.0, "multiple materials use production bottleneck")
    near(data.get_count_demand(), 20.0, "multiple materials use stock bottleneck")
    second.required = 0.0
    data.update()
    near(data.get_demand(), 25.0, "zero-required material ignored")
    second.required = -1.0
    data.update()
    near(data.get_demand(), 25.0, "negative-required material ignored")
    modern.material.production = 0.0
    near(data.get_demand(), 0.0, "empty production is finite zero, not uncapped")
    check(data.role == WDATA.SmartWindowRoles.CONSUMER, "starved machine retains finite role")
    modern.process.should_consume = false
    data.update()
    check(data.role == WDATA.SmartWindowRoles.STORAGE, "non-consuming process is genuinely uncapped")
    modern.process.should_consume = true
    data.update()
    check(data.role == WDATA.SmartWindowRoles.CONSUMER, "role returns when consumption resumes")

    var legacy := LegacyWindow.new()
    prepare_window(legacy)
    var legacy_speed := add_input(legacy, "legacy-speed", 1)
    add_input(legacy, "legacy-material", 0, 10.0, 8.0, 2.0)
    var legacy_data = WDATA.new(legacy)
    legacy_data.set_containers([legacy_speed.id])
    check(legacy_data.role == WDATA.SmartWindowRoles.CONSUMER, "legacy get_goal supported")
    near(legacy_data.get_demand(), 60.0, "legacy production demand preserved")
    near(legacy_data.get_count_demand(), 48.0, "legacy stock demand preserved")

    var seller := WindowBase.new()
    prepare_window(seller)
    var seller_speed := add_input(seller, "seller-speed", 1)
    var seller_data = WDATA.new(seller)
    seller_data.set_containers([seller_speed.id])
    check(seller_data.role == WDATA.SmartWindowRoles.STORAGE, "seller remains uncapped")
    var chained := ManagerWindow.new()
    prepare_window(chained)
    var chain_speed := add_input(chained, "chain-speed", 1)
    var chain_data = WDATA.new(chained)
    chain_data.set_containers([chain_speed.id])
    check(chain_data.role == WDATA.SmartWindowRoles.MANAGER, "manager chain role preserved")
    near(chain_data.get_demand(), 42.0, "manager chain demand preserved")

    var no_material := make_modern()
    no_material.process.resources.clear()
    no_material.data.update()
    check(no_material.data.role == WDATA.SmartWindowRoles.STORAGE, "speed-only miner remains uncapped")
    var mismatch := make_modern()
    var other_speed := add_input(mismatch.window, "other-speed", 1)
    mismatch.data.set_containers([other_speed.id])
    check(mismatch.data.role == WDATA.SmartWindowRoles.STORAGE, "unrelated speed port not mistaken for Process speed")
    mismatch.data.set_containers([])
    near(mismatch.data.get_demand(), 0.0, "disconnected binding is safe")

    # Reproduce the reported 25-target topology: 24 finite CPU machines plus
    # one processing seller, not 25 falsely uncapped targets.
    var state := {"wdata": {}, "demands": {}, "old_demands": {}, "consumers": [], "managers": [], "storages": ["seller"], "storage_connections": 1}
    var total := 0.0
    for index in range(24):
        var fixture := make_modern()
        fixture.goal.value = 100.0
        fixture.work_speed.rate = 1.0
        fixture.material.required = 1.0
        fixture.material.production = index + 1.0
        fixture.material.count = index + 1.0
        fixture.data.update()
        var key := "processor" + str(index)
        state.wdata[key] = fixture.data
        state.consumers.append(key)
        state.demands[key] = fixture.data.get_demand()
        state.old_demands[key] = state.demands[key]
        total += state.demands[key]
        check(fixture.data.role == WDATA.SmartWindowRoles.CONSUMER, "finite consumer %d" % index)
    state.wdata.seller = seller_data
    state.demands.seller = 0.0
    state.old_demands.seller = 0.0
    near(total, 30000.0, "25-target total finite CPU demand")
    for mode in [DISTRIBUTION.distribution_ratio, DISTRIBUTION.distribution_demand, DISTRIBUTION.distribution_graph]:
        state.line_suppliers = state.consumers
        state.line_receivers = []
        mode.call(1000000.0, state)
        near(state.demand, total, "all modes report finite demand")
        near(seller_speed.count, 970000.0, "only true surplus reaches seller")
        near(allocated(state), 1000000.0, "allocation conserves supply")
        for key in state.consumers:
            near(state.wdata[key].own_sources[0].count, state.demands[key], "finite demand satisfied")
    DISTRIBUTION.distribution_demand(1000.0, state)
    near(allocated(state), 1000.0, "shortage conserves supply")
    near(seller_speed.count, 0.0, "no seller allocation during finite shortage")
    DISTRIBUTION.distribution_demand(0.0, state)
    near(allocated(state), 0.0, "zero supply clears every target")

    for window in fixtures:
        window.free()
    fixtures.clear()
    print("ASM DEMAND: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)


func prepare_window(window: WindowBase) -> void:
    window.add_to_group("window")
    fixtures.append(window)


func add_input(window: WindowBase, id: String, type: int, production: float = 0.0, count: float = 0.0, required: float = 1.0) -> ResourceContainer:
    var container := ResourceContainer.new()
    container.id = id
    container.type = type
    container.production = production
    container.count = count
    container.required = required
    container.add_to_group("input")
    window.add_child(container)
    window.containers.append(container)
    return container


func make_modern() -> Dictionary:
    var window := WindowBase.new()
    prepare_window(window)
    var speed := add_input(window, "cpu-speed", 1)
    var material := add_input(window, "material", 0, 10.0, 8.0, 2.0)
    var process := WorkProcess.new()
    process.name = "Process"
    var goal := WorkGoal.new()
    var work_speed := WorkSpeed.new()
    work_speed.resource = speed
    process.add_child(goal)
    process.add_child(work_speed)
    process.goal_obj = goal
    process.speed_obj = work_speed
    process.resources.append(material)
    window.add_child(process)
    var data = WDATA.new(window)
    data.set_containers([speed.id])
    return {"window": window, "speed": speed, "material": material, "process": process, "goal": goal, "work_speed": work_speed, "data": data}


func allocated(state: Dictionary) -> float:
    var total := 0.0
    for data in state.wdata.values():
        for source in data.own_sources:
            total += source.count
    return total


func near(actual: float, expected: float, label: String) -> void:
    check(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [label, expected, actual])


func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(label)
