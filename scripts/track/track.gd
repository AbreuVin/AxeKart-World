class_name Track
extends Node3D
## Pista gerada a partir de pontos de controle (curva fechada Catmull-Rom).
## Fornece consulta de posição (ponto mais próximo, lateral, progresso) e a malha visual.

const SAMPLES_PER_SEGMENT := 24
const CURB_WIDTH := 1.2
const BARRIER_EXTRA := 6.0
const OFFROAD_SPEED := 0.45

var data: Dictionary = {}
var road_width := 14.0
var laps := 3
var samples := PackedVector3Array()
var tangents := PackedVector3Array()
var cum_len := PackedFloat32Array()
var total_length := 0.0


func setup(d: Dictionary, build_visual := true) -> void:
	data = d
	road_width = float(d.get("largura", 14.0))
	laps = int(d.get("voltas", 3))
	_build_samples()
	if build_visual:
		_build_visuals()


# ---------- geometria ----------

static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


func _build_samples() -> void:
	var ctrl: Array[Vector3] = []
	for p in data.get("pontos", []):
		ctrl.append(Vector3(float(p[0]), 0.0, float(p[1])))
	var n := ctrl.size()
	samples.clear()
	for i in n:
		var p0 := ctrl[(i - 1 + n) % n]
		var p1 := ctrl[i]
		var p2 := ctrl[(i + 1) % n]
		var p3 := ctrl[(i + 2) % n]
		for s in SAMPLES_PER_SEGMENT:
			samples.append(_catmull(p0, p1, p2, p3, float(s) / SAMPLES_PER_SEGMENT))
	var m := samples.size()
	tangents.resize(m)
	cum_len.resize(m + 1)
	cum_len[0] = 0.0
	for i in m:
		var a := samples[i]
		var b := samples[(i + 1) % m]
		tangents[i] = (samples[(i + 1) % m] - samples[(i - 1 + m) % m]).normalized()
		cum_len[i + 1] = cum_len[i] + a.distance_to(b)
	total_length = cum_len[m]


func sample_count() -> int:
	return samples.size()


func right_at(i: int) -> Vector3:
	return tangents[i % samples.size()].cross(Vector3.UP).normalized()


## Ponto mais próximo da linha central. hint = índice anterior (busca local).
func nearest(pos: Vector3, hint := -1) -> Dictionary:
	var m := samples.size()
	var best_i := 0
	var best_t := 0.0
	var best_d := INF
	var from := 0
	var count := m
	if hint >= 0:
		from = hint - 30
		count = 61
	for k in count:
		var i := (from + k + m) % m
		var a := samples[i]
		var b := samples[(i + 1) % m]
		var ab := b - a
		var t := clampf((pos - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var q := a + ab * t
		var dd := Vector2(pos.x - q.x, pos.z - q.z).length_squared()
		if dd < best_d:
			best_d = dd
			best_i = i
			best_t = t
	var a2 := samples[best_i]
	var b2 := samples[(best_i + 1) % m]
	var point := a2.lerp(b2, best_t)
	var tangent := (b2 - a2).normalized()
	var right := tangent.cross(Vector3.UP).normalized()
	var lateral := (pos - point).dot(right)
	var dist := cum_len[best_i] + (cum_len[best_i + 1] - cum_len[best_i]) * best_t
	return {"index": best_i, "point": point, "tangent": tangent, "right": right,
		"lateral": lateral, "distance": dist, "fraction": dist / total_length}


## Posição de largada: fila dupla atrás da linha.
func grid_transform(slot: int) -> Transform3D:
	var back := 8.0 + float(slot) * 6.0
	var m := samples.size()
	# caminha para trás pela pista
	var i := m - 1
	var acc := 0.0
	while acc < back and i > 0:
		acc += samples[i].distance_to(samples[(i + 1) % m])
		i -= 1
	var side := -3.2 if slot % 2 == 0 else 3.2
	var pos := samples[i] + right_at(i) * side
	var fwd := tangents[i]
	var heading := atan2(-fwd.x, -fwd.z)
	return Transform3D(Basis(Vector3.UP, heading), pos)


# ---------- visual ----------

func _build_visuals() -> void:
	var asphalt := Color(String(data.get("cor_asfalto", "#3b3f4a")))
	var grass := Color(String(data.get("cor_grama", "#4d9b4a")))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	var m := samples.size()
	var hw := road_width * 0.5
	for i in m:
		var j := (i + 1) % m
		var ri := right_at(i)
		var rj := right_at(j)
		var a := samples[i]
		var b := samples[j]
		var y := 0.08
		var alt := asphalt.lightened(0.04) if (i / 3) % 2 == 0 else asphalt
		_quad(st, a - ri * hw, a + ri * hw, b + rj * hw, b - rj * hw, alt, y)
		# zebras
		var curb := Color("#e11d48") if (i / 2) % 2 == 0 else Color("#f8fafc")
		_quad(st, a + ri * hw, a + ri * (hw + CURB_WIDTH), b + rj * (hw + CURB_WIDTH), b + rj * hw, curb, y + 0.01)
		_quad(st, a - ri * (hw + CURB_WIDTH), a - ri * hw, b - rj * hw, b - rj * (hw + CURB_WIDTH), curb, y + 0.01)
		# faixa central tracejada
		if i % 4 == 0:
			_quad(st, a - ri * 0.15, a + ri * 0.15, b + rj * 0.15, b - rj * 0.15, Color("#e2e8f0"), y + 0.005)
	# linha de largada quadriculada
	var r0 := right_at(0)
	var t0 := tangents[0]
	var cells := 10
	for cx in cells:
		for cz in 2:
			var w0 := -hw + road_width * cx / cells
			var w1 := -hw + road_width * (cx + 1) / cells
			var z0 := cz * 1.0
			var z1 := z0 + 1.0
			var c := Color.WHITE if (cx + cz) % 2 == 0 else Color("#111827")
			var p := samples[0]
			_quad(st, p + r0 * w0 + t0 * z0, p + r0 * w1 + t0 * z0, p + r0 * w1 + t0 * z1, p + r0 * w0 + t0 * z1, c, 0.11)
	st.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "Road"
	road.mesh = st.commit()
	add_child(road)

	# chão
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(900, 900)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = grass
	gm.roughness = 1.0
	ground.material_override = gm
	var c := _center()
	ground.position = Vector3(c.x, -0.05, c.z)
	add_child(ground)

	_build_decoration()


func _center() -> Vector3:
	var s := Vector3.ZERO
	for p in samples:
		s += p
	return s / max(1, samples.size())


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, color: Color, y: float) -> void:
	var pts := [p0, p1, p2, p0, p2, p3]
	for p in pts:
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(p.x, y, p.z))


