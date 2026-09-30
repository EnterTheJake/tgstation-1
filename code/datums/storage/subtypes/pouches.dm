/datum/storage/pouch

/datum/storage/pouch/contractor_magazines
	max_slots = 3
	max_total_storage = WEIGHT_CLASS_NORMAL * 3
	clickdraw = TRUE

/datum/storage/pouch/contractor_magazines/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(/obj/item/stock_parts/power_store/gauss_nanites)

/datum/storage/pouch/contractor_magazines/can_clickdraw(mob/living/carbon/human/drawer)
	if(!istype(drawer))
		return FALSE
	if(drawer.l_store != real_location && drawer.r_store != parent)
		return FALSE
	return ..()

/datum/storage/pouch/contractor_magazines/do_clickdraw(mob/living/user)
	var/obj/item/stock_parts/power_store/gauss_nanites/to_remove
	for(var/obj/item/stock_parts/power_store/gauss_nanites/cell in real_location.contents)
		if(!to_remove)
			to_remove = cell
		if(cell.charge > to_remove.charge)
			to_remove = cell

	if(!to_remove)
		return

	if(remove_single(user, to_remove))
		INVOKE_ASYNC(src, PROC_REF(put_in_hands_async), user, to_remove)
		if(!silent)
			user.visible_message(
				span_warning("[user] draws [to_remove] from [parent]!"),
				span_notice("You draw [to_remove] from [parent]."),
			)
		return
