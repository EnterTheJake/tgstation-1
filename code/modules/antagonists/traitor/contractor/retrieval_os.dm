/datum/retrieval_os
	/// The drone this operating system runs on
	var/mob/living/silicon/robot/model/contractor/drone

/datum/retrieval_os/New(mob/living/silicon/robot/model/contractor/new_drone)
	. = ..()
	drone = new_drone

/datum/retrieval_os/Destroy(force)
	drone = null
	return ..()

/datum/retrieval_os/ui_host(mob/user)
	return drone

/datum/retrieval_os/ui_state(mob/user)
	return GLOB.conscious_state

/datum/retrieval_os/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RetrievalOS")
		ui.open()

/datum/retrieval_os/proc/refresh()
	update_static_data_for_all_viewers()

/datum/retrieval_os/proc/get_occupant()
	return locate(/mob/living) in drone?.contents

/datum/retrieval_os/proc/get_contractor_state()
	var/mob/contractor = drone?.contractor_ref?.resolve()
	var/datum/antagonist/traitor/traitor = contractor?.mind?.has_antag_datum(/datum/antagonist/traitor)
	return traitor?.uplink_handler?.contractor_state

/datum/retrieval_os/proc/get_hub()
	var/static/datum/contractor_hub/hub
	if(hub)
		return hub
	var/mob/contractor = drone?.contractor_ref?.resolve()
	for(var/obj/item/held as anything in contractor?.get_all_contents())
		var/datum/component/uplink/contractor/uplink = held.GetComponent(/datum/component/uplink/contractor)
		if(uplink)
			hub = uplink.handler
			return hub
	return null

/datum/retrieval_os/ui_static_data(mob/user)
	var/list/data = list()
	var/list/targets = list()
	var/datum/contractor_hub/hub = get_hub()
	for(var/datum/syndicate_contract/bounty as anything in hub?.assigned_contracts)
		if(QDELETED(bounty.contract.target))
			continue
		targets += list(bounty.to_ui_static_data())
	data["targets"] = targets
	var/mob/living/occupant = get_occupant()
	data["identity"] = occupant ? identity_data(occupant) : null
	return data

/datum/retrieval_os/proc/identity_data(mob/living/occupant)
	var/datum/job/job = occupant.mind?.assigned_role
	var/datum/job_department/department = length(job?.departments_list) ? SSjob.get_department_type(job.departments_list[1]) : null
	var/mutable_appearance/portrait = new(occupant)
	portrait.dir = SOUTH
	var/list/data = list(
		"name" = occupant.real_name,
		"rank" = job?.title || "Unknown",
		"department" = department?.department_name,
		"department_color" = department?.ui_color,
		"implant" = HAS_TRAIT(occupant, TRAIT_CONTRACTOR_IMPLANT),
		"mugshot" = icon2base64(getFlatIcon(portrait)),
	)
	return data

/datum/retrieval_os/proc/get_designated_contract()
	var/datum/contractor_state/contractor_state = get_contractor_state()
	var/datum/syndicate_contract/bounty = contractor_state?.tracked_contract_ref?.resolve()
	if(isnull(bounty) || (bounty.status in list(CONTRACT_STATUS_COMPLETE, CONTRACT_STATUS_ABORTED)))
		return null
	return bounty

/datum/retrieval_os/proc/call_extraction(extraction_type)
	if(!(extraction_type in list(CONTRACTOR_DROPOFF_SAFE, CONTRACTOR_DROPOFF_UNSAFE, CONTRACTOR_DROPOFF_DANGEROUS)))
		return FALSE
	var/datum/syndicate_contract/bounty = get_designated_contract()
	var/mob/living/contractor = drone.contractor_ref?.resolve()
	if(isnull(bounty) || isnull(contractor))
		drone.balloon_alert(drone, "no designated target!")
		drone.playsound_local(drone, 'sound/machines/uplink/uplinkerror.ogg', 50)
		return FALSE
	if(bounty.status == CONTRACT_STATUS_EXTRACTING)
		drone.balloon_alert(drone, "already extracting!")
		drone.playsound_local(drone, 'sound/machines/uplink/uplinkerror.ogg', 50)
		return FALSE
	if(!bounty.handle_extraction(drone, extraction_type, contractor))
		drone.balloon_alert(drone, "not at the dropoff!")
		drone.playsound_local(drone, 'sound/machines/uplink/uplinkerror.ogg', 50)
		return FALSE
	bounty.status = CONTRACT_STATUS_EXTRACTING
	drone.playsound_local(drone, 'sound/effects/confirmdropoff.ogg', 100, TRUE)
	to_chat(contractor, span_notice("[drone] has called an extraction pod for [bounty.contract.target?.name]."))
	return TRUE

