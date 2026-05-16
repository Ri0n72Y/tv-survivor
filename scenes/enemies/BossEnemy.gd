extends BaseEnemy
class_name BossEnemy

const EnemyConstants = preload("res://scripts/core/Constants.gd")

func _init() -> void:
	configure_base_stats(EnemyConstants.BOSS_HP, EnemyConstants.BOSS_SPEED, EnemyConstants.BOSS_DAMAGE, 30.0)
	configure_damage_number_style(22, Color(1.0, 0.78, 0.42), Color(0.08, 0.02, 0.0, 0.8), -64.0, -40.0, 14.0, 12.0)

@onready var crown_ring: Line2D = $CrownRing
@onready var health_fill: Polygon2D = $HealthFill

func _sync_visuals() -> void:
	super._sync_visuals()
	crown_ring.points = _circle_points(radius + 5.0, 32, true)
	var ratio := get_hp_ratio()
	health_fill.polygon = PackedVector2Array([
		Vector2(-42, -50),
		Vector2(-42 + 84.0 * ratio, -50),
		Vector2(-42 + 84.0 * ratio, -42),
		Vector2(-42, -42),
	])

func _get_body_color() -> Color:
	return Color(0.22, 0.0, 0.0).lerp(Color(0.05, 0.0, 0.0), clampf(float(difficulty_tier) / 5.0, 0.0, 1.0))
