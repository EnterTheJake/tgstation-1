/// Called whenever the uplink handler receives any sort of update. Used by uplinks to update their UI. No arguments passed
#define COMSIG_UPLINK_HANDLER_ON_UPDATE "uplink_handler_on_update"

/// Called when a device a traitor has planted effects someone's mood. Pass the mind of the viewer.
#define COMSIG_DEMORALISING_EVENT "traitor_demoralise_event"
/// Called when you finish drawing some graffiti so we can register more signals on it. Pass the graffiti effect.
#define COMSIG_TRAITOR_GRAFFITI_DRAWN "traitor_rune_drawn"
/// Called when someone slips on some seditious graffiti. Pass the mind of the viewer.
#define COMSIG_TRAITOR_GRAFFITI_SLIPPED "traitor_demoralise_event"
/// For when someone is injected with the EHMS virus from /datum/traitor_objective_category/infect
#define COMSIG_EHMS_INJECTOR_INJECTED "after_ehms_inject"

/// Called by an battle royale implanter when successfully implanting someone. Passes the implanted mob.
#define COMSIG_ROYALE_IMPLANTED "royale_implanted"

/// Called when the gauss rifle's ammo state changes (on shot fired or fire mode switch). Passes shots_left (remaining shots) and max_shots (shots at full charge).
#define COMSIG_GAUSS_RIFLE_AMMO_CHANGED "gauss_rifle_ammo_changed"

/// Called when the gauss rifle fire mode changes. Passes (mob/living/user, obj/item/ammo_casing/energy/new_mode).
#define COMSIG_GAUSS_RIFLE_MODE_CHANGED "gauss_rifle_mode_changed"

/// Called to refresh the gauss rifle scope overlay without triggering mode-change dialogue.
#define COMSIG_GAUSS_RIFLE_SCOPE_REFRESH "gauss_rifle_scope_refresh"

/// Called when the gauss rifle discharges a live shot. Passes (mob/living/user).
#define COMSIG_GAUSS_RIFLE_SCOPE_KICK "gauss_rifle_scope_kick"

#define COMSIG_PARTICLE_DRIFT_WIND_DOWN "particle_drift_wind_down"
#define COMSIG_PARTICLE_DRIFT_RESUME "particle_drift_resume"
	#define PARTICLE_DRIFT_RESUMED (1<<0)

/// Fired on a contractor mob when they successfully kidnap a target. Passes (mob/living/victim).
#define COMSIG_CONTRACTOR_KIDNAPPED "contractor_kidnapped"

/// Fired on a contractor mob when their tracked contract changes, so an open minimap can refresh.
#define COMSIG_CONTRACTOR_TRACK_CHANGED "contractor_track_changed"

/// Called when a wire on the contractor bomb is cut
#define COMSIG_CONTRACTOR_BOMB_WIRE_CUT "contractor_bomb_wire_cut"

/// Called when the contractor arms the bomb via the UI
#define COMSIG_CONTRACTOR_UI_BOMB_ARMED "contractor_bomb_ui_armed"

/// Called when the contractor disarms the bomb via the UI
#define COMSIG_CONTRACTOR_UI_BOMB_DEFUSED "contractor_bomb_ui_defused"

/// Called when the contractor bomb is attached to a mob
#define COMSIG_CONTRACTOR_BOMB_ATTACHED_TO "contractor_bomb_attached_to"

/// Called when a fork is stuck into the bomb
#define COMSIG_FORK_STUCK_IN_BOMB "contractor_bomb_got_forked"

/// Called when the plutonium core is added to the bomb
#define COMSIG_PLUTONIUM_INSERTED "contractor_bomb_plutonium_added"

/// Called when the bomb is ready to explode and ready to play a line
#define COMSIG_CONTRACTOR_PRE_EXPLOSION "contractor_bomb_pre_explosion"
	// Returned if the pre_explosion was handled by the dialogue component
	#define EXPLOSION_DIALOGUE_HANDLED (1<<0)

/// Sent whenever the timer goes down naturally
#define COMSIG_CONTRACTOR_BOMB_TIME_LOWERED "contractor_bomb_time_lowered"

/// Send whenever a sound is emitted from the diaolgue system
#define COMSIG_DIALOGUE_SOUND_EMITTED "dialogue_sound_emitted"
