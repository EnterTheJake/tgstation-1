/datum/quirk/frail
	name = "Frail"
	desc = "You have skin of paper and bones of glass! You suffer wounds much more easily than most."
	icon = FA_ICON_SKULL
	value = -6
	mob_trait = TRAIT_EASILY_WOUNDED
	gain_text = span_danger("You feel frail.")
	lose_text = span_notice("You feel sturdy again.")
	medical_record_text = "Patient is absurdly easy to injure. Please take all due diligence to avoid possible malpractice suits."
	hardcore_value = 4
	mail_goodies = list(/obj/effect/spawner/random/medical/minor_healing)

/// A temporary version of the Frail quirk's trait, inflicted by antimatter gauss rounds.
/datum/status_effect/frail
	id = "frail"
	duration = 5 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/frail
	var/gain_message = span_danger("Your skin turns to paper and your bones to glass!")

/datum/status_effect/frail/on_apply()
	ADD_TRAIT(owner, TRAIT_EASILY_WOUNDED, TRAIT_STATUS_EFFECT(id))
	to_chat(owner, gain_message)
	return TRUE

/datum/status_effect/frail/on_remove()
	REMOVE_TRAIT(owner, TRAIT_EASILY_WOUNDED, TRAIT_STATUS_EFFECT(id))
	to_chat(owner, span_notice("Your body knits back to something more resilient."))

/atom/movable/screen/alert/status_effect/frail
	name = "Frail"
	desc = "Your body has turned horribly brittle - you take wounds far more easily than normal."

/datum/status_effect/frail/super
	id = "super_frail"
	alert_type = /atom/movable/screen/alert/status_effect/frail/super
	gain_message = span_userdanger("Your body teeters on the edge of total structural collapse!")
	/// 1.2 = takes 20% more damage of every type.
	var/damage_vulnerability = 1.2

/datum/status_effect/frail/super/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	adjust_physiology(damage_vulnerability)

/datum/status_effect/frail/super/on_remove()
	if(ishuman(owner))
		adjust_physiology(1 / damage_vulnerability)
	return ..()

/datum/status_effect/frail/super/proc/adjust_physiology(mult)
	var/mob/living/carbon/human/human_owner = owner
	var/datum/physiology/physiology = human_owner.physiology
	physiology.brute_mod *= mult
	physiology.burn_mod *= mult
	physiology.tox_mod *= mult
	physiology.oxy_mod *= mult
	physiology.stamina_mod *= mult
	physiology.brain_mod *= mult

/atom/movable/screen/alert/status_effect/frail/super
	name = "Super Frail"
	desc = "Your body is a fragile shell moments from disintegration. Another antimatter round will annihilate you outright."
