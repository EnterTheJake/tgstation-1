#define CONTRACTOR_TASER_WINDUP (2 SECONDS)

/obj/item/gun/energy/e_gun/advtaser/cyborg/contractor
	name = "integrated shock tether"
	desc = "A cyborg-integrated taser that fires latching electrodes. The electrodes need a moment to charge \
		before delivering current, giving the target a window to break the tether. \
		Runs off an internal self-charging capacitor instead of the cyborg's power cell."
	use_cyborg_cell = FALSE
	selfcharge = 1
	charge_delay = 4
	ammo_type = list(/obj/item/ammo_casing/energy/electrode/contractor, /obj/item/ammo_casing/energy/disabler)

/obj/item/ammo_casing/energy/electrode/contractor
	projectile_type = /obj/projectile/energy/electrode/contractor

/obj/projectile/energy/electrode/contractor
	name = "shock tether"
	tase_effect_type = /datum/status_effect/tased/contractor

/// Being tased, but the electrodes latch on inert and only start shocking after a wind-up.
/datum/status_effect/tased/contractor
	tase_beam_state = "electrodes_nozap"
	/// Whether the wind-up has finished and the electrodes are delivering current.
	var/shocking = FALSE

/datum/status_effect/tased/contractor/on_apply()
	. = ..()
	if(!.)
		return
	// No slowdown during the wind-up, so the target has a real chance to break the tether.
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/being_tased)
	addtimer(CALLBACK(src, PROC_REF(begin_shock)), CONTRACTOR_TASER_WINDUP)

/datum/status_effect/tased/contractor/tick(seconds_between_ticks)
	if(shocking)
		return ..()
	// Winding up: tether break checks only, no current.
	if(!do_tase_with(taser, seconds_between_ticks))
		end_tase()

/datum/status_effect/tased/contractor/proc/begin_shock()
	if(QDELETED(src) || shocking)
		return
	shocking = TRUE
	if(!QDELETED(tase_line))
		tase_line.icon_state = "electrodes"
		tase_line.set_up_effect(tase_line.visuals, "electrodes")
		tase_line.Draw()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/being_tased)
	playsound(owner, 'sound/items/weapons/taserhit.ogg', 75, TRUE, -1)
	do_sparks(2, FALSE, owner)
	owner.visible_message(
		span_danger("The electrodes latched onto [owner] crackle to life!"),
		span_userdanger("The electrodes latched onto you crackle to life!"),
	)

#undef CONTRACTOR_TASER_WINDUP
