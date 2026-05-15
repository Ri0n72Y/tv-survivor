extends BaseEnemy
class_name EliteEnemy

const EnemyConstants = preload("res://scripts/core/Constants.gd")

func _init() -> void:
	configure_base_stats(EnemyConstants.ELITE_HP, EnemyConstants.ELITE_SPEED, EnemyConstants.ELITE_DAMAGE, 22.0)
	configure_damage_number_style(20, Color(1.0, 0.85, 0.95), Color(0.08, 0.0, 0.04, 0.8), -50.0, -36.0, 12.0, 10.0)

func _draw() -> void:
	_draw_body_circle()
	var bar_back := Rect2(Vector2(-28, -38), Vector2(56, 6))
	draw_rect(bar_back, Color(0.12, 0.02, 0.06), true)
	draw_rect(Rect2(bar_back.position, Vector2(bar_back.size.x * get_hp_ratio(), bar_back.size.y)), Color(0.95, 0.25, 0.7), true)
	draw_rect(bar_back, Color.WHITE, false, 1.0)

func _get_body_color() -> Color:
	return Color(0.36, 0.0, 0.0).lerp(Color(0.18, 0.0, 0.0), clampf(float(difficulty_tier - 2) / 2.0, 0.0, 1.0))
