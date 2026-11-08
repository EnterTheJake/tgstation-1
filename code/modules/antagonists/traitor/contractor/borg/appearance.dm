
/mob/living/silicon/robot/model/contractor/proc/refresh_overlay_planes()
	for(var/overlay_type as anything in borg_overlays)
		var/obj/effect/overlay = borg_overlays[overlay_type]
		SET_PLANE_EXPLICIT(overlay, borg_piece_types[overlay_type], src)

/mob/living/silicon/robot/model/contractor/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents = TRUE)
	. = ..()
	refresh_overlay_planes()

/mob/living/silicon/robot/model/contractor/add_shared_particles(particle_type, custom_key = null, particle_flags = NONE, pool_size = 3)
	var/obj/effect/abstract/shared_particle_holder/holder = ..(particle_type, "[custom_key || particle_type]_contractor", particle_flags, pool_size)
	if(isnull(holder))
		return holder
	var/list/offsets = get_icon_centering_offset(src)
	holder.pixel_x = offsets[1]
	holder.pixel_y = offsets[2]
	return holder

/mob/living/silicon/robot/model/contractor/remove_shared_particles(particle_key, delete_on_empty = TRUE)
	if(!particle_key)
		return
	return ..("[particle_key]_contractor", delete_on_empty)

/mob/living/silicon/robot/model/contractor/proc/eyes_lit()
	return !IS_UNCONSCIOUS(src) && !IsStun() && !IsParalyzed() && !low_power_mode

/mob/living/silicon/robot/model/contractor/proc/get_eye_suffix()
	return (lamp_enabled || lamp_doom) ? "_e_y" : "_e"

// /mob/living/silicon/robot/model/contractor/proc/refresh_eyes()
// 	var/obj/effect/eyes = borg_overlays[/obj/effect/contractor_effect/eyes]
// 	var/obj/effect/eyes_emissive = borg_overlays[/obj/effect/contractor_effect/eyes_emissive]

// 	if(QDELETED(eyes))
// 		return
// 	if(!eyes_lit())
// 		eyes.alpha = 0
// 		eyes_emissive.icon_state = ""
// 		return
// 	var/eye_state = "[get_current_pose()][get_eye_suffix()]"
// 	eyes.alpha = 255
// 	eyes.icon_state = eye_state
// 	eyes_emissive.icon_state = cloaked ? "" : eye_state

// /mob/living/silicon/robot/model/contractor/proc/refresh_thrusters()
// 	var/obj/effect/thrusters_emissive = borg_overlays[/obj/effect/contractor_effect/thrusters_emissive]
// 	if(QDELETED(thrusters_emissive))
// 		return
// 	var/pose = get_current_pose()
// 	thrusters_emissive.icon_state = (!cloaked && (pose in thruster_glow_states)) ? "[pose]_glow" : ""

// /mob/living/silicon/robot/model/contractor/proc/get_panel_suffix()
// 	if(wiresexposed)
// 		return "+w"
// 	return cell ? "+c" : "-c"

// /mob/living/silicon/robot/model/contractor/proc/refresh_panel()
// 	var/obj/effect/panel = borg_overlays[/obj/effect/contractor_effect/panel]
// 	if(QDELETED(panel))
// 		return
// 	if(!opened)
// 		panel.alpha = 0
// 		return
// 	panel.alpha = 255
// 	panel.icon_state = "ov-opencover_[get_current_pose()] [get_panel_suffix()]"

/mob/living/silicon/robot/model/contractor/proc/play_disrupt(duration = CONTRACTOR_DISRUPT_TIME)
	SEND_SIGNAL(src, COMSIG_BORG_CLOAK_DISRUPT, duration)
	// var/obj/effect/disrupt = borg_overlays[/obj/effect/contractor_effect/disrupt]
	// var/obj/effect/disrupt_emissive = borg_overlays[/obj/effect/contractor_effect/disrupt/emissive]
	// if(QDELETED(disrupt))
	// 	return
	// disrupt.icon_state = "contractor_disrupt"
	// disrupt_emissive.icon_state = "contractor_disrupt"
	// addtimer(CALLBACK(src, PROC_REF(clear_disrupt)), duration, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/silicon/robot/model/contractor/proc/clear_disrupt()
	// var/obj/effect/disrupt = borg_overlays[/obj/effect/contractor_effect/disrupt]
	// var/obj/effect/disrupt_emissive = borg_overlays[/obj/effect/contractor_effect/disrupt/emissive]
	// if(!QDELETED(disrupt))
	// 	disrupt.icon_state = ""
	// if(!QDELETED(disrupt_emissive))
	// 	disrupt_emissive.icon_state = ""

/mob/living/silicon/robot/model/contractor/proc/flick_transition(state)
	SEND_SIGNAL(src, COMSIG_BORG_CHANGE_POSE, state)
	flick(state, src)
	// var/obj/effect/eyes = borg_overlays[/obj/effect/contractor_effect/eyes]
	// var/obj/effect/eyes_emissive = borg_overlays[/obj/effect/contractor_effect/eyes_emissive]
	// var/obj/effect/panel = borg_overlays[/obj/effect/contractor_effect/panel]
	// var/obj/effect/thrusters_emissive = borg_overlays[/obj/effect/contractor_effect/thrusters_emissive]

	// if(!QDELETED(eyes) && eyes_lit())
	// 	flick("[state][get_eye_suffix()]", eyes)
	// 	if(!cloaked)
	// 		flick("[state][get_eye_suffix()]", eyes_emissive)
	// if(!QDELETED(panel) && opened)
	// 	flick("ov-opencover_[state] [get_panel_suffix()]", panel)
	// if(!QDELETED(thrusters_emissive) && !cloaked && (state in thruster_glow_states))
	// 	flick("[state]_glow", thrusters_emissive)

