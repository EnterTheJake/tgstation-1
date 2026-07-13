/obj/item/ammo_casing/energy/gauss/thermite
	name = "red sun gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile embeds itself into a surface before unleashing a rapid buildup of thermal energy through a microfusion cascade. \n\
		In organics, this causes massive atrophic mutilation through rapid carbonization. \n\
		In inorganics, this often is capable of eventually eating through the thickest of hulls. \n\
		When salvage, or body recovery, is a luxury able to be afforded, Cybersun arms their shocktroopers with this round."
	icon_state = "thermite"
	projectile_type = /obj/projectile/bullet/gauss/thermite
	select_name = "red sun"

/// todo make this DOT on borgs/mechs
/obj/projectile/bullet/gauss/thermite
	name = "red sun gauss round"
	icon_state = "thermite_projectile"
	damage = 30
	damage_type = BURN
	armour_penetration = 35
	speed = 2
	wound_bonus = -10
	embed_type = /datum/embedding/gauss_thermite

// TODO should not work on mobs
/obj/projectile/bullet/gauss/thermite/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	var/turf/hit_turf = get_turf(target)
	if(hit_turf)
		hit_turf.AddComponent(/datum/component/thermite, 25)
		hit_turf.fire_act(2000)

/datum/embedding/gauss_thermite
	embed_chance = 100
	fall_chance = 1
	pain_chance = 15
	pain_mult = 3
	// ignore_throwspeed_threshold = TRUE
	rip_time = 1.5 SECONDS
	pain_stam_pct = 0
	var/overtime_damage = 5

/datum/embedding/gauss_thermite/set_owner(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	. = ..()
	owner.add_shared_particles(/particles/smoke/burning/small)

/datum/embedding/gauss_thermite/stop_embedding()
	owner?.remove_shared_particles(/particles/smoke/burning/small)
	return ..()

/// Applies ongoing burn damage from the microfusion cascade while embedded
/datum/embedding/gauss_thermite/process_effect(seconds_per_tick)
	owner_limb.receive_damage(burn = overtime_damage * seconds_per_tick)
	return FALSE
