/mob/living/silicon/robot/model/contractor/mouse_drop_receive(atom/dropped, mob/user, params)
	if(!isliving(dropped) || dropped == src)
		return ..()
	try_ingest(dropped, user)

/mob/living/silicon/robot/model/contractor/proc/ingest_is_unopposed(mob/living/victim)
	if(HAS_TRAIT(victim, TRAIT_CONTRACTOR_IMPLANT))
		return TRUE
	return IS_UNCONSCIOUS_OR_CRIT(victim) || victim.incapacitated

/mob/living/silicon/robot/model/contractor/proc/can_ingest(mob/living/victim, mob/user)
	if(QDELETED(victim))
		return FALSE
	if(stat == DEAD)
		balloon_alert(user, "chassis dead!")
		return FALSE
	if(victim == user && !HAS_TRAIT(victim, TRAIT_CONTRACTOR_IMPLANT))
		balloon_alert(user, "access denied!")
		return FALSE
	if(opened)
		balloon_alert(user, "maintenance cover open!")
		return FALSE
	if(cloaked)
		balloon_alert(user, "the chassis cannot open cloaked!")
		break_cloak()
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

	var/struggled = FALSE
	if(!ingest_is_unopposed(victim))
		balloon_alert(user, "forcing them in...")
		to_chat(victim, span_userdanger("[src] is trying to force you into its chassis!"))
		ingesting = TRUE
		struggled = TRUE
		addtimer(CALLBACK(src, PROC_REF(play_ingest_open)), CONTRACTOR_STRUGGLE_TIME - CONTRACTOR_OPEN_TIME)
		var/won = do_after(user || src, CONTRACTOR_STRUGGLE_TIME, target = victim)
		ingesting = FALSE
		if(!won || !can_ingest(victim, user))
			return

	ingesting = TRUE
	if(!struggled)
		play_ingest_open()
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

/mob/living/silicon/robot/model/contractor/proc/play_ingest_open()
	if(!ingesting)
		return
	play_chassis_open()

/mob/living/silicon/robot/model/contractor/proc/play_chassis_open()
	flick_transition("contractor_open")
	playsound(src, 'sound/vehicles/mecha/hydraulic.ogg', 50, TRUE, -3)
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, CONTRACTOR_CHASSIS_TRAIT)
	addtimer(CALLBACK(src, PROC_REF(end_chassis_open)), CONTRACTOR_OPEN_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/silicon/robot/model/contractor/proc/end_chassis_open()
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, CONTRACTOR_CHASSIS_TRAIT)

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
	victim.apply_status_effect(/datum/status_effect/contractor_chassis)
	if(cloaked && !HAS_TRAIT(victim, TRAIT_CONTRACTOR_IMPLANT))
		break_cloak()
	update_eject_action()
	victim.overlay_fullscreen("contractor_chassis_boot", /atom/movable/screen/fullscreen/contractor_chassis/boot)
	victim.overlay_fullscreen("contractor_chassis_grid", /atom/movable/screen/fullscreen/contractor_chassis/grid)
	addtimer(CALLBACK(victim, TYPE_PROC_REF(/mob, clear_fullscreen), "contractor_chassis_boot", CONTRACTOR_BOOT_FADE_TIME), CONTRACTOR_BOOT_FLASH_TIME)
	to_chat(victim, span_userdanger("The chassis folds shut around you, and a lattice of blue light crawls over your vision."))
	to_chat(src, span_notice("Chassis sealed. [victim] is secured inside."))

/mob/living/silicon/robot/model/contractor/proc/update_eject_action()
	var/obj/item/robot_model/contractor/contractor_model = model
	if(!istype(contractor_model))
		return
	var/datum/action/cooldown/contractor_eject/eject = contractor_model.eject_action_ref?.resolve()
	eject?.refresh_icon(!isnull(locate(/mob/living) in contents))

/mob/living/silicon/robot/model/contractor/proc/expel(mob/living/victim)
	if(victim.loc != src)
		return
	victim.clear_fullscreen("contractor_chassis_boot")
	victim.clear_fullscreen("contractor_chassis_grid")
	victim.remove_status_effect(/datum/status_effect/contractor_chassis)
	victim.forceMove(drop_location())
	victim.throw_at(get_step(src, dir), 1, 1, src)
	update_eject_action()
	play_chassis_open()

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

/datum/action/cooldown/contractor_eject
	name = "Eject Occupant"
	desc = "Unseal the chassis and dump whoever you are carrying onto the floor."
	button_icon = CONTRACTOR_ACTIONS_ICON
	button_icon_state = "contractor_eject_empty"
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

/datum/action/cooldown/contractor_eject/proc/refresh_icon(occupied)
	var/wanted = occupied ? "contractor_eject" : "contractor_eject_empty"
	if(button_icon_state == wanted)
		return
	button_icon_state = wanted
	build_all_button_icons()

/datum/action/cooldown/contractor_eject/IsAvailable(feedback = FALSE)
	var/mob/living/silicon/robot/model/contractor/borg = owner
	return ..() && istype(borg) && (locate(/mob/living) in borg.contents)

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
	alpha = CONTRACTOR_GRID_ALPHA_LOW

/atom/movable/screen/fullscreen/contractor_chassis/grid/Initialize(mapload)
	. = ..()
	add_filter("chassis_wave", 1, wave_filter(x = 1, y = 2, size = 1.5, offset = 0))
	var/wave = get_filter("chassis_wave")
	animate(wave, offset = 1, time = 3 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
	animate(src, alpha = CONTRACTOR_GRID_ALPHA_HIGH, time = 1.5 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
	animate(alpha = CONTRACTOR_GRID_ALPHA_LOW, time = 1.5 SECONDS)
