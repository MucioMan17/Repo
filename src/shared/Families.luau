-- Family (faction) definitions. Rename, recolor, reposition, or add your own.
-- `id`   stable key used in data and remotes
-- `name` what players see
-- `color`family color (HQ pad, ESP, territory ownership, etc.)
-- `base` world position of the family's HQ / spawn (move these to suit your map)
return {
	{ id = "salvatore", name = "Salvatore", color = Color3.fromRGB(170, 40, 40),  base = Vector3.new(-120, 0, 120) },
	{ id = "moretti",   name = "Moretti",   color = Color3.fromRGB(40, 90, 170),  base = Vector3.new(0, 0, 140) },
	{ id = "bianchi",   name = "Bianchi",   color = Color3.fromRGB(60, 150, 80),  base = Vector3.new(120, 0, 120) },
}
