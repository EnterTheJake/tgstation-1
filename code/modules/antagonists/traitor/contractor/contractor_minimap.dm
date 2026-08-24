/// Minimap toggle action granted by the contractor tracking suite module.
/// Reuses the standard implant minimap button, but only renders the contractor's
/// own position and the blip of the target they've flagged in their uplink.
/datum/action/minimap/contractor
	minimap_blip_tags = list(MINIMAP_CONTRACTOR_BLIP)
	// Same hud stack as the base action, but with the contractor display that also outlines
	// the tracked contract's extraction areas.
	huds = list(
		HUD_TAC_MINIMAP_DIMMER = /atom/movable/screen/fullscreen/dimmer/minimap,
		HUD_TAC_MINIMAP = /atom/movable/screen/minimap_display/contractor,
		HUD_TAC_MINIMAP_Z_INDICATOR = /atom/movable/screen/minimap_z_indicator,
		HUD_TAC_MINIMAP_Z_INDICATOR_UP = /atom/movable/screen/minimap_z_up,
		HUD_TAC_MINIMAP_Z_INDICATOR_DOWN = /atom/movable/screen/minimap_z_down
	)

/// Per-viewer overlay that shades the tracked contract's extraction areas on the minimap.
/// Sits just above the base map (below blips) and passes clicks/hover through.
/atom/movable/screen/minimap_element/contractor_highlight
	icon = 'icons/ui_icons/minimap/minimap.dmi'
	layer = MINIMAP_IMAGE_LAYER + 0.5

/// Minimap display that draws the contractor's colour-coded extraction-area highlight for
/// whatever z-level it's currently showing.
/atom/movable/screen/minimap_display/contractor
	var/atom/movable/screen/minimap_element/contractor_highlight/highlight
	var/tracked_dangerous_type
	var/tracked_unsafe_type
	var/tracked_active = FALSE

/atom/movable/screen/minimap_display/contractor/Destroy()
	QDEL_NULL(highlight)
	return ..()

/atom/movable/screen/minimap_display/contractor/set_minimap(datum/minimap/minimap)
	. = ..()
	refresh_extraction_highlight()

/atom/movable/screen/minimap_display/contractor/set_new_hud(datum/hud/hud_owner)
	var/mob/old_owner = get_mob()
	if(!isnull(old_owner))
		UnregisterSignal(old_owner, COMSIG_CONTRACTOR_TRACK_CHANGED)
	. = ..()
	var/mob/new_owner = get_mob()
	if(!isnull(new_owner))
		RegisterSignal(new_owner, COMSIG_CONTRACTOR_TRACK_CHANGED, PROC_REF(on_track_changed))

/atom/movable/screen/minimap_display/contractor/proc/on_track_changed(datum/source)
	SIGNAL_HANDLER
	refresh_extraction_highlight()

/atom/movable/screen/minimap_display/contractor/proc/get_tracked_contract()
	var/mob/viewer = get_mob()
	var/datum/antagonist/traitor/traitor = viewer?.mind?.has_antag_datum(/datum/antagonist/traitor)
	var/datum/contractor_state/state = traitor?.uplink_handler?.contractor_state
	return state?.tracked_contract_ref?.resolve()

/// Which extraction tier the area belongs to for the tracked contract, or null.
/atom/movable/screen/minimap_display/contractor/proc/extraction_tier_of(area/candidate)
	if(!tracked_active || isnull(candidate))
		return null
	if(!isnull(tracked_dangerous_type) && istype(candidate, tracked_dangerous_type))
		return CONTRACTOR_DROPOFF_DANGEROUS
	if(!isnull(tracked_unsafe_type) && istype(candidate, tracked_unsafe_type))
		return CONTRACTOR_DROPOFF_UNSAFE
	if(is_path_in_list(candidate.type, GLOB.safe_dropoff_areas))
		return CONTRACTOR_DROPOFF_SAFE
	return null

