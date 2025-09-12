extends Node


func _process(_delta):
	FPSDRAW()

var FPS
var MEM
func FPSDRAW():
	FPS = str(Engine.get_frames_per_second())
	MEM = String.humanize_size(OS.get_static_memory_usage()) + "/" + String.humanize_size(OS.get_static_memory_peak_usage())
	DisplayServer.window_set_title("%s %s" %[FPS,MEM])
