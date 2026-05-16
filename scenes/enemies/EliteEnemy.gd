extends BaseEnemy
class_name EliteEnemy

const EnemyConstants = preload("res://scripts/core/Constants.gd")

func _init() -> void:
	configure_base_stats(EnemyConstants.ELITE_HP, EnemyConstants.ELITE_SPEED, EnemyConstants.ELITE_DAMAGE, 22.0)
	configure_damage_number_style(20, Color(1.0, 0.85, 0.95), Color(0.08, 0.0, 0.04, 0.8), -50.0, -36.0, 12.0, 10.0)

@onready var health_fill: Polygon2D = $HealthFill

func _sync_visuals() -> void:
	super._sync_visuals()
	var ratio := get_hp_ratio()
	health_fill.polygon = PackedVector2Array([
		Vector2(-28, -38),
		Vector2(-28 + 56.0 * ratio, -38),
		Vector2(-28 + 56.0 * ratio, -32),
		Vector2(-28, -32),
	])

func _get_body_color() -> Color:
	return Color(0.36, 0.0, 0.0).lerp(Color(0.12, 0.0, 0.0), clampf(float(difficulty_tier) / 5.0, 0.0, 1.0))
