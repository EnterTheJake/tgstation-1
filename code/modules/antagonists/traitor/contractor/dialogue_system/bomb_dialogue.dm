#define DEFAULT_BOMB_SOUND "default_sounds"
#define NUCLEAR_BOMB_SOUND "nuclear_sounds"

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

	/// Boolean if the bomb was attached to a clown
	var/clown_bomb = FALSE
	/// Boolean if the bomb was attached to a felinid
	var/felinid_bomb = FALSE
	/// Boolean if the bomb is nuclear
	var/is_nuclear = FALSE
	/// Boolean if the patient is in surgery
	var/active_surgery = FALSE
	/// Memory of the last threshold that was announced
	var/previous_threshold = 100
	/// Time since last idle chatter
	COOLDOWN_DECLARE(last_idle)

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
	var/list/greeting_changeling
	var/list/deconstruction
	var/list/explodes_cutely
	var/list/explosion_successful
	var/list/explosion_successful_upgraded
	var/list/greeting
	var/list/mid_surgery
	var/list/fork_surgery
	var/list/core_insertion
	var/list/explosion_successful_nuclear
	var/list/nuclear_idle
	var/list/station_nuke_detonated
	var/list/timer_lines
	var/list/victim_crit

/datum/component/dialogue_system/contractor_bomb/Initialize()
	. = ..()
	COOLDOWN_START(src, last_idle, rand(30 SECONDS, 1 MINUTES)) // Grace period so that we have some time before the bomb starts yapping
	addtimer(CALLBACK(src, PROC_REF(play_greeting)), 1 SECONDS)

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
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse1_take1.ogg', priority = 4),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse2_take1.ogg', priority = 4),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/admin_abuse/adminabuse3_take1.ogg', priority = 4),
	)

	explosion_successful = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful3.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful5.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful6.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful7.ogg', priority = 3),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation2_take2.ogg', priority = 3),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_detonation/victim_felinid10_take1.ogg', priority = 3),
		),
	)

	explosion_successful_upgraded = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful4.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explosion_successful/explosion_successful1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion3.ogg', priority = 3),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_bad_wire_detonation1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_bad_wire_detonation2_take1.ogg', priority = 3),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_detonation/victim_felinid10_take1.ogg', priority = 3),
		),
	)

	explosion_successful_voltaic = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_explosion/bad_wire_explosion4.ogg', priority = 4),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_detonation/clown_detonation_tesla.ogg', priority = 4),
		),
	)

	explosion_successful_nuclear = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation1_take1.ogg', priority = 4),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation2_take1.ogg', priority = 4),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/detonation/nuke_detonation3_take1.ogg', priority = 4),
	)

	bomb_activated = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated2_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated3_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated4_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated5_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_activated/bomb_activated6_take2.ogg', priority = 3),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated1_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated2_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_activated/clown_activated3_take2.ogg', priority = 3),
		),
	)

	bomb_bad_wire_reduce_time = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_explosion1_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time1_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time2_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time3_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time4_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_reduce_time/bad_wire_reduce_time5_take2.ogg', priority = 2),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_time/clown_bad_wire_reduce_time1_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_time/clown_bad_wire_reduce_time2_take2.ogg', priority = 2),
		),
		NUCLEAR_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_time/nuke_bad_wire_reduce_time1_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_time/nuke_bad_wire_reduce_time2_take2.ogg', priority = 2),
		),
	)

	bomb_bad_wire_upgrade = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade1_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade2_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade3_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_bad_wire_upgrade/bad_wire_upgrade4_take2.ogg', priority = 2),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_upgrade/clown_bad_wire_upgrade1_take1.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_bad_wire_upgrade/clown_bad_wire_upgrade2_take2.ogg', priority = 2),
		),
		NUCLEAR_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_upgrade/nuke_bad_wire_upgrade1_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/bad_wire_upgrade/nuke_bad_wire_upgrade2_take1.ogg', priority = 2),
		),
	)

	bomb_good_wire = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire1_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire2_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire3_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_good_wire/good_wire4_take3.ogg', priority = 2),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_good_wire_time/clown_good_wire_increase_time1_take3.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_good_wire_time/clown_good_wire_increase_time2_take2.ogg', priority = 2),
		),
		NUCLEAR_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/good_wire_time/nuke_good_wire_increase_timer1_take2.ogg', priority = 2),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/good_wire_time/nuke_good_wire_increase_timer2_take1.ogg', priority = 2),
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
		DEFAULT_BOMB_SOUND = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor1_take1.ogg', priority = 3),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor2_take1.ogg', priority = 3),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_contractor/bomb_deactivated_contractor3_take2.ogg', priority = 3),
		),
		NUCLEAR_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/try_deactivate/nuke_agent_deactivate1_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/try_deactivate/nuke_agent_deactivate2_take2.ogg', priority = 3),
		),
	)

	bomb_deactivated_idle = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated1_take3.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated2_take1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated3_take1(needs to be chopped in different files).ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated4_take1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated5_take2.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_idle/bomb_deactivated6_take2.ogg', priority = 1),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will1_take2.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will2_take2.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deactivated_idle/clown_lost_will3_take1.ogg', priority = 1),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/idle_deactivated/victim_felinid11_take1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/idle_deactivated/victim_felinid12_take2.ogg', priority = 1),
		),
	)

	bomb_deactivated_surgery = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury2_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury3_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury4_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury5_take2.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_deactivated_surgury6_take2_variant.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire1_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire2_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/bomb_goodwire4_take1.ogg', priority = 3),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_deactivated_surgery/good_wire_disarmed3_take1.ogg', priority = 3),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_disarmed/clown_good_wire_deactivated_take1.ogg', priority = 3),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/felinid_disarmed/victim_felinid9_take1.ogg', priority = 3),
		),
		NUCLEAR_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/disarm/nuke_disarmed_take1.ogg', priority = 3),
		),
	)

	bomb_maskless = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless1_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless2_take2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless4_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless5_take1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_maskless/bomb_maskless6_take2.ogg'),
	)

	deconstruction = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction1_take2.ogg', priority = 4),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction2_take1.ogg', priority = 4),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction3_take2.ogg', priority = 4),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/deconstruction/deconstruction4_take1.ogg', priority = 4),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_deconstructed/clown_deconstructed1_take2_Static.ogg', priority = 4),
		),
	)

	explodes_cutely = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute1.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute2.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute3.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute4.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute5.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute6.ogg', priority = 5),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/explodes_cutely/explosion_cute7.ogg', priority = 5),
	)

	mid_surgery = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury1_take2.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury2_take4.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury4_take2.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury5_take3.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury6_take1.ogg', priority = 1),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/mid_surgery/mid_surgury2_take4.ogg', priority = 1),
		)
	)

	fork_surgery = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/fork_surgery/mid_surgury3_take3.ogg', priority = 4),
	)

	greeting = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting1_take1_variant.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting2_take4.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/bomb_greeting3_take3.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/greeting4_take3_variant1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/bomb_greeting/greeting5_take1.ogg', priority = 1),
		),
		JOB_CLOWN = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting1_take1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting2_take1.ogg', priority = 1),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/clown/clown_greeting/clown_greeting3_take2.ogg', priority = 1),
		),
		/datum/species/human/felinid = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/felinid/general/victim_felinid1_take1.ogg', priority = 1),
		),
	)

	greeting_changeling = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash1_take2.ogg', priority = 1),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash2_take2.ogg', priority = 1),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/changeling/changeling_power_backlash3_take1.ogg', priority = 1),
	)

	station_nuke_detonated = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/station_nuke_detonated/nuke_detonated1_take2.ogg', priority = 4),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/station_nuke_detonated/nuke_detonated2_take2.ogg', priority = 4),
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
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit1_take2.ogg', priority = 1),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit2_take2.ogg', priority = 1),
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/victim_crit/victim_crit3_take1.ogg', priority = 1),
	)

	//nuclear
	core_insertion = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/core_insertion/nuke_insertion_take4.ogg', priority = 3),
	)

	nuclear_idle = list(
		DEFAULT_BOMB_SOUND = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general2_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_bomb/nuclear/general/nuke_general4_take1.ogg'),
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
	//nuclear end

/datum/component/dialogue_system/contractor_bomb/apply_dialogue_channel()
	. = ..()
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_activated))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_corporate))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_deactivated_idle))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_deactivated_surgery))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_deactivated_contractor))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_bad_wire_upgrade))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_good_wire))
	apply_channel_to_sound_pool_list(assoc_to_values(bomb_bad_wire_reduce_time))
	apply_channel_to_sound_pool_list(assoc_to_values(deconstruction))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful_upgraded))
	apply_channel_to_sound_pool_list(assoc_to_values(explosion_successful_voltaic))
	apply_channel_to_sound_list(explosion_successful_nuclear)
	apply_channel_to_sound_pool_list(assoc_to_values(greeting))
	apply_channel_to_sound_list(greeting_changeling)
	apply_channel_to_sound_pool_list(assoc_to_values(assoc_to_values(timer_lines)))

	apply_channel_to_sound_list(admin_abuse)
	apply_channel_to_sound_list(bomb_maskless)
	apply_channel_to_sound_list(explodes_cutely)
	apply_channel_to_sound_pool_list(assoc_to_values(mid_surgery))
	apply_channel_to_sound_list(core_insertion)
	apply_channel_to_sound_pool_list(assoc_to_values(nuclear_idle))
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
	RegisterSignals(parent, list(COMSIG_CONTRACTOR_BOMB_TIME_LOWERED, COMSIG_CONTRACTOR_NOT_YET_ARMED_PROCESS), PROC_REF(on_bomb_process))
	RegisterSignal(parent, COMSIG_CONTRACTOR_DISARMED_PROCESS, PROC_REF(on_disarmed_process))

