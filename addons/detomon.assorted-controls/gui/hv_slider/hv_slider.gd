@tool
@icon("../icons/hv_slider.svg")
class_name HVSlider
extends Control

## A 2D slider that goes from bottom left ([member min_value]) to top right ([member max_value]),
## used to set independant values for the horizontal and vertical axis.

## Emitted when [member min_value], [member max_value], or [member step] changes.
signal changed()
## Emitted when [member value] changes.
signal value_changed(value: Vector2)

enum Element {
	NONE,
	GRABBER,
	GUIDE_H,
	GUIDE_V,
}

const STEP_AMOUNT_DEFAULT := 0.1

## Slider's current value. Changing this property (even via code) will trigger the
## [signal value_changed] signal. Use [method set_value_no_signal] to avoid this.
@export var value := Vector2.ZERO: set = set_value
## Minimum value. [member value] is clamped if less than [member min_value].
@export var min_value := Vector2(0, 0): set = set_min_value
## Maximum value. [member value] is clamped if greater than [member max_value].
@export var max_value := Vector2(1, 1): set = set_max_value
## If greater than [code]0[/code], the corresponding axis of [member value] will always be rounded
## to a multiple of this property's value.
@export var step := Vector2.ZERO: set = set_step
## Number of ticks displayed on the horizontal axis including border ticks. Ticks are
## uniformly-distributed value markers.
@export_range(0, 1024) var tick_count_h := 2: set = set_tick_count_h
## Number of ticks displayed on the vertical axis including border ticks. Ticks are
## uniformly-distributed value markers.
@export_range(0, 1024) var tick_count_v := 2: set = set_tick_count_v
## If [code]true[/code], shows horizontal and vertical guide lines centered at the grabber.
## Dragging these lines moves the grabber horizontally or vertically.
@export var show_guides := true: set = set_show_guides
## If [code]true[/code], sets the value to the corresponding position when clicking anywhere inside
## the control.
@export var click_sets_value := true
## If [code]true[/code], the slider can be interacted with. If [code]false[/code], the value can be
## changed only by code.
@export var editable := true: set = set_editable

var _drag_element := Element.NONE
var _highlight_element := Element.NONE
var _drag_offset := Vector2.ZERO
var _theme_cache := {
	slider_style = null,
	focus_style = null,
	grabber_icon = null,
	grabber_icon_disabled = null,
	grabber_icon_highlight = null,
	grabber_drag_margin = 0.0,
	tick_color = Color.WHITE,
	tick_width = 0.0,
	guide_color = Color.WHITE,
	guide_color_highlight = Color.WHITE,
	guide_width = 0.0,
	guide_drag_margin = 0.0,
}


func _init() -> void:
	mouse_exited.connect(_on_mouse_exited)


func _enter_tree() -> void:
	_update_theme_cache()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_update_theme_cache()


func _get_minimum_size() -> Vector2:
	var grabber: Texture2D = _theme_cache.grabber_icon
	return grabber.get_size() if grabber else Vector2.ZERO


func _draw() -> void:
	var grabber_rect := _get_grabber_rect()
	var slider_rect := Rect2i(grabber_rect.size * 0.5, Vector2i(size) - grabber_rect.size)
	var grid_color: Color = _theme_cache.tick_color
	var grid_thickness: float = _theme_cache.tick_width

	draw_style_box(_theme_cache.slider_style, Rect2(Vector2.ZERO, size))
	_draw_grid(slider_rect, grid_color, grid_thickness)

	if show_guides:
		_draw_grabber_guides(slider_rect, grabber_rect)

	if has_focus():
		var focus_rect := Rect2(Vector2.ZERO, size)
		draw_style_box(_theme_cache.focus_style, focus_rect)

	_draw_grabber(grabber_rect)


func _gui_input(event: InputEvent) -> void:
	if not editable:
		return

	var drag_element := _drag_element
	var highlight_element := _highlight_element

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			var element := _get_element_at_point(event.position)

			if element != Element.NONE:
				drag_element = element

			elif click_sets_value:
				drag_element = Element.GRABBER
				highlight_element = Element.GRABBER
				value = _point_to_value(event.position)
				_drag_offset = Vector2.ZERO

			highlight_element = drag_element

		else:
			drag_element = Element.NONE

			# Mouse was released outside of control.
			if not Rect2(Vector2.ZERO, size).has_point(event.position):
				highlight_element = Element.NONE

	elif event is InputEventMouseMotion:
		match _drag_element:
			Element.NONE:
				# Highlight element under mouse when not dragging.
				highlight_element = _get_element_at_point(event.position)

			Element.GRABBER:
				value = _point_to_value(event.position + _drag_offset)

			Element.GUIDE_H:
				var new_value := _point_to_value(event.position + _drag_offset)
				new_value.y = value.y
				value = new_value

			Element.GUIDE_V:
				var new_value := _point_to_value(event.position + _drag_offset)
				new_value.x = value.x
				value = new_value

	elif event is InputEventKey or event is InputEventJoypadMotion:
		var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_down", &"ui_up")

		if direction:
			var norm_range := max_value - min_value
			var value_step := Vector2(
				step.x if step.x else norm_range.x * STEP_AMOUNT_DEFAULT,
				step.y if step.y else norm_range.y * STEP_AMOUNT_DEFAULT,
			)

			value += value_step * direction

	if drag_element != _drag_element or highlight_element != _highlight_element:
		_drag_element = drag_element
		_highlight_element = highlight_element
		queue_redraw()


