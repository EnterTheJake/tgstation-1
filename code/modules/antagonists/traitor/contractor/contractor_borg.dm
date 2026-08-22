#define CONTRACTOR_BORG_ICON 'code/modules/antagonists/traitor/contractor/icons/contractor_borg.dmi'
#define CONTRACTOR_BORG_ICON_SIZE 48
#define CONTRACTOR_HOVER_TRAIT "contractor_hover"
#define CLOAK_ACTIVATION_COST (0.3 * STANDARD_CELL_CHARGE)
#define HOVER_ACTIVATION_COST (0.2 * STANDARD_CELL_CHARGE)
#define CLOAK_ALPHA 15
#define CLOAK_BUMP_ALPHA 40
#define CLOAK_FLARE_TIME (2 SECONDS)
#define CLOAK_FADE_TIME (0.5 SECONDS)
#define CONTRACTOR_DISRUPT_TIME (0.6 SECONDS)
#define CONTRACTOR_INGEST_TIME (0.6 SECONDS)
/// How long it takes to wrestle someone into the chassis if they are awake enough to fight back.
#define CONTRACTOR_STRUGGLE_TIME (4 SECONDS)
#define CONTRACTOR_RESIST_TIME (30 SECONDS)
#define CHASSIS_BOOT_FLASH_TIME (0.3 SECONDS)
#define CHASSIS_BOOT_FADE_TIME 4
#define CHASSIS_GRID_ALPHA_LOW 35
#define CHASSIS_GRID_ALPHA_HIGH 80
/// How long after the last step the walk cycle keeps playing before dropping back to the idle pose.
#define CONTRACTOR_WALK_LINGER 3

/mob/living/silicon/robot/model/contractor
	name = "contractor cyborg"
	set_model = /obj/item/robot_model/contractor
	icon = CONTRACTOR_BORG_ICON
	icon_state = "contractor_idle"
	bubble_icon = "syndibot"
	faction = list(ROLE_SYNDICATE)
	lawupdate = FALSE
	scrambledcodes = TRUE
	SET_BASE_PIXEL((ICON_SIZE_X - CONTRACTOR_BORG_ICON_SIZE) * 0.5, -8)
	var/hovering = FALSE
	var/chassis_open = FALSE
	var/ingesting = FALSE
	var/resisting = FALSE
	/// Whether we are mid-stride. Drives the walk cycle vs. the static idle pose.
	var/walking = FALSE
	var/obj/effect/contractor_eyes/eyes
	var/obj/effect/contractor_panel/panel
	var/obj/effect/contractor_disrupt/disrupt

/mob/living/silicon/robot/model/contractor/Initialize(mapload)
	. = ..()
	var/obj/item/borg/upgrade/thrusters/thrusters = new(src)
	add_to_upgrades(thrusters)
	ionpulse = TRUE

	// panel first so the eye glow still draws over the open cover
	panel = new(null)
	vis_contents += panel
	SET_PLANE_EXPLICIT(panel, ABOVE_GAME_PLANE, src)

	eyes = new(null)
	vis_contents += eyes
	SET_PLANE_EXPLICIT(eyes, ABOVE_GAME_PLANE, src)

	// added last so the disruption crackle draws over both the chassis and the eyes
	disrupt = new(null)
	vis_contents += disrupt
	SET_PLANE_EXPLICIT(disrupt, ABOVE_GAME_PLANE, src)

/mob/living/silicon/robot/model/contractor/Destroy()
	for(var/mob/living/trapped in contents)
		expel(trapped)
	vis_contents -= eyes
	vis_contents -= panel
	vis_contents -= disrupt
	QDEL_NULL(eyes)
	QDEL_NULL(panel)
	QDEL_NULL(disrupt)
	return ..()

/mob/living/silicon/robot/model/contractor/proc/eyes_lit()
	return !IS_UNCONSCIOUS(src) && !IsStun() && !IsParalyzed() && !low_power_mode

/mob/living/silicon/robot/model/contractor/proc/get_eye_suffix()
	return (lamp_enabled || lamp_doom) ? "_e_y" : "_e"

