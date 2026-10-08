#define CONTRACTOR_CASE_RECHARGE_RATE (0.1 * STANDARD_CELL_CHARGE)
#define CONTRACTOR_CASE_OPENING_DELAY (2.8 SECONDS)
/// Weight class the case takes on while open, large enough that it can't be stuffed into bags.
#define CONTRACTOR_CASE_OPEN_WEIGHT_CLASS WEIGHT_CLASS_HUGE

/obj/item/storage/contractor_gun_case
	name = "contractor gun case"
	desc = "A proprietary Cybersun case for securing and maintaining a Raijin Horizon rifle package."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_case.dmi'
	icon_state = "case_idle"
	worn_icon = 'code/modules/antagonists/traitor/contractor/icons/guncase_worn.dmi'
	worn_icon_state = "guncase_closed"
	lefthand_file = 'icons/mob/inhands/equipment/toolbox_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/toolbox_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	storage_type = /datum/storage/contractor_gun_case
	slot_flags = ITEM_SLOT_SUITSTORE
	/// Whether the case lid is currently open.
	var/case_opened = FALSE
	/// Whether the case has been unlocked from its default inert mode.
	var/case_unlocked = FALSE
	/// Prevents interactions while the opening animation is playing.
	COOLDOWN_DECLARE(opening_cooldown)

/obj/item/storage/contractor_gun_case/Initialize(mapload)
	AddElement(/datum/element/update_icon_updates_onmob)
	. = ..()
	var/matrix/offset = matrix()
	offset.Translate(-8, 0)
	transform = offset
	register_context()
	RegisterSignal(atom_storage, COMSIG_STORAGE_STORED_ITEM, PROC_REF(on_storage_updated))
	RegisterSignal(atom_storage, COMSIG_STORAGE_REMOVED_ITEM, PROC_REF(on_storage_updated))
	RegisterSignal(src, COMSIG_ITEM_PRE_STORAGE_INSERTION, PROC_REF(before_storage_attempt))
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_processing()
	update_appearance()

/obj/item/storage/contractor_gun_case/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src, alpha = alpha)

/obj/item/storage/contractor_gun_case/worn_overlays(mutable_appearance/standing, isinhands, icon_file, bodyshape)
	. = ..()
	if(isinhands)
		return
	if(case_opened)
		. += emissive_appearance(worn_icon, "emissive_open", src)

/obj/item/storage/contractor_gun_case/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(atom_storage)
		UnregisterSignal(atom_storage, list(COMSIG_STORAGE_STORED_ITEM, COMSIG_STORAGE_REMOVED_ITEM))
	return ..()

/obj/item/storage/contractor_gun_case/become_active_storage(datum/storage/source)
	. = ..()
	case_opened = TRUE
	update_appearance()

/obj/item/storage/contractor_gun_case/lose_active_storage(datum/storage/source)
	. = ..()
	case_opened = FALSE
	update_appearance()

/obj/item/storage/contractor_gun_case/PopulateContents()
	new /obj/item/gun/energy/gauss_rifle(src)
	new /obj/item/storage/pouch/contractor_cell_pouch(src)

/obj/item/storage/contractor_gun_case/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	context[SCREENTIP_CONTEXT_ALT_LMB] = case_unlocked ? "Lock case" : "Unlock case"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/storage/contractor_gun_case/click_alt(mob/user)
	if(interaction_locked(user))
		return CLICK_ACTION_BLOCKING
	if(case_unlocked)
		lock_case()
		balloon_alert(user, "case locked")
		return CLICK_ACTION_SUCCESS

	unlock_case()
	balloon_alert(user, "case unlocked")
	return CLICK_ACTION_SUCCESS

/obj/item/storage/contractor_gun_case/update_icon_state()
	. = ..()
	if(case_opened)
		icon_state = get_stored_gun() ? "case_open" : "case_open_empty"
		worn_icon_state = "guncase_open"
		return

	icon_state = case_unlocked ? "case_idle" : "case_off"
	worn_icon_state = "guncase_closed"

/// Unlocks the case, allowing access
/obj/item/storage/contractor_gun_case/proc/unlock_case()
	case_unlocked = TRUE
	atom_storage.set_locked(STORAGE_NOT_LOCKED)
	w_class = CONTRACTOR_CASE_OPEN_WEIGHT_CLASS
	COOLDOWN_START(src, opening_cooldown, CONTRACTOR_CASE_OPENING_DELAY)
	flick("case_opening", src)
	update_appearance()

/// Locks the case, preventing access
/obj/item/storage/contractor_gun_case/proc/lock_case()
	/// Notify everything in the box that the case is getting locked
	for(var/obj/thing in get_all_contents())
		SEND_SIGNAL(thing, COMSIG_CONTRACTOR_CASE_LOCKED)
	case_opened = FALSE
	case_unlocked = FALSE
	w_class = initial(w_class)
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/interaction_locked(mob/user)
	if(COOLDOWN_FINISHED(src, opening_cooldown))
		return FALSE
	if(user)
		balloon_alert(user, "wait...")
	return TRUE

