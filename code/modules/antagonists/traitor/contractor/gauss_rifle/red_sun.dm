/obj/item/ammo_casing/energy/gauss/thermite
	name = "red sun gauss round"
	icon_state = "thermite"
	projectile_type = /obj/projectile/bullet/gauss/thermite
	select_name = "red sun"
	e_cost = GAUSS_NANITES(5)
	charge_time = 0.5 SECONDS
	max_charge_time = 4 SECONDS

/// todo make this DOT on borgs/mechs
/obj/projectile/bullet/gauss/thermite
	name = "red sun gauss round"
	icon_state = "thermite_projectile"
	damage = 10
	damage_type = BURN
	armour_penetration = 35
	speed = 2
	wound_bonus = -10
	// Only a charged round has enough shell integrity to survive the impact and lodge itself.
	embed_type = null
	// The charge scales the payload, not the range. Distance must not reduce the embed chance.
	embed_falloff_tile = 0
	/// How much thermite the round applies to the impacted turf.
	var/thermite_payload = 25
	/// How many firestacks the cascade applies to an organic target.
	var/fire_stacks_applied = 2

/obj/projectile/bullet/gauss/thermite/empower(charge_ratio, atom/target)
	// A longer spin-up drives the payload harder. It flies faster, burns hotter, and embeds more often.
	speed = LERP(2, 0.6, charge_ratio)
	thermite_payload = round(LERP(25, 50, charge_ratio))
	fire_stacks_applied = round(LERP(2, 6, charge_ratio))
	set_embed(/datum/embedding/gauss_thermite)
	get_embed().embed_chance = round(charge_ratio * 100)

// TODO should not work on mobs
/obj/projectile/bullet/gauss/thermite/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		victim.adjust_fire_stacks(fire_stacks_applied)
		victim.ignite_mob()
	var/turf/hit_turf = get_turf(target)
	if(hit_turf)
		hit_turf.AddComponent(/datum/component/thermite, thermite_payload)
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
	// The cascade feeds the fire for as long as the round stays embedded.
	owner.adjust_fire_stacks(seconds_per_tick)
	owner.ignite_mob()
	return FALSE
