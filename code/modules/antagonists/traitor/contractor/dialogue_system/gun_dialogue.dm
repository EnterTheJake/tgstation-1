/// Raijin Horizon Gauss Rifle dialogue component.
/datum/component/dialogue_system/contractor_gun
	dupe_mode = COMPONENT_DUPE_UNIQUE
	signals_to_unregister = list(COMSIG_ITEM_PICKUP, COMSIG_ITEM_DROPPED, COMSIG_GAUSS_RIFLE_MODE_CHANGED, COMSIG_CONTRACTOR_KIDNAPPED)
	/// Weakref to the mob currently holding the parent, used to register/unregister kidnap signals.
	var/datum/weakref/current_holder_ref

	//---- Gun has a lot of lines, means we got a lot of lists for different situations. Buncha snowflake
	/// Job-title keyed kidnapped sound pools (e.g. JOB_HEAD_OF_PERSONNEL => list(...)).
	var/list/kidnapped_sounds_by_rank
	/// Ammo-casing-type keyed mode swap sound pools.
	var/list/mode_swap_sounds_by_ammo_type
	var/list/mode_unlocked
	var/list/unathorized_user
	var/list/unathorized_user_poisoned
	var/list/deconstruction
	var/list/overheated
	var/list/reloaded
	var/list/activated_bomb_implant

	/// Tracker that remembers how many times we've played the "empty mag" line. Plays it sequentially and resets on shot
	var/empty_mag_annoyance = 0
	/// Cooldown so we can't just zoom through all the empty mag lines
	COOLDOWN_DECLARE(empty_mag_cooldown)
	var/list/empty_mag

