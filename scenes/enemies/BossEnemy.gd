extends BaseEnemy
class_name BossEnemy

const EnemyConstants = preload("res://scripts/core/Constants.gd")

func _init() -> void:
	configure_base_stats(EnemyConstants.BOSS_HP, EnemyConstants.BOSS_SPEED, EnemyConstants.BOSS_DAMAGE, 30.0)
	configure_damage_number_style(22, Color(1.0, 0.78, 0.42), Color(0.08, 0.02, 0.0, 0.8), -64.0, -40.0, 14.0, 12.0)

func _draw() -> void:
	_draw_body_circle()
	draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 64, Color(1.0, 0.58, 0.16), 3.0)
	var bar_back := Rect2(Vector2(-42, -50), Vector2(84, 8))
	draw_rect(bar_back, Color(0.12, 0.02, 0.02), true)
	draw_rect(Rect2(bar_back.position, Vector2(bar_back.size.x * get_hp_ratio(), bar_back.size.y)), Color(1.0, 0.38, 0.15), true)
	draw_rect(bar_back, Color.WHITE, false, 1.0)

func _get_body_color() -> Color:
	return Color(0.22, 0.0, 0.0).lerp(Color(0.08, 0.0, 0.0), clampf(float(difficulty_tier - 2) / 2.0, 0.0, 1.0))
