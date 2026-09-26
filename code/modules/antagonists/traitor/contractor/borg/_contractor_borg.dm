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
	/// Whether we are mid-stride. Controls the walk cycle vs. the static idle pose.
	var/walking = FALSE
	/// Whether the cloak is up. Disables the eye and thruster emissives so we don't glow through it.
	var/cloaked = FALSE
	/// While cloaked, our appearance as shown only to authorized viewers.
	var/image/cloak_image
	// You might wonder why we're not using overlays. The reason is simple. Can't flick() them
	var/obj/effect/contractor_eyes/eyes
	var/obj/effect/contractor_panel/panel
	var/obj/effect/contractor_disrupt/disrupt
	var/obj/effect/contractor_eyes_emissive/eyes_emissive
	var/obj/effect/contractor_disrupt_emissive/disrupt_emissive
	var/obj/effect/contractor_thrusters_emissive/thrusters_emissive
	/// The contractor who deployed us. Their bounty board and minimap channel are the ones we use.
	var/datum/weakref/contractor_ref
	/// Sealed atmosphere the Holding Chamber keeps around its occupant, reset to station air whenever it is read
	var/datum/gas_mixture/chamber_air
	/// Spin-up the shock tether needs before it can fire again once the cloak drops
	COOLDOWN_DECLARE(taser_spinup)
	var/static/list/thruster_glow_states = list(
		"contractor_hover",
		"contractor_hover_open",
		"contractor_hover_openup",
		"contractor_thrusters",
		"contractor_landing",
	)

/mob/living/silicon/robot/model/contractor/Initialize(mapload, datum/ai_laws/innate_laws, mob/living/silicon/master_ai, aisync, lawsync)
	aisync = FALSE
	. = ..()
	has_builtin_flight = TRUE
	has_thermals = TRUE

	panel = new(null)
	vis_contents += panel

	eyes = new(null)
	vis_contents += eyes

	eyes_emissive = new(null)
	vis_contents += eyes_emissive
	eyes_emissive.color = GLOB.emissive_color

	thrusters_emissive = new(null)
	vis_contents += thrusters_emissive
	thrusters_emissive.color = GLOB.emissive_color

	disrupt = new(null)
	vis_contents += disrupt

	disrupt_emissive = new(null)
	vis_contents += disrupt_emissive
	disrupt_emissive.color = GLOB.emissive_color

	refresh_overlay_planes()

	sight_mode = BORGTHERM
	update_sight()

/mob/living/silicon/robot/model/contractor/make_laws()
	laws = new /datum/ai_laws/cybersun_override()

/mob/living/silicon/robot/model/contractor/set_modularInterface_theme()
	if(QDELETED(modularInterface))
		return
	modularInterface.device_theme = PDA_THEME_CONTRACTOR
	modularInterface.icon_state = "tablet-silicon-syndicate"
	modularInterface.update_icon()

/mob/living/silicon/robot/model/contractor/Destroy()
	for(var/mob/living/trapped in contents)
		expel(trapped)
	vis_contents -= eyes
	vis_contents -= panel
	vis_contents -= disrupt
	vis_contents -= eyes_emissive
	vis_contents -= disrupt_emissive
	vis_contents -= thrusters_emissive
	QDEL_NULL(eyes)
	QDEL_NULL(panel)
	QDEL_NULL(disrupt)
	QDEL_NULL(eyes_emissive)
	QDEL_NULL(disrupt_emissive)
	QDEL_NULL(thrusters_emissive)
	QDEL_NULL(chamber_air)
	return ..()
/mob/living/silicon/robot/model/contractor/return_air()
	var/static/datum/gas_mixture/station_air
	if(isnull(station_air))
		station_air = SSair.parse_gas_string(OPENTURF_DEFAULT_ATMOS, /datum/gas_mixture)
	if(isnull(chamber_air))
		chamber_air = new
	chamber_air.copy_from(station_air)
	var/mob/living/occupant = locate(/mob/living) in contents
	chamber_air.temperature = occupant?.get_body_temp_normal() || BODYTEMP_NORMAL
	return chamber_air

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