/datum/component/dialogue_system/contractor_gun/setup_sound_lists()
	. = ..()

	dropped_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_floor_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_floor_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_floor_3_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_floor_4_take1.ogg'),
	)

	pickup_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_1_take2_rare.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_2_stitched_take1_rare.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_3_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_3_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_4_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_4_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_5_take_bonus.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_5_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_5_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_6_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_6_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_6_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup7_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup7_take5.ogg'),
	)

	// XANTODO: Make it so that there's specific checks to whoever gets kidnapped for stuff like antag and shit
	kidnapped_sounds_by_rank = list(
		JOB_CAPTAIN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/captain/kidnapped_captain_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/captain/kidnapped_captain_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/captain/kidnapped_captain_3_take1.ogg'),
		),
		JOB_CHIEF_ENGINEER = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/ce/kidnapped_ce_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/ce/kidnapped_ce_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/ce/kidnapped_ce_3_take2.ogg'),
		),
		changeling = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/changeling/kidnapped_changeling_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/changeling/kidnapped_changeling1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/changeling/kidnapped_changeling2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/changeling/kidnapped_changeling3_take2.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/clown/kidnapped_clown_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/clown/kidnapped_clown_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/clown/kidnapped_clown_3_take1.ogg'),
		),
		JOB_CHIEF_MEDICAL_OFFICER = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/cmo/kidnapped_cmo_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/cmo/kidnapped_cmo_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/cmo/kidnapped_cmo_3_take2.ogg'),
		),
		corpse = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_corpse_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_corpse_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_corpse_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_important_corpse_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_important_corpse_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/corpse/kidnapped_important_corpse_3_take4.ogg'),
		),
		heretic = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/heretic/kidnapped_ascended_heretic_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/heretic/kidnapped_heretic1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/heretic/kidnapped_heretic2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/heretic/kidnapped_heretic3_take2.ogg'),
		),
		JOB_HEAD_OF_PERSONNEL = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_hop_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_hop_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_hop_3_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_hop_4_take1.ogg'),
		),
		JOB_HEAD_OF_SECURITY = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hos/kidnapped_hos_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hos/kidnapped_hos_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/hos/kidnapped_hos_3_take2.ogg'),
		),
		JOB_MIME = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/mime/kidnapped_mime_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/mime/kidnapped_mime_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/mime/kidnapped_mime_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/mime/kidnapped_mime_4_take1.ogg'),
		),
		JOB_QUARTERMASTER = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/qm/kidnapped_qm_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/qm/kidnapped_qm_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/qm/kidnapped_qm_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/qm/kidnapped_qm_4_take1.ogg'),
		),
		JOB_RESEARCH_DIRECTOR = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/rd/kidnapped_rd_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/rd/kidnapped_rd_2_take1.ogg'),
		),
		spy = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/spy/kidnapped_spy_1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/spy/kidnapped_spy_2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/spy/kidnapped_spy_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/spy/kidnapped_spy_dead_take3.ogg'),
		),
		traitor = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/traitor/kidnapped_traitor_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/traitor/kidnapped_traitor1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/traitor/kidnapped_traitor2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/kidnapped/traitor/kidnapped_traitor3_take1.ogg'),
		),
	)

	mode_unlocked = list(
		/obj/item/ammo_casing/energy/gauss/emp = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_unlocked/mode_swap_emp_2_take1_rare.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/thermite = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_unlocked/thermal_mode_unlocked.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/darkmatter = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/mode_unlocked/dark_matter_installed.ogg'),
		),
	)

	mode_swap_sounds_by_ammo_type = list(
		/obj/item/ammo_casing/energy/gauss = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_3_take1_rare.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_4_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_5_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_6_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/mode_swap_normal_7_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/emp = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_4_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_5_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_6_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/mode_swap/mode_swap_emp_7_take1.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/gyro = list(
//			giga_drillu_breakaaaaaaaaaa = list(
//				new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/giga_drillu_breakaaaaaaaaaa/charge_up_gyre1_take2.ogg'),
//				new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/giga_drillu_breakaaaaaaaaaa/charge_up_gyre2_take2.ogg'),
//				new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/giga_drillu_breakaaaaaaaaaa/charge_up_gyre3_take2.ogg'),
//			), // XANTODO: Sounds played when empowered shot
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_4_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_5_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_6_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/mode_swap_gyre_7_take1.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/darkmatter = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/swap_to/mode_swap_dark1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/swap_to/mode_swap_dark2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/swap_to/mode_swap_dark3_take3_rare.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/swap_to/mode_swap_dark4_take2_rare.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/swap_to/mode_swap_dark5_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/thermite = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_4_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/mode_swap/mode_swap_thermal_6_take1.ogg'),
		),
	)

	unathorized_user = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/unathorized_user/unauthorized_user_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/unathorized_user/unauthorized_user_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/unathorized_user/unauthorized_user_3_take2.ogg'),
	)

	unathorized_user_poisoned = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/unathorized_user_poisoned/unauthorized_user_poison_1_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/unathorized_user_poisoned/unauthorized_user_poison_2_take_stitched1.ogg'),
	)

	deconstruction = list( // Gun put through the deconstructor
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/oblivion/oblivion_2_take1_destroyed.ogg'),
	)

	overheated = list( // Plays line when the gun overheats
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/overheated/cooldown1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/overheated/cooldown1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/overheated/cooldown2_take2.ogg'),
	)

	reloaded = list( // New cell inserted
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/reloaded/reloaded_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/reloaded/reloaded_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/reloaded/reloaded_3_take2.ogg'),
	)

	empty_mag = list( // Every time you try to shoot with an empty magazines, plays the lines in order. Small cooldown. Resets when you reload
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/empty_mag/empty_mag_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/empty_mag/empty_mag_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/empty_mag/empty_mag_3_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/empty_mag/empty_mag_4_take2.ogg'),
	)



// XANTODO : Start implementing the lines

