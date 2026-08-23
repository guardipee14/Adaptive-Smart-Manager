static func get_parent_window(node: Node) -> WindowBase:
    if node == null:
        return null

    if not node.has_meta("adaptive_smart_manager_parent_window"):
        var window = node
        while window and not window.is_in_group("window"):
            window = window.get_parent()

        node.set_meta(
            "adaptive_smart_manager_parent_window",
            window
        )

    return node.get_meta(
        "adaptive_smart_manager_parent_window",
        null
    )
