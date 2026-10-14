/// Cybersun authorization, stored in the brain so implant removal can't touch it and it follows the brain between bodies.
/datum/component/cybersun_authorization
	dupe_mode = COMPONENT_DUPE_UNIQUE
	can_transfer = TRUE
	/// The detonator button granted to whoever owns our brain
	var/datum/action/cybersun_detonator/action

/datum/component/cybersun_authorization/Initialize()
	if(!istype(parent, /obj/item/organ/brain))
		return COMPONENT_INCOMPATIBLE
	action = new(src)

/datum/component/cybersun_authorization/Destroy(force)
	. = ..()
	QDEL_NULL(action)

/datum/component/cybersun_authorization/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ORGAN_IMPLANTED, PROC_REF(on_organ_implanted))
	RegisterSignal(parent, COMSIG_ORGAN_REMOVED, PROC_REF(on_organ_removed))
	RegisterSignal(parent, COMSIG_ORGAN_BEING_REPLACED, PROC_REF(on_organ_replaced))
	var/obj/item/organ/brain/brain = parent
	if(brain.owner)
		grant(brain.owner)

/datum/component/cybersun_authorization/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ORGAN_IMPLANTED, COMSIG_ORGAN_REMOVED, COMSIG_ORGAN_BEING_REPLACED))
	var/obj/item/organ/brain/brain = parent
	if(brain.owner)
		revoke(brain.owner)

/datum/component/cybersun_authorization/PostTransfer(datum/new_parent)
	if(!istype(new_parent, /obj/item/organ/brain))
		return COMPONENT_INCOMPATIBLE

/datum/component/cybersun_authorization/proc/grant(mob/living/carbon/target)
	ADD_TRAIT(target, TRAIT_CONTRACTOR_IMPLANT, REF(src))
	action.Grant(target)
	refresh_contractor_cloak_visibility(target)

/datum/component/cybersun_authorization/proc/revoke(mob/living/carbon/target)
	REMOVE_TRAIT(target, TRAIT_CONTRACTOR_IMPLANT, REF(src))
	action.Remove(target)
	SStgui.close_uis(src)
	refresh_contractor_cloak_visibility(target)

/datum/component/cybersun_authorization/proc/on_organ_implanted(obj/item/organ/source, mob/living/carbon/receiver)
	SIGNAL_HANDLER
	grant(receiver)

/datum/component/cybersun_authorization/proc/on_organ_removed(obj/item/organ/source, mob/living/carbon/old_owner)
	SIGNAL_HANDLER
	revoke(old_owner)

/datum/component/cybersun_authorization/proc/on_organ_replaced(obj/item/organ/source, obj/item/organ/replacement)
	SIGNAL_HANDLER
	replacement.TakeComponent(src)

/// Resolves the contractor state (and its tracked bombs) belonging to our brain's owner.
/datum/component/cybersun_authorization/proc/get_contractor_state()
	var/obj/item/organ/brain/brain = parent
	var/datum/antagonist/traitor/traitor = brain.owner?.mind?.has_antag_datum(/datum/antagonist/traitor)
	return traitor?.uplink_handler?.contractor_state

// ui_status measures distance to the host, and a component has no position
/datum/component/cybersun_authorization/ui_host(mob/user)
	return parent

/datum/component/cybersun_authorization/ui_state(mob/user)
	return GLOB.conscious_state

/datum/component/cybersun_authorization/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BombImplantDetonator")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/component/cybersun_authorization/ui_data(mob/user)
	var/list/data = list()
	var/list/bombs = list()
	var/datum/contractor_state/state = get_contractor_state()
	for(var/obj/item/contractor_bomb/bomb as anything in state?.bomb_implants)
		if(QDELETED(bomb))
			continue
		bombs += list(bomb.to_ui_data())
	data["bombs"] = bombs
	return data

/datum/component/cybersun_authorization/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("arm")
			var/datum/contractor_state/contractor_state = get_contractor_state()
			var/obj/item/contractor_bomb/bomb = locate(params["ref"]) in contractor_state?.bomb_implants
			if(QDELETED(bomb) || bomb.active || bomb.detonating)
				return TRUE
			SEND_SIGNAL(bomb, COMSIG_CONTRACTOR_UI_BOMB_ARMED)
			bomb.arm()
			return TRUE

		if("defuse")
			var/datum/contractor_state/contractor_state = get_contractor_state()
			var/obj/item/contractor_bomb/bomb = locate(params["ref"]) in contractor_state?.bomb_implants
			// Can only be defused before it's armed - once the fuse is running there's no calling it off.
			if(QDELETED(bomb) || bomb.active || bomb.detonating || QDELETED(bomb.owner))
				return TRUE
			SEND_SIGNAL(bomb, COMSIG_CONTRACTOR_UI_BOMB_DEFUSED)
			contractor_state.bomb_implants -= bomb
			bomb.defuse()
			return TRUE

/datum/action/cybersun_detonator
	name = "Remote Detonation Suite"
	button_icon = 'icons/hud/implants.dmi'
	button_icon_state = "explosive"

/datum/action/cybersun_detonator/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/datum/component/cybersun_authorization/authorization = target
	authorization.ui_interact(owner)

/obj/item/cybersun_authorizer
	name = "Cybersun authorizer"
	desc = "Uploads a Cybersun authorization key straight into your brain. Use it in hand."
	icon = 'icons/obj/medical/syringe.dmi'
	icon_state = "implanter1"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/cybersun_authorizer/attack_self(mob/user)
	if(!iscarbon(user))
		return
	if(HAS_TRAIT(user, TRAIT_CONTRACTOR_IMPLANT))
		balloon_alert(user, "already authorized!")
		return
	var/obj/item/organ/brain/brain = user.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain)
		balloon_alert(user, "no brain!")
		return
	brain.AddComponent(/datum/component/cybersun_authorization)
	to_chat(user, span_notice("You feel a cold prickle behind your eyes as the authorization key takes hold."))
	qdel(src)