/*

	// XANTODO: COMSIG_EXPLOSIVE_IMPLANT_MANUALLY_TRIGGERED needs to be registered on however we decide to track the contractor
	activated_bomb_implant = list( // Suicide self-destruct implant
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activated_bomb_implant/activated_bomb_implant_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activated_bomb_implant/activated_bomb_implant_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activated_bomb_implant/activated_bomb_implant_3_take1.ogg'),
	)

	activation = list( // First time holding the gun, presumably you took it out of the box into your hands
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activation/activation_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activation/activation_2_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/activation/activation_3_take3.ogg'),
	)

	apocalypse = list( // Heretic stuff
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_ash_take3.ogg'), // Ash ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_blade_blocks_near_gun_take2.ogg'), // Bullet blocked by blade heretic knife
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_blade_take4.ogg'), // Blade Ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_blob_take1.ogg'), // Blob reaches critical mass
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_cosmic_stargazer_beam_take1.ogg'), // Witnessing a gazer laser
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_cosmic_stargazer_beam_take4.ogg'), // Witnessing a gazer laser
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_cosmic_take2.ogg'), // Cosmic ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_darkmatter_take1.ogg'), // Dark singularity announcement
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_flesh_take2.ogg'), // Flesh ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_flesh_worm_spotted.ogg'), // First time you see the worm
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_lock_take1.ogg'), // Lock ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_moon_take5.ogg'), // Moon ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_narsie_ritual_take1.ogg'), // Cultists began the ritual
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_narsie_ritual_user_is_cultist_take1.ogg'), // Began the ritual as a cultist
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_narsie_take1.ogg'), // Narsie successfully summoned
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_nuclear_detonation_nanotrasen_rare_take1.ogg'), // Any Nuke going off
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_resonance_cascade_take1.ogg'), // Resonance cascade
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_revolution_take2.ogg'), // Revs winning
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_rust_take1.ogg'), // Rust ascension
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_singularity_take1.ogg'), // Singulo spawned
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_tesla_take1.ogg'), // Tesla spawned
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/apocalypse/apocalypse_void_take1.ogg'), // Void ascension
	)

	bomb_activation = list( // Activate the bomb via the UI
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_activation/bomb_activation_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_activation/bomb_activation_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_activation/bomb_activation_3_take2.ogg'),
	)

	bomb_defused = list( // Bomb was disarmed (Not from the UI). NOTE: The gun doesnt give a fuck if the contractor disables the bomb
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_defused/bomb_defused_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_defused/bomb_defused_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_defused/bomb_defused_knows_take1.ogg'), // SPEFICIALLY Gun has met the bomb
	)

	bomb_detonated = list( // Bomb went off
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_detonated/bomb_detonated_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_detonated/bomb_detonated_3_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_detonated/bomb_detonated_knows1_take3.ogg'), // Gun met bomb
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_detonated/bomb_detonated_knows2_take3.ogg'), // Gun met bomb
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/bomb_detonated/bomb_detonated_knows3_take3.ogg'), // Gun met bomb
	)

	box_take_in_out = list( // Taking the gun out of the suitcase / Putting it into the suitcase
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_put_in_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_put_in_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_put_in_3_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_taken_out_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_taken_out_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/box_take_in_out/box_taken_out_3_take2.ogg'),
	)

	contractor_borg = list( // Cubie lines
		greetings = list( // Borg summoned
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/greetings/cube_greet1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/greetings/cube_greet2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/greetings/cube_greet3_take1.ogg'),
		),
		vore_contractor = list( // Borg ate the contractor
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_contractor/cube_carries_contractor1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_contractor/cube_carries_contractor2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_contractor/cube_carries_contractor3_take2.ogg'),
		),
		vore_crew = list( // Borg ate non-contractor
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_crew/cube_carries_victim1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_crew/cube_carries_victim2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_crew/cube_carries_victim3_take1.ogg'),
		),
		vore_critical_contractor = list( // Cubie ate the contractor who's in crit
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_critical_contractor/cube_carries_contractor_dying1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_critical_contractor/cube_carries_contractor_dying2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/contractor_borg/vore_critical_contractor/cube_carries_contractor_dying3_take1.ogg'),
		),
	)

	fps_arrived = list( // IRS pirates have arrived. Not yet implemented so for now XANTODO ARTURTODO zzzzzzzzzzz
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/fps_arrived/fps_arrived_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/fps_arrived/fps_arrived_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/fps_arrived/fps_arrived_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/fps_arrived/fps_arrived_4_take1.ogg'),
	)

	gun_smack = list( // Melee-ing someone with the gun
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/gun_smack/gun_smack_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/gun_smack/gun_smack_2_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/gun_smack/gun_smack_3_take1.ogg'),
	)

	idle_on_floor = list( // Gun starts coping when you leave it alone. Follows order, resets when picked up.
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/idle_on_floor/idle_on_floor_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/idle_on_floor/idle_on_floor_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/idle_on_floor/idle_on_floor_3_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/idle_on_floor/idle_on_floor_4_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/idle_on_floor/idle_on_floor_long_time_take2.ogg'),
	)

	mode_swap_dark_matter = list(
		charging = list( // Start winding up the shot
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/charging/charge_up1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/charging/charge_up2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/charging/charge_up3_take3.ogg'),
		),
		dark_matter_singulo_conjured = list( // When you shoot a singulo and turn it into a dark matter. :)
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/dark_matter_singulo_conjured/wtf_have_you_done.ogg'),
		),

	/* NOT YET IMPLEMENTED
	When you try to shoot the darkmatter shot without the scope, the gun gets increasingly mad at you for your utter stupidity
	With every hipfire failure, it progresses through hip_fire_fail
	On the 5th failure, you get hit by "steve_has_had_enough_of_your_bs" and you can no longer shoot the darkmatter

	Spamming the gun while blocked will remove the block and hit you with "reluctant_concession"

	Fail AGAIN after you got blocked then unblocked. You get "disappointment"
	*/

		disappointment = list( // Not yet implemented.
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/disappointment/darkmatter_disappointment_take1.ogg'),
		),
		hip_fire_fail = list( // Not yet implemented
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/hip_fire_fail/darkmatter_misfire1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/hip_fire_fail/darkmatter_misfire2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/hip_fire_fail/darkmatter_misfire3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/hip_fire_fail/darkmatter_misfire4_take1.ogg'),
		),
		reluctant_concession = list( // Not yet implemented
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/reluctant_concession/mode_swap_dark_allow_take2.ogg'),
		),
		steve_has_had_enough_of_your_bs = list( // Not yet implemented
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_dark_matter/steve_has_had_enough_of_your_bs/darkmatter_stevesaysnope_take1.ogg'),
		),
	)

	moon_conversion = list( // While acting as a moonatic, all other lines are blocked. The only lines that can play are these ones:
		contractor_converted = list( // Converted to a moonatic. Either via their ascension event or hit by the amulet
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/contractor_converted/apocalypse_moon_afflicted_take1.ogg'),
		),
		moon_contractor_dies = list( // Dies as a moonatic, after this the lines go back to normal
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_contractor_dies/user_died_moon1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_contractor_dies/user_died_moon2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_contractor_dies/user_died_moon3_take1.ogg'),
		),

		moon_darkmatter = list( // Swap sound
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_darkmatter/ammo_swap_darkmatter_moon_take1.ogg'),
		),
		moon_emp = list( // Swap sound
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_emp/ammo_swap_emp_moon_take2.ogg'),
		),
		moon_gyre = list( // Swap sound
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_gyre/ammo_swap_gyre_moon_take3.ogg'),
		),
		moon_thermite = list( // Swap sound
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_thermite/ammo_swap_thermal_moon_take3.ogg'),
		),
		moon_normal = list( // Swap sound
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_normal/ammo_swap_standard_moon_take2.ogg'),
		),

		moon_idle = list( // Bored on the floor
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_idle/idle_moon_take1.ogg'),
		),
		moon_out_of_ammo = list( // Randomized + Repeatable
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_out_of_ammo/empty_mag_moon1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_out_of_ammo/empty_mag_moon2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_out_of_ammo/empty_mag_moon3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_out_of_ammo/empty_mag_moon4_take1.ogg'),
		),
		moon_pickup = list( // Equipping the gun
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_pickup/on_pickup_moon1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_pickup/on_pickup_moon2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_pickup/on_pickup_moon3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_pickup/on_pickup_moon4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_pickup/on_pickup_moon5_take2.ogg'),
		),
		moon_reloaded = list( // Insert a new cell
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_reloaded/reloaded_moon1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_reloaded/reloaded_moon2_take1.ogg'),
		),
		moon_user_shot = list( // Getting shot by any bullet
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_user_shot/user_shot_moon1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_user_shot/user_shot_moon2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/moon_conversion/moon_user_shot/user_shot_moon3_take2.ogg'),
		),
	)

	nope = list( // Trying to fire a round when it's not off cooldown yet or if the mode is blocked
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/nope/mode_swap_dark_fail1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/nope/mode_swap_dark_fail2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/nope/mode_swap_dark_fail3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/nope/mode_swap_dark_fail4_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/nope/mode_swap_dark_repeated.ogg'),
	)

	pointblank_shot = list( // When you land a shot on someone and they're 1-2 tiles away from you
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/pointblank_shot/pointblank_shot_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/pointblank_shot/pointblank_shot_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/pointblank_shot/pointblank_shot_3_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/pointblank_shot/pointblank_shot_3_take2.ogg'), // Died from the shot
	)

	pointblank_shot_scoped = list( // Same as above but scoped in
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/pointblank_shot_scoped/pointblank_shot_scoped_take2.ogg'),
	)

	scope_activated = list( // First time you ever scoped in. Only 1 of these lines will ever play (RNJesus decides)
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/scope_activated/scope_activated_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/scope_activated/scope_activated_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/scope_activated/scope_activated_3_take2.ogg'),
	)

	speaker = list( // Not yet implemented
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_off_1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_off_2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_off_3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_off_4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_on_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_on_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_on_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_on_new_user_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/speaker/speaker_on_new_user_2_take1.ogg'),
	)

	success_and_failure = list( // Plays a line when the round ends. Based on if the contractor succeded all objectives, or failed.
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/success_and_failure/failure_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/success_and_failure/failure_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/success_and_failure/success_1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/success_and_failure/success_2_take2.ogg'),
	)

	// kidnapped_sounds_by_rank will take priority. If there are no special lines to the person we kidnapped, we fall back to "user_paid" which is our standard basically
	user_paid = list( // Successfully kidnapped someone
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_paid/user_paid_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_paid/user_paid_2_take4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_paid/user_paid_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_paid/user_paid_5_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_paid/user_paid_first_time.ogg'), // First kidnapping, non-repeatable the rest are RNG
	)

	user_shot = list( // Getting hit by any bullet
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_shot/user_shot_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_shot/user_shot_2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_shot/user_shot_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_shot/user_shot_4_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_shot/user_shot_5_take1.ogg'),
	)

	user_died = list( // Contractor has died (while in view of the gun)
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_died/user_died_1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_died/user_died_2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_died/user_died_3_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/user_died/user_died_4_take2.ogg'),
	)
