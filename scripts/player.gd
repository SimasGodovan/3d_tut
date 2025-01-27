extends CharacterBody3D

var player_speed := 3.0
var is_locked := false
var is_running := false

@export var walking_speed := 3
@export var running_speed := 3 * 2.5

@export var sensitivity_rot_y = -0.2
@export var sensitivity_rot_x = -0.2

@onready var visuals: Node3D = $Visuals
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera_mount: Node3D = %CameraMount
@onready var camera_3d: Camera3D = %Camera3D

var visuals_target_rotation: Basis

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visuals_target_rotation = visuals.global_transform.basis

func _input(event) -> void:
	if Input.is_action_pressed("rotate_camera_x"):
		if event is InputEventMouseMotion:
			var delta_rot_y: float = sensitivity_rot_y * deg_to_rad(event.relative.x)
			rotate_y(delta_rot_y)
			visuals.rotate_y(-delta_rot_y)
		
	if Input.is_action_pressed("rotate_camera_y"):
		if event is InputEventMouseMotion:
			var delta_rot_x: float = sensitivity_rot_x * event.relative.y
			camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x + delta_rot_x, -40.0, 40.0)

	if Input.is_action_pressed("zoom_in"):
		camera_3d.fov = clamp(camera_3d.fov - 5, 25, 75)
		
	if Input.is_action_pressed("zoom_out"):
		camera_3d.fov = clamp(camera_3d.fov + 5, 25, 75)
	
func _physics_process(delta: float) -> void:	
	if !animation_player.is_playing():
		is_locked = false

	if Input.is_action_just_pressed("attack"):
		if animation_player.current_animation != "kick":
			animation_player.play("kick")
			is_locked = true
	else:
		if Input.is_action_pressed("run_modifier"):
			player_speed = running_speed
			is_running = true
		else:
			player_speed = walking_speed
			is_running = false
		
	if is_locked:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_running:
			if animation_player.current_animation != "running":
				animation_player.play("running")
		else:
			if animation_player.current_animation != "walking":
				animation_player.play("walking")
		
		var target_basis = visuals.global_transform.looking_at(position + direction, Vector3.UP).basis
		visuals_target_rotation = visuals_target_rotation.slerp(target_basis, 7.5 * delta)
		visuals.global_transform.basis = visuals_target_rotation
		
		velocity.x = direction.x * player_speed
		velocity.z = direction.z * player_speed
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
			
		velocity.x = move_toward(velocity.x, 0, player_speed)
		velocity.z = move_toward(velocity.z, 0, player_speed)

	move_and_slide()
