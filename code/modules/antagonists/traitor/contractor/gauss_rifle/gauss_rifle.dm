/obj/item/gun/energy/gauss_rifle
	name = "Raijin Horizon Gauss Rifle"
	desc = "The Raijin is a gauss type weapon designed more for utility and subterfuge rather than protracted combat engagements. \n\
		Scoped and suppressed. Chambered in 2mm FM (ferromagnetic)."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_item.dmi'
	lefthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_left.dmi'
	righthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_right.dmi'
	worn_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_back.dmi'
	base_icon_state = "empty"
	icon_state = "empty"
	inhand_icon_state = "standard"
	worn_icon_state = "contractor_gun_worn_back"
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	fire_delay = 2 SECONDS
	fire_mode_switch_sound = SFX_FIRE_MODE_SWITCH
	slot_flags = ITEM_SLOT_BACK
	automatic_charge_overlays = FALSE
	cell_type = /obj/item/stock_parts/power_store/gauss_nanites
	ammo_type = list(
		/obj/item/ammo_casing/energy/gauss,
		/obj/item/ammo_casing/energy/gauss/emp,
		/obj/item/ammo_casing/energy/gauss/gyro,
		/obj/item/ammo_casing/energy/gauss/antimatter,
		/obj/item/ammo_casing/energy/gauss/thermite,
	)
	force = 11
	/// If TRUE, scope art stretches fullscreen. If FALSE, it renders centered.
	var/scope_overlay_stretches = FALSE
	var/atom/movable/screen/gauss_ammo_display/ammo_display
	var/overheated = FALSE
	var/overheat_duration = 8 SECONDS
	var/antimatter_charging = FALSE

/obj/item/gun/energy/gauss_rifle/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 4, fullscreen_icon = "gauss_scope", tracker_type = /atom/movable/screen/fullscreen/cursor_catcher/scope/gauss)
	AddComponent(/datum/component/dialogue_system/contractor_gun)
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)
	ammo_display = new()
	ammo_display.RegisterSignal(src, COMSIG_GAUSS_RIFLE_AMMO_CHANGED, TYPE_PROC_REF(/atom/movable/screen/gauss_ammo_display, on_gun_ammo_changed))
	var/matrix/offset = matrix()
	offset.Translate(-16, 0)
	transform = offset

/obj/item/gun/energy/gauss_rifle/Destroy()
	// ammo_display?.hide_from_owner()
	QDEL_NULL(ammo_display)
	return ..()

/obj/item/gun/energy/gauss_rifle/pickup(mob/user)
	. = ..()
	ammo_display?.show_for(user)
	emit_ammo_signal()

/obj/item/gun/energy/gauss_rifle/dropped(mob/user, silent = FALSE)
	ammo_display?.hide_from_owner()
	return ..()

/obj/item/gun/energy/gauss_rifle/handle_chamber()
	. = ..()
	emit_ammo_signal()

/obj/item/gun/energy/gauss_rifle/can_shoot()
	if(overheated)
		return FALSE
	return ..()

/obj/item/gun/energy/gauss_rifle/shoot_live_shot(mob/living/user, pointblank = FALSE, atom/pbtarget = null, message = TRUE)
	. = ..()
	SEND_SIGNAL(src, COMSIG_GAUSS_RIFLE_SCOPE_KICK, user)

