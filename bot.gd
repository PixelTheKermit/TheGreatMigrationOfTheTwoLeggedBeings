extends RigidBody2D

var geneticInfo = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var legWeight = 0.25
var geneticTimer = .5
var curTimer = 0
var curGenInfo = 0
@onready var legs = [
	$Joints/LegUpper/LegUpper5,
	$Joints/LegUpper2/LegUpper7,
	$Joints/LegUpper/LegUpper5/LegLower/LegUpper6,
	$Joints/LegUpper2/LegUpper7/LegLower2/LegUpper8
]

@onready var angularLimits = [
	[$Joints/LegUpper/LegUpper5, [-PI / 4, PI / 4]],
	[$Joints/LegUpper2/LegUpper7, [-PI / 4, PI / 4]],
	[$Joints/LegUpper/LegUpper5/LegLower/LegUpper6, [-PI / 4, PI / 4]],
	[$Joints/LegUpper2/LegUpper7/LegLower2/LegUpper8, [-PI / 4, PI / 4]],
]

@onready var connections = [
	
]

func _physics_process(delta: float) -> void:
	curTimer += delta
	if curTimer > geneticTimer:
		curTimer = 0
		curGenInfo += 1
		
	curGenInfo = curGenInfo % geneticInfo.size()
	for i in angularLimits:
		if i[0].rotation < i[1][0] or i[0].rotation > i[1][1]:
			i[0].angular_velocity = 0
			#i[0].linear_velocity = Vector2.ZERO
		i[0].rotation = clamp(i[0].rotation, i[1][0], i[1][1]) 
	
	for i in legs.size():
		var leg:RigidBody2D = legs[i]
		#leg.linear_velocity = Vector2(0, 0)
		leg.angular_velocity = geneticInfo[curGenInfo][i]
	
	for i in angularLimits:
		if i[0].rotation < i[1][0] or i[0].rotation > i[1][1]:
			i[0].angular_velocity = 0
			#i[0].linear_velocity = Vector2.ZERO
		i[0].rotation = clamp(i[0].rotation, i[1][0], i[1][1]) 
