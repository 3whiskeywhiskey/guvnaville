extends RefCounted
class_name PerformanceProfiler

## Comprehensive performance profiling tool for Guvnaville
##
## Provides detailed performance measurement and tracking for:
## - FPS monitoring over time
## - Turn processing time
## - Memory usage tracking
## - Rendering performance
## - Pathfinding performance
## - System-level profiling
##
## Usage:
##   var profiler = PerformanceProfiler.new()
##   profiler.start_session("baseline_test")
##   profiler.start_profile("render_map")
##   # ... rendering code ...
##   profiler.end_profile("render_map")
##   profiler.end_session()
##   profiler.save_results("res://performance_results.json")
##
## @version 1.0
## @author Performance Optimization Agent

# ============================================================================
# CONSTANTS
# ============================================================================

const TARGET_FPS: int = 60
const TARGET_FRAME_TIME_MS: float = 16.67  # 1000ms / 60 fps
const TARGET_TURN_TIME_MS: int = 5000  # 5 seconds
const TARGET_MEMORY_MB: int = 2048  # 2 GB

# ============================================================================
# PROPERTIES
# ============================================================================

## Current profiling session name
var session_name: String = ""

## When the current session started
var session_start_time: int = 0

## All profile measurements for this session
var profiles: Dictionary = {}  # profile_name -> Array[measurement_dict]

## FPS samples collected over time
var fps_samples: Array[Dictionary] = []

## Memory samples collected over time
var memory_samples: Array[Dictionary] = []

## Turn processing samples
var turn_samples: Array[Dictionary] = []

## Active profile start times
var active_profiles: Dictionary = {}  # profile_name -> start_time_usec

## Whether profiling is currently active
var is_profiling: bool = false

## Accumulated statistics
var statistics: Dictionary = {}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

func start_session(name: String) -> void:
	"""
	Starts a new profiling session.

	Args:
		name: Name for this profiling session
	"""
	session_name = name
	session_start_time = Time.get_ticks_msec()
	is_profiling = true

	# Clear previous data
	profiles.clear()
	fps_samples.clear()
	memory_samples.clear()
	turn_samples.clear()
	active_profiles.clear()
	statistics.clear()

	print("[PerformanceProfiler] Session started: %s" % name)

func end_session() -> void:
	"""Ends the current profiling session and calculates statistics."""
	if not is_profiling:
		push_warning("[PerformanceProfiler] No active session to end")
		return

	var session_duration = Time.get_ticks_msec() - session_start_time

	# Calculate statistics
	_calculate_statistics()

	print("[PerformanceProfiler] Session ended: %s (duration: %d ms)" % [session_name, session_duration])
	print_summary()

	is_profiling = false

# ============================================================================
# PROFILING OPERATIONS
# ============================================================================

func start_profile(profile_name: String) -> void:
	"""
	Starts profiling a specific operation.

	Args:
		profile_name: Name of the operation being profiled
	"""
	active_profiles[profile_name] = Time.get_ticks_usec()

func end_profile(profile_name: String) -> Dictionary:
	"""
	Ends profiling for a specific operation and records the measurement.

	Args:
		profile_name: Name of the operation being profiled

	Returns:
		Dictionary with measurement data
	"""
	if not profile_name in active_profiles:
		push_warning("[PerformanceProfiler] Profile '%s' was not started" % profile_name)
		return {}

	var start_time = active_profiles[profile_name]
	var end_time = Time.get_ticks_usec()
	var duration_usec = end_time - start_time

	# Record measurement
	var measurement = {
		"profile": profile_name,
		"timestamp": Time.get_ticks_msec(),
		"duration_usec": duration_usec,
		"duration_ms": duration_usec / 1000.0,
		"memory_mb": _get_current_memory_mb()
	}

	if not profile_name in profiles:
		profiles[profile_name] = []
	profiles[profile_name].append(measurement)

	active_profiles.erase(profile_name)

	return measurement

func profile_function(profile_name: String, callable: Callable) -> Variant:
	"""
	Profiles a function call and returns its result.

	Args:
		profile_name: Name for this profile
		callable: Function to profile

	Returns:
		Result of the function call
	"""
	start_profile(profile_name)
	var result = callable.call()
	end_profile(profile_name)
	return result

