
extends RigidBody

# member variables here, example:
# var a=2
# var b="textvar"
const GROUNDED_STATE = 0

const FLYING_ANIMATION_NAME = "flying"
const WALKING_ANIMATION_NAME = "walk"
const FLYING_FIRE_ANIMATION_NAME = "flying_fire"



var animation_player = null 

# Object to track
var object_to_track = null
# Keep track of last poisiton in case object 
#   goes out of range. Still shoot in that direction etc
var last_position_of_object_to_track

# Detect when touching ground
var ground_ray = null
var canJump = true

var ObjectTypeTests = load("ObjectTypeTests.gd")

#------------------------------------------------
# Fireball variables
#------------------------------------------------
# Fireball class to instance
var fireballPreload = preload("res://Prefab/fireBallRigidBody.scn")
export var FIREBALL_DELAY = 0.3
# Timer when we are able to fire again
var attack_timer = null
var can_attack = false
const MIN_TIME_BETWEEN_ATTACKS_SECONDS = 6
const MIN_TIME_ON_SCREEN_BETWEEN_ATTACKS_SECONDS = 1.5
var FIREBALL_SPEED = 8.0
# How many shots were fired while target was out of range
var fired_out_of_range = 0

# If Krampus is visible on screen
var is_on_screen = false

#------------------------------------------------
# States to decide when to turn character
#------------------------------------------------
const RIGHT_STATE = 0
const LEFT_STATE = 1
var moving_state = LEFT_STATE
var last_moving_state = moving_state

# Used to interpolate turnings around
var current_x_rotation = 0
var next_x_rotation = 0

# Turn left by facing away from screen
const TURN_LEFT_BACK = 180
# Turn left by facing towards screen
const TURN_LEFT_FROM = -180
# Enable picking a random turn direction to vary visuals
var turn_direction = [TURN_LEFT_BACK, TURN_LEFT_FROM]

#*****************************************************************
func _ready():
	
	add_to_group("Enemy")
	set_fixed_process(true)
	animation_player = get_node("Spatial/AnimationPlayer")
	animation_player.set_current_animation(FLYING_ANIMATION_NAME)
	animation_player.set_active(true)
	
	ground_ray = get_node("ground_ray_cast")
	ground_ray.add_exception(self)
	
	attack_timer = get_node("attack_timer")
	pass

#*****************************************************************
func canAttack():
	if(can_attack):
		return true;

#*****************************************************************
func turnTowardsObjectIfClose():
	if(object_to_track == null):
		return
		
	last_position_of_object_to_track = object_to_track.get_translation()
	if(get_translation().x < last_position_of_object_to_track.x):
		moving_state = RIGHT_STATE
	else:
		moving_state = LEFT_STATE
	pass

#*****************************************************************
func rotateIfTurned(delta):
	if last_moving_state != moving_state:
		if next_x_rotation != TURN_LEFT_BACK && next_x_rotation != TURN_LEFT_FROM:
			var choice = randi() % turn_direction.size()
			next_x_rotation = turn_direction[choice]
		else:
			next_x_rotation = 0

#	print("ceil(-0.5): " +str(ceil(-0.5)))
#	print( "current_x_rotation: " + str(current_x_rotation))
#	print( "next X rotation: " + str(next_x_rotation))
#	print( "delta: " + str(delta))
	current_x_rotation = lerp(current_x_rotation, next_x_rotation, \
		clamp(10*delta, 0, 1))

#	for i in range(100):
#		print("randi()%2: "+ str(randi()% turn_direction.size()))
	set_rotation(Vector3(0, deg2rad(current_x_rotation), 0))
	#var trans = get_transform()
	#var matrix = trans.basis.rotated(Vector3(0, 1, 0), deg2rad(next_x_rotation))
	#set_transform(Transform(matrix, trans.origin));

	pass


var fire_ball_shoot_direction = null
#*****************************************************************
#  @param location to shoot at
func setFireBallShootDirection(location):
	if(location == null):
		return
	var direction = location
	# Aim a little higher
	direction.y += 3

	fire_ball_shoot_direction = (direction - get_translation())

#*****************************************************************
#  Shoot fireball at end of animation
func startFlyFireAnimation():
	
	if(!canAttack() || fire_ball_shoot_direction == null || !is_on_screen):
		return
	
	# Schedule firing a ball
	if(animation_player.get_current_animation() != FLYING_FIRE_ANIMATION_NAME):
		animation_player.set_current_animation(FLYING_FIRE_ANIMATION_NAME)
	
