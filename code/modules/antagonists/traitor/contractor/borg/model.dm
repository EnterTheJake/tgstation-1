/obj/item/robot_model/contractor
	name = "Contractor"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/construction/rcd/borg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/extinguisher,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/analyzer,
		/obj/item/borg/cyborg_omnitool/engineering,
		/obj/item/borg/cyborg_omnitool/engineering,
		/obj/item/stack/sheet/iron,
		/obj/item/stack/sheet/glass,
		/obj/item/stack/rods/cyborg,
		/obj/item/construction/rtd/borg,
		/obj/item/stack/cable_coil,
		/obj/item/gun/energy/e_gun/advtaser/cyborg/contractor,
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
	var/datum/weakref/minimap_action_ref

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

	var/datum/action/minimap = new /datum/action/minimap/contractor(loc)
	minimap.Grant(loc)
	minimap_action_ref = WEAKREF(minimap)

/obj/item/robot_model/contractor/Destroy()
	QDEL_NULL(cloak_action_ref)
	QDEL_NULL(hover_action_ref)
	QDEL_NULL(eject_action_ref)
	QDEL_NULL(minimap_action_ref)
	remove_minimap_blip(contractor_minimap_tag(contractor_board_owner(loc)), loc)
	return ..()
