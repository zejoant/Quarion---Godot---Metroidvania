extends Node

var app_id = "3870310"

func _init():
	OS.set_environment("SteamAppID", app_id)
	OS.set_environment("SteamGameID", app_id)

#func _process(_delta):
	#Steam.run_callbacks()

func _ready():
	Steam.steamInit()
	
	if !Steam.isSteamRunning():
		print("ERROR: Steam not running, bruh")
		return
	
	print("Steam is running")
	
	#clear_all_achivements()

func get_achivement(achivement_name: String):
	if !Steam.getAchievement(achivement_name)["achieved"]:
		Steam.setAchievement(achivement_name)
		Steam.storeStats()

func remove_achivement(achivement_name: String):
	if Steam.getAchievement(achivement_name)["achieved"]:
		Steam.clearAchievement(achivement_name)
		Steam.storeStats()

func clear_all_achivements():
	for ach in ["SkyfishAura", "SpiderGauntlets", "SwiftwindAmulet", "PegasusBoots", "FreezewakeCharm", "PhantomFlame", "HermitBoss", "NormalEnding", "GoodEnding", "FullMap", "AllApples", "100%", "FullAmulet", "Bubble", "Apaolo", "NoDeath", "Speedrun"]:
		if Steam.getAchievement(ach)["achieved"]:
			Steam.clearAchievement(ach)
	Steam.storeStats()
