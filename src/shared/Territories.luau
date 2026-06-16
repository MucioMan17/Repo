-- Capturable territories. Each is a circular zone (captured by standing in it).
-- `position` is the zone center; `radius` is how far the zone reaches (studs).
-- Capture uses horizontal (X/Z) distance, so the height doesn't matter — you can
-- move these to match your real map later, or replace the auto-spawned markers.
return {
	{ id = "docks",    name = "The Docks", position = Vector3.new(0, 1, 0),    radius = 16 },
	{ id = "downtown", name = "Downtown",  position = Vector3.new(90, 1, 0),   radius = 16 },
	{ id = "casino",   name = "The Casino", position = Vector3.new(-90, 1, 0), radius = 16 },
}