/mob/living/silicon/robot/model/contractor/proc/refresh_eyes()
	if(QDELETED(eyes))
		return
	if(!eyes_lit())
		eyes.alpha = 0
		return
	eyes.alpha = 255
	eyes.icon_state = "[get_current_pose()][get_eye_suffix()]"

/mob/living/silicon/robot/model/contractor/proc/get_panel_suffix()
	if(wiresexposed)
		return "+w"
	return cell ? "+c" : "-c"

/mob/living/silicon/robot/model/contractor/proc/refresh_panel()
	if(QDELETED(panel))
		return
	if(!opened)
		panel.alpha = 0
		return
	panel.alpha = 255
	panel.icon_state = "ov-opencover_[get_current_pose()] [get_panel_suffix()]"

/// Crackles the cloak-disruption animation over the chassis, wherever the chassis happens to be.
/mob/living/silicon/robot/model/contractor/proc/play_disrupt()
	if(QDELETED(disrupt))
		return
	disrupt.alpha = 255
	flick("contractor_disrupt", disrupt)
	addtimer(CALLBACK(src, PROC_REF(clear_disrupt)), CONTRACTOR_DISRUPT_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/silicon/robot/model/contractor/proc/clear_disrupt()
	if(!QDELETED(disrupt))
		disrupt.alpha = 0

/mob/living/silicon/robot/model/contractor/proc/flick_transition(state)
	flick(state, src)
	if(!QDELETED(eyes) && eyes_lit())
		flick("[state][get_eye_suffix()]", eyes)
	if(!QDELETED(panel) && opened)
		flick("ov-opencover_[state] [get_panel_suffix()]", panel)

/mob/living/silicon/robot/model/contractor/proc/get_current_pose()
	if(hovering)
		return chassis_open ? "contractor_hover_open" : "contractor_hover"
	if(chassis_open)
		return "contractor_open"
	return walking ? "contractor" : "contractor_idle"

/mob/living/silicon/robot/model/contractor/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(hovering) // the hover cycle already loops, there is no idle pose to fall back to
		return
	if(!walking)
		walking = TRUE
		update_icons()
	addtimer(CALLBACK(src, PROC_REF(stop_walking)), CONTRACTOR_WALK_LINGER, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/silicon/robot/model/contractor/proc/stop_walking()
	if(!walking)
		return
	walking = FALSE
	update_icons()

/mob/living/silicon/robot/model/contractor/update_icons()
	if(model)
		model.cyborg_base_icon = get_current_pose()
	. = ..()
	if(eye_lights)
		cut_overlay(eye_lights)
	if(opened) // the parent's flat panel overlay can't follow our poses, ours can
		cut_overlay("ov-opencover [get_panel_suffix()]")
	refresh_eyes()
	refresh_panel()

/mob/living/silicon/robot/model/contractor/proc/set_hovering(new_hovering)
	if(hovering == new_hovering)
		return
	if(new_hovering && !ionpulse)
		to_chat(src, span_warning("No thrusters are installed!"))
		return
	if(new_hovering && cell && !cell.use(HOVER_ACTIVATION_COST))
		to_chat(src, span_warning("Not enough charge to spin up the thrusters!"))
		return
	hovering = new_hovering
	if(!ion_trail)
		ion_trail = new /datum/effect_system/trail_follow/ion/grav_allowed(src)
	if(hovering)
		ADD_TRAIT(src, TRAIT_MOVE_FLYING, CONTRACTOR_HOVER_TRAIT)
		ionpulse_on = TRUE
		ion_trail.start()
		update_icons()
		flick_transition("contractor_thrusters")
	else
		REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, CONTRACTOR_HOVER_TRAIT)
		ionpulse_on = FALSE
		ion_trail.stop()
		update_icons()
		flick_transition("contractor_landing")
	balloon_alert(src, hovering ? "thrusters engaged" : "thrusters disengaged")

/mob/living/silicon/robot/model/contractor/proc/set_open(new_open)
	if(chassis_open == new_open)
		return
	if(new_open && opened)
		balloon_alert(src, "maintenance cover open!")
		return
	chassis_open = new_open
	update_icons()
	if(chassis_open)
		flick_transition(hovering ? "contractor_hover_openup" : "contractor_open")

/proc/is_contractor_agent(mob/living/target)
	var/datum/mind/target_mind = target?.mind
	if(!target_mind)
		return FALSE
	if(target_mind.has_antag_datum(/datum/antagonist/traitor/contractor_support))
		return TRUE
	var/datum/antagonist/traitor/traitor = target_mind.has_antag_datum(/datum/antagonist/traitor)
	return !isnull(traitor?.uplink_handler?.contractor_state)

/mob/living/silicon/robot/model/contractor/mouse_drop_receive(atom/dropped, mob/user, params)
	if(!isliving(dropped) || dropped == src)
		return ..()
	try_ingest(dropped, user)

/// Anyone who can't fight back gets folded in immediately. Everyone else has to be wrestled in.
/mob/living/silicon/robot/model/contractor/proc/ingest_is_unopposed(mob/living/victim)
	if(HAS_TRAIT(victim, TRAIT_CONTRACTOR_IMPLANT))
		return TRUE
	// incapacitated already folds in cuffs, stuns, aggressive grabs and stasis
	return IS_UNCONSCIOUS_OR_CRIT(victim) || victim.incapacitated

/mob/living/silicon/robot/model/contractor/proc/can_ingest(mob/living/victim, mob/user)
	if(QDELETED(victim))
		return FALSE
	if(opened)
		balloon_alert(user, "maintenance cover open!")
		return FALSE
	if(locate(/mob/living) in contents)
		balloon_alert(user, "chassis occupied!")
		return FALSE
	return isturf(victim.loc) && Adjacent(victim) && !victim.anchored && !victim.buckled

/mob/living/silicon/robot/model/contractor/proc/try_ingest(mob/living/victim, mob/user)
	if(ingesting || QDELETED(victim))
		return
	if(!can_ingest(victim, user))
		return

	if(!ingest_is_unopposed(victim))
		balloon_alert(user, "forcing them in...")
		to_chat(victim, span_userdanger("[src] is trying to force you into its chassis!"))
		ingesting = TRUE // also locks out a second attempt while we wrestle
		var/won = do_after(user || src, CONTRACTOR_STRUGGLE_TIME, target = victim)
		ingesting = FALSE
		if(!won || !can_ingest(victim, user))
			return

	ingesting = TRUE
	flick_transition("contractor_open")
	playsound(src, 'sound/machines/airlock/airlock.ogg', 50, TRUE, -3)
	var/old_alpha = victim.alpha
	var/old_pixel_x = victim.pixel_x
	var/old_pixel_y = victim.pixel_y
	animate(
		victim,
		pixel_x = old_pixel_x + (x - victim.x) * ICON_SIZE_X,
		pixel_y = old_pixel_y + (y - victim.y) * ICON_SIZE_Y,
		alpha = 0,
		time = CONTRACTOR_INGEST_TIME,
	)
	addtimer(CALLBACK(src, PROC_REF(finish_ingest), victim, old_alpha, old_pixel_x, old_pixel_y), CONTRACTOR_INGEST_TIME)

/mob/living/silicon/robot/model/contractor/proc/finish_ingest(mob/living/victim, old_alpha, old_pixel_x, old_pixel_y)
	ingesting = FALSE
	if(QDELETED(victim))
		return
	victim.pixel_x = old_pixel_x
	victim.pixel_y = old_pixel_y
	victim.alpha = old_alpha
	if(QDELETED(src) || !isturf(victim.loc) || !Adjacent(victim))
		return
	victim.forceMove(src)
	victim.overlay_fullscreen("contractor_chassis_boot", /atom/movable/screen/fullscreen/contractor_chassis/boot)
	victim.overlay_fullscreen("contractor_chassis_grid", /atom/movable/screen/fullscreen/contractor_chassis/grid)
	addtimer(CALLBACK(victim, TYPE_PROC_REF(/mob, clear_fullscreen), "contractor_chassis_boot", CHASSIS_BOOT_FADE_TIME), CHASSIS_BOOT_FLASH_TIME)
	to_chat(victim, span_userdanger("The chassis folds shut around you, and a lattice of blue light crawls over your vision."))
	to_chat(src, span_notice("Chassis sealed. [victim] is secured inside."))

/mob/living/silicon/robot/model/contractor/proc/expel(mob/living/victim)
	if(victim.loc != src)
		return
	victim.clear_fullscreen("contractor_chassis_boot")
	victim.clear_fullscreen("contractor_chassis_grid")
	victim.forceMove(drop_location())
	flick_transition("contractor_open")
	playsound(src, 'sound/machines/airlock/airlock.ogg', 50, TRUE, -3)

/mob/living/silicon/robot/model/contractor/container_resist_act(mob/living/user)
	if(user.loc != src)
		return
	if(is_contractor_agent(user))
		to_chat(user, span_notice("You key in the contractor release and slip straight out of [src]."))
		expel(user)
		return
	if(resisting)
		return
	to_chat(user, span_warning("You start forcing [src]'s chassis open from the inside..."))
	to_chat(src, span_userdanger("Something inside your chassis is forcing it open!"))
	resisting = TRUE
	if(run_escape_bar(user, CONTRACTOR_RESIST_TIME))
		to_chat(user, span_notice("You force [src]'s chassis apart and spill out!"))
		expel(user)
	resisting = FALSE

/mob/living/silicon/robot/model/contractor/proc/run_escape_bar(mob/living/user, delay)
	var/datum/progressbar/trapped_bar = new(user, delay, src)
	var/datum/progressbar/borg_bar = new(src, delay, src)
	var/starttime = world.time
	var/endtime = starttime + delay
	. = TRUE
	while(world.time < endtime)
		stoplag(1)
		if(QDELETED(src) || QDELETED(user) || user.loc != src || IS_UNCONSCIOUS_OR_CRIT(user))
			. = FALSE
			break
		trapped_bar.update(world.time - starttime)
		borg_bar.update(world.time - starttime)
	qdel(trapped_bar)
	qdel(borg_bar)

/obj/item/robot_model/contractor
	name = "Contractor"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/pinpointer/syndicate_cyborg,
	)
	emag_modules = list(
		/obj/item/borg/stun,
	)
	cyborg_base_icon = "contractor_idle"
	model_select_icon = "malf"
	model_traits = list(TRAIT_PUSHIMMUNE)
	var/datum/weakref/cloak_action_ref
	var/datum/weakref/hover_action_ref
	var/datum/weakref/eject_action_ref

