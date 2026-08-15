#define DEFAULT_BOMB_SOUND "default_sounds"

/// Contractor bomb dialogue component.
/datum/component/dialogue_system/contractor_bomb
	dupe_mode = COMPONENT_DUPE_UNIQUE
	signals_to_unregister = list(
		COMSIG_ITEM_PICKUP,
		COMSIG_ITEM_DROPPED,
		COMSIG_CONTRACTOR_BOMB_WIRE_CUT,
		COMSIG_CONTRACTOR_UI_BOMB_ARMED,
		COMSIG_CONTRACTOR_UI_BOMB_DEFUSED,
		COMSIG_FORK_STUCK_IN_BOMB,
		COMSIG_PLUTONIUM_INSERTED,
		COMSIG_GLOB_NUKE_DEVICE_DETONATING,
		COMSIG_DESTRUCTIVE_ANALYZER_DESTROY,
		COMSIG_CONTRACTOR_PRE_EXPLOSION,
		COMSIG_CONTRACTOR_BOMB_TIME_LOWERED,
	)

	/// Reference to the mob that the bomb is attached to
	var/datum/weakref/bomb_wearer

	/// Memory of the last threshold that was announced
	var/previous_threshold = 100
	/// Time since last idle chatter
	COOLDOWN_DECLARE(last_idle)
	/// Time until next idle chatter is due
	var/next_idle = 1 MINUTES

	//---- Bomb has a lot of lines, means we got a lot of lists for different situations. Buncha snowflake
	var/list/admin_abuse
	var/list/bomb_activated
	var/list/explosion_successful_voltaic
	var/list/bomb_bad_wire_reduce_time
	var/list/bomb_bad_wire_upgrade
	var/list/bomb_corporate
	var/list/bomb_deactivated_contractor
	var/list/bomb_deactivated_idle
	var/list/bomb_deactivated_surgery
	var/list/bomb_good_wire
	var/list/bomb_maskless
	var/list/changeling
	var/list/deconstruction
	var/list/explodes_cutely
	var/list/explosion_successful
	var/list/explosion_successful_upgraded
	var/list/greeting
	var/list/mid_surgery
	var/list/fork_surgery
	var/list/bad_wire_time
	var/list/bad_wire_upgrade
	var/list/core_insertion
	var/list/explosion_successful_nuclear
	var/list/disarm
	var/list/nuclear_idle
	var/list/good_wire_time
	var/list/try_deactivate
	var/list/station_nuke_detonated
	var/list/timer_lines
	var/list/victim_crit

/datum/component/dialogue_system/contractor_bomb/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(emit_sound_from_list), has_special_line(greeting)), 1 SECONDS)

