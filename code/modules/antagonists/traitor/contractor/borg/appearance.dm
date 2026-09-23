/mob/living/silicon/robot/model/contractor/proc/refresh_overlay_planes()
	SET_PLANE_EXPLICIT(panel, ABOVE_GAME_PLANE, src)
	SET_PLANE_EXPLICIT(eyes, ABOVE_GAME_PLANE, src)
	SET_PLANE_EXPLICIT(disrupt, ABOVE_GAME_PLANE, src)
	SET_PLANE_EXPLICIT(eyes_emissive, EMISSIVE_PLANE, src)
	SET_PLANE_EXPLICIT(thrusters_emissive, EMISSIVE_PLANE, src)
	SET_PLANE_EXPLICIT(disrupt_emissive, EMISSIVE_PLANE, src)

/mob/living/silicon/robot/model/contractor/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents = TRUE)
	. = ..()
	reattach_overlays()
	addtimer(CALLBACK(src, PROC_REF(reattach_overlays)), 1, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Detaches, re-planes and re-attaches our overlay objects. A plane change on its own does not
/// make the client redraw them, so they have to be handed back over as new visual contents.
/mob/living/silicon/robot/model/contractor/proc/reattach_overlays()
	if(QDELETED(src))
		return
	var/list/parts = list(panel, eyes, disrupt, eyes_emissive, disrupt_emissive, thrusters_emissive)
	vis_contents -= parts
	refresh_overlay_planes()
	vis_contents += parts
	update_icons()

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

/mob/living/silicon/robot/model/contractor/proc/refresh_eyes()
	if(QDELETED(eyes))
		return
	if(!eyes_lit())
		eyes.alpha = 0
		eyes_emissive.icon_state = ""
		return
	var/eye_state = "[get_current_pose()][get_eye_suffix()]"
	eyes.alpha = 255
	eyes.icon_state = eye_state
	eyes_emissive.icon_state = cloaked ? "" : eye_state

/mob/living/silicon/robot/model/contractor/proc/refresh_thrusters()
	if(QDELETED(thrusters_emissive))
		return
	var/pose = get_current_pose()
	thrusters_emissive.icon_state = (!cloaked && (pose in thruster_glow_states)) ? "[pose]_glow" : ""

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

/mob/living/silicon/robot/model/contractor/proc/play_disrupt(duration = CONTRACTOR_DISRUPT_TIME)
	if(QDELETED(disrupt))
		return
	disrupt.icon_state = "contractor_disrupt"
	disrupt_emissive.icon_state = "contractor_disrupt"
	addtimer(CALLBACK(src, PROC_REF(clear_disrupt)), duration, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/silicon/robot/model/contractor/proc/clear_disrupt()
	if(!QDELETED(disrupt))
		disrupt.icon_state = ""
	if(!QDELETED(disrupt_emissive))
		disrupt_emissive.icon_state = ""

/mob/living/silicon/robot/model/contractor/proc/flick_transition(state)
	flick(state, src)
	if(!QDELETED(eyes) && eyes_lit())
		flick("[state][get_eye_suffix()]", eyes)
		if(!cloaked)
			flick("[state][get_eye_suffix()]", eyes_emissive)
	if(!QDELETED(panel) && opened)
		flick("ov-opencover_[state] [get_panel_suffix()]", panel)
	if(!QDELETED(thrusters_emissive) && !cloaked && (state in thruster_glow_states))
		flick("[state]_glow", thrusters_emissive)

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
	if(eye_lights)
		cut_overlay(eye_lights)
	if(opened)
		cut_overlay("ov-opencover [get_panel_suffix()]")
	refresh_eyes()
	refresh_panel()
	refresh_thrusters()
	sync_cloak_image()

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
	if(QDELETED(eyes) || QDELETED(eyes_emissive))
		return
	if(eyes.alpha)
		eyes.alpha = 0
		eyes_emissive.icon_state = ""
		return
	var/dead_eye_state = "[get_current_pose()]_e_r"
	eyes.alpha = 255
	eyes.icon_state = dead_eye_state
	eyes_emissive.icon_state = dead_eye_state

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

/obj/effect/contractor_disrupt
	icon = CONTRACTOR_BORG_ICON
	icon_state = ""
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_APART|RESET_ALPHA

/obj/effect/contractor_eyes_emissive
	icon = CONTRACTOR_BORG_ICON
	icon_state = ""
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_DIR
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS

/obj/effect/contractor_thrusters_emissive
	icon = CONTRACTOR_BORG_ICON
	icon_state = ""
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_DIR
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS

/obj/effect/contractor_disrupt_emissive
	icon = CONTRACTOR_BORG_ICON
	icon_state = ""
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS|RESET_ALPHA
