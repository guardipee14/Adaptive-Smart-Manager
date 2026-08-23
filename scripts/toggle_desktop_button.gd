extends DesktopButton

# Preserve the original Smart Manager DesktopButton interaction code, but keep
# the manager control clickable at every desktop zoom level.

func _ready() -> void:
    var callback := Callable(self, "_on_distance_level_set")
    if not Signals.distance_level_set.is_connected(callback):
        Signals.distance_level_set.connect(callback)
    mouse_filter = Control.MOUSE_FILTER_STOP


func handle_press_event(event: InputEvent) -> void:
    if event.is_released():
        if not dragged and (click_disabled or not disabled) and not cancel_press:
            button_pressed = not button_pressed
        dragged = false


func _gui_input(event: InputEvent) -> void:
    if event.device == -1:
        return

    if event is InputEventScreenTouch:
        get_viewport().gui_release_focus()
        if event.index == 0:
            handle_press_event(event)
    elif event is InputEventMouseButton:
        get_viewport().gui_release_focus()
        if event.button_index == MOUSE_BUTTON_LEFT:
            handle_press_event(event)
    elif event is InputEventScreenDrag:
        if event.index == 0:
            handle_drag_input(event)
    elif event is InputEventMouseMotion:
        if event.button_mask == MOUSE_BUTTON_LEFT:
            handle_drag_input(event)

    Signals.unhandled_input.emit(event, global_position)


func _on_distance_level_set(_distance: int) -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
