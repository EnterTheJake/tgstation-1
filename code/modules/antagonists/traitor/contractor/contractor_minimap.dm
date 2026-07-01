/// Minimap toggle action granted by the contractor tracking suite module.
/// Reuses the standard implant minimap button, but only renders the contractor's
/// own position and the blip of the target they've flagged in their uplink.
/datum/action/minimap/contractor
	minimap_blip_tags = list(MINIMAP_CONTRACTOR_BLIP)

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
	var/datum/hud/hud = owner.hud_used
	if(!isnull(hud) && minimap_action.has_minimap_huds(hud))
		minimap_action.remove_huds(hud)
	minimap_action.Remove(owner)
