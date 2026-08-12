/obj/item/ammo_casing/energy/gauss/gyro
	name = "gyre gauss round"
	icon_state = "gyro"
	projectile_type = /obj/projectile/bullet/gauss/gyro
	select_name = "gyre"
	e_cost = GAUSS_NANITES(2)
	charged_e_cost = GAUSS_NANITES(6)
	max_charge_time = 10 SECONDS
	charged_cooldown_time = 1 MINUTES

/// The charged round homes, so the spin-up needs a mob target rather than a turf.
/obj/item/ammo_casing/energy/gauss/gyro/get_charge_focus(atom/target, mob/living/user)
	if(isliving(target))
		return target
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return null
	var/list/mob/living/candidates = list()
	for(var/mob/living/potential in target_turf)
		if(potential == user)
			continue
		candidates += potential
	if(!length(candidates))
		return null
	var/mob/living/mark = pick(candidates)
	return mark.z == user.z ? mark : null

/obj/item/ammo_casing/energy/gauss/gyro/charge_checks(mob/living/user, atom/focus)
	if(!..())
		return FALSE
	return isturf(focus.loc) || istype(focus.loc, /obj/structure/closet)

/obj/item/ammo_casing/energy/gauss/gyro/on_empowered_fire(mob/living/user)
	. = ..()
	var/obj/item/gun/energy/gauss_rifle/rifle = astype(loc)
	rifle?.overheat()

/obj/projectile/bullet/gauss/gyro
	name = "gyre gauss round"
	icon_state = "drill_off"
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
	/// How many tiles the stored charge throws the victim on a direct hit.
	var/impact_throw_distance = 3
	/// Fraction of the payload that survives a locker hit instead of a body hit.
	var/locker_damage_mult = 0.5
	/// How long the locker victim stays dizzy and confused.
	var/locker_disorientation = 15 SECONDS
	var/drilling = FALSE
	var/list/turf/drilled_turfs
	var/datum/weakref/charged_target
	var/shocked_target = FALSE

/obj/projectile/bullet/gauss/gyro/empower(charge_ratio, atom/target)
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
	icon_state = "drill_on"
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
		icon_state = "drill_off"
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
	kick_victim(victim)

/// The discharge dumps its momentum into the victim and throws them clear.
/obj/projectile/bullet/gauss/gyro/proc/kick_victim(mob/living/victim)
	var/throw_target = get_edge_target_turf(victim, angle2dir(angle))
	victim.safe_throw_at(throw_target, impact_throw_distance, 3, firer, force = MOVE_FORCE_STRONG)

/**
 * Earths the stored charge through the victim's hiding spot instead of the body.
 *
 * The victim takes a reduced jolt and loses the locker. Dizziness and confusion follow.
 */
/obj/projectile/bullet/gauss/gyro/proc/shock_target(mob/living/victim)
	var/obj/structure/closet/hiding_spot = victim.loc
	victim.visible_message(
		span_danger("Electricity violently arcs through [victim]'s hiding spot!"),
		span_userdanger("The gyre round arcs its stored charge into you!"),
	)
	do_sparks(3, FALSE, hiding_spot)
	if(istype(hiding_spot))
		hiding_spot.deconstruct(FALSE)
	victim.apply_damage(damage * locker_damage_mult, STAMINA, forced = TRUE)
	victim.Knockdown(charged_knockdown)
	victim.adjust_dizzy(locker_disorientation)
	victim.adjust_confusion(locker_disorientation)
	kick_victim(victim)