*/























/datum/component/dialogue_system/contractor_gun/apply_dialogue_channel()
	. = ..()
	apply_channel_to_sound_pool_list(assoc_to_values(kidnapped_sounds_by_rank))
	apply_channel_to_sound_pool_list(assoc_to_values(mode_swap_sounds_by_ammo_type))
	apply_channel_to_sound_pool_list(assoc_to_values(mode_unlocked))
	apply_channel_to_sound_list(unathorized_user)
	apply_channel_to_sound_list(unathorized_user_poisoned)

/datum/component/dialogue_system/contractor_gun/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_MODE_CHANGED, PROC_REF(on_mode_changed))
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_AMMOTYPE_UNLOCKED, PROC_REF(on_mode_unlocked))
	RegisterSignal(parent, COMSIG_FIRING_PIN_AUTH_FAILED, PROC_REF(on_auth_failed))
	RegisterSignal(parent, COMSIG_DESTRUCTIVE_ANALYZER_DESTROY, PROC_REF(on_destructive_analysis))
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_OVERHEATED, PROC_REF(on_gun_overheat))
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_CELL_REFILLED, PROC_REF(on_cell_refilled))
	RegisterSignal(parent, COMSIG_GUN_FIRED_EMPTY_CHAMBER, PROC_REF(on_shoot_empty))

