/// Raijin Horizon Gauss Rifle dialogue component.
/datum/component/dialogue_system/contractor_gun
	dupe_mode = COMPONENT_DUPE_UNIQUE
	signals_to_unregister = list(COMSIG_ITEM_PICKUP, COMSIG_ITEM_DROPPED, COMSIG_GAUSS_RIFLE_MODE_CHANGED, COMSIG_CONTRACTOR_KIDNAPPED)
	/// Job-title keyed kidnapped sound pools (e.g. JOB_HEAD_OF_PERSONNEL => list(...)).
	var/list/kidnapped_sounds_by_rank
	/// Ammo-casing-type keyed mode swap sound pools.
	var/list/mode_swap_sounds_by_ammo_type
	/// Weakref to the mob currently holding the parent, used to register/unregister kidnap signals.
	var/datum/weakref/current_holder_ref

/datum/component/dialogue_system/contractor_gun/setup_sound_lists()
	. = ..()
	pickup_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_5.ogg'),
	)
	dropped_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_4.ogg'),
	)
	kidnapped_sounds_by_rank = list(
		JOB_HEAD_OF_PERSONNEL = list(
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_1.ogg', priority = 10),
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_2.ogg', priority = 10),
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_3.ogg', priority = 10),
		),
	)
	mode_swap_sounds_by_ammo_type = list(
		/obj/item/ammo_casing/energy/gauss = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_4_take1.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/emp = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap_emp_4_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/gyro = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_4_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/antimatter = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/mode_swap_anti_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/mode_swap_anti_2_take4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/mode_swap_anti_4_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/mode_swap_anti_4_take4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/mode_swap_anti_4_take5.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/thermite = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap_thermal_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap_thermal_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap_thermal_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap_thermal_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap_thermal_4_take2.ogg'),
		),
	)

/datum/component/dialogue_system/contractor_gun/apply_dialogue_channel()
	. = ..()
	apply_channel_to_sound_pool_list(assoc_to_values(kidnapped_sounds_by_rank))
	apply_channel_to_sound_pool_list(assoc_to_values(mode_swap_sounds_by_ammo_type))

/datum/component/dialogue_system/contractor_gun/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_MODE_CHANGED, PROC_REF(on_mode_changed))

/datum/component/dialogue_system/contractor_gun/Destroy(force)
	_unregister_holder()
	return ..()

/datum/component/dialogue_system/contractor_gun/proc/_unregister_holder()
	var/mob/prev_holder = current_holder_ref?.resolve()
	if(prev_holder)
		UnregisterSignal(prev_holder, COMSIG_CONTRACTOR_KIDNAPPED)
	current_holder_ref = null

/datum/component/dialogue_system/contractor_gun/UnregisterFromParent()
	_unregister_holder()
	return ..()

/datum/component/dialogue_system/contractor_gun/on_pickup(obj/item/source, mob/taker)
	_unregister_holder()
	current_holder_ref = WEAKREF(taker)
	RegisterSignal(taker, COMSIG_CONTRACTOR_KIDNAPPED, PROC_REF(on_kidnapped))
	return ..()

/datum/component/dialogue_system/contractor_gun/on_dropped(obj/item/source, mob/user)
	_unregister_holder()
	return ..()

/// Called when the contractor successfully kidnaps a target.
/datum/component/dialogue_system/contractor_gun/proc/on_kidnapped(mob/source, mob/living/victim)
	SIGNAL_HANDLER

	var/victim_rank = victim?.mind?.assigned_role?.title
	var/list/sounds_for_rank = kidnapped_sounds_by_rank?[victim_rank]
	var/datum/dialogue_sound/sound = pick_available_sound(sounds_for_rank, victim, parent)
	sound?.delayed_play(victim, parent, 3 SECONDS)

/datum/component/dialogue_system/contractor_gun/proc/on_mode_changed(obj/item/gun/energy/gauss_rifle/source, mob/living/user, obj/item/ammo_casing/energy/new_mode)
	SIGNAL_HANDLER

	var/list/sounds_for_mode = mode_swap_sounds_by_ammo_type?[new_mode.type]
	var/datum/dialogue_sound/sound = pick_available_sound(sounds_for_mode, user, parent)
	sound?.play(user, parent)