/obj/item/robot_model/contractor/be_transformed_to(obj/item/robot_model/old_model, forced = FALSE)
	. = ..()
	if(!.)
		return

	var/datum/action/cloak = new /datum/action/cooldown/contractor_cloak(loc)
	cloak.Grant(loc)
	cloak_action_ref = WEAKREF(cloak)

	var/datum/action/hover = new /datum/action/cooldown/contractor_hover(loc)
	hover.Grant(loc)
	hover_action_ref = WEAKREF(hover)

	var/datum/action/eject = new /datum/action/cooldown/contractor_eject(loc)
	eject.Grant(loc)
	eject_action_ref = WEAKREF(eject)

/obj/item/robot_model/contractor/Destroy()
	QDEL_NULL(cloak_action_ref)
	QDEL_NULL(hover_action_ref)
	QDEL_NULL(eject_action_ref)
	return ..()

/datum/action/cooldown/contractor_cloak
	name = "Toggle Cloak"
	desc = "Warps the light around your chassis, turning you invisible. Being touched, shot, or otherwise interacted with violently disrupts the field."
	button_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_camogear_helm"
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

/datum/action/cooldown/contractor_cloak/Activate(atom/target)
	var/mob/living/silicon/robot/borg = owner
	if(active)
		reveal(silent = FALSE)
		StartCooldown()
		return TRUE
	if(deploying)
		return FALSE
	if(borg.cell && borg.cell.charge < CLOAK_ACTIVATION_COST)
		borg.balloon_alert(borg, "not enough charge!")
		return FALSE

	deploying = TRUE
	borg.balloon_alert(borg, "cloaking...")
	playsound(borg, 'sound/effects/seedling_chargeup.ogg', 100, TRUE, -6)
	apply_wibbly_filters(borg)
	if(!do_after(borg, 1.5 SECONDS, target = borg, cog_icon = null) || (borg.cell && !borg.cell.use(CLOAK_ACTIVATION_COST)))
		remove_wibbly_filters(borg)
		deploying = FALSE
		do_sparks(2, FALSE, borg)
		return FALSE
	deploying = FALSE
	cloak(borg)
	StartCooldown()
	return TRUE