/// Helper proc, plays a sound from a given sound pool.
/datum/component/dialogue_system/contractor_gun/proc/emit_sound_from_list(list/sound_list)
	if(!length(sound_list))
		return
	var/datum/dialogue_sound/sound = pick_available_sound(sound_list, parent, parent)
	sound_list -= sound
	sound?.play(location = parent)
	var/line_duration = rustg_sound_length(sound.sound_path)
	SEND_SIGNAL(parent, COMSIG_DIALOGUE_SOUND_EMITTED, line_duration)

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

/datum/component/dialogue_system/contractor_gun/proc/on_mode_unlocked(datum/source, obj/item/ammo_casing/energy/casing_path)
	SIGNAL_HANDLER
	emit_sound_from_list(mode_unlocked[casing_path])

/datum/component/dialogue_system/contractor_gun/on_pickup(obj/item/source, mob/taker)
	_unregister_holder()
	current_holder_ref = WEAKREF(taker)
	RegisterSignal(taker, COMSIG_CONTRACTOR_KIDNAPPED, PROC_REF(on_kidnapped))
	return ..()

/datum/component/dialogue_system/contractor_gun/try_play_pickup_line(mob/living/taker)
	if(!isliving(taker))
		return
	if(!taker?.is_holding(parent))
		return
	var/list/sound_pool = pickup_sounds
	if(!locate(/obj/item/implant/explosive/contractor) in taker.implants) // No implant found?
		sound_pool = unathorized_user
	emit_sound_from_list(sound_pool)