/obj/item/gun/energy/gauss_rifle/shoot_with_empty_chamber(mob/living/user)
	if(overheated)
		balloon_alert(user, "overheated!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 40, TRUE)
		return
	return ..()

/obj/item/gun/energy/gauss_rifle/proc/overheat()
	if(overheated)
		return
	overheated = TRUE
	do_sparks(3, FALSE, src)
	playsound(src, 'sound/effects/wounds/sizzle1.ogg', 50, TRUE)
	if(!(SEND_SIGNAL(src, COMSIG_PARTICLE_DRIFT_RESUME) & PARTICLE_DRIFT_RESUMED))
		AddComponent(/datum/component/particle_drift_on_move, /particles/smoke/gauss_overheat)
	if(isliving(loc))
		balloon_alert(loc, "gun overheating!")
	addtimer(CALLBACK(src, PROC_REF(end_overheat)), overheat_duration)

/obj/item/gun/energy/gauss_rifle/proc/end_overheat()
	overheated = FALSE
	SEND_SIGNAL(src, COMSIG_PARTICLE_DRIFT_WIND_DOWN)
	update_appearance()
	playsound(src, 'sound/items/weapons/gun/general/bolt_rack.ogg', 40, TRUE)
	if(isliving(loc))
		balloon_alert(loc, "gun ready")

/obj/item/gun/energy/gauss_rifle/select_fire(mob/living/user)
	. = ..()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[select]
	SEND_SIGNAL(src, COMSIG_GAUSS_RIFLE_MODE_CHANGED, user, current_ammo)
	emit_ammo_signal()

/obj/item/gun/energy/gauss_rifle/proc/get_current_mode_prefix()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[select]
	return current_ammo?.select_name || "normal"

/obj/item/gun/energy/gauss_rifle/proc/get_scope_icon_state(mode_prefix)
	if(mode_prefix == "antimatter")
		return antimatter_charging ? "antimatter_scope_hollow_shooting" : "antimatter_scope_hollow"
	return "[mode_prefix]_scope_hollow"

/obj/item/gun/energy/gauss_rifle/proc/set_antimatter_charging(charging)
	antimatter_charging = charging
	SEND_SIGNAL(src, COMSIG_GAUSS_RIFLE_SCOPE_REFRESH)

/obj/item/gun/energy/gauss_rifle/proc/emit_ammo_signal()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[select]
	var/mode_prefix = current_ammo?.select_name || "normal"
	if(!cell || !current_ammo || current_ammo.e_cost <= 0)
		SEND_SIGNAL(src, COMSIG_GAUSS_RIFLE_AMMO_CHANGED, 0, 0, mode_prefix)
		return
	SEND_SIGNAL(src, COMSIG_GAUSS_RIFLE_AMMO_CHANGED, \
		clamp(FLOOR(cell.charge / current_ammo.e_cost, 1), 0, 10), \
		clamp(FLOOR(cell.maxcharge / current_ammo.e_cost, 1), 0, 10), \
		mode_prefix)

/obj/item/gun/energy/gauss_rifle/examine_more(mob/user)
	. = ..()
	. += "The Raijin Horizon Gauss Rifle is slow to fire but fires a high velocity, high impact, high penetration round."
	. += "Has an implant restricted firing pin similar to nuclear operatives, and can only be fired by users with the Cybersun authorization implant. "
	. += "This implant is injected upon picking up the gun for the first time."
	. += "The case contains the gun, and comes with a number of customizable magazines."
	. += "A magazine can be swapped to a different ammunition type before being inserted into the gun."
	. += "Each projectile type expends more 'ammunition' from the magazine, which acts more like a battery than a traditional magazine."
	. += "Recharging these magazines requires either using a recharger, or the weapon case that came with the gun."

/obj/item/gun/energy/gauss_rifle/update_icon_state()
	. = ..()
	inhand_icon_state = current_state()

/obj/item/gun/energy/gauss_rifle/update_overlays()
	. = ..()
	if(current_state() != "empty")
		. += mutable_appearance(icon, current_state())
	. += emissive_appearance(icon, current_state(), src)

/obj/item/gun/energy/gauss_rifle/worn_overlays(mutable_appearance/standing, isinhands, icon_file, bodyshape = NONE)
	. = ..()
	if(!isinhands)
		return
	var/emissive_icon = "emissive_[current_state()]"
	. += emissive_appearance(icon_file, emissive_icon, src)

/obj/item/gun/energy/gauss_rifle/proc/current_state()
	// Charge-based rather than get_charge_ratio(), so overheating (can_shoot() == FALSE) doesn't read as empty.
	var/obj/item/ammo_casing/energy/gauss/gauss_chamber = astype(chambered)
	if(isnull(gauss_chamber) || !cell || cell.charge < gauss_chamber.e_cost)
		return "empty"
	return gauss_chamber.select_name

/obj/item/stock_parts/power_store/gauss_nanites
	name = "gauss nanite power store"
	desc = "A power storage unit containing self-replicating nanites that flash-fabricate microcartridge assemblies for gauss weaponry."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_hud.dmi'
	icon_state = "ammo_hud"
	maxcharge = STANDARD_CELL_CHARGE
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/stock_parts/power_store/gauss_nanites/Initialize(mapload, override_maxcharge)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/obj/item/stock_parts/power_store/gauss_nanites/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!istype(target, /obj/item/gun/energy/gauss_rifle))
		return ..()

	var/obj/item/gun/energy/gauss_rifle/target_gun = target
	if(!target_gun.cell)
		balloon_alert(user, "no cell inserted!")
		return TRUE

	if(target_gun.cell.charge >= target_gun.cell.maxcharge)
		balloon_alert(user, "already fully charged!")
		return TRUE

	if(!charge)
		balloon_alert(user, "power store empty!")
		return TRUE

	var/transfer_amount = min(charge, target_gun.cell.maxcharge - target_gun.cell.charge)
	if(!transfer_amount)
		return TRUE

	use(transfer_amount)
	target_gun.cell.give(transfer_amount)
	target_gun.recharge_newshot(TRUE)
	target_gun.update_appearance()
	update_appearance()
	target_gun.emit_ammo_signal()
	playsound(target_gun, 'sound/items/weapons/kinetic_reload.ogg', 60, TRUE)
	balloon_alert(user, "cell recharged")
	return TRUE

/obj/item/ammo_box/magazine/gauss
	name = "Raijin Horizon Gauss Magazine"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities."
	caliber = CALIBER_GAUSS
	max_ammo = 5
	icon_state = ".50mag"
	ammo_type = /obj/item/ammo_casing/energy/gauss

/obj/item/ammo_box/magazine/gauss/emp
	name = "Raijin Horizon Smart EMP Gauss Magazine"
	color = COLOR_BLUE
	ammo_type = /obj/item/ammo_casing/energy/gauss/emp

/obj/item/ammo_box/magazine/gauss/gyro
	name = "Raijin Horizon Gyre Gauss Magazine"
	color = COLOR_YELLOW
	ammo_type = /obj/item/ammo_casing/energy/gauss/gyro

/obj/item/ammo_box/magazine/gauss/antimatter
	name = "Raijin Horizon Antimatter Gauss Magazine"
	color = COLOR_PURPLE
	ammo_type = /obj/item/ammo_casing/energy/gauss/antimatter

/obj/item/ammo_box/magazine/gauss/thermite
	name = "Raijin Horizon Red Sun Gauss Magazine"
	color = COLOR_RED
	ammo_type = /obj/item/ammo_casing/energy/gauss/thermite

/particles/smoke/gauss_overheat
	count = 200
	spawning = 2