/datum/action/cooldown/contractor_cloak/proc/cloak(mob/living/silicon/robot/borg)
	active = TRUE
	playsound(borg, 'sound/effects/bamf.ogg', 60, TRUE, -6)
	animate(borg, alpha = CLOAK_ALPHA, time = CLOAK_FADE_TIME)
	remove_wibbly_filters(borg, CLOAK_FADE_TIME)
	borg.balloon_alert(borg, "cloaked")
	RegisterSignals(borg, disrupt_signals, PROC_REF(on_disrupt))
	RegisterSignal(borg, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))
	RegisterSignal(borg, COMSIG_ATOM_BUMPED, PROC_REF(on_bumped))
	RegisterSignal(borg, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))
	build_all_button_icons()

/datum/action/cooldown/contractor_cloak/proc/reveal(silent = TRUE, disrupted = FALSE)
	var/mob/living/silicon/robot/borg = owner
	if(!active)
		return
	active = FALSE
	UnregisterSignal(borg, disrupt_signals)
	UnregisterSignal(borg, list(COMSIG_MOVABLE_BUMP, COMSIG_ATOM_BUMPED, COMSIG_ATOM_HITBY))
	animate(borg, alpha = initial(borg.alpha), time = disrupted ? 0 : 0.5 SECONDS)
	if(disrupted)
		play_disrupt(borg)
		playsound(borg, 'sound/effects/empulse.ogg', 60, TRUE, -4)
		do_sparks(3, FALSE, borg)
		borg.balloon_alert(borg, "cloak disrupted!")
	else if(!silent)
		playsound(borg, 'sound/effects/pop.ogg', 60, TRUE, -6)
		borg.balloon_alert(borg, "decloaked")
	build_all_button_icons()

