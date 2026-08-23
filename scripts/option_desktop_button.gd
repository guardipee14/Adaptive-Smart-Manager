extends OptionButton

@export var click_disabled: bool

var dragged: bool
var cancel_press: bool

const KDRAG_LEN_SQUARED := 10000

# Preserve the original Smart Manager OptionButton interaction semantics, but
# never disable mouse input merely because the desktop is zoomed out.

func _init() -> void:
    button_mask = 0
    mouse_force_pass_scroll_events = false
    toggle_mode = true


func _ready() -> void:
    var callback := Callable(self, "_on_distance_level_set")
    if not Signals.distance_level_set.is_connected(callback):
        Signals.distance_level_set.connect(callback)
    mouse_filter = Control.MOUSE_FILTER_STOP


func _toggled(toggled_on: bool) -> void:
    if toggled_on:
        show_popup()
        button_down.emit()
    else:
        get_popup().hide()
        button_up.emit()


func handle_drag_input(event: InputEvent) -> void:
    dragged = dragged or event.velocity.length_squared() >= KDRAG_LEN_SQUARED
    button_pressed = not dragged


func _gui_input(event: InputEvent) -> void:
    if event.device == -1:
        return

    if event is InputEventScreenTouch:
        get_viewport().gui_release_focus()
        if event.index == 0:
            button_pressed = event.is_pressed()
            if event.is_pressed():
                button_down.emit()
            elif event.is_released():
                if not dragged and (click_disabled or not disabled) and not cancel_press:
                    pressed.emit()
                dragged = false
                button_up.emit()
                return
    elif event is InputEventMouseButton:
        get_viewport().gui_release_focus()
        if event.button_index == MOUSE_BUTTON_LEFT:
            button_pressed = event.is_pressed()
            if event.is_pressed():
                button_down.emit()
            elif event.is_released():
                if not dragged:
                    pressed.emit()
                dragged = false
                button_up.emit()
                return
    elif event is InputEventScreenDrag:
        if event.index == 0:
            handle_drag_input(event)
    elif event is InputEventMouseMotion:
        if event.button_mask == MOUSE_BUTTON_LEFT:
            handle_drag_input(event)

    Signals.unhandled_input.emit(event, global_position)


func _on_distance_level_set(_distance: int) -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
