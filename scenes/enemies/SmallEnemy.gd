extends Area2D
class_name SmallEnemy

signal died(enemy: Node)
signal damaged_player(amount: float)

const Constants = preload("res://scripts/core/Constants.gd")

var hp: float = Constants.SMALL_ENEMY_HP
var max_hp: float = Constants.SMALL_ENEMY_HP
var speed: float = Constants.SMALL_ENEMY_SPEED
var damage: float = Constants.SMALL_ENEMY_DAMAGE
var player: Node2D
var contact_timer := 0.0
var difficulty_tier := 0
var overlapping_player := false
var radius := 10.0

func setup(target_player: Node2D) -> void:
	player = target_player

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	contact_timer = maxf(0.0, contact_timer - delta)
	if is_instance_valid(player):
		global_position += global_position.direction_to(player.global_position) * speed * delta
		if overlapping_player and contact_timer <= 0.0:
			contact_timer = Constants.ENEMY_CONTACT_COOLDOWN
			damaged_player.emit(damage)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		overlapping_player = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		overlapping_player = false

func configure_spawn_tier(level: int) -> void:
	difficulty_tier = maxi(0, level)
	var hp_multiplier := 1.0 + float(difficulty_tier) * Constants.ENEMY_DIFFICULTY_HP_MULTIPLIER
	var speed_multiplier := 1.0 + float(difficulty_tier) * Constants.ENEMY_DIFFICULTY_SPEED_MULTIPLIER
	max_hp *= hp_multiplier
	hp = max_hp
	speed *= speed_multiplier

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit(self)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _get_body_color())

func _get_body_color() -> Color:
	return Color(1.0, 0.45, 0.32).lerp(Color(0.55, 0.0, 0.0), clampf(float(difficulty_tier) / 2.0, 0.0, 1.0))
