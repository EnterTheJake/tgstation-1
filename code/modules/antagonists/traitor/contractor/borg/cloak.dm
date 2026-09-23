/mob/living/silicon/robot/model/contractor/proc/set_cloaked(new_cloaked)
	if(cloaked == new_cloaked)
		return
	cloaked = new_cloaked
	COOLDOWN_START(src, taser_spinup, CONTRACTOR_TASER_SPINUP)
	if(cloaked)
		cloak_image = image(null, src)
		sync_cloak_image()
		add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/contractor_cloak, "contractor_cloak", cloak_image)
		RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_cloaked_dir_change))
	else
		UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
		remove_alt_appearance("contractor_cloak")
		cloak_image = null
	refresh_eyes()
	refresh_thrusters()

/// Mirrors our current appearance onto the authorized-viewers-only cloak image.
/mob/living/silicon/robot/model/contractor/proc/sync_cloak_image()
	if(isnull(cloak_image))
		return
	cloak_image.appearance = appearance
	// The copied appearance brings our pixel offsets with it, and the image already rides them once. Clear the copy.
	cloak_image.pixel_x = 0
	cloak_image.pixel_y = 0
	cloak_image.pixel_w = 0
	cloak_image.pixel_z = 0
	cloak_image.override = TRUE
	cloak_image.dir = dir
	cloak_image.alpha = CONTRACTOR_CLOAK_ALLY_ALPHA

/mob/living/silicon/robot/model/contractor/proc/on_cloaked_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	if(!isnull(cloak_image))
		cloak_image.dir = new_dir

/// Forcibly drops the cloak with the full disruption fanfare.
/mob/living/silicon/robot/model/contractor/proc/break_cloak()
	if(!cloaked)
		return
	var/obj/item/robot_model/contractor/contractor_model = model
	if(!istype(contractor_model))
		return
	var/datum/action/cooldown/contractor_cloak/cloak_action = contractor_model.cloak_action_ref?.resolve()
	cloak_action?.disrupt_cloak()

/mob/living/silicon/robot/model/contractor/on_module_used(obj/item/module, atom/target)
	break_cloak()

/// Re-evaluates whether target should be seeing any active contractor cloaks.
/proc/refresh_contractor_cloak_visibility(mob/target)
	if(!ismob(target))
		return
	for(var/datum/atom_hud/alternate_appearance/basic/contractor_cloak/cloak_hud in GLOB.active_alternate_appearances)
		cloak_hud.check_hud(target)

/datum/atom_hud/alternate_appearance/basic/contractor_cloak

/datum/atom_hud/alternate_appearance/basic/contractor_cloak/mobShouldSee(mob/viewer)
	if(isobserver(viewer))
		return TRUE
	if(istype(viewer, /mob/living/silicon/robot/model/contractor))
		return TRUE
	return HAS_TRAIT(viewer, TRAIT_CONTRACTOR_IMPLANT)

/datum/action/cooldown/contractor_cloak
	name = "Toggle Cloak"
	desc = "Warps the light around your chassis, turning you invisible. Being touched, shot, or otherwise interacted with violently disrupts the field."
	button_icon = CONTRACTOR_ACTIONS_ICON
	button_icon_state = "contractor_cloak"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 2 SECONDS
	var/active = FALSE
	var/deploying = FALSE
	COOLDOWN_DECLARE(glitch_cooldown)
	var/static/list/disrupt_signals = list(
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_ATTACK_HAND,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_MOVABLE_IMPACT,
		COMSIG_ATOM_EX_ACT,
		COMSIG_ATOM_EMP_ACT,
		COMSIG_ATOM_FIRE_ACT,
	)
	var/static/list/stun_signals = list(
		COMSIG_LIVING_STATUS_STUN,
		COMSIG_LIVING_STATUS_KNOCKDOWN,
		COMSIG_LIVING_STATUS_PARALYZE,
		COMSIG_LIVING_STATUS_UNCONSCIOUS,
	)
	/// Attacking or shooting breaks the cloak.
	var/static/list/offense_signals = list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_FIRED_GUN,
	)

/datum/action/cooldown/contractor_cloak/Activate(atom/target)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	if(active)
		reveal(silent = FALSE)
		StartCooldown()
		return TRUE
	if(deploying)
		return FALSE
	if(borg.cell && borg.cell.charge < CONTRACTOR_CLOAK_COST)
		borg.balloon_alert(borg, "not enough charge!")
		return FALSE
	var/mob/living/occupant = locate() in borg.contents
	if(occupant && !HAS_TRAIT(occupant, TRAIT_CONTRACTOR_IMPLANT))
		borg.balloon_alert(borg, "unauthorized occupant interferes!")
		return FALSE

	borg.set_hovering(FALSE)
	deploying = TRUE
	borg.balloon_alert(borg, "cloaking...")
	playsound(borg, 'sound/effects/seedling_chargeup.ogg', 100, TRUE, -6)
	apply_wibbly_filters(borg)
	borg.play_disrupt(CONTRACTOR_CLOAK_DEPLOY_TIME)
	if(!do_after(borg, CONTRACTOR_CLOAK_DEPLOY_TIME, target = borg, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE, cog_icon = null) || (borg.cell && !borg.cell.use(CONTRACTOR_CLOAK_COST)))
		remove_wibbly_filters(borg)
		deploying = FALSE
		do_sparks(2, FALSE, borg)
		return FALSE
	deploying = FALSE
	cloak(borg)
	StartCooldown()
	return TRUE