/atom/movable/screen/minimap_display/contractor/proc/refresh_extraction_highlight()
	if(!isnull(highlight))
		hide_minimap_element(highlight)
		QDEL_NULL(highlight)
	tracked_active = FALSE
	tracked_dangerous_type = null
	tracked_unsafe_type = null
	if(isnull(minimap) || isnull(minimap.base_map))
		return
	var/datum/syndicate_contract/tracked = get_tracked_contract()
	var/datum/objective/contract/objective = tracked?.contract
	if(isnull(objective))
		return
	tracked_dangerous_type = objective.dropoffs[CONTRACTOR_DROPOFF_DANGEROUS]
	tracked_unsafe_type = objective.dropoffs[CONTRACTOR_DROPOFF_UNSAFE]
	tracked_active = TRUE
	var/static/list/tier_colors = list(
		CONTRACTOR_DROPOFF_DANGEROUS = "#ff2a2099",
		CONTRACTOR_DROPOFF_UNSAFE = "#ffd20099",
		CONTRACTOR_DROPOFF_SAFE = "#3ad46066"
	)
	var/display_z = minimap.z
	var/icon/canvas = icon('icons/ui_icons/minimap/minimap.dmi')
	canvas.Scale(minimap.base_map.Width(), minimap.base_map.Height())
	var/drew_anything = FALSE
	for(var/area/candidate as anything in GLOB.areas)
		var/tier = extraction_tier_of(candidate)
		if(isnull(tier))
			continue
		var/highlight_color = tier_colors[tier]
		for(var/turf/spot as anything in candidate.get_turfs_by_zlevel(display_z))
			var/px = MINIMAP_WORLD_TO_PIXEL(spot.x, minimap.min_x, 0)
			var/py = MINIMAP_WORLD_TO_PIXEL(spot.y, minimap.min_y, 0)
			canvas.DrawBox(highlight_color, px, py, px + 1, py + 1)
			drew_anything = TRUE
	if(!drew_anything)
		return
	highlight = new /atom/movable/screen/minimap_element/contractor_highlight()
	highlight.icon = canvas
	show_minimap_element(highlight)

/atom/movable/screen/minimap_display/contractor/get_hover_text(x, y)
	. = ..()
	if(!tracked_active || isnull(minimap))
		return
	var/turf/hovered = locate(x, y, minimap.z)
	var/tier = extraction_tier_of(hovered?.loc)
	if(isnull(tier))
		return
	var/static/list/tier_labels = list(
		CONTRACTOR_DROPOFF_DANGEROUS = "<span style='color:#ff5a4a'>● DANGEROUS DROPOFF</span>",
		CONTRACTOR_DROPOFF_UNSAFE = "<span style='color:#ffd200'>● UNSAFE DROPOFF</span>",
		CONTRACTOR_DROPOFF_SAFE = "<span style='color:#3ad460'>● SAFE ZONE</span>"
	)
	return "[.]<br>[tier_labels[tier]]"

/proc/add_contractor_track_blip(mob/target)
	if(QDELETED(target))
		return
	add_minimap_blip(target, MINIMAP_CONTRACTOR_BLIP, "locator")
	var/icon/job_icon = get_job_hud_icon(target.mind?.assigned_role)
	if(isnull(job_icon))
		return
	var/atom/movable/screen/minimap_element/blip/blip = get_minimap_blip(MINIMAP_CONTRACTOR_BLIP, target)
	if(isnull(blip))
		return
	blip.icon = job_icon
	blip.icon_state = ""

/// MODsuit module that grants the "Toggle Minimap" action while the suit is active.
/// The contractor flags a target for tracking in their uplink; this lets them open a
/// minimap to see that target's blip. Closes itself when the suit powers down or is removed.
/obj/item/mod/module/contractor_minimap
	name = "Contractor Minimap Navigation Suite"
	desc = "A miniaturised tactical map wired into your helmet's hud, \
		letting you keep eyes on the mark you've flagged for tracking, \
		Or any targets hit by a tracking dart and any of your allies."
	complexity = 0
	removable = FALSE
	/// The minimap toggle action granted to the wearer while the suit is active.
	var/datum/action/minimap/contractor/minimap_action

/obj/item/mod/module/contractor_minimap/Destroy()
	QDEL_NULL(minimap_action)
	return ..()

/obj/item/mod/module/contractor_minimap/on_part_activation()
	. = ..()
	if(isnull(mod.wearer))
		return
	if(isnull(minimap_action))
		minimap_action = new(src)
	minimap_action.Grant(mod.wearer)
	add_minimap_blip(mod.wearer, MINIMAP_CONTRACTOR_BLIP, "contractor")

/obj/item/mod/module/contractor_minimap/on_part_deactivation(deleting = FALSE)
	. = ..()
	close_minimap()

/obj/item/mod/module/contractor_minimap/on_unequip()
	. = ..()
	close_minimap()

/// Closes any open minimap display and revokes the action - the suit is off or gone.
/obj/item/mod/module/contractor_minimap/proc/close_minimap()
	if(isnull(minimap_action))
		return
	var/mob/owner = minimap_action.owner
	if(isnull(owner))
		return
	remove_minimap_blip(MINIMAP_CONTRACTOR_BLIP, owner)
	var/datum/hud/hud = owner.hud_used
	if(!isnull(hud) && minimap_action.has_minimap_huds(hud))
		minimap_action.remove_huds(hud)
	minimap_action.Remove(owner)