func set_value(new_value: Vector2) -> void:
	if new_value == value:
		return

	value = _validate_value(new_value)
	queue_redraw()
	value_changed.emit(value)


func set_min_value(new_value: Vector2) -> void:
	if new_value == min_value:
		return

	min_value = new_value
	value = _validate_value(value)
	changed.emit()
	queue_redraw()


func set_max_value(new_value: Vector2) -> void:
	if new_value == max_value:
		return

	max_value = new_value
	value = _validate_value(value)
	changed.emit()
	queue_redraw()


func set_step(new_value: Vector2) -> void:
	step = new_value
	changed.emit()


func set_editable(new_value: bool) -> void:
	editable = new_value
	if not editable:
		_drag_element = Element.NONE
		_highlight_element = Element.NONE
	queue_redraw()


func set_tick_count_h(new_value: int) -> void:
	tick_count_h = clampi(new_value, 0, 1024)
	queue_redraw()


func set_tick_count_v(new_value: int) -> void:
	tick_count_v = clampi(new_value, 0, 1024)
	queue_redraw()


func set_show_guides(new_value: bool) -> void:
	show_guides = new_value
	queue_redraw()


## Sets the current value to the specified [param value], without emitting the [signal changed]
## signal.
func set_value_no_signal(new_value: Vector2) -> void:
	var is_blocking := is_blocking_signals()
	set_block_signals(true)
	value = new_value
	set_block_signals(is_blocking)


func _update_theme_cache() -> void:
	_theme_cache.slider_style = _theme_stylebox_get_or_fallback(&"slider", &"HVSlider", &"HSlider")
	_theme_cache.focus_style = _theme_stylebox_get_or_fallback(&"focus", &"HVSlider", &"Button")

	_theme_cache.grabber_icon = _theme_icon_get_or_fallback(&"grabber", &"HVSlider", &"HSlider")
	_theme_cache.grabber_icon_disabled = _theme_icon_get_or_fallback(&"grabber_disabled", &"HVSlider", &"HSlider")
	_theme_cache.grabber_icon_highlight = _theme_icon_get_or_fallback(&"grabber_highlight", &"HVSlider",  &"HSlider")
	_theme_cache.grabber_drag_margin = get_theme_constant(&"grabber_drag_margin", &"HVSlider")

	_theme_cache.tick_color = get_theme_color(&"tick", &"HVSlider")
	_theme_cache.tick_width = get_theme_constant(&"tick_width", &"HVSlider")

	_theme_cache.guide_color = get_theme_color(&"guide", &"HVSlider")
	_theme_cache.guide_color_highlight = get_theme_color(&"guide_highlight", &"HVSlider")
	_theme_cache.guide_width = get_theme_constant(&"guide_width", &"HVSlider")
	_theme_cache.guide_drag_margin = get_theme_constant(&"guide_drag_margin", &"HVSlider")


func _theme_icon_get_or_fallback(icon_name: StringName, theme_type: StringName, theme_type_fallback: StringName) -> Texture2D:
	if has_theme_icon(name, theme_type):
		return get_theme_icon(icon_name, theme_type)
	else:
		return get_theme_icon(icon_name, theme_type_fallback)


func _theme_stylebox_get_or_fallback(icon_name: StringName, theme_type: StringName, theme_type_fallback: StringName) -> StyleBox:
	if has_theme_stylebox(name, theme_type):
		return get_theme_stylebox(icon_name, theme_type)
	else:
		return get_theme_stylebox(icon_name, theme_type_fallback)


func _validate_value(new_value: Vector2) -> Vector2:
	var min_x := minf(min_value.x, max_value.x)
	var max_x := maxf(min_value.x, max_value.x)
	var min_y := minf(min_value.y, max_value.y)
	var max_y := maxf(min_value.y, max_value.y)

	new_value = new_value.snapped(step)
	new_value.x = clampf(new_value.x, min_x, max_x)
	new_value.y = clampf(new_value.y, min_y, max_y)

	return new_value


func _draw_grid(slider_rect: Rect2i, grid_color: Color, grid_thickness: float) -> void:
	if tick_count_h >= 2:
		var line_rect := slider_rect
		line_rect.size.x = 0

		for i in tick_count_h:
			var tick_offset := float(i) / float(tick_count_h - 1)
			line_rect.position.x = int(slider_rect.position.x + slider_rect.size.x * tick_offset)
			draw_line(line_rect.position, line_rect.end, grid_color, grid_thickness)

	if tick_count_v >= 2:
		var line_rect := slider_rect
		line_rect.size.y = 0

		for i in tick_count_v:
			var tick_offset := float(i) / float(tick_count_v - 1)
			line_rect.position.y = int(slider_rect.position.y + slider_rect.size.y * tick_offset)
			draw_line(line_rect.position, line_rect.end, grid_color, grid_thickness)


