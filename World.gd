extends Spatial

export(String, "player", "orthagonal") var camera_select setget _set_camera

func _set_camera(camera):
	camera_select = camera
	# the scene ready check is necessary since the setter can send signals before the scene is fully loaded
	if scene_ready:
		match camera:
			"player":
				# sets all properties and assets for Player View
				$CameraPivot/Camera.current = false
				$Player/Head/Camera.current = true

				$HUD.visible = true
				$Player.visible = true

				$CameraPivot.visible = false
				$CameraPivot/Arrow.visible = false
				arrow = $HUD/DirectionalArrow
				player = $Player
				offset = 270
				
				# sets arrow position
				arrow.position = $Player/Head/Camera.unproject_position($Player.translation)
			"orthagonal":
				# sets all properties and assets for Orthagonal View
				$Player/Head/Camera.current = false
				$CameraPivot/Camera.current = true

				$HUD.visible = false
				$Player.visible = false
				
				$CameraPivot.visible = true
				$CameraPivot/Arrow.visible = true
				arrow = $CameraPivot/Arrow
				player = $CameraPivot
				offset = 90
			
				# sets arrow position
				arrow.position = $CameraPivot/Camera.unproject_position($CameraPivot.translation)
			
				# adjusts the initial arrow size
				adjust = 1 - ($CameraPivot/Camera.size / cam_max)
				adjusted = (adjust * 0.30) + 0.10
				
				$CameraPivot/Arrow.scale.x = adjusted
				$CameraPivot/Arrow.scale.y = adjusted
		

var adjust
var adjusted

var nearest_node = null
var arrow
var player
var offset
var scene_ready = false

func _ready():
	scene_ready = true
	_set_camera("player")

func _process(_delta):
	
	if player:
		# sets nearest enemy, compares enemy distances to player and identifies the shortest, therefore, nearest enemy
#		for enemy in $Enemies.get_children():
		for node in get_tree().get_nodes_in_group("Detectable"):
			if nearest_node == null:
				nearest_node = node
			else:
				if node.translation.distance_to(player.translation) < nearest_node.translation.distance_to(player.translation):
					nearest_node = node

		# uses player distance to mesh to modify arrow color
		var distance = player.translation.distance_to(nearest_node.translation)
		
		var distance_normalized = 1.0 / ( distance - 0 + 1.0) * 10
		var distance_clamped = clamp(distance_normalized, 0, 1)
		
		# changes arrow color per nearest node parent name
		match nearest_node.get_parent().name:
			"Enemies":
				arrow.modulate = Color(1, 1-distance_clamped, 1-distance_clamped)
			"Items":
				arrow.modulate = Color(1-distance_clamped, 1-distance_clamped, 1)
			"Resources":
				arrow.modulate = Color(1-distance_clamped, 1, 1-distance_clamped)
				
		# controls arrow rotation for player view
		if $Player/Head/Camera.current == true:
			var angle = rad2deg(atan2($Player.translation.z-nearest_node.translation.z,$Player.translation.x-nearest_node.translation.x))
			arrow.rotation_degrees = angle+$Player.rotation_degrees.y+offset
			
		# controls arrow rotation for orthagonal view
		if $CameraPivot/Camera.current == true:
			var angle = rad2deg(atan2($CameraPivot.translation.z-nearest_node.translation.z,$CameraPivot.translation.x-nearest_node.translation.x))
			arrow.rotation_degrees = angle+$CameraPivot.rotation_degrees.y+offset
			
			var forward = $CameraPivot.transform.basis.z.normalized() * 1
			
			if Input.is_action_pressed("forward"):
				$CameraPivot.transform.origin += -forward
			if Input.is_action_pressed("backward"):
				$CameraPivot.transform.origin += forward
			if Input.is_action_pressed("left"):
				$CameraPivot.transform.origin += forward.cross(Vector3.UP) / 1.5
			if Input.is_action_pressed("right"):
				$CameraPivot.transform.origin += -forward.cross(Vector3.UP) / 1.5

			if Input.is_action_pressed("rotate_left"):
				$CameraPivot.rotation_degrees.y -= 1

			if Input.is_action_pressed("rotate_right"):
				$CameraPivot.rotation_degrees.y += 1
				

# maximum and minimum orthagonal camera size
var cam_max = 30
var cam_min = 10

func _input(event):
	if $CameraPivot/Camera.current == true:
		# scales arrow size per camera size
		adjust = 1 - ($CameraPivot/Camera.size / cam_max)
		adjusted = (adjust * 0.30) + 0.10

		if Input.is_action_pressed("zoom_in"):
			if $CameraPivot/Camera.size > cam_min:
				$CameraPivot/Camera.size -= 1

				arrow.scale.x = adjusted
				arrow.scale.y = adjusted
		if Input.is_action_pressed("zoom_out"):
			if $CameraPivot/Camera.size < cam_max:
				$CameraPivot/Camera.size += 1

				arrow.scale.x = adjusted
				arrow.scale.y = adjusted
