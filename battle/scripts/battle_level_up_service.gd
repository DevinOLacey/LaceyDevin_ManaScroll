extends RefCounted

const BattleConstants = preload("res://shared/constants/battle_constants.gd")


static func build_level_up_options(count: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option in BattleConstants.LEVEL_UP_OPTIONS:
		options.append(option.duplicate(true))

	options.shuffle()
	return options.slice(0, mini(count, options.size()))


static func get_option_by_id(option_id: String) -> Dictionary:
	for option in BattleConstants.LEVEL_UP_OPTIONS:
		if str(option.get("id", "")) == option_id:
			return option.duplicate(true)
	return {}
