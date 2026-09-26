/datum/status_effect/contractor_chassis
	id = "contractor chassis"
	alert_type = null
	duration = -1
	tick_interval = 1 SECONDS
	/// The one target each repair thread is aimed at by hand, or null while that thread picks its own
	var/list/focus = list("damage" = null, "body" = null, "organ" = null)
	/// Repairs run this many times faster on a thread aimed by hand instead of one left to itself
	var/manual_multiplier = 2
	/// Whether idle threads pick their own repairs. Off leaves every thread waiting to be aimed.
	var/automatic = TRUE
	/// Whether the chamber holds the occupant in stasis, the way a stasis bed does
	var/stasis = FALSE
	/// Cell energy stasis draws per second while it holds
	var/stasis_energy = 0.025 * STANDARD_CELL_CHARGE
	/// The order each thread works through on its own, first match wins
	var/static/list/auto_order = list(
		"damage" = list(OXY, BRUTE, BURN, TOX),
		"body" = list("bleeding", "blood", "temperature", "wounds"),
		"organ" = list(ORGAN_SLOT_HEART, ORGAN_SLOT_BRAIN, ORGAN_SLOT_LUNGS, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_APPENDIX),
	)
	/// Damage healed per second on the selected damage type
	var/damage_rate = 2
	/// Oxygen healed per second on top of damage_rate while oxygen is selected
	var/oxy_bonus = 2
	/// Blood volume restored per second, up to BLOOD_VOLUME_NORMAL
	var/blood_rate = 2
	/// Kelvin per second the occupant is dragged back towards a normal body temperature
	var/temperature_rate = 10
	/// Bleed stacks cleared from each bodypart per second
	var/bleed_rate = 1
	/// Blood flow bled off each wound per second, before the wound itself closes
	var/wound_rate = 0.1
	/// Damage repaired per second on the selected organ
	var/organ_rate = 1.4
	/// Cell energy each running repair thread draws per second
	var/thread_energy = 0.0125 * STANDARD_CELL_CHARGE
	/// Cell energy drawn to charge the resuscitation array once
	var/charge_energy = 0.5 * STANDARD_CELL_CHARGE
	/// How long the array spends charging before it can discharge
	var/charge_time = 7 SECONDS
	/// world.time the current charge began, or 0 while not charging
	var/charge_started = 0
	/// Whether the array holds a charge ready to discharge
	var/charged = FALSE
	/// world.time the occupant was sealed in
	var/sealed_at = 0
	/// Drowsiness added per second to an occupant with no contractor implant
	var/drowsiness_per_second = 2 SECONDS
	/// How long an occupant with no contractor implant stays awake before the chamber puts them under
	var/sleep_after = 10 SECONDS
	/// Sleep topped up each second once the occupant is under, so they wake shortly after release
	var/sleep_per_tick = 4 SECONDS

/datum/status_effect/contractor_chassis/on_apply()
	sealed_at = world.time
	RegisterSignal(owner, COMSIG_CARBON_ATTEMPT_BREATHE, PROC_REF(supply_breath))
	return TRUE

/datum/status_effect/contractor_chassis/on_remove()
	UnregisterSignal(owner, COMSIG_CARBON_ATTEMPT_BREATHE)
	set_stasis(FALSE)

/datum/status_effect/contractor_chassis/proc/supply_breath(mob/living/carbon/source, seconds_per_tick)
	SIGNAL_HANDLER
	var/static/datum/gas_mixture/station_breath
	if(isnull(station_breath))
		var/datum/gas_mixture/station_air = SSair.parse_gas_string(OPENTURF_DEFAULT_ATMOS, /datum/gas_mixture)
		station_breath = station_air.remove(station_air.total_moles() * BREATH_PERCENTAGE)
	var/datum/gas_mixture/breath = null
	if(can_breathe())
		breath = station_breath.copy()
		breath.temperature = source.get_body_temp_normal()
	INVOKE_ASYNC(source, TYPE_PROC_REF(/mob/living/carbon, check_breath), breath)
	return COMSIG_CARBON_BLOCK_BREATH

/datum/status_effect/contractor_chassis/proc/can_breathe()
	var/mob/living/carbon/patient = owner
	if(!istype(patient) || patient.stat >= HARD_CRIT)
		return FALSE
	var/obj/item/organ/lungs = patient.get_organ_slot(ORGAN_SLOT_LUNGS)
	return !(lungs?.organ_flags & ORGAN_FAILING)