/datum/component/dialogue_system/contractor_bomb/setup_sound_lists()
	. = ..()

	/*
	 * We have 5 types of explosions:
	 * 1 - Admin pressed a button to make the bomb blow up immediately (lol) -> admin_abuse
	 * 2 - The bomb explodes normally without modifiers	 -> explosion_successful
	 * 3 - The bomb has it's radius upgraded either via fork or surgery -> explosion_successful_upgraded
	 * 4 - The bomb will explode into a tesla if the wearer has a voltaic heart -> explosion_successful_voltaic
	 * 5 - The bomb will explode past the maximum amount with a nuclear core installed -> explosion_successful_nuclear
	*/
	admin_abuse = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse3_take1.ogg'),
	)

	explosion_successful = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful5.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful6.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful7.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation2_take2.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_detonation/victim_felinid10_take1.ogg'),
		),
	)

	explosion_successful_upgraded = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion3.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_bad_wire_detonation1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_bad_wire_detonation2_take1.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_detonation/victim_felinid10_take1.ogg'),
		),
	)

	explosion_successful_voltaic = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion4.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation_tesla.ogg'),
		),
	)

	explosion_successful_nuclear = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation3_take1.ogg'),
	)

	bomb_activated = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated6_take2.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated3_take2.ogg'),
		),
	)

	bomb_bad_wire_reduce_time = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_explosion1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time5_take2.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_time/clown_bad_wire_reduce_time1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_time/clown_bad_wire_reduce_time2_take2.ogg'),
		),
	)

	bomb_bad_wire_upgrade = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade4_take2.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_upgrade/clown_bad_wire_upgrade1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_upgrade/clown_bad_wire_upgrade2_take2.ogg'),
		),
	)

	bomb_corporate = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate6_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_corporate/bomb_corporate7_take3.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_general/clown_general1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_general/clown_general2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_general/clown_general3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_general/clown_general4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_general/clown_general5_take2.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid3_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid5_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid6_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid7_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid8_take2.ogg'),
		),
	)

	bomb_deactivated_contractor = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor2_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor3_take2.ogg'),
	)

	bomb_deactivated_idle = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated3_take1(needs to be chopped in different files).ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated6_take2.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will3_take1.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/idle_deactivated/victim_felinid11_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/idle_deactivated/victim_felinid12_take2.ogg'),
		),
	)

	bomb_deactivated_surgery = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury6_take2_variant.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/good_wire_disarmed3_take1.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_disarmed/clown_good_wire_deactivated_take1.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_disarmed/victim_felinid9_take1.ogg'),
		),
	)

	bomb_good_wire = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire4_take3.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_good_wire_time/clown_good_wire_increase_time1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_good_wire_time/clown_good_wire_increase_time2_take2.ogg'),
		),
	)

	bomb_maskless = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless4_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless5_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless6_take2.ogg'),
	)

	changeling = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash3_take1.ogg'),
	)

	deconstruction = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction4_take1.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deconstructed/clown_deconstructed1_take2_Static.ogg'),
		),
	)

	explodes_cutely = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute5.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute6.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute7.ogg'),
	)

	mid_surgery = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury2_take4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury4_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury5_take3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury6_take1.ogg'),
	)

	fork_surgery = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/fork_surgery/mid_surgury3_take3.ogg'),
	)

	greeting = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting1_take1_variant.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting2_take4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting3_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/greeting4_take3_variant1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/greeting5_take1.ogg'),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting3_take1.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid1_take1.ogg'),
		),
	)

	station_nuke_detonated = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/station_nuke_detonated/nuke_detonated1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/station_nuke_detonated/nuke_detonated2_take2.ogg'),
	)

	timer_lines = list(
		DEFAULT_BOMB_SOUND = list(
			"seventy_five" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer25_1_take3.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer25_2_take3.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer25_3_take3.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer25_4_take5.ogg'),
			),
			"fifty" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer50_1_take2.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer50_2_take2.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer50_3_take2.ogg'),
			),
			"twenty_five" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer75_1_take2.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer75_2_take2.ogg'),
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/timer_lines/timer75_3_take2.ogg'),
			)
		),
		JOB_CLOWN = list(
			"seventy_five" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_timer/clown_countdown_75_take1.ogg'),
			),
			"fifty" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_timer/clown_countdown_50_take2.ogg'),
			),
			"twenty_five" = list(
				new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_timer/clown_countdown_25_take1.ogg'),
			),
		),
	)

	victim_crit = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit3_take1.ogg'),
	)

	//nuclear
	bad_wire_time = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_time/nuke_bad_wire_reduce_time1_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_time/nuke_bad_wire_reduce_time2_take2.ogg'),
	)

	bad_wire_upgrade = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_upgrade/nuke_bad_wire_upgrade1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_upgrade/nuke_bad_wire_upgrade2_take1.ogg'),
	)

	core_insertion = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/core_insertion/nuke_insertion_take4.ogg'),
	)

	disarm = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/disarm/nuke_disarmed_take1.ogg'),
	)

	nuclear_idle = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general4_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general5_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general6_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general7_take2.ogg'),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/nuke_felinid/nuke_felinid1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/nuke_felinid/nuke_felinid2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/nuke_felinid/nuke_felinid3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/nuke_felinid/nuke_felinid4_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/nuke_felinid/nuke_felinid5_take2.ogg'),
		),
	)

	good_wire_time = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/good_wire_time/nuke_good_wire_increase_timer1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/good_wire_time/nuke_good_wire_increase_timer2_take1.ogg'),
	)

	try_deactivate = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/try_deactivate/nuke_agent_deactivate1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/try_deactivate/nuke_agent_deactivate2_take2.ogg'),
	)
	//nuclear end

/datum/component/dialogue_system/contractor_bomb/apply_dialogue_channel()
	. = ..()
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_activated))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_corporate))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_deactivated_idle))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_deactivated_surgery))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_bad_wire_upgrade))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_good_wire))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_bad_wire_reduce_time))
	apply_channel_to_sound_pool_list(assoc_to_values(deconstruction))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful_upgraded))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful_voltaic))
	apply_channel_to_sound_list(explosion_successful_nuclear)
	apply_channel_to_sound_pool_list(assoc_to_values(greeting))
	apply_channel_to_sound_pool_list(assoc_to_values(timer_lines))

	apply_channel_to_sound_list(admin_abuse)
	apply_channel_to_sound_list(bomb_deactivated_contractor)
	apply_channel_to_sound_list(bomb_maskless)
	apply_channel_to_sound_list(changeling)
	apply_channel_to_sound_list(explodes_cutely)
	apply_channel_to_sound_list(mid_surgery)
	apply_channel_to_sound_list(bad_wire_time)
	apply_channel_to_sound_list(bad_wire_upgrade)
	apply_channel_to_sound_list(core_insertion)
	apply_channel_to_sound_list(disarm)
	apply_channel_to_sound_list(nuclear_idle)
	apply_channel_to_sound_list(good_wire_time)
	apply_channel_to_sound_list(try_deactivate)
	apply_channel_to_sound_list(station_nuke_detonated)
	apply_channel_to_sound_list(victim_crit)