# ============================================================================
# FPS MONITORING
# ============================================================================

func sample_fps() -> void:
	"""Samples current FPS and frame time."""
	var fps = Engine.get_frames_per_second()
	var frame_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

	var sample = {
		"timestamp": Time.get_ticks_msec(),
		"fps": fps,
		"frame_time_ms": frame_time_ms,
		"meets_target": fps >= TARGET_FPS and frame_time_ms <= TARGET_FRAME_TIME_MS
	}

	fps_samples.append(sample)

func monitor_fps_continuous(duration_ms: int, sample_interval_ms: int = 100) -> Array[Dictionary]:
	"""
	Monitors FPS continuously for a specified duration.

	Args:
		duration_ms: How long to monitor in milliseconds
		sample_interval_ms: How often to sample FPS

	Returns:
		Array of FPS samples
	"""
	var samples: Array[Dictionary] = []
	var start_time = Time.get_ticks_msec()
	var next_sample_time = start_time

	while Time.get_ticks_msec() - start_time < duration_ms:
		if Time.get_ticks_msec() >= next_sample_time:
			sample_fps()
			samples.append(fps_samples[-1])
			next_sample_time += sample_interval_ms

		# Small delay to avoid busy-waiting
		await Engine.get_main_loop().process_frame

	return samples

# ============================================================================
# MEMORY MONITORING
# ============================================================================

func sample_memory() -> void:
	"""Samples current memory usage."""
	var sample = {
		"timestamp": Time.get_ticks_msec(),
		"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0,
		"dynamic_mb": Performance.get_monitor(Performance.MEMORY_DYNAMIC) / 1024.0 / 1024.0,
		"total_mb": _get_current_memory_mb(),
		"meets_target": _get_current_memory_mb() < TARGET_MEMORY_MB
	}

	memory_samples.append(sample)

func _get_current_memory_mb() -> float:
	"""Returns current total memory usage in MB."""
	var static_mem = Performance.get_monitor(Performance.MEMORY_STATIC)
	var dynamic_mem = Performance.get_monitor(Performance.MEMORY_DYNAMIC)
	return (static_mem + dynamic_mem) / 1024.0 / 1024.0

# ============================================================================
# TURN PROCESSING
# ============================================================================

func start_turn_profile(faction_count: int) -> void:
	"""
	Starts profiling a turn processing operation.

	Args:
		faction_count: Number of factions in this turn
	"""
	start_profile("turn_processing")
	active_profiles["turn_faction_count"] = faction_count

func end_turn_profile() -> Dictionary:
	"""
	Ends turn profiling and records the measurement.

	Returns:
		Dictionary with turn measurement data
	"""
	var measurement = end_profile("turn_processing")

	if measurement:
		var faction_count = active_profiles.get("turn_faction_count", 1)
		measurement["faction_count"] = faction_count
		measurement["meets_target"] = measurement["duration_ms"] < TARGET_TURN_TIME_MS
		turn_samples.append(measurement)
		active_profiles.erase("turn_faction_count")

	return measurement

# ============================================================================
# RENDERING PROFILING
# ============================================================================

func profile_rendering(map_view) -> Dictionary:
	"""
	Profiles rendering performance of a MapView.

	Args:
		map_view: MapView instance to profile

	Returns:
		Dictionary with rendering metrics
	"""
	var metrics = {
		"timestamp": Time.get_ticks_msec(),
		"visible_chunks": 0,
		"total_chunks": 0,
		"visible_tiles": 0,
		"unit_count": 0,
		"draw_calls": 0
	}

	if map_view:
		if "visible_chunks" in map_view:
			metrics["visible_chunks"] = map_view.visible_chunks.size()
		if "chunks" in map_view:
			metrics["total_chunks"] = map_view.chunks.size()
		if "render_stats" in map_view:
			var stats = map_view.render_stats
			metrics["visible_tiles"] = stats.get("visible_tiles", 0)
			metrics["visible_units"] = stats.get("visible_units", 0)
			metrics["draw_calls"] = stats.get("draw_calls", 0)
		if "unit_renderers" in map_view:
			metrics["unit_count"] = map_view.unit_renderers.size()

	return metrics