/datum/retrieval_os/proc/contract_for(mob/living/occupant, datum/syndicate_contract/bounty)
	var/datum/mind/target_mind = bounty?.contract?.target
	if(isnull(target_mind))
		return null
	if(target_mind != occupant.mind && target_mind.current != occupant)
		return null
	return list(
		"payout" = bounty.contract.payout,
		"bonus" = bounty.contract.payout_bonus,
	)

/datum/retrieval_os/ui_data(mob/user)
	var/list/data = list()
	data["integrity"] = clamp(drone.health / drone.maxHealth, 0, 1)
	data["damage_pulses"] = drone.damage_pulses
	data["last_hit"] = drone.last_hit_severity
	data["cell_percent"] = drone.cell ? round(drone.cell.charge / drone.cell.maxcharge * 100) : 0

	var/datum/contractor_hub/hub = get_hub()
	var/list/locations = list()
	for(var/datum/syndicate_contract/bounty as anything in hub?.assigned_contracts)
		if(QDELETED(bounty.contract.target))
			continue
		locations["[bounty.id]"] = bounty.to_ui_data()["location"]
	data["target_locations"] = locations
	var/datum/contractor_state/contractor_state = get_contractor_state()
	data["tracked_contract_id"] = contractor_state?.tracked_contract_id
	var/datum/syndicate_contract/designated = get_designated_contract()
	data["designated_contract_id"] = designated?.id
	data["extracting"] = designated?.status == CONTRACT_STATUS_EXTRACTING

	data["last_occupant"] = null
	if(drone.last_occupant)
		var/list/last = drone.last_occupant.Copy()
		last["ago"] = round((world.time - last["released_at"]) / (1 SECONDS))
		data["last_occupant"] = last

	var/mob/living/occupant = get_occupant()
	var/datum/status_effect/contractor_chassis/chassis = occupant?.has_status_effect(/datum/status_effect/contractor_chassis)
	data["occupant"] = chassis ? occupant_data(occupant, chassis) : null
	data["contract"] = chassis ? contract_for(occupant, designated) : null
	var/mob/contractor = drone.contractor_ref?.resolve()
	data["is_handler"] = !!chassis && !isnull(contractor) && (occupant == contractor || (!isnull(occupant.mind) && occupant.mind == contractor.mind))
	return data

/datum/retrieval_os/proc/occupant_data(mob/living/occupant, datum/status_effect/contractor_chassis/chassis)
	var/mob/living/carbon/patient = occupant
	var/list/data = list(
		"dead" = occupant.stat == DEAD,
		"breathing" = chassis.can_breathe(),
		"health" = round(occupant.health),
		"max_health" = occupant.maxHealth,
		"sealed" = round((world.time - chassis.sealed_at) / (1 SECONDS)),
		"damage" = list(
			BRUTE = occupant.get_brute_loss(),
			BURN = occupant.get_fire_loss(),
			TOX = occupant.get_tox_loss(),
			OXY = occupant.get_oxy_loss(),
		),
		"revive_limit" = MAX_REVIVE_BRUTE_DAMAGE,
		"body" = list(
			"blood" = occupant.blood_volume,
			"temperature" = occupant.bodytemperature,
			"bleeding" = chassis.bleed_stacks(),
			"wounds" = istype(patient) ? length(patient.all_wounds) : 0,
		),
		"blood_max" = BLOOD_VOLUME_NORMAL,
		"temperature_target" = occupant.get_body_temp_normal(),
		"focus" = chassis.focus,
		"rates" = list(
			"damage" = chassis.damage_rate,
			"oxy_bonus" = chassis.oxy_bonus,
			"blood" = chassis.blood_rate,
			"temperature" = chassis.temperature_rate,
			"bleeding" = chassis.bleed_rate,
			"wounds" = chassis.wound_rate,
			"organ" = chassis.organ_rate,
		),
		"thread_power" = display_power(chassis.thread_energy * chassis.running_threads(), convert = FALSE),
		"charge_cost" = display_energy(chassis.charge_energy),
		"charge_time" = chassis.charge_time,
		"charge_elapsed" = chassis.charge_started ? world.time - chassis.charge_started : null,
		"charged" = chassis.charged,
	)

	var/list/organs = list()
	var/list/blockers = list()
	if(istype(patient))
		for(var/obj/item/organ/organ as anything in patient.organs)
			if(organ.organ_flags & ORGAN_EXTERNAL)
				continue
			organs += list(list(
				"slot" = organ.slot,
				"name" = organ.name,
				"damage" = organ.damage,
				"max" = organ.maxHealth,
				"failing" = !!(organ.organ_flags & ORGAN_FAILING),
			))

		var/list/vitals = contractor_vitals(patient)
		for(var/key in vitals)
			data[key] = vitals[key]
		if(patient.stat != DEAD && patient.undergoing_cardiac_arrest())
			data["pulse"] = 0
		data["rhythm"] = rhythm_of(patient, data["pulse"])

		if(patient.stat == DEAD)
			if(patient.get_brute_loss() >= MAX_REVIVE_BRUTE_DAMAGE)
				blockers += list(list("reason" = "Tissue damage", "thread" = "damage", "target" = BRUTE))
			if(patient.get_fire_loss() >= MAX_REVIVE_FIRE_DAMAGE)
				blockers += list(list("reason" = "Tissue damage", "thread" = "damage", "target" = BURN))
			var/obj/item/organ/heart = patient.get_organ_slot(ORGAN_SLOT_HEART)
			if(heart?.organ_flags & ORGAN_FAILING)
				blockers += list(list("reason" = "Failing heart", "thread" = "organ", "target" = ORGAN_SLOT_HEART))
			var/obj/item/organ/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
			if(brain?.organ_flags & ORGAN_FAILING)
				blockers += list(list("reason" = "Failing brain", "thread" = "organ", "target" = ORGAN_SLOT_BRAIN))
			var/result = patient.can_defib()
			if(!(result & (DEFIB_POSSIBLE | DEFIB_FAIL_TISSUE_DAMAGE | DEFIB_FAIL_FAILING_HEART | DEFIB_FAIL_FAILING_BRAIN)))
				data["fatal"] = fatal_reason(result)
			data["revivable"] = result == DEFIB_POSSIBLE
	data["organs"] = organs
	data["blockers"] = blockers
	return data

