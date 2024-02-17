@tool
extends EditorPlugin

const HV_SLIDER_ICON := preload("icons/hv_slider.svg")
const H_RANGE_SLIDER_ICON := preload("icons/h_range_slider.svg")
const V_RANGE_SLIDER_ICON := preload("icons/v_range_slider.svg")

const HVSliderScript := preload("gui/hv_slider/hv_slider.gd")
const HRangeSliderScript := preload("gui/range_slider/h_range_slider.gd")
const VRangeSliderScript := preload("gui/range_slider/v_range_slider.gd")


func _enter_tree() -> void:
	add_custom_type("HVSlider", "Control", HVSliderScript, HV_SLIDER_ICON)
	add_custom_type("HRangeSlider", "Control", HRangeSliderScript, H_RANGE_SLIDER_ICON)
	add_custom_type("VRangeSlider", "Control", VRangeSliderScript, V_RANGE_SLIDER_ICON)


func _exit_tree() -> void:
	remove_custom_type("HVSlider")
	remove_custom_type("HRangeSlider")
	remove_custom_type("VRangeSlider")