/// Saves a ref to the victim when the bomb is attached to a mob
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_attached(datum/source, mob/living/carbon/human/victim)
	SIGNAL_HANDLER
	clown_bomb = FALSE // In case they were attached to something before
	felinid_bomb = FALSE // In case they were attached to something before
	if(!istype(victim))
		return
	if(victim.job == JOB_CLOWN)
		clown_bomb = TRUE
	if(victim.dna.species.type == /datum/species/human/felinid)
		felinid_bomb = TRUE
	bomb_wearer = WEAKREF(victim)
	// Slap on the signals that need to come from the mob as well
	RegisterSignal(victim, COMSIG_ATOM_SURGERY_STARTED, PROC_REF(on_surgery_started))
	RegisterSignal(victim, COMSIG_MOB_STATCHANGE, PROC_REF(on_victim_stat_change))

/// Helper proc, plays a sound from a given sound pool. If explodes is TRUE, will blow up the bomb after a delay
/datum/component/dialogue_system/contractor_bomb/proc/emit_sound_from_list(list/sound_list, explodes = FALSE, obj/item/contractor_bomb/about_to_explode)
	var/datum/dialogue_sound/sound = pick_available_sound(sound_list, parent, parent)
	sound_list -= sound
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
	// Priority is: Clown lines -> Nuclear lines -> Felinid lines -> Default lines
	if(clown_bomb && !isnull(sound_pool[JOB_CLOWN]))
		return sound_pool[JOB_CLOWN]
	else if(is_nuclear == TRUE && !isnull(sound_pool[NUCLEAR_BOMB_SOUND]))
		return sound_pool[NUCLEAR_BOMB_SOUND]
	else if(felinid_bomb && !isnull(sound_pool[/datum/species/human/felinid]))
		return sound_pool[/datum/species/human/felinid]