# ============================================================================
# PATHFINDING PROFILING
# ============================================================================

func profile_pathfinding(spatial_query, start: Vector3i, goal: Vector3i) -> Dictionary:
	"""
	Profiles a pathfinding operation.

	Args:
		spatial_query: SpatialQuery instance
		start: Start position
		goal: Goal position

	Returns:
		Dictionary with pathfinding metrics
	"""
	start_profile("pathfinding")
	var path = spatial_query.find_path(start, goal)
	var measurement = end_profile("pathfinding")

	measurement["path_length"] = path.size()
	measurement["start"] = start
	measurement["goal"] = goal
	measurement["distance"] = spatial_query.manhattan_distance(start, goal)

	return measurement

# ============================================================================
# STATISTICS CALCULATION
# ============================================================================

func _calculate_statistics() -> void:
	"""Calculates aggregate statistics from all samples."""
	statistics.clear()

	# Profile statistics
	for profile_name in profiles:
		var measurements = profiles[profile_name]
		statistics[profile_name] = _calculate_measurement_stats(measurements)

	# FPS statistics
	if fps_samples.size() > 0:
		statistics["fps"] = _calculate_fps_stats(fps_samples)

	# Memory statistics
	if memory_samples.size() > 0:
		statistics["memory"] = _calculate_memory_stats(memory_samples)

	# Turn statistics
	if turn_samples.size() > 0:
		statistics["turns"] = _calculate_turn_stats(turn_samples)

func _calculate_measurement_stats(measurements: Array) -> Dictionary:
	"""Calculates statistics for an array of measurements."""
	if measurements.is_empty():
		return {}

	var durations: Array[float] = []
	for m in measurements:
		durations.append(m["duration_usec"])

	durations.sort()

	var total = 0.0
	var min_val = durations[0]
	var max_val = durations[0]

	for d in durations:
		total += d
		if d < min_val:
			min_val = d
		if d > max_val:
			max_val = d

	var count = durations.size()
	var avg = total / count
	var median = durations[count / 2]
	var p95 = durations[int(count * 0.95)] if count > 1 else max_val
	var p99 = durations[int(count * 0.99)] if count > 1 else max_val

	return {
		"count": count,
		"min_usec": min_val,
		"max_usec": max_val,
		"avg_usec": avg,
		"median_usec": median,
		"p95_usec": p95,
		"p99_usec": p99,
		"min_ms": min_val / 1000.0,
		"max_ms": max_val / 1000.0,
		"avg_ms": avg / 1000.0,
		"median_ms": median / 1000.0,
		"p95_ms": p95 / 1000.0,
		"p99_ms": p99 / 1000.0
	}

func _calculate_fps_stats(samples: Array) -> Dictionary:
	"""Calculates FPS statistics."""
	if samples.is_empty():
		return {}

	var total_fps = 0.0
	var total_frame_time = 0.0
	var min_fps = samples[0]["fps"]
	var max_fps = samples[0]["fps"]
	var meets_target_count = 0

	for sample in samples:
		var fps = sample["fps"]
		total_fps += fps
		total_frame_time += sample["frame_time_ms"]

		if fps < min_fps:
			min_fps = fps
		if fps > max_fps:
			max_fps = fps

		if sample["meets_target"]:
			meets_target_count += 1

	var count = samples.size()

	return {
		"count": count,
		"avg_fps": total_fps / count,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"avg_frame_time_ms": total_frame_time / count,
		"target_fps": TARGET_FPS,
		"meets_target_percent": (meets_target_count * 100.0) / count
	}

func _calculate_memory_stats(samples: Array) -> Dictionary:
	"""Calculates memory statistics."""
	if samples.is_empty():
		return {}

	var total_static = 0.0
	var total_dynamic = 0.0
	var total_memory = 0.0
	var max_memory = 0.0
	var meets_target_count = 0

	for sample in samples:
		total_static += sample["static_mb"]
		total_dynamic += sample["dynamic_mb"]
		total_memory += sample["total_mb"]

		if sample["total_mb"] > max_memory:
			max_memory = sample["total_mb"]

		if sample["meets_target"]:
			meets_target_count += 1

	var count = samples.size()

	return {
		"count": count,
		"avg_static_mb": total_static / count,
		"avg_dynamic_mb": total_dynamic / count,
		"avg_total_mb": total_memory / count,
		"max_total_mb": max_memory,
		"target_mb": TARGET_MEMORY_MB,
		"meets_target_percent": (meets_target_count * 100.0) / count
	}

