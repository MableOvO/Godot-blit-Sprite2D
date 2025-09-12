@icon("res://blit_Sprite2D.svg")
@tool
class_name Blit_Sprite2D
extends Sprite2D


##A texture pool for the sprite's frames, also contains some stuff for slicing them
var crop_pool := TextureCrop.new()


##if true texture is flipped horizontally
@export var h_flip := false:
	set(value):
		h_flip = value
		reparse = true

##if true texture is flipped vertically
@export var v_flip := false:
	set(value):
		v_flip = value
		reparse = true

##Sets both the x and y scale at the same time, ignore if freeballin it by using scale
@export var size := 1.0:
	set(value):
		size = value 
		scale = Vector2(value,value)


@export_category("Json Options")

##reparses the given json and reslices the Image if need be, dont call this too often
@export var reparse := false:
	set(value):
		reparse = value 


##Whether or not json capabilities are enabled, needed for the animation tab to work
@export var use_json := false:
	set(value):
		
		use_json = value
		reparse = true





##the index where the frame is pulled from in the texture stack, used by the animation player exclusivley
var current_stack_idx = 0:
	set(value):
		current_stack_idx = value
		set_texture(crop_pool.get_texture_from_pool(value)) 


@export_category("Resource Paths")

##The source texture, must be filled instead of the built in sprite2d's Texture
@export var image :Texture2D:
	set(value):
		image = value
		reparse = true

##The source json, where _animations get read from
@export_file("*.json") var json_path: String:
	set(value):
		var extension = value.get_extension()
		if extension != "json":
			if extension != "":
				printerr("json path isnt a json file!")
		json_path = value
		reparse = true



##False on reparse, true after parsing finishes.
var finished_parsing := false


@export_category("Animation")


var _animations := {}

##The available animations that can be used
var available := []

var _raw_offsets := {}


var _offsets = []



var icon = ""


##The point that the sprite position's itself around
@export_enum("Feet","Top left","Center") var pivot_point: int = 0:
	set(value):
		pivot_point = value
		_last_frame = -1
		animation_frame = animation_frame



var current_animation_name := "": ##The current animation name
	set(value):
		current_animation_name = value
		animation_frame = 0

func _get_property_list() -> Array:
	var properties = []
	properties.append({
		"name": "current_animation_name",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(available),
		"usage": PROPERTY_USAGE_DEFAULT
	})
	return properties

##The current time in seconds, for how long the animation is taking
var time = 0.0

##The speed scaling ratio for the animation
@export var speed_scale = 1.0

##Frame rate of the current animation, set to 25 by default
var frame_rate = 25

##Simple toggle for playing / pausing
@export var Playing := false:
	set(value):
		
		Playing = value
		if Playing:
			animation_frame = 0
			time = 0.0

##The current frame of animation, seperate from the internal "current_stack_idx"
@export var animation_frame := 0:
	set(value):
		animation_frame = value
		if image != null and json_path != "" and finished_parsing:
			play_frame()



var _anim_end := 0:
	get():
		return _animations[current_animation_name].size() - 1


func _process(delta: float) -> void:
	
	if flip_v:
		printerr("native flip_v doesnt work for blit sprites, use the one under Blit Sprite2D")
		flip_v = false
		
	if flip_h:
		printerr("native flip_h doesnt work for blit sprites, use the one under Blit Sprite2D")
		flip_h = false
	
	if region_enabled:
		printerr("region is not allowed for blit sprites, use a regular Sprite2d instead!")
		region_enabled = false
	
	
	if reparse:
		reparse = false
		finished_parsing = false
		_LOAD()
	
	if not finished_parsing:
		return
	
	if image == null or json_path == "":
		return
	
	if not use_json:
		return
	
	
	
	
	animation_frame = clamp(animation_frame,-_anim_end,_anim_end)

	#what
	if animation_frame >= _anim_end ||  animation_frame <= -_anim_end :
		Playing = false
		
	
	if not Playing: #not calculating allat
		return
	
	time += delta
	animation_frame = round(time * frame_rate * speed_scale)

func _LOAD():
	
	crop_pool.clear_pool()
	_offsets.clear()
	texture = image
	
	
	var base_tex = null
	if use_json:
		base_tex = texture.get_image()
		texture = null
	
		if ResourceLoader.exists(json_path) and use_json:
			#READ data
			var datafile = FileAccess.open(json_path, FileAccess.READ)
			var parsedResult = JSON.parse_string(datafile.get_as_text())
			datafile.close()
			
			if parsedResult != null:

				
				_animations = parsedResult.get("SPRITE", {})
				
				_raw_offsets = parsedResult.get("OFFSETS", {})
				var ETC = parsedResult.get("ETC", {})
				size = ETC.get("SCALE",size)
				icon = ETC.get("ICON_NAME","")
				var is_pixel = ETC.get("IS_PIXEL",false)
				texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  if is_pixel else CanvasItem.TEXTURE_FILTER_LINEAR
				
				available = _animations.keys()
				current_animation_name = available.front()
				crop_pool.source_Image = base_tex
				base_tex = null
				await _parse_frames()
	
	finished_parsing = true
	notify_property_list_changed()




