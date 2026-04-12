extends RefCounted

const UPGRADE_OPTIONS := [
	{
		"id": "path_of_flame",
		"title": "The Path of Flame",
		"subtitle": "Embrace the ember road and sharpen your next ascent.",
		"accent": Color(0.96, 0.47, 0.27, 1.0),
	},
	{
		"id": "path_of_energy",
		"title": "The Path of Energy",
		"subtitle": "Channel surging mana and keep your momentum alive.",
		"accent": Color(0.38, 0.83, 1.0, 1.0),
	},
	{
		"id": "path_of_frost",
		"title": "The Path of Frost",
		"subtitle": "Lean into the cold current and steady your power.",
		"accent": Color(0.72, 0.91, 1.0, 1.0),
	},
]


static func build_level_up_options(count: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option in UPGRADE_OPTIONS:
		options.append(option.duplicate(true))

	options.shuffle()
	return options.slice(0, mini(count, options.size()))


static func get_option_by_id(option_id: String) -> Dictionary:
	for option in UPGRADE_OPTIONS:
		if str(option.get("id", "")) == option_id:
			return option.duplicate(true)
	return {}
