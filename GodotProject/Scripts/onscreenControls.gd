
extends Node2D

export(float) var scale = 1
export var scoreLabelPrefix = "Score: "

var viewportScale 
var viewportResolution
const view_port_index = 1

const VIEWPORT_SCALE_KEY = "viewportScale"
const VIEWPORT_RESOLUTION_KEY = "viewportResolution"
var score_label = null

#*****************************************************************
func _ready():
	resizeGUIBasedOnViewPort()
	score_label = get_node("score")
	pass

#*****************************************************************
func setScoreLabel(var score):
	score_label.set_text(scoreLabelPrefix + str(score))
	
#*****************************************************************
#  @return scale adjusted for uniform scaling
func getAdjustedUniformScale(var scale):
	var adjusted = Vector2()
	if(scale.y < scale.x):
		adjusted = Vector2(scale.y/scale.x, 1)
	else:
		adjusted = Vector2(1, scale.x/scale.y)
	print("adjusted scale: "+str(adjusted))
	return adjusted
	pass

#*****************************************************************
func recursiveUniformScale(node, combinedScale):
	for child in node.get_children():
		#resizeNode(child, getAdjustedUniformScale(combinedScale))
		pass
	pass

#*****************************************************************
func resizeNode(node, combinedScale):
	if(node.has_method("set_scale") && \
	   node.has_method("get_scale")):			
			node.set_scale(node.get_scale()*combinedScale)
			print("Adjusted scale is: " + str(node.get_scale()));
	recursiveUniformScale(node, combinedScale)

#*****************************************************************
func resizeGUIBasedOnViewPort():
	saveViewPortInfo()
	if(viewportScale == null):
		print("viewportScale was null!");
		return
	print("scale: " +str(scale) + " viewportScale: "+ str(viewportScale))
	var combinedScale = viewportScale*scale
	print("Scaling buttons by: "+ str(combinedScale))
	resizeNode(self, combinedScale)

	pass

#*****************************************************************
func saveViewPortInfo():
	# Save for other GUIs with Global
	if(!Globals.has(VIEWPORT_RESOLUTION_KEY)):
		viewportResolution = \
			get_tree().get_root().get_visible_rect().size
		print("Saved resolution: "+ \
			VIEWPORT_RESOLUTION_KEY +": " + str(viewportResolution))	
		Globals.set("viewportResolution", viewportResolution)
		
	if(!Globals.has(VIEWPORT_SCALE_KEY)):
		viewportScale = Vector2(viewportResolution.x/800, \
			viewportResolution.y / 600)
		print("Saved Scale"+ VIEWPORT_SCALE_KEY + ": "+ str(viewportScale));
		Globals.set(VIEWPORT_SCALE_KEY, viewportScale)
	pass
