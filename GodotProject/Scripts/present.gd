
extends KinematicBody

var DEFAULT_ANIMATION = "default"
var animation_player = null
var collection_animation_player = null
var collected = false

var sample_player = null 
var present = null

#*****************************************************************
func _ready():
	# Initialization here
	present = get_node("present")
	set_collide_with_rigid_bodies(true)
	add_to_group("Collectable")
	get_node("present").show()
	animation_player = get_node("present").get_node("AnimationPlayer");
	animation_player.set_current_animation(DEFAULT_ANIMATION)
	animation_player.set_active(true)
	set_fixed_process(true)
	get_node("Particles").set_emitting(false)
	
	sample_player = get_node("SpatialSamplePlayer")
	sample_player.set_polyphony(2)
	
	if(is_in_group("Collectable")):
		print("In Collectable!")
	else:
		print("Not in Collectable")
	
	collection_animation_player = get_node("AnimationPlayer")
	pass

#*****************************************************************
func collected():
	
	if(collected):
		return

	collection_animation_player.set_current_animation("collect")
	collection_animation_player.set_active(true)
	print("collected called! on "+ str(self))
	sample_player.play("collect_sound", 0)
	collected = true
	pass
	
#*****************************************************************
# Pretty much the effects this is collected
func enableParticles():
	get_node("Particles").set_emitting(true)
	pass
	
#*****************************************************************
# Pretty much the effects this is collected
func disableParticles():
	get_node("Particles").set_emitting(false)
	pass

#*****************************************************************	
func _cleanup():
	print("Deleting present!")
	queue_free()
	pass
	
var was_left = true
#*****************************************************************
func _fixed_process(dt):
#	print("delta: " , dt)
	animation_player.advance(dt)
	collection_animation_player.advance(dt)
	
	if(is_colliding()):
		print("KINEMATIC COLLISION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	# Plays at wrong speed, BUG
	if(!animation_player.is_playing()):
		pass
		#print("animation wasn't playing...")
#		animation_player.play(DEFAULT_ANIMATION)
	pass