/datum/action/cooldown/contractor_cloak/proc/play_disrupt(mob/living/silicon/robot/model/contractor/borg)
	if(istype(borg))
		borg.play_disrupt()

/datum/action/cooldown/contractor_cloak/proc/disrupt_cloak()
	reveal(silent = FALSE, disrupted = TRUE)
	StartCooldown()

/datum/action/cooldown/contractor_cloak/proc/flare_cloak()
	var/mob/living/silicon/robot/borg = owner
	if(!active || !COOLDOWN_FINISHED(src, glitch_cooldown))
		return
	COOLDOWN_START(src, glitch_cooldown, CONTRACTOR_DISRUPT_TIME)
	play_disrupt(borg)
	do_sparks(2, FALSE, borg)
	animate(borg, alpha = CLOAK_BUMP_ALPHA, time = 1)
	animate(alpha = CLOAK_BUMP_ALPHA, time = CLOAK_FLARE_TIME)
	animate(alpha = CLOAK_ALPHA, time = 0.5 SECONDS)

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

/datum/action/cooldown/contractor_cloak/Remove(mob/removed_from)
	if(active)
		reveal(silent = TRUE)
	return ..()

/datum/action/cooldown/contractor_cloak/IsAvailable(feedback = FALSE)
	return ..() && istype(owner, /mob/living/silicon/robot/model/contractor)

/datum/action/cooldown/contractor_hover
	name = "Toggle Thrusters"
	desc = "Engage the ion thrusters to hover. You lift off with a thruster burn and set back down with a landing sequence."
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_thrusters_off"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 1 SECONDS