/datum/component/dialogue_system/contractor_gun/on_dropped(obj/item/source, mob/living/dropper)
	_unregister_holder()
	if(!locate(/obj/item/implant/explosive/contractor) in dropper.implants) // No implant found?
		return // Parent call plays a line "hey you forgot me"
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

	var/list/sound_pool = mode_swap_sounds_by_ammo_type?[new_mode.type]
	var/datum/dialogue_sound/sound = pick_available_sound(sound_pool, user, parent)
	sound?.play(user, parent)

/// Called when the firing pin fails to auth the shooter
/datum/component/dialogue_system/contractor_gun/proc/on_auth_failed(datum/source, mob/user)
	SIGNAL_HANDLER
	emit_sound_from_list(unathorized_user_poisoned)

/// Plays when the bomb is killed by a deconstructive analyzer
/datum/component/dialogue_system/contractor_gun/proc/on_destructive_analysis()
	SIGNAL_HANDLER
	emit_sound_from_list(deconstruction)

/// Plays when the gun ends up overheating
/datum/component/dialogue_system/contractor_gun/proc/on_gun_overheat()
	SIGNAL_HANDLER
	emit_sound_from_list(overheated)

/// Plays when the gun is given a cell that allows it to reach max battery
/datum/component/dialogue_system/contractor_gun/proc/on_cell_refilled()
	SIGNAL_HANDLER
	empty_mag_annoyance = 0
	emit_sound_from_list(reloaded)

/// Plays when the user tries to shoot the gun while the cell is completely empty. Goes through the list in order
/datum/component/dialogue_system/contractor_gun/proc/on_shoot_empty()
	SIGNAL_HANDLER
	if(!COOLDOWN_FINISHED(src, empty_mag_cooldown))
		return
	empty_mag_annoyance++
	if(empty_mag_annoyance > length(empty_mag)) // Ran out of lines, will reset the var to 0 when the gun is reloaded
		return
	var/datum/dialogue_sound/sound = empty_mag[empty_mag_annoyance]
	var/line_duration = rustg_sound_length(sound.sound_path)
	sound?.play(location = parent)
	COOLDOWN_START(src, empty_mag_cooldown, (5 SECONDS + line_duration))
// XANTODO: Make it where when you put the gun in the gun case it resets `empty_mag_annoyance` back to 0 as well (Since it recharges the gun)