func _draw_grabber(grabber_rect: Rect2i) -> void:
	var grabber := _get_grabber_icon()
	draw_texture(grabber, grabber_rect.position)


func _draw_grabber_guides(slider_rect: Rect2i, grabber_rect: Rect2i) -> void:
	var grabber_center := grabber_rect.get_center()
	var line_h := Rect2(Vector2(grabber_center.x, slider_rect.position.y), Vector2(0.0, slider_rect.size.y))
	var line_v := Rect2(Vector2(slider_rect.position.x, grabber_center.y), Vector2(slider_rect.size.x, 0.0))
	var guide_h_highlight := _highlight_element == Element.GUIDE_H
	var guide_v_highlight := _highlight_element == Element.GUIDE_V
	var guide_h_color: Color = _theme_cache.guide_color_highlight if guide_h_highlight else _theme_cache.guide_color
	var guide_v_color: Color = _theme_cache.guide_color_highlight if guide_v_highlight else _theme_cache.guide_color

	draw_line(line_h.position, line_h.end, guide_h_color, _theme_cache.guide_width)
	draw_line(line_v.position, line_v.end, guide_v_color, _theme_cache.guide_width)


func _get_grabber_icon() -> Texture2D:
	if _highlight_element == Element.GRABBER:
		return _theme_cache.grabber_icon_highlight
	elif not editable:
		return _theme_cache.grabber_icon_disabled

	return _theme_cache.grabber_icon


func _get_grabber_rect() -> Rect2i:
	var offset := Vector2(
		remap(value.x, min_value.x, max_value.x, 0.0, 1.0),
		remap(value.y, max_value.y, min_value.y, 0.0, 1.0),
	)

	# Minimum and maximum of the horizontal axis is the same.
	if not is_finite(offset.x):
		offset.x = max_value.x
	# Minimum and maximum of the vertical axis is the same.
	if not is_finite(offset.y):
		offset.y = max_value.y

	var grabber := _get_grabber_icon()
	var grabber_size := grabber.get_size()
	var grabber_rect :=  Rect2i((size - grabber_size) * offset, grabber_size)

	return grabber_rect


func _get_grabber_hit_area() -> Rect2:
	var rect := _get_grabber_rect()
	rect = rect.grow(_theme_cache.grabber_drag_margin)

	return rect


func _get_guide_h_hit_area() -> Rect2:
	var guide_rect := _get_slider_hit_area()
	var grabber_position := _get_grabber_rect().get_center()
	var width: float = _theme_cache.guide_width + _theme_cache.guide_drag_margin * 2.0

	guide_rect.position.x = grabber_position.x - width * 0.5
	guide_rect.size.x = width

	return guide_rect


func _get_guide_v_hit_area() -> Rect2:
	var guide_rect := _get_slider_hit_area()
	var grabber_position := _get_grabber_rect().get_center()
	var width: float = _theme_cache.guide_width + _theme_cache.guide_drag_margin * 2.0

	guide_rect.position.y = grabber_position.y - width * 0.5
	guide_rect.size.y = width

	return guide_rect


func _get_slider_hit_area() -> Rect2:
	var grabber_rect := _get_grabber_rect()
	var grow := grabber_rect.size * -0.5
	var slider_rect := Rect2(Vector2.ZERO, size).grow_individual(grow.x, grow.y, grow.x, grow.y)

	return slider_rect


func _point_to_value(point: Vector2) -> Vector2:
	var value_rect := _get_slider_hit_area()
	var point_value := Vector2(
		remap(point.x, value_rect.position.x, value_rect.end.x, min_value.x, max_value.x),
		remap(point.y, value_rect.position.y, value_rect.end.y, max_value.y, min_value.y),
	)

	return point_value


func _get_element_at_point(point: Vector2) -> Element:
	var grabber_rect := _get_grabber_hit_area()
	var guide_h_drag_rect := _get_guide_h_hit_area()
	var guide_v_drag_rect := _get_guide_v_hit_area()

	if grabber_rect.has_point(point):
		_drag_offset = grabber_rect.get_center() - point
		return Element.GRABBER

	elif show_guides and guide_h_drag_rect.has_point(point):
		_drag_offset = guide_h_drag_rect.get_center() - point
		return Element.GUIDE_H

	elif show_guides and guide_v_drag_rect.has_point(point):
		_drag_offset = guide_v_drag_rect.get_center() - point
		return Element.GUIDE_V

	return Element.NONE


func _on_mouse_exited() -> void:
	if _drag_element == Element.NONE:
		_highlight_element = Element.NONE
		queue_redraw()