func _calculate_turn_stats(samples: Array) -> Dictionary:
	"""Calculates turn processing statistics."""
	if samples.is_empty():
		return {}

	var total_time = 0.0
	var max_time = 0.0
	var meets_target_count = 0

	# Group by faction count
	var by_faction_count: Dictionary = {}

	for sample in samples:
		total_time += sample["duration_ms"]

		if sample["duration_ms"] > max_time:
			max_time = sample["duration_ms"]

		if sample["meets_target"]:
			meets_target_count += 1

		var faction_count = sample.get("faction_count", 1)
		if not faction_count in by_faction_count:
			by_faction_count[faction_count] = []
		by_faction_count[faction_count].append(sample["duration_ms"])

	var count = samples.size()

	var stats = {
		"count": count,
		"avg_ms": total_time / count,
		"max_ms": max_time,
		"target_ms": TARGET_TURN_TIME_MS,
		"meets_target_percent": (meets_target_count * 100.0) / count,
		"by_faction_count": {}
	}

	# Calculate stats per faction count
	for faction_count in by_faction_count:
		var times = by_faction_count[faction_count]
		var faction_total = 0.0
		for time in times:
			faction_total += time
		stats["by_faction_count"][faction_count] = {
			"count": times.size(),
			"avg_ms": faction_total / times.size()
		}

	return stats

# ============================================================================
# OUTPUT AND REPORTING
# ============================================================================

func print_summary() -> void:
	"""Prints a summary of the profiling session."""
	print("\n========================================")
	print("Performance Profiling Summary")
	print("Session: %s" % session_name)
	print("========================================\n")

	# Profile timings
	if not statistics.is_empty():
		print("--- Operation Timings ---")
		for profile_name in statistics:
			if profile_name in ["fps", "memory", "turns"]:
				continue

			var stats = statistics[profile_name]
			print("  %s:" % profile_name)
			print("    Count: %d" % stats["count"])
			print("    Avg: %.2f ms" % stats["avg_ms"])
			print("    Min: %.2f ms" % stats["min_ms"])
			print("    Max: %.2f ms" % stats["max_ms"])
			print("    P95: %.2f ms" % stats["p95_ms"])

	# FPS stats
	if "fps" in statistics:
		print("\n--- FPS Statistics ---")
		var stats = statistics["fps"]
		print("  Samples: %d" % stats["count"])
		print("  Avg FPS: %.1f" % stats["avg_fps"])
		print("  Min FPS: %.1f" % stats["min_fps"])
		print("  Max FPS: %.1f" % stats["max_fps"])
		print("  Avg Frame Time: %.2f ms" % stats["avg_frame_time_ms"])
		print("  Target: %d FPS" % stats["target_fps"])
		print("  Meets Target: %.1f%%" % stats["meets_target_percent"])

	# Memory stats
	if "memory" in statistics:
		print("\n--- Memory Statistics ---")
		var stats = statistics["memory"]
		print("  Samples: %d" % stats["count"])
		print("  Avg Total: %.2f MB" % stats["avg_total_mb"])
		print("  Max Total: %.2f MB" % stats["max_total_mb"])
		print("  Target: %d MB" % stats["target_mb"])
		print("  Meets Target: %.1f%%" % stats["meets_target_percent"])

	# Turn stats
	if "turns" in statistics:
		print("\n--- Turn Processing Statistics ---")
		var stats = statistics["turns"]
		print("  Samples: %d" % stats["count"])
		print("  Avg Time: %.2f ms" % stats["avg_ms"])
		print("  Max Time: %.2f ms" % stats["max_ms"])
		print("  Target: %d ms" % stats["target_ms"])
		print("  Meets Target: %.1f%%" % stats["meets_target_percent"])

		if "by_faction_count" in stats:
			print("  By Faction Count:")
			for faction_count in stats["by_faction_count"]:
				var fc_stats = stats["by_faction_count"][faction_count]
				print("    %d factions: %.2f ms avg (%d samples)" % [faction_count, fc_stats["avg_ms"], fc_stats["count"]])

	print("\n========================================\n")

