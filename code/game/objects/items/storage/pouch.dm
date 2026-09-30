/**
 * Contains pouches, a storage type that fits in your pockets
 */

/obj/item/storage/pouch
	abstract_type = /obj/item/storage/pouch
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_BULKY
	storage_type = /datum/storage/pouch

/obj/item/storage/pouch/contractor_cell_pouch
	name = "Portable nanite recharger"
	desc = "ANNETODO"
	icon = 'code/modules/antagonists/traitor/contractor/icons/nanitepouch.dmi'
	icon_state = "nanite_pouch"
	storage_type = /datum/storage/pouch/contractor_magazines
	/// If the batteries are currently being recharged
	var/charging_cells = FALSE

/obj/item/storage/pouch/contractor_cell_pouch/Initialize(mapload)
	. = ..()
	RegisterSignal(atom_storage, COMSIG_STORAGE_STORED_ITEM, PROC_REF(on_storage_updated))
	RegisterSignal(atom_storage, COMSIG_STORAGE_REMOVED_ITEM, PROC_REF(on_storage_updated))

/obj/item/storage/pouch/contractor_cell_pouch/PopulateContents()
	new /obj/item/stock_parts/power_store/gauss_nanites(src)
	update_appearance()

/obj/item/storage/pouch/contractor_cell_pouch/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	if(atom_storage)
		UnregisterSignal(atom_storage, list(COMSIG_STORAGE_STORED_ITEM, COMSIG_STORAGE_REMOVED_ITEM))
	return ..()

/obj/item/storage/pouch/contractor_cell_pouch/update_icon_state()
	. = ..()
	switch(length(contents))
		if(1)
			icon_state = "nanite_pouch_1"
			if(charging_cells)
				icon_state = icon_state + "_active"
		if(2)
			icon_state = "nanite_pouch_2"
			if(charging_cells)
				icon_state = icon_state + "_active"
		if(3)
			icon_state = "nanite_pouch_3"
			if(charging_cells)
				icon_state = icon_state + "_active"
		else
			icon_state = "nanite_pouch"

#define CONTRACTOR_POUCH_RECHARGE_RATE (0.04 * STANDARD_CELL_CHARGE)

/obj/item/storage/pouch/contractor_cell_pouch/process(seconds_per_tick)
	if(!length(contents))
		charging_cells = FALSE
		return PROCESS_KILL

	// The case has a fixed recharge budget that is shared evenly between every cell it holds,
	// so the more cells are stowed the slower each individual one charges.
	var/recharge_amount = (CONTRACTOR_POUCH_RECHARGE_RATE * seconds_per_tick) / length(contents)

	var/has_activity = FALSE
	var/play_ding = FALSE
	for(var/obj/item/stock_parts/power_store/cell as anything in contents)
		if(cell.charge >= cell.maxcharge)
			continue
		if(!cell.give(recharge_amount))
			continue
		has_activity = TRUE
		cell.update_appearance()
		if(cell.charge >= cell.maxcharge)
			play_ding = TRUE
	if(play_ding)
		playsound(src, 'sound/machines/ping.ogg', 30, TRUE, extrarange = -14)
	if(!has_activity)
		charging_cells = FALSE
		update_appearance()
		return PROCESS_KILL

#undef CONTRACTOR_POUCH_RECHARGE_RATE

/obj/item/storage/pouch/contractor_cell_pouch/proc/on_storage_updated(datum/source, mob/user, obj/to_insert)
	SIGNAL_HANDLER

	update_processing()
	update_appearance()

/obj/item/storage/pouch/contractor_cell_pouch/proc/update_processing()
	var/list/cells = list()
	for(var/obj/item/stock_parts/power_store/cell in contents)
		if(cell.charge >= cell.maxcharge) // Don't bother processing if our cells are full
			continue
		cells += cell
	if(length(cells))
		START_PROCESSING(SSobj, src)
		charging_cells = TRUE
		return
	STOP_PROCESSING(SSobj, src)
	charging_cells = FALSE
