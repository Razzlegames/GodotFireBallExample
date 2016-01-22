
extends RigidBody

# Actual typical run speed (in x directions)
export var run_speed = 3.0
# The impulse of a jump
export var jump_impulse = 1.0
export var double_jump_impulse = 2.0

# How fast to scale the run animation exported from blender
#  (e.g. 2.0 is twice as fast)
export var run_animation_scaling = 1.0

# Timer for scheduling action
var jumpTimer = null

var max_speed = 3.1
var animation_player = null
# Used to detect collisions with the ground (can we jump tests etc)
var ground_ray = null
# Detect collisions with potentially stuck objects
var forward_ray_cast = null

#------------------------------------------------
# In air states
#------------------------------------------------
#  Min fall in the negative y direction to start the fall animation
const MIN_FALL_Y_VECOCITY = 0.2
const GROUNDED_STATE = 0
const JUMPING_STATE = 1
const DOUBLE_JUMPING_STATE = 2
# Used when character is falling
const FALLING_OFF_STATE = 3

# Current state
var state = GROUNDED_STATE
var previous_state = state

# List of pending tasks to perform during the next frame
var pending_tasks = []
const JUMP_TASK = 0

# List of bodies currently touching
var touching_bodies = []

# List of bodies close and below Santa
var close_below_bodies = []

var presents_collected = 0

#------------------------------------------------
# States to decide when to turn character
#------------------------------------------------
const RIGHT_STATE = 0
const LEFT_STATE = 1
var moving_state = RIGHT_STATE
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


# Reference to player mesh to rotate as needed
var player_mesh
# current speed of player, to help interpolate between frames
var current_speed = Vector3(0,0,0)

var ground_acceleration = 3
var air_acceleration = ground_acceleration/2.0


# Frames to let pass before scene objects have settled in the 
#   physics world
const MIN_SETTLE_FRAMES = 30

const IDLE_ANIMATION_NAME = "idle"
const RUNNING_ANIMATION_NAME = "Running"
const JUMPING_ANIMATION_NAME = "Jumping"
const LANDING_ANIMATION_NAME = "Landing"
const FALLING_ANIMATION_NAME = "Falling"
const FLIPPING_START_ANIMATION_NAME = "Flipping_start"
const FLIPPING_ANIMATION_NAME = "Flipping"

# Gui for displaying score and touch buttons
var gui = null

var ObjectTypeTests = load("ObjectTypeTests.gd")

#*****************************************************************
func getHeadingRight():
	return (next_x_rotation == 0)

#*****************************************************************
func _ready():
	
	add_to_group("Hero")
	# Initalization here
	gui = get_node("gui2DNode")
	gui.setScoreLabel(presents_collected)
	
	jumpTimer = get_node("JumpTimer")
	player_mesh = get_node("Spatial")
	animation_player = player_mesh.get_node("AnimationPlayer");
	print(animation_player.get_name())

	animation_player.set_current_animation(IDLE_ANIMATION_NAME)
	animation_player.set_speed(.5)
	animation_player.set_blend_time(RUNNING_ANIMATION_NAME, IDLE_ANIMATION_NAME, 3)
	animation_player.set_blend_time(IDLE_ANIMATION_NAME, RUNNING_ANIMATION_NAME, 0.2)
	animation_player.set_blend_time(IDLE_ANIMATION_NAME, JUMPING_ANIMATION_NAME, 0)
	animation_player.set_blend_time(RUNNING_ANIMATION_NAME, JUMPING_ANIMATION_NAME, 0)
	animation_player.set_active(true)

	ground_ray = get_node("ground_ray_cast")
	ground_ray.add_exception(self)
	forward_ray_cast = get_node("forward_ray_cast")
	forward_ray_cast.add_exception(self)
	
	setState(GROUNDED_STATE)
	set_fixed_process(true)
	
	set_process_input(true)
	var enabled = get_node("Area").is_monitoring_enabled()
	print("Monitoring enabled: "+str(enabled))
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

#*****************************************************************
# Move player using acceleration and apply given previous velocity
func move(speed, acc, delta):
	current_speed.x = lerp(current_speed.x, speed, acc*delta)
	var lin_vel = get_linear_velocity()
	set_linear_velocity(Vector3(current_speed.x, lin_vel.y, lin_vel.z))
	pass

#*****************************************************************
#  Check if player is on ground by using a ray cast
func isOnGround():
	if(ground_ray.is_colliding() && canJump &&
		# Make sure object isn't in the process of being deleted
		!ObjectTypeTests.isCollectable( ground_ray.get_collider()) &&
		!ObjectTypeTests.isEnemy(ground_ray.get_collider())):
#		print("Jumping_state: "+ str(state))
		setState(GROUNDED_STATE)
		return true	
#	print("Jumping_state: "+ str(state))
	return false
	pass

