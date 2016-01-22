
extends Camera

# member variables here, example:
# var a=2
# var b="textvar"
var main_character = null
var main_char_prev_pos = null

var next_position = Vector3()
var current_translation = Vector3()

const LEFT_MODE = 0
const RIGHT_MODE = 1
var mode = RIGHT_MODE
var previous_mode = mode
var translate_offset_for_direction = 10

export var min_distance = 0.05
export var max_distance = 4.0

#*****************************************************************
func _ready():
	main_character = get_tree().get_root().get_node("Game/SantaRigidBody")
	main_char_prev_pos = main_character.get_global_transform().origin
	
	next_position = get_global_transform().origin
	current_translation = get_global_transform().origin

	set_process(true)
	# Initialization here
	pass

#*****************************************************************
# Decide where the character is headed so we can show the 
#   area in front of the character more
func calculateHeadingMode(diff):
	if diff.x != 0:
		if main_character.getHeadingRight():
			mode = RIGHT_MODE
		else:
			mode = LEFT_MODE
			
#	print("mode: "+str(mode))
#	print("previous_mode: "+str(previous_mode))

#*****************************************************************
# Process stuff regularly
func _process(delta):
	var char_pos = main_character.get_global_transform().origin
	var diff = char_pos - main_char_prev_pos
	var cam_trans = get_global_transform().origin
#	print("Diff: " + str(diff))
	
	next_position = Vector3(diff.x+next_position.x, \
	   diff.y+next_position.y, next_position.z);
	
	calculateHeadingMode(diff)

	if mode != previous_mode:
		if mode == LEFT_MODE:
			
			next_position.x -= translate_offset_for_direction
		else:
			next_position.x += translate_offset_for_direction

	previous_mode = mode
	
	current_translation = cam_trans
	current_translation = current_translation.linear_interpolate(\
	   next_position, clamp(5*delta, 0, 1))
	
#	print("current_translation: " + str(current_translation))
#	print("next_position: " + str(next_position))

	set_translation(current_translation)
	#set_translation(next_position)
	# keep track of previous position of main char
	main_char_prev_pos = char_pos
	pass


