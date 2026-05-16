extends BaseEnemy
class_name SmallEnemy

const EnemyConstants = preload("res://scripts/core/Constants.gd")

func _init() -> void:
	configure_base_stats(EnemyConstants.SMALL_ENEMY_HP, EnemyConstants.SMALL_ENEMY_SPEED, EnemyConstants.SMALL_ENEMY_DAMAGE, 10.0)
	configure_damage_number_style(18, Color(1.0, 0.95, 0.55), Color(0.08, 0.02, 0.0, 0.8), -34.0, -34.0, 10.0, 10.0)

func _get_body_color() -> Color:
	return Color(1.0, 0.45, 0.32).lerp(Color(0.45, 0.0, 0.0), clampf(float(difficulty_tier) / 5.0, 0.0, 1.0))
