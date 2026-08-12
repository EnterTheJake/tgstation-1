/obj/item/ammo_casing/energy/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard"
	caliber = CALIBER_GAUSS
	projectile_type = /obj/projectile/bullet/gauss
	select_name = "standard"
	e_cost = GAUSS_NANITES(3)
	/// Nanites an empowered shot costs. A null value bills the empowered shot at e_cost.
	var/charged_e_cost
	/// Floor on the scoped spin-up. Also the whole spin-up when seconds_per_distance is zero.
	var/charge_time = 1 SECONDS
	/// Extra spin-up time per tile between the shooter and the target.
	var/seconds_per_distance = 0.2 SECONDS
	/// Spin-up ceiling, and the point where charge-scaled effects reach full strength.
	var/max_charge_time = 5 SECONDS
	/// If TRUE, the shooter must scope in. This round has no hip fired version.
	var/scope_only = FALSE
	/// How long empowered shots stay blocked after one fires. Hip fire ignores this.
	var/charged_cooldown_time = 0
	/// Blocks a second spin-up while one already runs.
	var/currently_charging = FALSE
	/// TRUE when the chambered shot carries a finished spin-up. The gun then bills charged_e_cost.
	var/empowered_shot = FALSE
	/// How far the last spin-up ran toward max_charge_time, 0 to 1. Drives charge-scaled effects.
	var/charge_ratio = 0
	/// charge_shot() picks this target. ready_proj() hands it to the projectile.
	var/datum/weakref/charge_target
	var/charge_alert = "spinning up..."
	var/charge_sound = 'sound/items/weapons/gun/general/chunkyrack.ogg'
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

/**
 * Runs the scoped spin-up that empowers a round.
 *
 * A hip shot skips the spin-up and stays unempowered. A scoped shot fires only after the do_after
 * finishes. Every empowered round therefore costs the shooter time on the scope.
 *
 * Returns GAUSS_CHARGE_ABORT, GAUSS_CHARGE_HIP or GAUSS_CHARGE_EMPOWERED.
 */
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

/// The atom that the spin-up do_after watches. A round that needs a mob target overrides this.
/obj/item/ammo_casing/energy/gauss/proc/get_charge_focus(atom/target, mob/living/user)
	return user

/obj/item/ammo_casing/energy/gauss/proc/get_charge_time(mob/living/user, atom/focus)
	if(!seconds_per_distance)
		return charge_time
	return clamp(get_dist(user, focus) * seconds_per_distance, charge_time, max_charge_time)

/// The charge fails if the shooter leaves the scope. This also roots the shooter for the whole spin-up.
/obj/item/ammo_casing/energy/gauss/proc/charge_checks(mob/living/user, atom/focus)
	return HAS_TRAIT(user, TRAIT_USER_SCOPED)

/// Hook for the visuals that the shooter wears during the spin-up.
/obj/item/ammo_casing/energy/gauss/proc/on_charge_started(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	return

/obj/item/ammo_casing/energy/gauss/proc/on_charge_ended(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	return

/// Runs after an empowered round fires. Handles cooldowns and heat.
/obj/item/ammo_casing/energy/gauss/proc/on_empowered_fire(mob/living/user)
	if(charged_cooldown_time)
		COOLDOWN_START(src, charged_cooldown, charged_cooldown_time)

/// Extra nanites that the gun owes above e_cost for the shot it just fired.
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
	damage = 35
	armour_penetration = 20
	speed = 2
	wound_bonus = -20

/// Upgrades the round after a completed scoped spin-up. charge_ratio runs 0 to 1.
/obj/projectile/bullet/gauss/proc/empower(charge_ratio, atom/target)
	damage = 55
	armour_penetration = 35
	projectile_piercing = PASSMOB
