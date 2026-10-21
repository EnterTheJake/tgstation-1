// Pinpointer
/obj/item/pinpointer/crew/contractor
	name = "contractor pinpointer"
	desc = "A handheld tracking device that locks onto certain signals. Ignores suit sensors, but is much less accurate."
	icon_state = "pinpointer_syndicate"
	worn_icon_state = "pinpointer_black"
	minimum_range = 25
	ignore_suit_sensor_level = TRUE

/obj/item/restraints/handcuffs/contractor
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	icon_state = "handcuffs"
	handcuff_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	handcuff_icon_state = "handcuffs_worn"
	handcuff_emissive_icon_state = "handcuffs_worn_emissive"

/obj/item/restraints/handcuffs/contractor/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/restraints/handcuffs/contractor/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src, alpha = alpha)

/obj/item/restraints/handcuffs/contractor/equipped(mob/living/user, slot)
	. = ..()
	UnregisterSignal(user, list(COMSIG_MOB_STATCHANGE, COMSIG_LIVING_TRY_SUCCUMB))
	if(slot == ITEM_SLOT_HANDCUFFED)
		RegisterSignal(user, COMSIG_MOB_STATCHANGE, PROC_REF(on_enter_crit))
		RegisterSignal(user, COMSIG_LIVING_TRY_SUCCUMB, PROC_REF(on_succumb_attempt))

/obj/item/restraints/handcuffs/contractor/on_uncuffed(datum/source, mob/living/wearer)
	. = ..()
	UnregisterSignal(wearer, list(COMSIG_MOB_STATCHANGE, COMSIG_LIVING_TRY_SUCCUMB))

/obj/item/restraints/handcuffs/contractor/proc/on_enter_crit(mob/owner, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat != SOFT_CRIT && new_stat != HARD_CRIT)
		return
	if(!owner?.reagents.has_reagent(/datum/reagent/medicine/epinephrine) && !owner?.reagents.has_reagent(/datum/reagent/medicine/c2/penthrite))
		to_chat(owner, "[src]'s heart monitor starts beeping, trying to keep [owner.p_them()] alive.") // ANNETODO
		owner.reagents.add_reagent(/datum/reagent/medicine/epinephrine, 10)
		owner.reagents.add_reagent(/datum/reagent/medicine/coagulant, 2)

/obj/item/restraints/handcuffs/contractor/proc/on_succumb_attempt()
	SIGNAL_HANDLER
	return SUCCUMB_PREVENTED // Can't succumb if you are in cuffs, helps prevent victims griefing the contractor

// Emag
/obj/item/card/emag/doorjack/contractor
	name = "contractor emag" // ANNETODO
	desc = "funny emag for contractors"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_emag.dmi'
	icon_state = "contractor_emag"
	charges = 5
	max_charges = 5
	airlock_breaker = FALSE

/obj/item/card/emag/doorjack/contractor/use_charge(mob/user)
	. = ..()
	flick("contractor_emag_active", src)

/obj/item/card/emag/doorjack/contractor/can_emag(atom/target, mob/user)
	for(var/list/subtypelist in type_whitelist)
		if(target.type in subtypelist)
			if(charges <= 0) // This card only needs charges when used on doors
				return FALSE
	return TRUE