func _parse_frames():
	
	var frames = [] #stores the ACTUAL individual frames
	#rather than the whole animation as some frames are "duplicates"
	var frames_data = []
	
	
	
	var Pivot_data = {}
	
	for anim in available:
		var anim_has_rotation = false
		
		var anim_keys = _animations[anim]
		Pivot_data[anim] = []
		
		for key in anim_keys:
			if key[6] == true:
				anim_has_rotation = true
				break
			
			
		for key in anim_keys:
			if not frames.has(key):
				var rect = Rect2(key[0], key[1], key[2], key[3])
				var is_rotated = key[6]
				
				var local_offset = Vector2(key[4] * -0.5 , key[5] * -0.5)
				
				if is_rotated:
					local_offset = Vector2(local_offset.y,local_offset.x)
				
				if _raw_offsets.keys().has(anim):
					var raw = _raw_offsets[anim][0]
					var spr_off = Vector2(raw[0], raw[1])
					
					
					local_offset += spr_off if anim_has_rotation else -spr_off
				

				Pivot_data[anim].append(local_offset)
				
				frames.append(key)
				frames_data.append({
					"rect": rect,
					"x": key[4],
					"y": key[5],
					"rotated":is_rotated
				})

	_offsets = Pivot_data
	_raw_offsets.clear() # no point in storing this after this point
	for frame_idx in frames.size():
		var data = frames_data[frame_idx]
		var pool_idx = crop_pool.add_texture_pool(data.rect, data.rotated,h_flip,v_flip)
		
		for anim in available:
			for i in _animations[anim].size():
				var key = _animations[anim][i]
				if typeof(key) == TYPE_ARRAY:
					if key == frames[frame_idx]:
						_animations[anim][i] = pool_idx
						
		#replace the source key frame with the location of the parsed frame

	crop_pool.source_Image = null 
	
	if crop_pool.STACK.size() > 0:
		play_abstract("idle") #if such animation even exists in this sprite






##Plays the animation with that key name
func play(animation_name := "",custom_speed := 1.0):
	current_animation_name = animation_name
	speed_scale = custom_speed
	Playing = true



##Plays the animation with a vague search and an index_value, if one is not applied the front of the available matching animations is used
func play_abstract(animation_name := "",custom_speed := 1.0,index_value = -1):
	var this_animation = ""
	var local_index = []
	
	
	for anim in available:
		if anim.containsn(animation_name):
			local_index.append(anim)
	local_index.sort()
	
	this_animation = local_index.front() if index_value == -1 else local_index[clamp(index_value,0,local_index.size() - 1)]
	
	if this_animation == "":
		printerr("animation could not be found in player: %s" %animation_name)
		return 
	
	current_animation_name = this_animation
	speed_scale = custom_speed
	Playing = true






##apply the sprite's offsets set from it's JSON.      NOTE: It can only use feet pivot points
@export var apply_offsets := true


var _last_frame = 0



