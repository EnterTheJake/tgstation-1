#define CONTRACTOR_CASE_RECHARGE_RATE (0.1 * STANDARD_CELL_CHARGE)
#define CONTRACTOR_CASE_OPENING_DELAY (2.8 SECONDS)
/// Weight class the case takes on while open, large enough that it can't be stuffed into bags.
#define CONTRACTOR_CASE_OPEN_WEIGHT_CLASS WEIGHT_CLASS_HUGE

/obj/item/storage/contractor_gun_case
	name = "contractor gun case"
	desc = "A proprietary Cybersun case for securing and maintaining a Raijin Horizon rifle package."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_case.dmi'
	icon_state = "case_idle"
	inhand_icon_state = "infiltrator_case"
	lefthand_file = 'icons/mob/inhands/equipment/toolbox_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/toolbox_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	storage_type = /datum/storage/contractor_gun_case
	/// Whether the case lid is currently open.
	var/case_opened = FALSE
	/// Whether the case has been unlocked from its default inert mode.
	var/case_unlocked = FALSE
	/// Prevents interactions while the opening animation is playing.
	COOLDOWN_DECLARE(opening_cooldown)

/obj/item/storage/contractor_gun_case/Initialize(mapload)
	. = ..()
	var/matrix/offset = matrix()
	offset.Translate(-8, 0)
	transform = offset
	register_context()
	// We drive open/close through right click ourselves, so drop the storage's own right-click-to-open
	// handler that would otherwise fire a stray "closed!" balloon while the case is locked.
	atom_storage.UnregisterSignal(src, COMSIG_ATOM_ATTACK_HAND_SECONDARY)
	RegisterSignal(atom_storage, COMSIG_STORAGE_STORED_ITEM, PROC_REF(on_storage_updated))
	RegisterSignal(atom_storage, COMSIG_STORAGE_REMOVED_ITEM, PROC_REF(on_storage_updated))
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_processing()
	update_appearance()

/obj/item/storage/contractor_gun_case/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src, alpha = alpha)

/obj/item/storage/contractor_gun_case/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(atom_storage)
		UnregisterSignal(atom_storage, list(COMSIG_STORAGE_STORED_ITEM, COMSIG_STORAGE_REMOVED_ITEM))
	return ..()

/obj/item/storage/contractor_gun_case/PopulateContents()
	new /obj/item/gun/energy/gauss_rifle(src)
	new /obj/item/stock_parts/power_store/gauss_nanites(src)

/obj/item/storage/contractor_gun_case/attack_hand(mob/user, list/modifiers)
	if(loc.atom_storage)
		return ..()
	if(interaction_locked(user))
		return TRUE

	// Open case: left click browses its contents.
	if(case_opened)
		atom_storage.open_storage(user)
		return TRUE

	// Closed case: left click picks it up.
	if(loc != user && user.can_perform_action(src, FORBID_TELEKINESIS_REACH | ALLOW_RESTING))
		user.put_in_hands(src)
	return TRUE

/obj/item/storage/contractor_gun_case/attack_self(mob/user, modifiers)
	if(interaction_locked(user))
		return TRUE

	// Already in hand, so left click can only browse the contents of an open case.
	if(case_opened)
		atom_storage.open_storage(user)
	return TRUE

/obj/item/storage/contractor_gun_case/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(interaction_locked(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	toggle_case(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/storage/contractor_gun_case/attack_self_secondary(mob/user, modifiers)
	. = ..()
	if(.)
		return .

	if(interaction_locked(user))
		return TRUE

	toggle_case(user)
	return TRUE

/// Runs the case through its unlock -> open -> close cycle, playing the unlock animation on the first step. Bound to right click.
/obj/item/storage/contractor_gun_case/proc/toggle_case(mob/user)
	if(!case_unlocked)
		unlock_case()
		return
	if(!case_opened)
		open_case(user)
		return
	close_case()

/obj/item/storage/contractor_gun_case/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	context[SCREENTIP_CONTEXT_LMB] = case_opened ? "Open inventory" : "Pick up"
	context[SCREENTIP_CONTEXT_RMB] = case_opened ? "Close case" : (case_unlocked ? "Open case" : "Unlock case")
	context[SCREENTIP_CONTEXT_ALT_LMB] = case_unlocked ? "Lock case" : "Unlock case"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/storage/contractor_gun_case/click_alt(mob/user)
	if(interaction_locked(user))
		return CLICK_ACTION_BLOCKING
	if(case_opened)
		return
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
		return

	icon_state = case_unlocked ? "case_idle" : "case_off"

/obj/item/storage/contractor_gun_case/proc/unlock_case()
	case_unlocked = TRUE
	w_class = CONTRACTOR_CASE_OPEN_WEIGHT_CLASS
	COOLDOWN_START(src, opening_cooldown, CONTRACTOR_CASE_OPENING_DELAY)
	flick("case_opening", src)
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/interaction_locked(mob/user)
	if(COOLDOWN_FINISHED(src, opening_cooldown))
		return FALSE
	if(user)
		balloon_alert(user, "wait...")
	return TRUE

/obj/item/storage/contractor_gun_case/proc/lock_case()
	case_unlocked = FALSE
	case_opened = FALSE
	w_class = initial(w_class)
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_appearance()

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

/obj/item/storage/contractor_gun_case/proc/update_processing()
	if(length(get_charging_cells()))
		START_PROCESSING(SSobj, src)
		return
	STOP_PROCESSING(SSobj, src)

/datum/storage/contractor_gun_case
	max_slots = 5
	max_specific_storage = WEIGHT_CLASS_BULKY
	max_total_storage = WEIGHT_CLASS_BULKY + WEIGHT_CLASS_NORMAL * 3
	animated = FALSE
	click_alt_open = FALSE

/datum/storage/contractor_gun_case/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(list(/obj/item/gun/energy/gauss_rifle, /obj/item/stock_parts/power_store/gauss_nanites))

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
