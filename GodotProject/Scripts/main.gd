
extends Node

# member variables here, example:
# var a=2
# var b="textvar"
var res = preload("res://imported_Assets/SantaRigidBody.scn")

var list_of_stuff = []
var santa_count = -1
var time_passed = 0

var lookup_table = {}



#*****************************************************************
func getDictParam(param):
	return lookup_table[param]
	
#*****************************************************************
func _ready():
	set_process(true)
	pass

#*****************************************************************
func _process(delta):
	processInput(delta)
	time_passed += delta

	
#	if time_passed > 1:
#		newSanta()
#		time_passed = 0
#	for santa in list_of_stuff:
#		var position = get_node(santa).get_translation()
#		position.z += 10*delta
#		get_node(santa).set_translation(position)
	pass
	
#*****************************************************************
func processInput(delta):
	if(Input.is_action_pressed("exit")):
		OS.get_main_loop().quit()
	pass
	
#*****************************************************************
func newSanta():

	if(list_of_stuff.size() > 0):
		var prev_santa = get_node(list_of_stuff[list_of_stuff.size()-1])
		prev_santa.jump()

	var santa = res.instance()
	santa_count += 1
	var name = "santa"+str(santa_count)
	santa.set_name(name)
	print("New santa name: "+ santa.get_name())
	add_child(santa)
	list_of_stuff.push_back(name)
	
	print("Object owner is: "+ str(santa.get_owner()) + \
		"This node's owner is: "+ str(get_owner()))
	santa.set_owner(self)
	print("Object owner is: "+ str(santa.get_owner()) + \
		"This node's owner is: "+ str(get_owner()))
	pass