/obj/item/storage/contractor_gun_case/process(seconds_per_tick)
	var/list/cells = get_charging_cells()
	if(!length(cells))
		return PROCESS_KILL

	// The case has a fixed recharge budget that is shared evenly between every cell it holds,
	// so the more cells are stowed the slower each individual one charges.
	var/recharge_amount = (CONTRACTOR_CASE_RECHARGE_RATE * seconds_per_tick) / length(cells)

	var/obj/item/gun/energy/gauss_rifle/stored_gun = get_stored_gun()
	var/has_activity = FALSE
	for(var/obj/item/stock_parts/power_store/cell as anything in cells)
		if(cell.charge >= cell.maxcharge)
			continue
		if(!cell.give(recharge_amount))
			continue
		has_activity = TRUE
		cell.update_appearance()
		if(stored_gun && cell == stored_gun.cell)
			stored_gun.recharge_newshot(TRUE)
			stored_gun.update_appearance()
			stored_gun.emit_ammo_signal()

	if(!has_activity)
		return PROCESS_KILL

/// Returns every power cell the case is responsible for charging: any cells stowed inside plus the stored gun's cell.
/obj/item/storage/contractor_gun_case/proc/get_charging_cells()
	var/list/cells = list()
	for(var/obj/item/stock_parts/power_store/cell in contents)
		cells += cell
	var/obj/item/gun/energy/gauss_rifle/stored_gun = get_stored_gun()
	if(stored_gun?.cell)
		cells += stored_gun.cell
	return cells

/obj/item/storage/contractor_gun_case/proc/open_case(mob/user)
	if(loc.atom_storage)
		if(user)
			balloon_alert(user, "remove from bag first!")
		return
	case_opened = TRUE
	atom_storage.set_locked(STORAGE_NOT_LOCKED)
	update_appearance()
	atom_storage.open_storage(user)

/obj/item/storage/contractor_gun_case/proc/close_case()
	case_opened = FALSE
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/get_stored_gun()
	return locate(/obj/item/gun/energy/gauss_rifle) in contents

/obj/item/storage/contractor_gun_case/proc/on_storage_updated(datum/source)
	SIGNAL_HANDLER

	update_processing()
	update_appearance()

/// Locks and closes the case, so that it's less jank when trying to store the suitcase in your backpack
/obj/item/storage/contractor_gun_case/proc/before_storage_attempt()
	SIGNAL_HANDLER
	lock_case()

/obj/item/storage/contractor_gun_case/proc/update_processing()
	if(length(get_charging_cells()))
		START_PROCESSING(SSobj, src)
		return
	STOP_PROCESSING(SSobj, src)

/obj/item/storage/contractor_gun_case/equipped(mob/user, slot, initial)
	. = ..()
	UnregisterSignal(user, COMSIG_BEST_SLOT_EQUIP)
	if(slot & ITEM_SLOT_SUITSTORE)
		RegisterSignal(user, COMSIG_BEST_SLOT_EQUIP, PROC_REF(on_try_quick_equip))

/obj/item/storage/contractor_gun_case/proc/on_try_quick_equip(mob/equipper, obj/item/equipping_item)
	SIGNAL_HANDLER
	if(!istype(equipping_item, /obj/item/gun/energy/gauss_rifle) && !istype(equipping_item, /obj/item/storage/pouch/contractor_cell_pouch))
		return
	if(atom_storage.attempt_insert(equipping_item, equipper))
		return BEST_SLOT_EQUIP_HANDLED

/datum/storage/contractor_gun_case
	max_slots = 2
	max_specific_storage = WEIGHT_CLASS_BULKY
	max_total_storage = WEIGHT_CLASS_BULKY * 2
	animated = FALSE
	click_alt_open = FALSE

/datum/storage/contractor_gun_case/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(list(/obj/item/gun/energy/gauss_rifle, /obj/item/storage/pouch/contractor_cell_pouch))

/datum/storage/contractor_gun_case/can_insert(obj/item/to_insert, mob/user, messages = TRUE, force = STORAGE_NOT_LOCKED)
	. = ..()
	if(!.)
		return FALSE

	if(istype(to_insert, /obj/item/gun/energy/gauss_rifle) && locate(/obj/item/gun/energy/gauss_rifle) in real_location)
		if(messages && user)
			user.balloon_alert(user, "already has gun!")
		return FALSE

	return TRUE

/datum/storage/contractor_gun_case/on_mousedrop_onto(datum/source, atom/over_object, mob/user)
	if(ismecha(user.loc) || user.incapacitated || !user.canUseStorage())
		return NONE

	if(over_object == user)
		if(!user.can_perform_action(parent, FORBID_TELEKINESIS_REACH | ALLOW_RESTING))
			return NONE
		INVOKE_ASYNC(user, TYPE_PROC_REF(/mob, put_in_hands), parent)
		return COMPONENT_CANCEL_MOUSEDROP_ONTO

	return ..()

#undef CONTRACTOR_CASE_RECHARGE_RATE
#undef CONTRACTOR_CASE_OPENING_DELAY
#undef CONTRACTOR_CASE_OPEN_WEIGHT_CLASS