/datum/status_effect/contractor_chassis/tick(seconds_between_ticks)
	if(!HAS_TRAIT(owner, TRAIT_CONTRACTOR_IMPLANT))
		owner.adjust_drowsiness(drowsiness_per_second * seconds_between_ticks)
		if(world.time >= sealed_at + sleep_after && owner.stat != DEAD)
			owner.Sleeping(sleep_per_tick)
	var/mob/living/silicon/robot/drone = owner.loc
	if(automatic)
		set_stasis(owner.stat >= SOFT_CRIT)
	if(stasis && !drone?.cell?.use(stasis_energy * seconds_between_ticks))
		set_stasis(FALSE)
	var/list/working = working_targets()
	if(!length(working))
		return
	if(!istype(drone) || !drone.cell?.use(thread_energy * length(working) * seconds_between_ticks))
		return
	for(var/thread in working)
		var/seconds = seconds_between_ticks * (focus[thread] ? manual_multiplier : 1)
		switch(thread)
			if("damage")
				repair_damage(working[thread], seconds)
			if("body")
				repair_body(working[thread], seconds)
			if("organ")
				repair_organ(working[thread], seconds)

/// What each thread is repairing right now, by hand or on its own. Threads with nothing to do are left out.
/datum/status_effect/contractor_chassis/proc/working_targets()
	. = list()
	for(var/thread in focus)
		var/target = focus[thread] || (automatic ? auto_target(thread) : null)
		if(target)
			.[thread] = target

/// The first thing this thread can find to repair on its own, or null if it has nothing to do
/datum/status_effect/contractor_chassis/proc/auto_target(thread)
	for(var/target in auto_order[thread])
		if(needs_repair(thread, target))
			return target
	return null

/datum/status_effect/contractor_chassis/proc/running_threads()
	return length(working_targets())
/datum/status_effect/contractor_chassis/proc/bleed_stacks()
	. = 0
	var/mob/living/carbon/patient = owner
	if(!istype(patient))
		return
	for(var/obj/item/bodypart/part as anything in patient.bodyparts)
		. += part.generic_bleedstacks

/datum/status_effect/contractor_chassis/proc/set_stasis(new_stasis)
	if(stasis == new_stasis)
		return FALSE
	stasis = new_stasis
	if(stasis)
		owner.apply_status_effect(/datum/status_effect/grouped/stasis, CONTRACTOR_STASIS_EFFECT)
		owner.extinguish_mob()
		playsound(owner, 'sound/effects/spray.ogg', 5, TRUE, 2, frequency = rand(24750, 26550))
	else
		owner.remove_status_effect(/datum/status_effect/grouped/stasis, CONTRACTOR_STASIS_EFFECT)
	var/mob/living/silicon/robot/drone = owner.loc
	if(istype(drone))
		drone.balloon_alert(drone, stasis ? "stasis engaged" : "stasis released")
	return TRUE

/datum/status_effect/contractor_chassis/proc/toggle_stasis()
	// Taking stasis into your own hands drops the whole system out of automatic, the same as aiming a thread.
	set_automatic(FALSE)
	return set_stasis(!stasis)

/datum/status_effect/contractor_chassis/proc/toggle_automatic()
	return set_automatic(!automatic)

/datum/status_effect/contractor_chassis/proc/set_automatic(new_automatic)
	if(automatic == new_automatic)
		return TRUE
	automatic = new_automatic
	// Handing the threads back drops every hand-aimed lock, and the doubled output that came with it.
	if(automatic)
		for(var/thread in focus)
			focus[thread] = null
	var/mob/living/silicon/robot/drone = owner.loc
	if(istype(drone))
		drone.balloon_alert(drone, automatic ? "life support automatic" : "life support manual")
	return TRUE

/datum/status_effect/contractor_chassis/proc/set_focus(thread, target)
	if(!(thread in focus))
		return FALSE
	// Aiming a thread by hand drops the whole system out of automatic. Only the switch puts it back.
	if(focus[thread] == target)
		focus[thread] = null
		return TRUE
	if(!needs_repair(thread, target))
		return FALSE
	focus[thread] = target
	set_automatic(FALSE)
	return TRUE

/datum/status_effect/contractor_chassis/proc/needs_repair(thread, target)
	var/static/list/damage_targets = list(BRUTE, BURN, TOX, OXY)
	var/mob/living/carbon/patient = owner
	switch(thread)
		if("damage")
			return (target in damage_targets) && owner.get_current_damage_of_type(target) > 0
		if("body")
			switch(target)
				if("blood")
					return owner.blood_volume < BLOOD_VOLUME_NORMAL
				if("temperature")
					return abs(owner.get_body_temp_normal() - owner.bodytemperature) >= 0.5
				if("bleeding")
					return bleed_stacks() > 0
				if("wounds")
					return istype(patient) && length(patient.all_wounds) > 0
		if("organ")
			var/obj/item/organ/organ = istype(patient) ? patient.get_organ_slot(target) : null
			return !isnull(organ) && organ.damage > 0
	return FALSE

/datum/status_effect/contractor_chassis/proc/repair_damage(damage_type, seconds)
	var/amount = damage_rate * seconds
	if(damage_type == OXY)
		amount += oxy_bonus * seconds
	owner.heal_damage_type(amount, damage_type)
	if(owner.get_current_damage_of_type(damage_type) <= 0)
		focus["damage"] = null