/datum/action/cooldown/contractor_cloak/proc/cloak(mob/living/silicon/robot/model/contractor/borg)
	active = TRUE
	playsound(borg, 'sound/effects/bamf.ogg', 60, TRUE, -6)
	animate(borg, alpha = CONTRACTOR_CLOAK_ALPHA, time = CONTRACTOR_CLOAK_FADE_TIME)
	remove_wibbly_filters(borg, CONTRACTOR_CLOAK_FADE_TIME)
	borg.set_cloaked(TRUE)
	// Re-sync once the deploy filters finish animating off, so they aren't baked into the ally image.
	addtimer(CALLBACK(borg, TYPE_PROC_REF(/mob/living/silicon/robot/model/contractor, sync_cloak_image)), CONTRACTOR_CLOAK_FADE_TIME)
	borg.balloon_alert(borg, "cloaked")
	button_icon_state = "contractor_reveal"
	borg.play_disrupt()
	RegisterSignals(borg, disrupt_signals, PROC_REF(on_disrupt))
	RegisterSignal(borg, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))
	RegisterSignal(borg, COMSIG_ATOM_BUMPED, PROC_REF(on_bumped))
	RegisterSignal(borg, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))
	RegisterSignals(borg, stun_signals, PROC_REF(on_stunned))
	RegisterSignals(borg, offense_signals, PROC_REF(on_offense))
	RegisterSignal(borg, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	build_all_button_icons()

/datum/action/cooldown/contractor_cloak/proc/reveal(silent = TRUE, disrupted = FALSE)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	if(!active)
		return
	active = FALSE
	UnregisterSignal(borg, disrupt_signals)
	UnregisterSignal(borg, list(COMSIG_MOVABLE_BUMP, COMSIG_ATOM_BUMPED, COMSIG_ATOM_HITBY, COMSIG_LIVING_UNARMED_ATTACK))
	UnregisterSignal(borg, stun_signals)
	UnregisterSignal(borg, offense_signals)
	animate(borg, alpha = initial(borg.alpha), time = disrupted ? 0 : 0.5 SECONDS)
	button_icon_state = "contractor_cloak"
	borg.set_cloaked(FALSE)
	borg.play_disrupt()
	if(disrupted)
		playsound(borg, 'sound/effects/empulse.ogg', 60, TRUE, -4)
		do_sparks(3, FALSE, borg)
		borg.balloon_alert(borg, "cloak disrupted!")
	else if(!silent)
		playsound(borg, 'sound/effects/pop.ogg', 60, TRUE, -6)
		borg.balloon_alert(borg, "decloaked")
	build_all_button_icons()

/datum/action/cooldown/contractor_cloak/proc/disrupt_cloak()
	reveal(silent = FALSE, disrupted = TRUE)
	StartCooldown()

/datum/action/cooldown/contractor_cloak/proc/flare_cloak()
	var/mob/living/silicon/robot/model/contractor/borg = owner
	if(!active || !COOLDOWN_FINISHED(src, glitch_cooldown))
		return
	COOLDOWN_START(src, glitch_cooldown, CONTRACTOR_DISRUPT_TIME)
	borg.play_disrupt()
	do_sparks(2, FALSE, borg)
	animate(borg, alpha = CONTRACTOR_CLOAK_BUMP_ALPHA, time = 1)
	animate(alpha = CONTRACTOR_CLOAK_BUMP_ALPHA, time = CONTRACTOR_CLOAK_FLARE_TIME)
	animate(alpha = CONTRACTOR_CLOAK_ALPHA, time = 0.5 SECONDS)

/datum/action/cooldown/contractor_cloak/proc/on_disrupt(datum/source)
	SIGNAL_HANDLER
	disrupt_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_bump(datum/source, atom/bumped_atom)
	SIGNAL_HANDLER
	if(isliving(bumped_atom))
		flare_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_bumped(datum/source, atom/movable/bumper)
	SIGNAL_HANDLER
	if(isliving(bumper))
		flare_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_hitby(datum/source, atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	flare_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_stunned(datum/source, amount, ignore_canstun)
	SIGNAL_HANDLER
	if(amount > 0)
		disrupt_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_offense(datum/source)
	SIGNAL_HANDLER
	disrupt_cloak()

/datum/action/cooldown/contractor_cloak/proc/on_unarmed_attack(datum/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	// Borgs interact with almost everything via unarmed attacks; only combat counts.
	var/mob/living/borg = source
	if(!isliving(target) || !borg.combat_mode)
		return
	disrupt_cloak()

/datum/action/cooldown/contractor_cloak/Remove(mob/removed_from)
	if(active)
		reveal(silent = TRUE)
	return ..()

/datum/action/cooldown/contractor_cloak/IsAvailable(feedback = FALSE)
	return ..() && istype(owner, /mob/living/silicon/robot/model/contractor)
