extends SceneTree

func _initialize() -> void:
	print("=== Phase A Smoke Test ===")

	# --- Build graph ---
	var doc := ShaderGraphDocument.new()
	doc.set_name("SmokeTest")
	doc.set_shader_domain("spatial")

	var add_id : String = doc.add_node("math/add", Vector2(0, 0))
	var mul_id : String = doc.add_node("math/multiply", Vector2(200, 0))
	var out_id : String = doc.add_node("output/spatial", Vector2(400, 0))

	print("Nodes: add=%s  mul=%s  out=%s" % [add_id, mul_id, out_id])

	# add.result → multiply.a
	doc.add_edge(add_id, "result", mul_id, "a")
	# multiply.result → output.roughness  (both FLOAT — valid)
	doc.add_edge(mul_id, "result", out_id, "roughness")

	print("Edges connected.")

	# --- Compile ---
	var compiler := ShaderGraphCompiler.new()
	var result : Dictionary = compiler.compile_gd(doc)

	print("")
	if result["success"]:
		print(">>> RESULT: SUCCESS <<<")
		print("--- Generated shader ---")
		print(result["shader_code"])
	else:
		print(">>> RESULT: FAILED <<<")

	var issues : Array = result["issues"]
	if issues.size() > 0:
		print("--- Issues ---")
		for issue in issues:
			var prefix := "INFO"
			match issue["severity"]:
				1: prefix = "WARN"
				2: prefix = "ERROR"
			print("[%s][%s] %s  (node=%s port=%s)" % [
				prefix, issue["code"], issue["message"],
				issue["node_id"], issue["port_id"]
			])

	print("")
	print("=== Smoke test complete ===")
	quit()