/datum/status_effect/contractor_chassis/proc/repair_body(target, seconds)
	var/mob/living/carbon/patient = owner
	switch(target)
		if("blood")
			owner.blood_volume = min(owner.blood_volume + blood_rate * seconds, BLOOD_VOLUME_NORMAL)
		if("temperature")
			var/step = temperature_rate * seconds
			owner.adjust_bodytemperature(clamp(owner.get_body_temp_normal() - owner.bodytemperature, -step, step))
		if("bleeding")
			if(istype(patient))
				for(var/obj/item/bodypart/part as anything in patient.bodyparts)
					part.adjustBleedStacks(-bleed_rate * seconds, 0)
		if("wounds")
			if(istype(patient))
				for(var/datum/wound/wound as anything in LAZYCOPY(patient.all_wounds))
					wound.adjust_blood_flow(-wound_rate * seconds)
					if(wound.blood_flow <= 0)
						wound.remove_wound()
	if(!needs_repair("body", target))
		focus["body"] = null

/datum/status_effect/contractor_chassis/proc/repair_organ(slot, seconds)
	var/mob/living/carbon/patient = owner
	var/obj/item/organ/organ = istype(patient) ? patient.get_organ_slot(slot) : null
	if(isnull(organ))
		focus["organ"] = null
		return
	organ.apply_organ_damage(-organ_rate * seconds)
	if(organ.damage <= 0)
		focus["organ"] = null

/datum/status_effect/contractor_chassis/proc/start_charge()
	set_automatic(FALSE)
	var/mob/living/carbon/patient = owner
	var/mob/living/silicon/robot/drone = owner.loc
	if(!istype(patient) || !istype(drone) || patient.stat != DEAD || charge_started || charged)
		return FALSE
	if(patient.can_defib() != DEFIB_POSSIBLE)
		drone.balloon_alert(drone, "shock will not take!")
		return FALSE
	if(!drone.cell?.use(charge_energy))
		drone.balloon_alert(drone, "not enough charge!")
		return FALSE
	charge_started = world.time
	patient.notify_revival("The chassis around you is trying to restart your heart!")
	playsound(patient, 'sound/machines/defib/defib_charge.ogg', 60, FALSE)
	to_chat(patient, span_notice("The chassis clamps tighten around your chest, and something inside it begins to whine..."))
	to_chat(drone, span_notice("Charging resuscitation array..."))
	addtimer(CALLBACK(src, PROC_REF(finish_charge)), charge_time)
	return TRUE

/datum/status_effect/contractor_chassis/proc/finish_charge()
	if(!charge_started)
		return
	charge_started = 0
	charged = TRUE
	playsound(owner, 'sound/machines/defib/defib_ready.ogg', 50, FALSE)

/datum/status_effect/contractor_chassis/proc/discharge()
	set_automatic(FALSE)
	var/mob/living/carbon/patient = owner
	var/mob/living/silicon/robot/drone = owner.loc
	if(!charged || !istype(patient))
		return FALSE
	charged = FALSE
	set_stasis(FALSE)
	if(patient.stat != DEAD || patient.can_defib() != DEFIB_POSSIBLE)
		playsound(patient, 'sound/machines/defib/defib_failed.ogg', 60, FALSE)
		to_chat(patient, span_warning("The whine dies away without a shock."))
		if(istype(drone))
			drone.balloon_alert(drone, "defib failed!")
		return TRUE
	var/total_brute = patient.get_brute_loss()
	var/total_burn = patient.get_fire_loss()
	var/revive_health = (HEALTH_THRESHOLD_CRIT + HEALTH_THRESHOLD_DEAD) * 0.5
	if(patient.health > revive_health)
		patient.adjust_oxy_loss(patient.health - revive_health, updating_health = FALSE)
	else
		var/overall_damage = total_brute + total_burn + patient.get_tox_loss() + patient.get_oxy_loss()
		var/mob_health = patient.health
		patient.adjust_oxy_loss((mob_health - revive_health) * (patient.get_oxy_loss() / overall_damage), updating_health = FALSE)
		patient.adjust_tox_loss((mob_health - revive_health) * (patient.get_tox_loss() / overall_damage), updating_health = FALSE, forced = TRUE)
		patient.adjust_fire_loss((mob_health - revive_health) * (total_burn / overall_damage), updating_health = FALSE)
		patient.adjust_brute_loss((mob_health - revive_health) * (total_brute / overall_damage), updating_health = FALSE)
	patient.updatehealth()
	playsound(patient, 'sound/machines/defib/defib_zap.ogg', 75, TRUE, -1)
	patient.set_heartattack(FALSE)
	patient.grab_ghost()
	patient.revive()
	patient.emote("gasp")
	patient.set_jitter_if_lower(200 SECONDS)
	SEND_SIGNAL(patient, COMSIG_LIVING_MINOR_SHOCK)
	to_chat(patient, span_userdanger("A jolt of current slams through your chest, dragging you back to life!"))
	if(istype(drone))
		to_chat(drone, span_notice("Occupant cardiac rhythm restored."))
		drone.balloon_alert(drone, "rhythm restored")
	return TRUE