/datum/action/cooldown/contractor_hover/Activate(atom/target)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	borg.set_hovering(!borg.hovering)
	button_icon_state = borg.hovering ? "mech_thrusters_on" : "mech_thrusters_off"
	build_all_button_icons()
	StartCooldown()
	return TRUE

/datum/action/cooldown/contractor_hover/IsAvailable(feedback = FALSE)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	return ..() && istype(borg) && (borg.ionpulse || borg.hovering)

/datum/action/cooldown/contractor_eject
	name = "Eject Occupant"
	desc = "Unseal the chassis and dump whoever you are carrying onto the floor."
	button_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_eject"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 1 SECONDS

/datum/action/cooldown/contractor_eject/Activate(atom/target)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	var/mob/living/occupant = locate(/mob/living) in borg.contents
	if(!occupant)
		borg.balloon_alert(borg, "chassis empty!")
		return FALSE
	borg.expel(occupant)
	StartCooldown()
	return TRUE

/datum/action/cooldown/contractor_eject/IsAvailable(feedback = FALSE)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	return ..() && istype(borg) && (locate(/mob/living) in borg.contents)

/obj/effect/contractor_eyes
	icon = CONTRACTOR_BORG_ICON
	icon_state = "contractor_idle_e"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_DIR
	appearance_flags = KEEP_APART

/obj/effect/contractor_panel
	icon = CONTRACTOR_BORG_ICON
	icon_state = "ov-opencover_contractor_idle -c"
	alpha = 0
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_DIR
	appearance_flags = KEEP_APART

// Rides in the borg's vis_contents rather than sitting on a turf, so it tracks the chassis
// while it moves. That also means no pixel offset of its own - it inherits the borg's.
/obj/effect/contractor_disrupt
	icon = CONTRACTOR_BORG_ICON
	icon_state = "contractor_disrupt"
	alpha = 0
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// RESET_ALPHA so the crackle reads at full strength over a chassis sitting at CLOAK_ALPHA;
	// the eyes and panel deliberately do fade with the cloak, this must not.
	appearance_flags = KEEP_APART|RESET_ALPHA

/atom/movable/screen/fullscreen/contractor_chassis
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/contractor_chassis/boot
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "noise"
	color = "#04a8d1"
	alpha = 200

/atom/movable/screen/fullscreen/contractor_chassis/grid
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_borg_hud.dmi'
	icon_state = "grid"
	color = "#5fd7ef"
	alpha = CHASSIS_GRID_ALPHA_LOW

/atom/movable/screen/fullscreen/contractor_chassis/grid/Initialize(mapload)
	. = ..()
	add_filter("chassis_wave", 1, wave_filter(x = 1, y = 2, size = 1.5, offset = 0))
	var/wave = get_filter("chassis_wave")
	animate(wave, offset = 1, time = 3 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
	animate(src, alpha = CHASSIS_GRID_ALPHA_HIGH, time = 1.5 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
	animate(alpha = CHASSIS_GRID_ALPHA_LOW, time = 1.5 SECONDS)

#undef CONTRACTOR_BORG_ICON
#undef CONTRACTOR_BORG_ICON_SIZE
#undef CONTRACTOR_HOVER_TRAIT
#undef CLOAK_FADE_TIME
#undef CONTRACTOR_DISRUPT_TIME
#undef CLOAK_ACTIVATION_COST
#undef HOVER_ACTIVATION_COST
#undef CLOAK_ALPHA
#undef CLOAK_BUMP_ALPHA
#undef CLOAK_FLARE_TIME
#undef CONTRACTOR_INGEST_TIME
#undef CONTRACTOR_STRUGGLE_TIME
#undef CONTRACTOR_RESIST_TIME
#undef CHASSIS_BOOT_FLASH_TIME
#undef CHASSIS_BOOT_FADE_TIME
#undef CHASSIS_GRID_ALPHA_LOW
#undef CHASSIS_GRID_ALPHA_HIGH
#undef CONTRACTOR_WALK_LINGER
