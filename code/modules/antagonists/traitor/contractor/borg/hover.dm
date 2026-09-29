/mob/living/silicon/robot/model/contractor/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..()
	if(.)
		return TRUE
	return hovering

/mob/living/silicon/robot/model/contractor/proc/set_hovering(new_hovering)
	if(hovering == new_hovering)
		return
	if(new_hovering && !has_builtin_flight)
		to_chat(src, span_warning("No thrusters are installed!"))
		return
	if(new_hovering && cell && !cell.use(CONTRACTOR_HOVER_COST))
		to_chat(src, span_warning("Not enough charge to spin up the thrusters!"))
		return
	hovering = new_hovering
	if(!ion_trail)
		ion_trail = new /datum/effect_system/trail_follow/ion/grav_allowed(src)
	if(hovering)
		break_cloak()
		ADD_TRAIT(src, TRAIT_MOVE_FLYING, CONTRACTOR_HOVER_TRAIT)
		ion_trail.start()
		update_icons()
		flick_transition("contractor_thrusters")
	else
		REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, CONTRACTOR_HOVER_TRAIT)
		ion_trail.stop()
		update_icons()
		flick_transition("contractor_landing")
	balloon_alert(src, hovering ? "thrusters engaged" : "thrusters disengaged")

// TODO: should have a passive power cost
/datum/action/cooldown/contractor_hover
	name = "Toggle Thrusters"
	desc = "Engage the ion thrusters to hover. You lift off with a thruster burn and set back down with a landing sequence."
	button_icon = CONTRACTOR_ACTIONS_ICON
	button_icon_state = "contractor_hover"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 1 SECONDS

/datum/action/cooldown/contractor_hover/Activate(atom/target)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	borg.set_hovering(!borg.hovering)
	button_icon_state = borg.hovering ? "contractor_land" : "contractor_hover"
	build_all_button_icons()
	StartCooldown()
	return TRUE

/datum/action/cooldown/contractor_hover/IsAvailable(feedback = FALSE)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	return ..() && istype(borg) && !borg.cloaked && (borg.has_builtin_flight || borg.hovering)
