/obj/structure/blob/shield
	name = "strong blob"
	icon = 'icons/mob/nonhuman-player/blob_tall.dmi'
	icon_state = "blob_shield"
	desc = "A solid wall of slightly twitching tendrils."
	var/damaged_desc = "A wall of twitching tendrils."
	max_integrity = BLOB_STRONG_MAX_HP
	health_regen = BLOB_STRONG_HP_REGEN
	brute_resist = BLOB_BRUTE_RESIST * 0.5
	explosion_block = 3
	point_return = BLOB_REFUND_STRONG_COST
	atmosblock = TRUE
	armor_type = /datum/armor/blob_shield

/datum/armor/blob_shield
	fire = 90
	acid = 90
	laser = 25

/obj/structure/blob/shield/Initialize(mapload, owner_overmind)
	AddElement(/datum/element/blocks_explosives)
	return ..()

/obj/structure/blob/shield/scannerreport()
	if(atmosblock)
		return "Will prevent the spread of atmospheric changes."
	return "N/A"

/obj/structure/blob/shield/core // Automatically generated by the core
	point_return = 0

/obj/structure/blob/shield/update_name(updates)
	. = ..()
	name = "[(atom_integrity < (max_integrity * 0.5)) ? "weakened " : null][initial(name)]"

/obj/structure/blob/shield/update_desc(updates)
	. = ..()
	desc = (atom_integrity < (max_integrity * 0.5)) ? "[damaged_desc]" : initial(desc)

/obj/structure/blob/shield/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir)
	. = ..()
	if(. && atom_integrity > 0)
		atmosblock = atom_integrity < (max_integrity * 0.5)
		air_update_turf(TRUE, atmosblock)

/obj/structure/blob/shield/update_icon_state()
	icon_state = "[initial(icon_state)][(atom_integrity < (max_integrity * 0.5)) ? "_damaged" : null]"
	return ..()

/obj/structure/blob/shield/reflective
	name = "reflective blob"
	desc = "A solid wall of slightly twitching tendrils with a reflective glow."
	damaged_desc = "A wall of twitching tendrils with a reflective glow."
	icon_state = "blob_glow"
	flags_ricochet = RICOCHET_SHINY
	point_return = BLOB_REFUND_REFLECTOR_COST
	explosion_block = 2
	max_integrity = BLOB_REFLECTOR_MAX_HP
	health_regen = BLOB_REFLECTOR_HP_REGEN

/obj/structure/blob/shield/reflective/core // Automatically generated by the core
	point_return = 0