func _build_decoration() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("semente_decoracao", 1))
	var wanted := int(data.get("decoracao", 40))
	var c := _center()
	var placed := 0
	var tries := 0
	var trunk_mat := _flat_mat(Color("#8b5a2b"))
	var leaf_mat := _flat_mat(Color("#15803d"))
	var box_mat := _flat_mat(Color("#e7d7b0"))
	var tape_mat := _flat_mat(Color("#dc2626"))
	while placed < wanted and tries < wanted * 30:
		tries += 1
		var p := c + Vector3(rng.randf_range(-260, 260), 0, rng.randf_range(-260, 260))
		var info := nearest(p)
		if absf(info.lateral) < road_width * 0.5 + 10.0:
			continue
		var node := Node3D.new()
		node.position = p
		if rng.randf() < 0.7:
			# palmeira
			var h := rng.randf_range(5.0, 9.0)
			var trunk := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.25
			cyl.bottom_radius = 0.4
			cyl.height = h
			trunk.mesh = cyl
			trunk.material_override = trunk_mat
			trunk.position.y = h * 0.5
			node.add_child(trunk)
			for k in 5:
				var leaf := MeshInstance3D.new()
				var lb := BoxMesh.new()
				lb.size = Vector3(0.6, 0.15, 3.2)
				leaf.mesh = lb
				leaf.material_override = leaf_mat
				leaf.position = Vector3(0, h, 0)
				leaf.rotation = Vector3(deg_to_rad(-20), TAU * k / 5.0, 0)
				leaf.translate_object_local(Vector3(0, 0, 1.4))
				node.add_child(leaf)
		else:
			# pilha de processos
			var stack := rng.randi_range(2, 5)
			for k in stack:
				var b := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(1.6, 0.9, 1.2)
				b.mesh = bm
				b.material_override = box_mat
				b.position = Vector3(rng.randf_range(-0.1, 0.1), 0.45 + k * 0.9, 0)
				b.rotation.y = rng.randf_range(-0.2, 0.2)
				node.add_child(b)
			var tape := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(1.65, 0.2, 1.25)
			tape.mesh = tm
			tape.material_override = tape_mat
			tape.position.y = 0.9 * stack - 0.3
			node.add_child(tape)
		add_child(node)
		placed += 1


func _flat_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m
