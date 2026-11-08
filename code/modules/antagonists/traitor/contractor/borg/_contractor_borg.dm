
/mob/living/silicon/robot/model/contractor
	name = "contractor cyborg"
	set_model = /obj/item/robot_model/contractor
	icon = CONTRACTOR_BORG_ICON
	icon_state = "contractor_idle"
	bubble_icon = "syndibot"
	faction = list(ROLE_SYNDICATE)
	lawupdate = FALSE
	scrambledcodes = TRUE
	req_access = list(ACCESS_SYNDICATE)
	cell = /obj/item/stock_parts/power_store/cell/bluespace
	SET_BASE_PIXEL((ICON_SIZE_X - CONTRACTOR_BORG_ICON_SIZE) * 0.5, -8)
	var/hovering = FALSE
	var/chassis_open = FALSE
	var/ingesting = FALSE
	var/resisting = FALSE
	/// whether we are mid-walking, we have a separate state during walking
	var/walking = FALSE
	/// whether the cloak is up. Disables the eye and thruster emissives so we don't glow during cloaking
	var/cloaked = FALSE
	/// only the contractor can see the borg in invisibility, this is what they see
	var/image/cloak_image
	// you might wonder why we're not using overlays. The reason is simple. Can't flick() them
	var/static/list/borg_piece_types = list(
		/obj/effect/contractor_effect/eyes = ABOVE_GAME_PLANE,
		/obj/effect/contractor_effect/panel = ABOVE_GAME_PLANE,
		/obj/effect/contractor_effect/disrupt = ABOVE_GAME_PLANE,
		/obj/effect/contractor_effect/eyes_emissive = EMISSIVE_PLANE,
		/obj/effect/contractor_effect/disrupt/emissive = EMISSIVE_PLANE,
		/obj/effect/contractor_effect/thrusters_emissive = EMISSIVE_PLANE,
	)
	var/list/borg_overlays
	/// the contractor that spawned us in, who's minimap and contractor targets we see
	var/datum/weakref/contractor_ref
	/// airmix that the victim inside the borg breathes in, so they don't die horribly
	var/datum/gas_mixture/chamber_air
	/// delay before you can shoot the taser
	COOLDOWN_DECLARE(taser_spinup)
	/// dead eye flash state, toggles between TRUE and false
	var/dead_eye_flash = FALSE

/mob/living/silicon/robot/model/contractor/Initialize(mapload, datum/ai_laws/innate_laws, mob/living/silicon/master_ai, aisync, lawsync)
	aisync = FALSE

	borg_overlays = list()
	for(var/overlay_path in borg_piece_types)
		var/obj/effect/contractor_effect/overlay = new overlay_path(null, src)
		if(borg_piece_types[overlay_path] == EMISSIVE_PLANE)
			overlay.color = GLOB.emissive_color
		borg_overlays[overlay_path] = overlay
		vis_contents += overlay

	refresh_overlay_planes()
	. = ..()

	has_builtin_flight = TRUE
	has_thermals = TRUE

/mob/living/silicon/robot/model/contractor/make_laws()
	laws = new /datum/ai_laws/cybersun_override()

/mob/living/silicon/robot/model/contractor/set_modularInterface_theme()
	if(QDELETED(modularInterface))
		return
	modularInterface.device_theme = PDA_THEME_CONTRACTOR
	modularInterface.icon_state = "tablet-silicon-syndicate"
	modularInterface.update_icon()

/mob/living/silicon/robot/model/contractor/Destroy()
	for(var/mob in contents)
		expel(mob)
	for(var/path in borg_overlays)
		var/obj/effect/overlay = borg_overlays[path]
		vis_contents -= overlay
		qdel(overlay)

	QDEL_NULL(chamber_air)
	return ..()

/mob/living/silicon/robot/model/contractor/return_air()
	var/static/datum/gas_mixture/station_air
	if(isnull(station_air))
		station_air = SSair.parse_gas_string(OPENTURF_DEFAULT_ATMOS, /datum/gas_mixture)
	return station_air

/mob/living/silicon/robot/model/contractor/proc/link_contractor(mob/contractor)
	var/mob/previous = contractor_ref?.resolve()
	if(previous)
		UnregisterSignal(previous, COMSIG_CONTRACTOR_TRACK_CHANGED)
	contractor_ref = WEAKREF(contractor)
	RegisterSignal(contractor, COMSIG_CONTRACTOR_TRACK_CHANGED, PROC_REF(on_contractor_track_changed))

/mob/living/silicon/robot/model/contractor/proc/on_contractor_track_changed(datum/source)
	SIGNAL_HANDLER
	SEND_SIGNAL(src, COMSIG_CONTRACTOR_TRACK_CHANGED)

/mob/living/silicon/robot/model/contractor/get_hud_x_offset()
	return -base_pixel_x

/mob/living/silicon/robot/model/contractor/get_hud_y_offset()
	return -base_pixel_y

/mob/living/silicon/robot/model/contractor/death(gibbed)
	for(var/mob/living/trapped in contents)
		expel(trapped)
	return ..()

/proc/is_contractor_agent(mob/living/target)
	var/datum/mind/target_mind = target?.mind
	if(!target_mind)
		return FALSE
	if(target_mind.has_antag_datum(/datum/antagonist/traitor/contractor_support))
		return TRUE
	var/datum/antagonist/traitor/traitor = target_mind.has_antag_datum(/datum/antagonist/traitor)
	return !isnull(traitor?.uplink_handler?.contractor_state)