#*****************************************************************
func setRunningAnimation():
	var current = animation_player.get_current_animation()
	#print("isJumping(): "+ str(isJumping()) + " state: "+str(state) + \
	#  " animation: " + str(current) + " isOnGround: " + str(isOnGround()))
	if(	current != RUNNING_ANIMATION_NAME && !isJumping() && isOnGround()):
		#print("Set running animation")
		animation_player.set_current_animation(RUNNING_ANIMATION_NAME)
	pass

#*****************************************************************
func isJumping():
	return (getState() == JUMPING_STATE || 
		getState() == DOUBLE_JUMPING_STATE ||
		!canJump)

#*****************************************************************
#   Make the player jump by applying impulse
# IF we can jump again right now (not double jump, just initial)
var canJump = true
func jump():

	if(!canJump):
		return

	canJump = false
	print("Jump impulse!!!!")
	apply_impulse(Vector3(0,0,0), Vector3(0, jump_impulse, 0))
	if(animation_player.get_current_animation() != JUMPING_ANIMATION_NAME):
		animation_player.set_current_animation(JUMPING_ANIMATION_NAME)
		animation_player.set_speed(2)

	jumpTimer.set_wait_time(0.3)
	jumpTimer.start()
	setState(JUMPING_STATE)
	pass

#*****************************************************************
#   Make the player jump by applying impulse
func doubleJump():
	var current_vel = get_linear_velocity()
	set_linear_velocity(Vector3(current_vel.x, 0, current_vel.z))

	apply_impulse(Vector3(0,0,0), Vector3(0, double_jump_impulse, 0))
	var current = animation_player.get_current_animation()
	if(current != FLIPPING_START_ANIMATION_NAME &&
			current != FLIPPING_ANIMATION_NAME):
		animation_player.set_current_animation(FLIPPING_START_ANIMATION_NAME)
		animation_player.set_speed(2)
	setState(DOUBLE_JUMPING_STATE)
	pass	

#*****************************************************************
func canRun(direction):
	
	if(forward_ray_cast.is_colliding() &&
		#!ObjectTypeTests.isEnemy(forward_ray_cast.get_collider()) &&
		!ObjectTypeTests.isCollectable(forward_ray_cast.get_collider()) &&
		
		forward_ray_cast.get_collision_normal().dot(direction) < 0):
		return false
	else:
		return true

#*****************************************************************
func handleJumpAction():
	print("handleJumpAction: state: "+ str(state))
	var on_ground = isOnGround()
	if(on_ground && state != JUMPING_STATE):
		jump()
	elif(!on_ground && state == JUMPING_STATE && get_linear_velocity().y < 0):
		doubleJump()

#*****************************************************************
func _input(event):
	if(event.is_action_pressed("jump") && 
	  !event.is_echo() && event.is_action("jump")):
			handleJumpAction()
	pass

#*****************************************************************
func processInput(delta):

  last_moving_state = moving_state
  if(Input.is_action_pressed("run_right")):
    if(canRun(Vector3(1,0,0))):
      if isOnGround():
        move(run_speed, ground_acceleration, delta)
        setRunningAnimation()
      else:
        move(run_speed, air_acceleration, delta)
      moving_state = RIGHT_STATE

  elif(Input.is_action_pressed("run_left")):
    if(canRun(Vector3(-1,0,0))):
      if isOnGround():
        #print ("Left running on ground")
        move(-run_speed, ground_acceleration, delta)
        setRunningAnimation()
      else:
        #print ("Left running in air")
        move(-run_speed, air_acceleration, delta)
      moving_state = LEFT_STATE

  rotateIfTurned(delta)
  pass

#*****************************************************************
func updateAnimation(dt):
	animation_player.advance(dt)
	var on_ground = isOnGround()
	var current_animation = animation_player.get_current_animation()

	# Don't transition animation states unless player is settled
	if(frame_count < MIN_SETTLE_FRAMES):
		return

	if(on_ground || !isJumping()):
		# Should really be if you were falling for more than 
		#   x seconds or something, else no Landing animation.
		if(current_animation == FALLING_ANIMATION_NAME &&
				previous_state == JUMPING_STATE):
			#animation_player.set_current_animation(LANDING_ANIMATION_NAME)
			#print("Set animation to Landing")
			animation_player.set_speed(1)

		elif(current_animation == LANDING_ANIMATION_NAME &&
				animation_player.get_current_animation_pos() <
				animation_player.get_current_animation_length()):
			#print ("Waiting for landing to finish")
			return

		elif(get_linear_velocity().length_squared() <  0.04 &&
				current_animation != IDLE_ANIMATION_NAME ):
			#print ("Setting animation to idle"+ str(frame_count) + \
					#   "Previous animation was: "+ str(current_animation))
				animation_player.set_speed(.5)
				animation_player.set_current_animation(IDLE_ANIMATION_NAME)

		elif(current_animation == RUNNING_ANIMATION_NAME):
			#print ("Setting animation to running"+ str(frame_count))

			# abs = Don't play animation in reverse!
			var speed = abs(get_linear_velocity().x/run_speed * run_animation_scaling)

			animation_player.set_speed(speed)

	# In Air case