/// Plays a welcome message to our new victim
/datum/component/dialogue_system/contractor_bomb/proc/play_greeting()
	var/mob/living/carbon/wearer = bomb_wearer?.resolve()
	if(isnull(wearer))
		return
	if(IS_CHANGELING(wearer))
		emit_sound_from_list(greeting_changeling)
		return
	emit_sound_from_list(has_special_line(greeting))

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
		COOLDOWN_START(src, last_idle, 1 MINUTES)
	if(wire_flags & CONTRACTOR_WIRE_TIME_ADDER)
		sound_pool = has_special_line(bomb_good_wire)
	if(wire_flags & CONTRACTOR_WIRE_TIME_REDUCER)
		sound_pool = has_special_line(bomb_bad_wire_reduce_time)
	if(isnull(sound_pool))
		return // Dummy wires have no voicelines
	emit_sound_from_list(sound_pool)

/// Plays when the bomb is armed by the contractor via their UI
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_ui_armed()
	SIGNAL_HANDLER
	COOLDOWN_START(src, last_idle, rand(30 SECONDS, 1 MINUTES))
	emit_sound_from_list(has_special_line(bomb_activated))

/// Plays when the bomb is disarmed by the contractor via their UI
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_ui_neutralized()
	SIGNAL_HANDLER
	emit_sound_from_list(has_special_line(bomb_deactivated_contractor))