func get_statistics() -> Dictionary:
	"""
	Returns the calculated statistics.

	Returns:
		Dictionary with all statistics
	"""
	return statistics.duplicate(true)

func save_results(file_path: String) -> bool:
	"""
	Saves profiling results to a JSON file.

	Args:
		file_path: Path to save results

	Returns:
		True if successful, false otherwise
	"""
	var data = {
		"session_name": session_name,
		"session_duration_ms": Time.get_ticks_msec() - session_start_time,
		"timestamp": Time.get_datetime_string_from_system(),
		"statistics": statistics,
		"fps_samples": fps_samples,
		"memory_samples": memory_samples,
		"turn_samples": turn_samples,
		"profiles": profiles
	}

	var json = JSON.stringify(data, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file:
		file.store_string(json)
		file.close()
		print("[PerformanceProfiler] Results saved to: %s" % file_path)
		return true
	else:
		push_error("[PerformanceProfiler] Failed to save results to: %s" % file_path)
		return false

func load_results(file_path: String) -> bool:
	"""
	Loads profiling results from a JSON file.

	Args:
		file_path: Path to load results from

	Returns:
		True if successful, false otherwise
	"""
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		push_error("[PerformanceProfiler] Failed to load results from: %s" % file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("[PerformanceProfiler] Failed to parse JSON from: %s" % file_path)
		return false

	var data = json.data
	session_name = data.get("session_name", "")
	statistics = data.get("statistics", {})
	fps_samples = data.get("fps_samples", [])
	memory_samples = data.get("memory_samples", [])
	turn_samples = data.get("turn_samples", [])
	profiles = data.get("profiles", {})

	print("[PerformanceProfiler] Results loaded from: %s" % file_path)
	return true

# ============================================================================
# COMPARISON AND ANALYSIS
# ============================================================================

func compare_with(other_profiler: PerformanceProfiler, operation_name: String = "") -> Dictionary:
	"""
	Compares this profiler's results with another profiler.

	Args:
		other_profiler: Another PerformanceProfiler to compare with
		operation_name: Specific operation to compare (empty = all)

	Returns:
		Dictionary with comparison data
	"""
	var comparison = {
		"baseline": session_name,
		"optimized": other_profiler.session_name,
		"operations": {}
	}

	var ops_to_compare = []
	if operation_name.is_empty():
		# Compare all common operations
		for op in statistics:
			if op in other_profiler.statistics:
				ops_to_compare.append(op)
	else:
		ops_to_compare.append(operation_name)

	for op in ops_to_compare:
		if not op in statistics or not op in other_profiler.statistics:
			continue

		var baseline = statistics[op]
		var optimized = other_profiler.statistics[op]

		var improvement_percent = 0.0
		if "avg_ms" in baseline and "avg_ms" in optimized:
			var baseline_time = baseline["avg_ms"]
			var optimized_time = optimized["avg_ms"]
			improvement_percent = ((baseline_time - optimized_time) / baseline_time) * 100.0

		comparison["operations"][op] = {
			"baseline_avg_ms": baseline.get("avg_ms", 0),
			"optimized_avg_ms": optimized.get("avg_ms", 0),
			"improvement_percent": improvement_percent,
			"improvement_factor": baseline.get("avg_ms", 1) / optimized.get("avg_ms", 1) if optimized.get("avg_ms", 0) > 0 else 0
		}

	return comparison

func print_comparison(comparison: Dictionary) -> void:
	"""Prints a comparison report."""
	print("\n========================================")
	print("Performance Comparison")
	print("Baseline: %s" % comparison["baseline"])
	print("Optimized: %s" % comparison["optimized"])
	print("========================================\n")

	for op in comparison["operations"]:
		var data = comparison["operations"][op]
		print("  %s:" % op)
		print("    Baseline: %.2f ms" % data["baseline_avg_ms"])
		print("    Optimized: %.2f ms" % data["optimized_avg_ms"])
		print("    Improvement: %.1f%% (%.2fx faster)" % [data["improvement_percent"], data["improvement_factor"]])
		print()
