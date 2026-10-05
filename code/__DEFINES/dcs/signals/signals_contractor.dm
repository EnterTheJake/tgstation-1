//---- Contractor Rifle signals

/// Called when the gauss rifle's ammo state changes (on shot fired or fire mode switch). Passes shots_left (remaining shots) and max_shots (shots at full charge).
#define COMSIG_GAUSS_RIFLE_AMMO_CHANGED "gauss_rifle_ammo_changed"

/// Called when the gauss rifle fire mode changes. Passes (mob/living/user, obj/item/ammo_casing/energy/new_mode).
#define COMSIG_GAUSS_RIFLE_MODE_CHANGED "gauss_rifle_mode_changed"

/// Called to refresh the gauss rifle scope overlay without triggering mode-change dialogue.
#define COMSIG_GAUSS_RIFLE_SCOPE_REFRESH "gauss_rifle_scope_refresh"

/// Called when the gauss rifle discharges a live shot. Passes (mob/living/user).
#define COMSIG_GAUSS_RIFLE_SCOPE_KICK "gauss_rifle_scope_kick"

/// Sent from /obj/item/gun/energy/gauss_rifle/unlock_ammo_type when a new ammo type is installed
#define COMSIG_GAUSS_RIFLE_AMMOTYPE_UNLOCKED "gauss_rifle_ammotype_unlocked"

/// Called when the gauss rifle overheats
#define COMSIG_GAUSS_RIFLE_OVERHEATED "gauss_rifle_overheated"

/// Called when the gauss rifle has it's internal cell maxed out via a nanite cell
#define COMSIG_GAUSS_RIFLE_CELL_REFILLED "gauss_rifle_cell_refilled"

//---- Contractor Bomb signals
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

/// Sent on process when the bomb is disarmed
#define COMSIG_CONTRACTOR_DISARMED_PROCESS "contractor_bomb_disarmed_process"

/// Sent on process when the bomb is attached but not primed nor disarmed
#define COMSIG_CONTRACTOR_NOT_YET_ARMED_PROCESS "contractor_bomb_not_yet_armed_process"

/// Sent whenever the timer goes down naturally
#define COMSIG_CONTRACTOR_BOMB_TIME_LOWERED "contractor_bomb_time_lowered"


//---- Contractor signals
/// Fired on a contractor mob when they successfully kidnap a target. Passes (mob/living/victim).
#define COMSIG_CONTRACTOR_KIDNAPPED "contractor_kidnapped"

/// Fired on a contractor mob when their tracked contract changes, so an open minimap can refresh.
#define COMSIG_CONTRACTOR_TRACK_CHANGED "contractor_track_changed"

/// Sent whenever a sound is emitted from the dialogue system
#define COMSIG_DIALOGUE_SOUND_EMITTED "dialogue_sound_emitted"
