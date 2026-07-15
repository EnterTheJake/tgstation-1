/obj/item/ammo_casing/energy/gauss/gyro
	name = "gyre gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile deliberately slows itself down to generate power through internal gyroscopes to charge a secondary power capacitor payload. \n\
		Upon impact, this triggers the transformer system to direct the stored charge into the impacted surface. \n\
		Used against organic targets, this induces cardiac and synaptic disruption. \n\
		In other words, it switches people off like a light switch for a moment, possibly rendering them completely helpless with enough generated power or repeat exposure. \n\
		Do not overuse on targets intended to be taken in alive."
	icon_state = "gyro"
	projectile_type = /obj/projectile/bullet/gauss/gyro
	select_name = "gyre"
	var/currently_aiming = FALSE
	var/seconds_per_distance = 0.2 SECONDS
	/// Mob locked in during check_fire, reused in ready_proj so both stages target the same one.
	var/datum/weakref/charge_target

/obj/item/ammo_casing/energy/gauss/gyro/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
	if(!loaded_projectile)
		return
	if(!check_fire(target, user))
		return
	return ..()

/// Scoped fire hands over the target turf, so resolve it to a random living mob standing there.
/obj/item/ammo_casing/energy/gauss/gyro/proc/resolve_target(atom/target)
	if(isliving(target))
		return target
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return null
	var/list/mob/living/candidates = list()
	for(var/mob/living/potential in target_turf)
		candidates += potential
	return length(candidates) ? pick(candidates) : null

/obj/item/ammo_casing/energy/gauss/gyro/proc/check_fire(atom/target, mob/living/user)
	charge_target = null
	if(!iscarbon(user) || !istype(loc, /obj/item/gun/energy/gauss_rifle))
		return TRUE
	if(!HAS_TRAIT(user, TRAIT_USER_SCOPED))
		return TRUE
	if(currently_aiming)
		user.balloon_alert(user, "already charging!")
		return FALSE

	var/mob/living/mark = resolve_target(target)
	if(!mark)
		return FALSE
	if(mark.z != user.z)
		return FALSE
	charge_target = WEAKREF(mark)

	var/fire_time = min(get_dist(user, mark) * seconds_per_distance, 10 SECONDS)
	user.balloon_alert(user, "spinning up...")
	user.playsound_local(get_turf(user), 'sound/items/weapons/gun/general/chunkyrack.ogg', 100, TRUE)

	currently_aiming = TRUE
	. = do_after(user, fire_time, mark, IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(check_fire_callback), mark))
	currently_aiming = FALSE

	if(!.)
		user.balloon_alert(user, "interrupted!")
	return .

/obj/item/ammo_casing/energy/gauss/gyro/proc/check_fire_callback(mob/living/target)
	return isturf(target.loc) || istype(target.loc, /obj/structure/closet)

/obj/item/ammo_casing/energy/gauss/gyro/ready_proj(atom/target, mob/living/user, quiet, zone_override, atom/fired_from)
	. = ..()
	if(!loaded_projectile)
		return
	var/obj/projectile/bullet/gauss/gyro/gyre = loaded_projectile
	if(!istype(gyre))
		return
	var/mob/living/mark = charge_target?.resolve()
	charge_target = null
	if(HAS_TRAIT(user, TRAIT_USER_SCOPED) && mark && iscarbon(user))
		gyre.charge_up(mark)
		var/obj/item/gun/energy/gauss_rifle/gauss_gun = astype(loc)
		gauss_gun?.overheat()

/obj/projectile/bullet/gauss/gyro
	name = "gyre gauss round"
	icon_state = "gyro_projectile"
	damage_type = STAMINA
	armor_flag = ENERGY
	armour_penetration = 20
	speed = 2
	damage_falloff_tile = 0
	damage = 40
	range = 20
	wound_bonus = CANT_WOUND
	sharpness = NONE
	embed_type = null
	var/charged = FALSE
	var/charged_knockdown = 2 SECONDS
	var/locker_shock_damage = 30
	var/drilling = FALSE
	var/list/turf/drilled_turfs
	var/datum/weakref/charged_target
	var/shocked_target = FALSE

/obj/projectile/bullet/gauss/gyro/proc/charge_up(atom/target)
	charged = TRUE
	damage = 80
	armour_penetration = 35
	projectile_phasing = PASSTABLE | PASSGLASS | PASSGRILLE | PASSCLOSEDTURF | PASSMACHINE | PASSSTRUCTURE | PASSDOORS
	projectile_piercing = PASSMOB
	phasing_ignore_direct_target = TRUE
	homing_turn_speed = 150
	if(isliving(target))
		charged_target = WEAKREF(target)
	set_homing_target(target)

/obj/projectile/bullet/gauss/gyro/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(!fired || !charged || drilling)
		return
	var/turf/current = get_turf(src)
	if(!current)
		return
	if(!shocked_target)
		var/mob/living/mark = charged_target?.resolve()
		if(mark && istype(mark.loc, /obj/structure/closet) && get_turf(mark) == current)
			shocked_target = TRUE
			shock_target(mark)
	if(isclosedturf(current) && !(current in drilled_turfs))
		start_drilling(current)

/obj/projectile/bullet/gauss/gyro/proc/start_drilling(turf/closed/drilled_turf)
	drilling = TRUE
	paused = TRUE
	LAZYADD(drilled_turfs, drilled_turf)
	// hardness is inverted (lower == harder), so harder walls bore slower.
	var/turf/closed/wall/drilled_wall = istype(drilled_turf, /turf/closed/wall) ? drilled_turf : null
	var/wall_hardness = drilled_wall ? drilled_wall.hardness : 40
	var/drill_time = clamp((70 - wall_hardness) * 0.05 SECONDS, 0.4 SECONDS, 4 SECONDS)
	playsound(drilled_turf, 'sound/items/tools/drill_use.ogg', 35, TRUE)
	do_sparks(2, FALSE, drilled_turf)
	addtimer(CALLBACK(src, PROC_REF(finish_drilling)), drill_time)

/obj/projectile/bullet/gauss/gyro/proc/finish_drilling()
	drilling = FALSE
	if(!QDELETED(src))
		paused = FALSE

/obj/projectile/bullet/gauss/gyro/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!charged || !isliving(target))
		return
	var/mob/living/victim = target
	if(istype(victim.loc, /obj/structure/closet))
		shock_target(victim)
		return
	victim.Knockdown(charged_knockdown)

/obj/projectile/bullet/gauss/gyro/proc/shock_target(mob/living/victim)
	victim.electrocute_act(locker_shock_damage, src, flags = SHOCK_NOGLOVES)
	victim.apply_damage(damage, STAMINA, forced = TRUE)
	victim.Knockdown(charged_knockdown)
	victim.visible_message(
		span_danger("Electricity violently arcs through [victim]'s hiding spot!"),
		span_userdanger("The gyre round arcs its stored charge into you!"),
	)