##actually sets the frame for the current animation, using the currently set frame value's
func play_frame():
	if current_animation_name == "": return
	if not available.has(current_animation_name):
		printerr("animation does not exist, falling back to the start of animation index :/")
		current_animation_name = available.front()
		return
	

	
	
	var this_frame = _animations[current_animation_name][clamp(animation_frame,-_anim_end,_anim_end)]
	
	if _last_frame == this_frame:
		return
	
	if typeof(this_frame) == TYPE_ARRAY:
		printerr("parsing error, somehow an array leaked into the frames report to mae /n
		#.. or if you are mae, fix it you little fucker")
		current_animation_name = ""
		return






	
	_last_frame = this_frame
	current_stack_idx = this_frame
	
	var offs_end = _offsets[current_animation_name].size() - 1
	var extra_data = _offsets[current_animation_name][clamp(animation_frame,-offs_end,offs_end)] if not _offsets[current_animation_name].is_empty() else Vector2.ZERO
	
	
	var local_pivot = Vector2.ZERO
	var texture_size =  texture.get_size() 
	match pivot_point:
		0:
			local_pivot.y = -texture_size.y * 0.5 
			extra_data = Vector2(extra_data.x,0) #ignore y, it creates problems
		1:
			local_pivot = texture_size * 0.5
	
	if apply_offsets and pivot_point != 0:
		printerr("NOTE: applying offsets can only be used when the pivot is set to Feet")
		apply_offsets = false


	offset = local_pivot + (extra_data if apply_offsets else  Vector2.ZERO)


#stuff that mimics the AnimationPlayer node's formatting

##The length (in seconds) of the currently playing animation.
func get_current_animation_length():
	var frames = _animations[current_animation_name].size()
	var _time =  (frames /frame_rate * speed_scale)
	return round(_time)


##Sets the speed scaling ratio
func set_speed_scale(value):
	speed_scale = value





class BLIT_RES:
	#i dont like dealing with the xml format, and i was already using jsons soooo

	##Converts XML files to a usable format that i can use, if the save was successful, returns true
	static func convert_XML(XML_path:String,save_location = "") -> bool:
		var data = {"SPRITE": {}}
		
		if XML_path.get_extension() == "xml":
			var parser = XMLParser.new()
			var final_path = XML_path if save_location == "" else save_location
			
			final_path = final_path.replacen(final_path.get_extension(),"json")
			
			parser.open(XML_path)
			while parser.read() != ERR_FILE_EOF:
				var node_name = parser.get_node_name()
				if node_name != "SubTexture":
					continue
				
				var this_attribute = {}
				
				for idx in range(parser.get_attribute_count()):
					this_attribute[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
				
				var animation_name = this_attribute.name.rstrip("0123456789")
				#print(animation_name)
				if not data.SPRITE.has(animation_name):
					data.SPRITE[animation_name] = []
				
				var frame_format = [
					int(this_attribute.get("x",0)),
					int(this_attribute.get("y",0)),
					int(this_attribute.get("width",0)),
					int(this_attribute.get("height",0)),
					int(this_attribute.get("frameX",0)),
					int(this_attribute.get("frameY",0)),
					this_attribute.get("rotated",false)
				]
				data.SPRITE[animation_name].append(frame_format)
				
				
			

			var file = FileAccess.open(final_path,FileAccess.WRITE)
			
			file.store_string(JSON.stringify(data," ",false))
			
			#hello my name is snapple, my ingredients consist of... watermelon and lemonade !
			return true
		else:
			printerr("XML conversion went wrong somewhere... is the xml path even an xml?? %s" %XML_path)
			return false
	
	
	##For Friday Night Funkin the offsets and animations are placed in different locations,
	###I consolidate mine into one file, because I dont like checking 8 different paths
	static func append_offsets(JSON_path:String,JSON_offsets:String):
		var Main = FileAccess.open(JSON_path,FileAccess.READ_WRITE)
		var Offsets = FileAccess.open(JSON_offsets,FileAccess.READ)
		
		
		if Main == null || Offsets == null:
			push_error("error appending offsets, one of your files contains an incorrect or invalid path")
			return 
		
		var data = JSON.parse_string(Offsets.get_as_text())
		
		if data == null:
			push_error("error getting offsets from JSON, file contains invalid data")
			return
		
		Offsets.close()
		
		var ICO = data.get("healthIcon",{"id":null}).get("id",null)
		var size = data.get("scale",1)
		var is_pixel = data.get("isPixel",false)
		var OFFSETS = {}
		var extra_data = {
			"ICON_NAME":ICO,
			"SCALE":size,
			"IS_PIXEL":is_pixel
		}
		for anim in data.get("animations",[]):
			if not OFFSETS.has(anim):
				OFFSETS[anim.name] = []
			OFFSETS[anim.name].append(anim.offsets)
		
		data = JSON.parse_string(Main.get_as_text())
		if data == null:
			push_error("error getting animation data from the main JSON, file contains invalid data")
			return
		
		data["OFFSETS"] = OFFSETS
		data["ETC"] = extra_data
		Main.store_string(JSON.stringify(data," ",false))





class TextureCrop:
	
	##The raw frames of the animation, does not contain duplicates.. or it shouldnt if i did this right
	var STACK = []
	
	var source_Image:Image
	
	func add_texture_pool(Rect:Rect2i,rotated := false,flip_x = false,flip_y = false) -> int:
		var position = -999
		if source_Image:
			var SRC_D = Image.create(Rect.size.x,Rect.size.y,false,source_Image.get_format())
			
			SRC_D.blit_rect(source_Image,Rect,Vector2i.ZERO)
			
			if flip_x:
				SRC_D.flip_x()
				
			if flip_y:
				SRC_D.flip_y()
			
			if rotated: SRC_D.rotate_90(COUNTERCLOCKWISE)
			STACK.append(ImageTexture.create_from_image(SRC_D))
			position = STACK.size() - 1
			SRC_D = null

		return position

	func get_texture_from_pool(Index:int) -> Texture2D:
		source_Image = null #free ts, takes up alotta memory
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(10,10)
		
		if Index == -999:
			push_warning("Texture Might not have been cropped correctly :/")
			return texture
		
		if STACK.is_empty():
			return texture
		
		Index = clamp(Index, 0, STACK.size() - 1)
		return STACK[Index]

	func clear_pool() -> void:
		if STACK.is_empty():
			return
		STACK.clear()



#haha fuck you .. fuck your keyframes
#more like..idiotframe !
#No, keystupid!
#ha ha ha ha
