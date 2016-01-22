
extends Spatial

# member variables here, example:
# var a=2
# var b="textvar"
var animation_player

const FLIPPING_START_ANIMATION_NAME = "Flipping_start"
const FLIPPING_ANIMATION_NAME = "Flipping"

#*****************************************************************
func sanityCheck():
	if(!animation_player.has_animation(FLIPPING_ANIMATION_NAME)	||
		animation_player.has_animation(FLIPPING_START_ANIMATION_NAME)):
		print("ERROR Animation player doesn't have expected animations!")

#*****************************************************************
func _ready():
	animation_player = get_node("AnimationPlayer");
	sanityCheck()
	# Initialization here
	pass
	
#*****************************************************************
func _on_AnimationPlayer_finished():
	var current = animation_player.get_current_animation()
	if(current == FLIPPING_START_ANIMATION_NAME):
		animation_player.set_current_animation(FLIPPING_ANIMATION_NAME)
	pass 