/datum/retrieval_os/proc/rhythm_of(mob/living/carbon/patient, pulse)
	if(patient.stat == DEAD || patient.undergoing_cardiac_arrest())
		return "ASYSTOLE"
	if(pulse > 100)
		return "SINUS TACHYCARDIA"
	if(pulse < 60)
		return "SINUS BRADYCARDIA"
	return "SINUS RHYTHM"

/datum/retrieval_os/proc/fatal_reason(result)
	switch(result)
		if(DEFIB_FAIL_SUICIDE)
			return "No intelligence pattern can be detected. The revival matrix cannot restore the mind."
		if(DEFIB_FAIL_HUSK)
			return "The subject's body is a husk. The revival matrix cannot restore it."
		if(DEFIB_FAIL_NO_HEART)
			return "The subject's heart is missing. The revival matrix cannot restore it."
		if(DEFIB_FAIL_NO_BRAIN)
			return "The subject's brain is missing. The revival matrix cannot restore it."
		if(DEFIB_FAIL_NO_INTELLIGENCE)
			return "No intelligence pattern can be detected in the subject's brain."
		if(DEFIB_FAIL_BLACKLISTED)
			return "The subject cannot be revived."
		if(DEFIB_NOGRAB_AGHOST)
			return "The subject's mind has departed."
		if(DEFIB_FAIL_GOLEM)
			return "The subject is constructed from inorganic materials."
	return "The revival matrix cannot revive this subject."

/datum/retrieval_os/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(ui.user != drone)
		return FALSE
	if(action == "call_extraction")
		return call_extraction(params["extraction_type"])
	var/mob/living/occupant = get_occupant()
	var/datum/status_effect/contractor_chassis/chassis = occupant?.has_status_effect(/datum/status_effect/contractor_chassis)
	if(isnull(chassis))
		return FALSE
	switch(action)
		if("set_focus")
			return chassis.set_focus(params["thread"], params["target"])
		if("charge")
			return chassis.start_charge()
		if("discharge")
			return chassis.discharge()
	return FALSE

/datum/action/retrieval_os
	name = "RetrievalOS"
	desc = "Access RetrievalOS"
	button_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_actions.dmi'
	button_icon_state = "contractor_uplink"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/retrieval_os/IsAvailable(feedback = FALSE)
	return ..() && istype(owner, /mob/living/silicon/robot/model/contractor)

/datum/action/retrieval_os/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/mob/living/silicon/robot/model/contractor/drone = owner
	drone.open_retrieval_os()
	return TRUE
