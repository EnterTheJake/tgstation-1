/datum/status_effect/rust_corruption
	alert_type = null
	id = "rust_turf_effects"
	tick_interval = 2 SECONDS
	remove_on_fullheal = TRUE

/datum/status_effect/rust_corruption/tick(seconds_between_ticks)
	if(issilicon(owner))
		owner.adjustBruteLoss(10 * seconds_between_ticks)
		return
	owner.adjust_disgust(10)
	owner.reagents.remove_all(1.5)
