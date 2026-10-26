extends MissionJob
class_name KillQuotaJob
## Sweep & Clear: the LZ unlocks once the contract's kill quota is reached.

var kills_required: int = 25


func start() -> void:
	kills_required = int(contract.get("kills_required", 25))
	on_run_kills_changed(0)


func on_run_kills_changed(run_kills: int) -> void:
	if met:
		return
	if run_kills >= kills_required:
		_complete()
		return
	status_changed.emit("ELIMINATE HOSTILES  %d / %d" % [run_kills, kills_required], Color.WHITE)


func get_locked_hint() -> String:
	return "Eliminate %d hostiles before evac" % kills_required