#	else
#		if(animation_player.get_current_animation() == JUMPING_ANIMATION_NAME &&
#			 get_linear_velocity().y < 0):
#			animation_player.set_current_animation(FALLING_ANIMATION_NAME)
#			animation_player.set_speed(1)

	# Should really be if you were falling for more than 
		#   x seconds or something
	if(!on_ground && get_linear_velocity().y < MIN_FALL_Y_VECOCITY && 
	  animation_player.get_current_animation() != FALLING_ANIMATION_NAME &&
	   # Don't restart landing animation 
	  animation_player.get_current_animation() != LANDING_ANIMATION_NAME):

		animation_player.set_current_animation(FALLING_ANIMATION_NAME)
		animation_player.set_speed(1)

	pass

#*****************************************************************
func processTasks():
	for task in pending_tasks:
		if(task == JUMP_TASK):
			jump()
			pending_tasks.erase(JUMP_TASK)
	pass

var frame_count = 0
#*****************************************************************
func _fixed_process(dt):
	#	print("delta: " , dt)
	frame_count += 1

	updateAnimation(dt)
	processTasks()
	processInput(dt)
	pushAwayFromStuckBodies()

	#print("Current state: "+ str(state) + " isOnGround(): "+ str(isOnGround()))
	#print("Current animation: "+ animation_player.get_current_animation())
	#if(frame_count % 100 == 0):
	#	print("get_linear_velocity(): ", get_linear_velocity() )
	#	print("Touching bodies: "+ str(touching_bodies.size()))
	#	for body in touching_bodies:
	#		print(body)

#*****************************************************************
func pushAwayFromBody(body):
	#push away from that collision to avoid getting stuck
	var direction = get_global_transform().origin \
	   - body.get_global_transform().origin
	# Adjust if too close
	if(direction.length_squared() < 0.0000001):
	   print("Too close!")
	   return
	#print("Pushing away from: "+ str(body) + \
	#   " pos: "+ str(get_global_transform().origin) + \
	#   " body: "+ str(body.get_global_transform().origin) +\
	#   " dir: "+ str(direction))
	apply_impulse(Vector3(0,0,0), direction.normalized())	
	pass

#*****************************************************************
func pushAwayFromStuckBodies():
	if(forward_ray_cast.is_colliding()):
		#print("forward_ray_cast is touching");
		var body = forward_ray_cast.get_collider()
		if(body == null):
			print("Forward touching body was null!")
			return;
		if(!ObjectTypeTests.isCollectable(body) && !isOnGround()):
			# don't push away in the air so character will fall properly
			#   (else pushing forward will keep player in air against object)
			pushAwayFromBody(body)
		elif(!ObjectTypeTests.isCollectable(body)):
			apply_impulse(Vector3(0,0,0), forward_ray_cast.get_collision_normal())

#*****************************************************************
func _on_SantaRigidBody_body_enter( body ):
	print("Santa touched stuff" + str(body) + " has collected: "+\
			str(body.has_method("collected")))

	if(ObjectTypeTests.isCollectable(body)):
		print ("Touched Collectable: "+ body.get_name()+  "!")

		if(body.has_method("collected")):
			body.collected()
		else:
			print("ERROR: DOESNT HAVE collected method in class!"+ str(body))

		addPresentCollected()
		print("Presents collected: "+ str(presents_collected))

	elif( ObjectTypeTests.isEnemy(body)):
		# Santa jumped on enemy
		#if(abs( get_translation().y - body.get_translation().y) > 1.3):
		if(body in close_below_bodies ||
		  body == ground_ray.get_collider()):
			doubleJump()
			print("Santa jumped on enemy");

	else:
		# Make sure we track this
		touching_bodies.push_back(body)
		pushAwayFromBody(body)
		pass
	
#*****************************************************************
func addPresentCollected():
	presents_collected += 1
	gui.setScoreLabel(presents_collected)
	pass

#*****************************************************************
func setState(s):
	previous_state = state
	state = s
	pass

#*****************************************************************
func getState():
	return state
#*****************************************************************	
func _on_SantaRigidBody_body_exit( body ):
	print("body exited" + str(body))
	touching_bodies.erase(body)
	pass # replace with function body

#*****************************************************************	
func _on_JumpTimer_timeout():
	print("Renabling Jump!")
	canJump = true
	jumpTimer.stop()
	pass # replace with function body

#*****************************************************************	
func _on_Area_body_enter( body ):
	close_below_bodies.push_back(body)
	print("Touched close bodies below : "+ str(close_below_bodies.size()))

#*****************************************************************	
func _on_Area_body_exit( body ):
	close_below_bodies.erase(body)
	print("EXIT close bodies below : "+ str(close_below_bodies.size()))
