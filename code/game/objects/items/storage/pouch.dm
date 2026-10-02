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

/obj/item/storage/pouch/contractor_cell_pouch/equipped(mob/user, slot, initial)
	. = ..()
	UnregisterSignal(user, COMSIG_BEST_SLOT_EQUIP)
	if(slot & ITEM_SLOT_POCKETS)
		RegisterSignal(user, COMSIG_BEST_SLOT_EQUIP, PROC_REF(on_try_quick_equip))

/obj/item/storage/pouch/contractor_cell_pouch/proc/on_try_quick_equip(mob/equipper, obj/item/stock_parts/power_store/gauss_nanites/equipping_item)
	SIGNAL_HANDLER
	if(!istype(equipping_item))
		return
	if(atom_storage.attempt_insert(equipping_item, equipper))
		return BEST_SLOT_EQUIP_HANDLED

#define CONTRACTOR_POUCH_RECHARGE_RATE (0.04 * STANDARD_CELL_CHARGE)

/obj/item/storage/pouch/contractor_cell_pouch/process(seconds_per_tick)
	if(!length(contents))
		charging_cells = FALSE // Don't need to update appearance on process since if the pouch is empty we already updated the state when we took the cell out
		return PROCESS_KILL

	// Prioritize charging whichever NON-FULL battery has the most charge, if there is overflow, we can send it down to the next one.
	var/obj/item/stock_parts/power_store/gauss_nanites/highest_cell
	var/list/cells_to_charge = list()
	for(var/obj/item/stock_parts/power_store/gauss_nanites/to_charge in contents)
		if(to_charge.charge >= to_charge.maxcharge)
			continue
		if(isnull(highest_cell))
			highest_cell = to_charge
		if(to_charge.charge > highest_cell.charge)
			highest_cell = to_charge
		cells_to_charge += to_charge

	if(!length(cells_to_charge)) // All batteries are full, stop here
		charging_cells = FALSE
		update_appearance()
		return PROCESS_KILL

	var/recharge_amount = (CONTRACTOR_POUCH_RECHARGE_RATE * seconds_per_tick)
	var/play_ding = FALSE
	var/remaining_charge = recharge_amount - highest_cell.give(recharge_amount)
	highest_cell.update_appearance()
	if(highest_cell.charge >= highest_cell.maxcharge)
		play_ding = TRUE
		cells_to_charge -= highest_cell

	if(remaining_charge)
		for(var/obj/item/stock_parts/power_store/gauss_nanites/cell as anything in cells_to_charge)
			if(remaining_charge <= 0)
				break
			remaining_charge -= cell.give(recharge_amount)
			cell.update_appearance()
			if(cell.charge >= cell.maxcharge)
				play_ding = TRUE
	if(play_ding)
		playsound(src, 'sound/machines/ping.ogg', 30, TRUE, extrarange = -14)

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