#*****************************************************************
func shootFireBall(direction):
	
	if(direction == null):
		return

	print("fireBall!: "+ str(direction))
	var fireball = fireballPreload.instance()
	#animation_player.set_current_animation(FLYING_FIRE_ANIMATION_NAME);
	direction = direction.normalized()
	fireball.set_linear_velocity(direction* FIREBALL_SPEED)

	var start_location = get_translation()
	start_location = start_location + direction * 1.5
	start_location.y += 2
	fireball.set_translation(start_location)
	fireball.add_collision_exception_with(self)
	get_tree().get_current_scene().add_child(fireball)

	attack_timer.set_wait_time(MIN_TIME_BETWEEN_ATTACKS_SECONDS)
	attack_timer.start()
	can_attack = false
	pass

#*****************************************************************
func shootFireBallAtLocation(location):
	if(location == null):
		return
	var direction = location
	# Aim a little higher
	direction.y += 3

	direction = (direction - get_translation())
	shootFireBall(direction)

#*****************************************************************
func handleAttacking():
	#shootFireBallAtLocation(last_position_of_object_to_track)
	setFireBallShootDirection(last_position_of_object_to_track)
	startFlyFireAnimation()
	
	var current_animation = animation_player.get_current_animation()
	var length = animation_player.get_current_animation_length()
	var position = animation_player.get_current_animation_pos()
	
	if(fire_ball_shoot_direction != null &&
		current_animation == FLYING_FIRE_ANIMATION_NAME &&
		position + FIREBALL_DELAY >= length && canAttack()):
			shootFireBall(fire_ball_shoot_direction)
			fire_ball_shoot_direction = null
	
	# Only fire 1 ball after target is out of range
	if(object_to_track == null):
		if(fired_out_of_range > 0):
			last_position_of_object_to_track = null
			fired_out_of_range = 0
		else:
			fired_out_of_range += 1

#*****************************************************************
func _fixed_process(delta):
	updateAnimation(delta)
	
	last_moving_state = moving_state
	turnTowardsObjectIfClose()
	handleAttacking()	
	rotateIfTurned(delta)
	pass

#*****************************************************************
func setState(s):
	pass

#*****************************************************************
#  Check if player is on ground by using a ray cast
func isOnGround():
	if(ground_ray.is_colliding() && canJump &&
		# Make sure object isn't in the process of being deleted
		!ObjectTypeTests.isCollectable( ground_ray.get_collider())):
#		print("Jumping_state: "+ str(state))
		setState(GROUNDED_STATE)
		return true	
#	print("Jumping_state: "+ str(state))
	return false
	pass

#*****************************************************************
func updateAnimation(dt):
	animation_player.advance(dt)
	var on_ground = isOnGround()
	var current_animation = animation_player.get_current_animation()
	var length = animation_player.get_current_animation_length()
	var position = animation_player.get_current_animation_pos()
	
	if(on_ground && current_animation != WALKING_ANIMATION_NAME && 
		current_animation != FLYING_FIRE_ANIMATION_NAME):
			
		print("Krampus is in walking animation")

		animation_player.set_current_animation(WALKING_ANIMATION_NAME)
	elif(!on_ground && current_animation != FLYING_ANIMATION_NAME &&
		current_animation != FLYING_FIRE_ANIMATION_NAME):
			
		animation_player.set_current_animation(FLYING_ANIMATION_NAME)

	elif(current_animation == FLYING_FIRE_ANIMATION_NAME && 
		position >= length):
		print("Animation position: "+ str(position) + " length: "+ str(length))
		animation_player.set_current_animation(FLYING_ANIMATION_NAME)
		
	pass

#*****************************************************************
func _on_Area_body_enter( body ):
	print("Object got close to Krampus: "+ str(body))
	if(ObjectTypeTests.isHero(body)):
		object_to_track = body
		print("hero close to krampus")

#*****************************************************************
func _on_Area_body_exit( body ):
	if(ObjectTypeTests.isHero(body)):
		object_to_track = null
		print("hero close to krampus")

#*****************************************************************
func _on_attack_timer_timeout():
	if(is_on_screen):
		can_attack = true

#*****************************************************************
func _on_VisibilityEnabler_enter_screen():
	# Wait a little while on screen before we're allowed to attack
	if(attack_timer.get_time_left() > 0):
		return
	attack_timer.set_wait_time(MIN_TIME_ON_SCREEN_BETWEEN_ATTACKS_SECONDS)
	attack_timer.start()
	print("Krampus entered screen..")
	is_on_screen = true

#*****************************************************************
func _on_VisibilityEnabler_exit_screen():
	print("Krampus EXITED screen..")
	attack_timer.stop()
	can_attack = false
	