/datum/component/dialogue_system/contractor_bomb/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_CONTRACTOR_BOMB_ATTACHED_TO, PROC_REF(on_bomb_attached))
	RegisterSignal(parent, COMSIG_CONTRACTOR_BOMB_WIRE_CUT, PROC_REF(on_wire_cut))
	RegisterSignal(parent, COMSIG_CONTRACTOR_UI_BOMB_ARMED, PROC_REF(on_bomb_ui_armed))
	RegisterSignal(parent, COMSIG_CONTRACTOR_UI_BOMB_DEFUSED, PROC_REF(on_bomb_ui_neutralized))
	RegisterSignal(parent, COMSIG_FORK_STUCK_IN_BOMB, PROC_REF(these_are_the_consequences_upon_getting_absolutely_forked))
	RegisterSignal(parent, COMSIG_PLUTONIUM_INSERTED, PROC_REF(on_plutonium_added))
	RegisterSignal(SSdcs, COMSIG_GLOB_NUKE_DEVICE_DETONATING, PROC_REF(on_nuke_detonate))
	RegisterSignal(parent, COMSIG_DESTRUCTIVE_ANALYZER_DESTROY, PROC_REF(on_destructive_analysis))
	RegisterSignal(parent, COMSIG_CONTRACTOR_PRE_EXPLOSION, PROC_REF(pre_explosion))
	RegisterSignal(parent, COMSIG_CONTRACTOR_BOMB_TIME_LOWERED, PROC_REF(on_timer_threshold))

/// Saves a ref to the victim when the bomb is attached to a mob
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_attached(mob/living/carbon/human/victim)
	SIGNAL_HANDLER
	if(!istype(victim))
		return
	bomb_wearer = WEAKREF(victim)
	// Slap on the signals that need to come from the mob as well
	RegisterSignal(victim, COMSIG_ATOM_SURGERY_STARTED, PROC_REF(on_surgery_started))

/// Helper proc, plays a sound from a given sound pool. If explodes is TRUE, will blow up the bomb after a delay
/datum/component/dialogue_system/contractor_bomb/proc/emit_sound_from_list(list/sound_list, explodes = FALSE, obj/item/contractor_bomb/about_to_explode)
	var/datum/dialogue_sound/sound = pick_available_sound(sound_list, parent, parent)
	sound?.emit_sound(location = parent)
	var/line_duration = rustg_sound_length(sound.sound_path)
	SEND_SIGNAL(parent, COMSIG_DIALOGUE_SOUND_EMITTED, line_duration)
	if(!explodes)
		return
	if(isnull(about_to_explode))
		CRASH("Sound helper tried to explode but no bomb was passed to actually explode")
	about_to_explode.delayed_explosion(line_duration)

/// Helper proc, checks if the victim is a clown or a felinid for the special voice lines
/datum/component/dialogue_system/contractor_bomb/proc/has_special_line(sound_pool)
	. = sound_pool[DEFAULT_BOMB_SOUND]
	var/mob/living/carbon/human/victim = bomb_wearer.resolve()
	if(!istype(victim))
		return
	if(victim.job == JOB_CLOWN && !isnull(sound_pool[JOB_CLOWN]))
		return sound_pool[JOB_CLOWN]
	else if(victim.dna.species == /datum/species/human/felinid && !isnull(sound_pool[/datum/species/human/felinid]))
		return sound_pool[victim.dna.species]

/// Plays when any wire is cut during a defusal attempt
/datum/component/dialogue_system/contractor_bomb/proc/on_wire_cut(obj/item/contractor_bomb/source, wire_flags)
	SIGNAL_HANDLER
	var/list/sound_pool
	if(wire_flags & CONTRACTOR_WIRE_EXPLOSIVE)
		if(source.upgraded_explosion) // Means the bomb is about to explode
			pre_explosion(source, source.explosion_flags)
			return
		else
			sound_pool = has_special_line(bomb_bad_wire_upgrade)
	if(wire_flags & CONTRACTOR_WIRE_DEFUSIVE)
		sound_pool = has_special_line(bomb_deactivated_surgery)
	if(wire_flags & CONTRACTOR_WIRE_TIME_ADDER)
		sound_pool = has_special_line(bomb_good_wire)
	if(wire_flags & CONTRACTOR_WIRE_TIME_REDUCER)
		sound_pool = has_special_line(bomb_bad_wire_reduce_time)
	emit_sound_from_list(sound_pool)

/// Plays when the bomb is armed by the contractor via their UI
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_ui_armed()
	SIGNAL_HANDLER
	emit_sound_from_list(has_special_line(bomb_activated))