/// Plays when a nuke core is added to the bomb
/datum/component/dialogue_system/contractor_bomb/proc/on_plutonium_added(obj/item/contractor_bomb/source)
	SIGNAL_HANDLER
	is_nuclear = TRUE
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
	if(is_nuclear)
		sound_pool = explosion_successful_nuclear
	if(explosion_flags & ADMIN_SHENANIGANS)
		sound_pool = admin_abuse

	emit_sound_from_list(sound_pool, TRUE, source)
	return EXPLOSION_DIALOGUE_HANDLED

/// Plays a line when you start the channel bar to open the surgery
/datum/component/dialogue_system/contractor_bomb/proc/on_surgery_started(datum/source, datum/surgery_operation/specific_surgery, obj/item/bodypart/limb, obj/item/tool)
	SIGNAL_HANDLER
	if(specific_surgery.type != /datum/surgery_operation/limb/contractor_bomb_defusal)
		return
	if(istype(tool, /obj/item/kitchen/fork))
		return
	emit_sound_from_list(has_special_line(mid_surgery))
	active_surgery = TRUE

/// Plays a line on process according to some conditions
/datum/component/dialogue_system/contractor_bomb/proc/on_bomb_process(obj/item/contractor_bomb/source, timeleft_percentage)
	SIGNAL_HANDLER
	if(active_surgery)
		return // Once our bomb carrier is being operated on, we will just assume they are soon going to be defused or eradicated

	if(is_nuclear && !clown_bomb)
		// Drop the timer lines if they ever get a nuclear core, instead we'll just play the nuclear-exclusive lines
		play_nuclear_idle()
		return

	if(!felinid_bomb && !clown_bomb)
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
	if(prob(25) && !clown_bomb && !felinid_bomb) // Clowns/Felinids can never roll for maskless lines
		sound_pool = bomb_maskless
	emit_sound_from_list(sound_pool)

/// Plays a line when the bomb is disarmed
/datum/component/dialogue_system/contractor_bomb/proc/on_disarmed_process()
	SIGNAL_HANDLER
	if(!check_idle_time())
		return
	emit_sound_from_list(has_special_line(bomb_deactivated_idle))

/// Change our pools to use the nuclear sound pools when a core is installed
/datum/component/dialogue_system/contractor_bomb/proc/play_nuclear_idle()
	if(!check_idle_time())
		return
	var/list/sound_pool = has_special_line(nuclear_idle)
	emit_sound_from_list(sound_pool)

/// Checks to see if they are due for an idle line, will return FALSE if it's too early
/datum/component/dialogue_system/contractor_bomb/proc/check_idle_time()
	// If no line is played, we can then see if they are due for some idle yap
	if(!COOLDOWN_FINISHED(src, last_idle))
		return
	COOLDOWN_START(src, last_idle, rand(1.5 MINUTES, 3 MINUTES))
	return TRUE

/// Checks to see if our victim has gone into crit/died with the bomb not-yet-exploded
/datum/component/dialogue_system/contractor_bomb/proc/on_victim_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(is_nuclear)
		return
	if(new_stat == SOFT_CRIT || new_stat == HARD_CRIT)
		emit_sound_from_list(victim_crit)

#undef DEFAULT_BOMB_SOUND
#undef NUCLEAR_BOMB_SOUND
