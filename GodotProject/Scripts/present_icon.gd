
extends Spatial

var animation_player = null
var DEFAULT_ANIMATION = "default"

func _ready():
	animation_player = get_node("AnimationPlayer");
	animation_player.set_current_animation(DEFAULT_ANIMATION)
	animation_player.set_active(true)
	
	set_process(true)
	pass
	
func _process(delta):
	animation_player.advance(delta)
	pass


