extends Spatial

onready var ball = $CarBody
onready var car_mesh = $CarMesh
onready var ground_ray = $CarMesh/RayCast
onready var right_wheel = $CarMesh/tmpParent/suv/wheel_frontRight
onready var left_wheel = $CarMesh/tmpParent/suv/wheel_frontLeft

var sphere_offset = Vector3(0, -1.05, 0)
var acceleration = 50.0
var steering = 21.0 # turn amount in degrees
var turn_speed = 5 # how quickly the car turns
var turn_stop_limit = 0.75 # below this speed, the car does not turn

var body_tilt = 25

var speed_input = 0
var rotate_input = 0

func _ready():
	ground_ray.add_exception(ball)


func _physics_process(_delta):
	car_mesh.transform.origin = ball.transform.origin + sphere_offset
	# Accelerate based on car's forward direction
	ball.add_central_force(-car_mesh.global_transform.basis.z * speed_input)

func _process(delta):
	# we don't process the input if the car is in the air
	if not ground_ray.is_colliding():
		return
	
	speed_input = 0
	speed_input += Input.get_action_strength("accelerate")
	speed_input -= Input.get_action_strength("brake")
	speed_input *= acceleration
	
	rotate_input = 0
	rotate_input += Input.get_action_strength("steer_left")
	rotate_input -= Input.get_action_strength("steer_right")
	rotate_input *= deg2rad(steering)

	# rotate wheels for effect
	right_wheel.rotation.y = rotate_input*1.5
	left_wheel.rotation.y = rotate_input*1.5

	# smoke?
	var d = ball.linear_velocity.normalized().dot(-car_mesh.transform.basis.z)
	if ball.linear_velocity.length() > 5.5 and d < 0.9:
		$CarMesh/Smoke.emitting = true
		$CarMesh/Smoke2.emitting = true
	else:
		$CarMesh/Smoke.emitting = false
		$CarMesh/Smoke2.emitting = false
	
	# rotate the car mesh
	if ball.linear_velocity.length() > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(
			car_mesh.global_transform.basis.y, rotate_input)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(
			new_basis, turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
		# Because of floating point imprecision, repeatedly rotating a transform 
		# will eventually cause it to become distorted. The scale can drift or 
		# the axes can become no-perpendicular. In any script where you’re regu-
		# larly rotating a transform, it’s a good idea to use orthonormalized() 
		# to correct any error before it accumulates.

		# tilt body for effect
		var t = -rotate_input * ball.linear_velocity.length() / body_tilt
		car_mesh.rotation.z = lerp(car_mesh.rotation.z, t, 5 * delta)

	var n = ground_ray.get_collision_normal()
	var xform = align_with_y(car_mesh.global_transform, n.normalized())
	car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 10 * delta)


func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
