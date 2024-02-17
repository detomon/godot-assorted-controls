@tool
@icon("../../icons/v_range_slider.svg")
class_name VRangeSlider
extends RangeSlider

## A vertical [RangeSlider] that goes from bottom ([member min_value]) to top ([member max_value]),
## used to adjust a range by moving grabbers along a vertical axis.


func _init() -> void:
	_orientation = Orientation.VERTICAL
	super()
