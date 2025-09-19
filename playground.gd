extends Node2D

## Also controls the birth percentage
@export_range(0, 100, 0.5) var purgePercent: float = 75.0
@export var initialPopulation: int = 100
@export var headUpBonus: float = 2.0
@export var guaranteedReproduce: int = 10

var rng = RandomNumberGenerator.new()
@onready var spawnPoint = $SpawnPoint

var botScene = preload("res://bot.tscn")

var totalDeaths = 0
var roundTime = 0
var generation = 0
var furthestDistanceWalked: float = 0.0
var highestScore: float = 0.0

var geneticInfo = []

func GetMoves():
	var ls = []
	for i in range(randi_range(1, 3)):
		ls.append([MoveMutate(),
		MoveMutate(),
		MoveMutate(),
		MoveMutate()])
	return ls

func PopulateGenetics():
		for i in range(initialPopulation):
			geneticInfo.append(
				{"geneticTimer": rng.randf_range(0.25, 1),
				"color": Color(rng.randf(), rng.randf(), rng.randf()),
				"geneticInfo": GetMoves()
				})

func CreateNewGeneration():
	if generation == 0:
		rng.randomize()
		PopulateGenetics()
	else:
		var deaths = Purge()
		totalDeaths += deaths
		$CanvasLayer/Control/VBoxContainer/DeathTally.text = "Total deaths: " + str(totalDeaths)
		CreateChildren(deaths)
	
	SpawnBots()
	$CanvasLayer/Control/VBoxContainer/Population.text = "Current population: " + str(spawnPoint.get_child_count())
	generation += 1
	$CanvasLayer/Control/VBoxContainer/Generation.text = "Generation " + str(ceil(generation))
	roundTime = GetNewRoundTime()

func MoveMutate():
	return rng.randf_range(-2, 2) / PI

func Purge():
	geneticInfo = []
	var toPurge = spawnPoint.get_children()
	var dead = toPurge.size() - toPurge.size() * (1 - purgePercent / 100.0)
	toPurge.sort_custom(func(a: RigidBody2D, b: RigidBody2D):
		
		var bonusA = headUpBonus if (a.get_colliding_bodies()) else 1.0
		var bonusB = headUpBonus if (b.get_colliding_bodies()) else 1.0
		if a.position.x > furthestDistanceWalked:
			furthestDistanceWalked = a.position.x
			$CanvasLayer/Control/VBoxContainer/HBoxContainer2/ColorRect.color = a.modulate
		if b.position.x > furthestDistanceWalked:
			furthestDistanceWalked = b.position.x
			$CanvasLayer/Control/VBoxContainer/HBoxContainer2/ColorRect.color = b.modulate
		$CanvasLayer/Control/VBoxContainer/HBoxContainer2/FurthestTravelled.text = "Furthest travelled: " + str(snapped(furthestDistanceWalked/10.0, 0.1)) + "u/s by " + ""
		if a.position.x * bonusA > highestScore:
			highestScore = a.position.x * bonusA
			$CanvasLayer/Control/VBoxContainer/HBoxContainer/ColorRect.color = a.modulate
		if b.position.x * bonusB > highestScore:
			highestScore = b.position.x * bonusB
			$CanvasLayer/Control/VBoxContainer/HBoxContainer/ColorRect.color = b.modulate
		$CanvasLayer/Control/VBoxContainer/HBoxContainer/Label.text = " with score " + str(snapped(highestScore, 0.1))
		return a.position.x * bonusA > b.position.x * bonusB)
	@warning_ignore("integer_division")
	for i in range(toPurge.size() * (1 - purgePercent / 100.0)):
		geneticInfo.append(
			{
				"geneticTimer": toPurge[i].geneticTimer,
				"geneticInfo": toPurge[i].geneticInfo,
				"color": toPurge[i].modulate
			}
			)
	for i in toPurge:
		spawnPoint.remove_child(i)
		i.queue_free()
	geneticInfo.reverse()
	return int(dead)

func CreateChildren(childCount: int):
	var children = []
	
	var clone = []
	var firstReproducers = min(guaranteedReproduce, geneticInfo.size())
	#for i in range(firstReproducers, geneticInfo.size()):
		#clone.append(geneticInfo[i])
	
	for i in range(firstReproducers):
		clone.append(geneticInfo[i])
	
	for c in clone:
		children.append(MakeMutatedCopy(c, 0.5))
	
	for v in range(childCount - firstReproducers):
		var i = geneticInfo.pick_random()
		# Make evolution harsher for the failures
		children.append(MakeMutatedCopy(i, 1.0 + 0.01 * max(geneticInfo.find(i) - firstReproducers, 0)))

	geneticInfo.append_array(children)

func MakeMutatedCopy(parent, mutationMult: float = 1.0):
		var child = {}
		child.geneticTimer = parent.geneticTimer + rng.randf_range(-0.01, 0.01)
		child.color = parent.color + Color(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05) * mutationMult)
		child.geneticInfo = []
		for ii in parent.geneticInfo:
			var info = []
			for iii in ii:
				info.append(clamp(iii + MoveMutate() * mutationMult, -PI*2, PI*2))
			child.geneticInfo.append(info)
		
		var chance = rng.randf()
		if chance > .9 and child.geneticInfo.size() < 10:
			child.geneticInfo.append([] + child.geneticInfo.pick_random())
		if chance < .9 and child.geneticInfo.size() > 1:
			child.geneticInfo.remove_at(randi_range(0, child.geneticInfo.size() - 1))
		return child

func SpawnBots():
	for i in geneticInfo:
		var bot = botScene.instantiate()
		bot.geneticInfo = i.geneticInfo
		bot.geneticTimer = i.geneticTimer
		bot.modulate = i.color
		
		spawnPoint.add_child(bot)

func GetNewRoundTime():
	@warning_ignore("integer_division")
	return 3 + 1 * floor(generation / 5)

func _physics_process(delta: float) -> void:
	$CanvasLayer/Control/VBoxContainer/RoundTime.text = "Time left: " + str(int(ceil(roundTime)))
	
	roundTime -= delta
	if roundTime <= 0:
		CreateNewGeneration()