/mob/living/silicon/robot/model/contractor/proc/get_current_pose()
	if(hovering)
		return chassis_open ? "contractor_hover_open" : "contractor_hover"
	if(chassis_open)
		return "contractor_open"
	return walking ? "contractor" : "contractor_idle"

/mob/living/silicon/robot/model/contractor/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(hovering)
		if(cell && !cell.use(CONTRACTOR_HOVER_UPKEEP))
			set_hovering(FALSE)
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
	sync_cloak_image()

// special handling, see /obj/effect/contractor_effect/eyes
/mob/living/silicon/robot/model/contractor/add_eye_overlay()
	if(should_show_eye_overlay() && (lamp_enabled || lamp_doom))
		update_borg_lights()

/mob/living/silicon/robot/model/contractor/add_panel_overlay()
	return

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

/mob/living/silicon/robot/model/contractor/flash_headlamp()
	dead_eye_flash = !dead_eye_flash
	update_icons()

/obj/effect/contractor_effect
	icon = CONTRACTOR_BORG_ICON
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_DIR
	appearance_flags = KEEP_APART
	layer = ABOVE_MOB_LAYER

/obj/effect/contractor_effect/Initialize(mapload, mob/owner_mob)
	. = ..()
	if(!istype(owner_mob, /mob/living/silicon/robot/model/contractor))
		return
	RegisterSignal(owner_mob, COMSIG_ATOM_UPDATE_ICON, PROC_REF(on_borg_update_icon))
	RegisterSignal(owner_mob, COMSIG_BORG_CHANGE_POSE, PROC_REF(on_borg_change_pose))

/obj/effect/contractor_effect/proc/on_borg_update_icon(mob/living/silicon/robot/model/contractor/borg, updates)
	SIGNAL_HANDLER
	return

/obj/effect/contractor_effect/proc/on_borg_change_pose(mob/living/silicon/robot/model/contractor/borg, new_state)
	SIGNAL_HANDLER
	return

/obj/effect/contractor_effect/proc/get_eye_state(mob/living/silicon/robot/model/contractor/borg)
	if(borg.stat == DEAD)
		return borg.dead_eye_flash ? "[borg.get_current_pose()]_e_r" : ""
	if(!borg.should_show_eye_overlay() || !borg.eyes_lit())
		return ""
	return "[borg.get_current_pose()][borg.get_eye_suffix()]"

/obj/effect/contractor_effect/eyes

/obj/effect/contractor_effect/eyes/on_borg_update_icon(mob/living/silicon/robot/model/contractor/borg, updates)
	icon_state = get_eye_state(borg)

/obj/effect/contractor_effect/eyes/on_borg_change_pose(mob/living/silicon/robot/model/contractor/borg, new_state)
	if(icon_state == "")
		return
	flick("[new_state][borg.get_eye_suffix()]", src)

/obj/effect/contractor_effect/panel

/obj/effect/contractor_effect/panel/on_borg_update_icon(mob/living/silicon/robot/model/contractor/borg, updates)
	icon_state = borg.opened ? "ov-opencover_[borg.get_current_pose()] [borg.get_panel_suffix()]" : ""

/obj/effect/contractor_effect/panel/on_borg_change_pose(mob/living/silicon/robot/model/contractor/borg, new_state)
	if(icon_state == "")
		return
	flick("ov-opencover_[new_state] [borg.get_panel_suffix()]", src)

/obj/effect/contractor_effect/disrupt
	appearance_flags = KEEP_APART | RESET_ALPHA

/obj/effect/contractor_effect/disrupt/Initialize(mapload, mob/owner_mob)
	. = ..()
	RegisterSignal(owner_mob, COMSIG_BORG_CLOAK_DISRUPT, PROC_REF(on_borg_cloak_disrupt))

/obj/effect/contractor_effect/disrupt/proc/on_borg_cloak_disrupt(mob/living/silicon/robot/model/contractor/borg, duration = CONTRACTOR_DISRUPT_TIME)
	SIGNAL_HANDLER
	icon_state = "contractor_disrupt"
	addtimer(VARSET_CALLBACK(src, icon_state, ""), duration, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/effect/contractor_effect/eyes_emissive
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS

/obj/effect/contractor_effect/eyes_emissive/on_borg_update_icon(mob/living/silicon/robot/model/contractor/borg, updates)
	icon_state = !borg.cloaked ? get_eye_state(borg) : ""

/obj/effect/contractor_effect/eyes_emissive/on_borg_change_pose(mob/living/silicon/robot/model/contractor/borg, new_state)
	if(icon_state == "")
		return
	flick("[new_state][borg.get_eye_suffix()]", src)

/obj/effect/contractor_effect/thrusters_emissive
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS

/obj/effect/contractor_effect/thrusters_emissive/on_borg_update_icon(mob/living/silicon/robot/model/contractor/borg, updates)
	icon_state = borg.cloaked ? "" : "[borg.get_current_pose()]_glow"

/obj/effect/contractor_effect/thrusters_emissive/on_borg_change_pose(mob/living/silicon/robot/model/contractor/borg, new_state)
	if(icon_state == "")
		return
	flick("[new_state]_glow", src)

/obj/effect/contractor_effect/disrupt/emissive
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS|RESET_ALPHA
