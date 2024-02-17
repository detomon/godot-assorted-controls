@tool
@icon("../../icons/h_range_slider.svg")
class_name HRangeSlider
extends RangeSlider

## A horizontal [RangeSlider] that goes from left ([member min_value]) to right ([member max_value]),
## used to adjust a range by moving grabbers along a horizontal axis.


func _init() -> void:
	_orientation = Orientation.HORIZONTAL
	super()