/// Plays when the bomb is disarmed by the contractor via their UI
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_ui_neutralized()
	SIGNAL_HANDLER
	emit_sound_from_list(bomb_deactivated_contractor)

/// Plays when a nuke core is added to the bomb
/datum/component/dialogue_system/contractor_bomb/proc/on_plutonium_added(obj/item/contractor_bomb/source)
	SIGNAL_HANDLER
	emit_sound_from_list(core_insertion)

/// Plays when the nuke detonates
/datum/component/dialogue_system/contractor_bomb/proc/on_nuke_detonate()
	SIGNAL_HANDLER
	emit_sound_from_list(station_nuke_detonated)

/// Plays when the bomb is killed by a deconstructive analyzer
/datum/component/dialogue_system/contractor_bomb/proc/on_destructive_analysis()
	SIGNAL_HANDLER
	emit_sound_from_list(has_special_line(deconstruction))

/// Plays when the bomb had a fork stuck in it...
/datum/component/dialogue_system/contractor_bomb/proc/these_are_the_consequences_upon_getting_absolutely_forked(obj/item/contractor_bomb/source)
	SIGNAL_HANDLER
	emit_sound_from_list(fork_surgery, TRUE, source)

/// Plays before the bomb explodes, in this case it is already in the process of exploding and drops the line right before the boom
/datum/component/dialogue_system/contractor_bomb/proc/pre_explosion(obj/item/contractor_bomb/source, explosion_flags)
	SIGNAL_HANDLER
	var/list/sound_pool = has_special_line(explosion_successful)
	if(source.upgraded_explosion)
		sound_pool = has_special_line(explosion_successful_upgraded)
	if(prob(1))
		sound_pool = explodes_cutely

	if(explosion_flags & CONTRACTOR_EXPLOSION_ENERGYBALL)
		sound_pool = has_special_line(explosion_successful_voltaic)
	if(explosion_flags & CONTRACTOR_EXPLOSION_NUCLEAR)
		sound_pool = explosion_successful_nuclear

	emit_sound_from_list(sound_pool, TRUE, source)
	return EXPLOSION_DIALOGUE_HANDLED

/// Plays a line when you start the channel bar to open the surgery
/datum/component/dialogue_system/contractor_bomb/proc/on_surgery_started()
	SIGNAL_HANDLER
	emit_sound_from_list(mid_surgery)

/// Plays a line based on how much time is left on the bomb timer
/datum/component/dialogue_system/contractor_bomb/proc/on_timer_threshold(obj/item/contractor_bomb/source, timeleft_percentage)
	SIGNAL_HANDLER
	if(source.explosion_flags & CONTRACTOR_EXPLOSION_NUCLEAR)
		// Drop the timer lines if they ever get a nuclear core, instead we'll just play the nuclear-exclusive lines
		play_nuclear_idle()
		return

	switch(timeleft_percentage)
		if(51 to 75)
			if(previous_threshold <= 75)
				return
			previous_threshold = 75
			emit_sound_from_list(has_special_line(timer_lines)["seventy_five"])
			return
		if(26 to 50)
			if(previous_threshold <= 50)
				return
			previous_threshold = 50
			emit_sound_from_list(has_special_line(timer_lines)["fifty"])
			return
		if(1 to 25)
			if(previous_threshold <= 25)
				return
			previous_threshold = 25
			emit_sound_from_list(has_special_line(timer_lines)["twenty_five"])
			return

	if(!check_idle_time())
		return
	var/list/sound_pool = has_special_line(bomb_corporate)
	var/mob/living/carbon/human/victim = bomb_wearer.resolve()
	if(prob(25) && victim?.job != JOB_CLOWN && victim?.dna?.species != /datum/species/human/felinid)
		sound_pool = bomb_maskless
	emit_sound_from_list(sound_pool)

/// Change our pools to use the nuclear sound pools when a core is installed
/datum/component/dialogue_system/contractor_bomb/proc/play_nuclear_idle()
	if(!check_idle_time())
		return
	var/list/sound_pool = nuclear_idle
	// XANTODO: Add a job check for clown, add a race check for felinid
	emit_sound_from_list(sound_pool)

/// Checks to see if they are due for an idle line, will return FALSE if it's too early
/datum/component/dialogue_system/contractor_bomb/proc/check_idle_time()
	// If no line is played, we can then see if they are due for some idle yap
	if(!COOLDOWN_FINISHED(src, last_idle))
		return
	COOLDOWN_START(src, next_idle, rand(1.5 MINUTES, 3 MINUTES))
	return TRUE

/* //
sounds left to implement :
admin_abuse
bomb_deactivated_idle
changeling

bad_wire_time
bad_wire_upgrade
disarm
good_wire_time
try_deactivate
victim_crit
*/

#undef DEFAULT_BOMB_SOUND
