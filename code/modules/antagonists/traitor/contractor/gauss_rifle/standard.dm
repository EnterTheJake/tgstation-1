/obj/item/ammo_casing/energy/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard"
	caliber = CALIBER_GAUSS
	projectile_type = /obj/projectile/bullet/gauss
	select_name = "standard"
	e_cost = GAUSS_NANITES(3)
	/// How much energy cost each shot takes when shot in scoped mode with charging
	var/charged_e_cost
	/// Minimum charge time for the scoped shot
	var/charge_time = 1 SECONDS
	/// Extra spin up time based on range between user and target
	var/seconds_per_distance = 0.2 SECONDS
	/// Maximum charge-time for the mode
	var/max_charge_time = 5 SECONDS
	/// If TRUE this mode only works while scoped-in
	var/scope_only = FALSE
	/// Separate cooldown besides overheating to prevent shooting the special mode again.
	var/charged_cooldown_time = 0
	/// Is the gun currently charging a shot.
	var/currently_charging = FALSE
	/// Only true when the do_after charge has finished, used for energy cost calculations
	var/empowered_shot = FALSE
	/// How far from 0 to 1 we are done with charging the gun
	var/charge_ratio = 0
	/// Saved target that we are charging up and trying to shoot.
	var/datum/weakref/charge_target
	var/charge_alert = "spinning up..."
	var/charge_sound = 'sound/items/weapons/gun/general/chunkyrack.ogg'
	/// Projectile sound that is based on the bullet type
	var/projectile_sound
	COOLDOWN_DECLARE(charged_cooldown)

/obj/item/ammo_casing/energy/gauss/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
	if(!loaded_projectile)
		return
	var/charge_state = charge_shot(target, user)
	if(charge_state == GAUSS_CHARGE_ABORT)
		return
	. = ..()
	if(. && charge_state == GAUSS_CHARGE_EMPOWERED)
		on_empowered_fire(user)

/obj/item/ammo_casing/energy/gauss/proc/charge_shot(atom/target, mob/living/user)
	reset_charge()
	var/obj/item/gun/energy/gauss_rifle/rifle = astype(loc)
	if(!iscarbon(user) || isnull(rifle))
		return GAUSS_CHARGE_HIP
	if(!HAS_TRAIT(user, TRAIT_USER_SCOPED))
		if(scope_only)
			user.balloon_alert(user, "must be scoped!")
			return GAUSS_CHARGE_ABORT
		return GAUSS_CHARGE_HIP
	if(currently_charging)
		user.balloon_alert(user, "already charging!")
		return GAUSS_CHARGE_ABORT
	if(!COOLDOWN_FINISHED(src, charged_cooldown))
		user.balloon_alert(user, "cycling! [DisplayTimeText(COOLDOWN_TIMELEFT(src, charged_cooldown))]")
		return GAUSS_CHARGE_ABORT
	if((rifle.cell?.charge || 0) < (charged_e_cost || e_cost))
		user.balloon_alert(user, "not enough nanites to empower!")
		return scope_only ? GAUSS_CHARGE_ABORT : GAUSS_CHARGE_HIP

	var/atom/focus = get_charge_focus(target, user)
	if(isnull(focus))
		return GAUSS_CHARGE_ABORT

	var/spun_time = get_charge_time(user, focus)
	user.balloon_alert(user, charge_alert)
	user.playsound_local(get_turf(user), charge_sound, 100, TRUE)
	on_charge_started(user, rifle)

	currently_charging = TRUE
	var/spun_up = do_after(user, spun_time, focus, IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(charge_checks), user, focus))
	currently_charging = FALSE
	on_charge_ended(user, rifle)

	if(!spun_up)
		user.balloon_alert(user, "interrupted!")
		return GAUSS_CHARGE_ABORT

	charge_ratio = max_charge_time ? clamp(spun_time / max_charge_time, 0, 1) : 1
	charge_target = WEAKREF(focus)
	empowered_shot = TRUE
	return GAUSS_CHARGE_EMPOWERED

/obj/item/ammo_casing/energy/gauss/proc/get_charge_focus(atom/target, mob/living/user)
	return user

/obj/item/ammo_casing/energy/gauss/proc/get_charge_time(mob/living/user, atom/focus)
	if(!seconds_per_distance)
		return charge_time
	return clamp(get_dist(user, focus) * seconds_per_distance, charge_time, max_charge_time)

/obj/item/ammo_casing/energy/gauss/proc/charge_checks(mob/living/user, atom/focus)
	return HAS_TRAIT(user, TRAIT_USER_SCOPED)

/obj/item/ammo_casing/energy/gauss/proc/on_charge_started(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	return

/obj/item/ammo_casing/energy/gauss/proc/on_charge_ended(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	return

/obj/item/ammo_casing/energy/gauss/proc/on_empowered_fire(mob/living/user)
	if(charged_cooldown_time)
		COOLDOWN_START(src, charged_cooldown, charged_cooldown_time)

/obj/item/ammo_casing/energy/gauss/proc/get_charge_surcharge()
	if(!empowered_shot || isnull(charged_e_cost))
		return 0
	return max(charged_e_cost - e_cost, 0)

/obj/item/ammo_casing/energy/gauss/proc/reset_charge()
	empowered_shot = FALSE
	charge_ratio = 0
	charge_target = null

/obj/item/ammo_casing/energy/gauss/ready_proj(atom/target, mob/living/user, quiet, zone_override, atom/fired_from)
	. = ..()
	var/obj/projectile/bullet/gauss/round = astype(loaded_projectile)
	if(isnull(round) || !empowered_shot)
		return
	round.empower(charge_ratio, charge_target?.resolve())

/obj/projectile/bullet/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard_projectile"
	damage = 30
	armour_penetration = 20
	speed = 2
	wound_bonus = -20

/// Scoped harging makes the projectile far, far more stronger
/obj/projectile/bullet/gauss/proc/empower(charge_ratio, atom/target)
	damage = 55
	armour_penetration = 35
	speed = 3
	projectile_piercing = PASSMOB
