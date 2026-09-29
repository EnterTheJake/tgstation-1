/datum/storage/pouch

/datum/storage/pouch/contractor_magazines
	max_slots = 3
	max_total_storage = WEIGHT_CLASS_NORMAL * 3

/datum/storage/pouch/contractor_magazines/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(/obj/item/stock_parts/power_store/gauss_nanites)

