/datum/contractor_state
	///The current contract in progress, and can be null if no contract is in progress.
	var/datum/syndicate_contract/current_contract
	///Amount of contracts that have already been completed, for flavor in the UI & round-end logs.
	var/contracts_completed = 0
	///How much TC has been paid out, for flavor in the UI & round-end logs.
	var/contract_TC_payed_out = 0
	///How much TC we can cash out currently. Used when redeeming TC and for round-end logs.
	var/contract_TC_to_redeem = 0
	// ///Reference to a contractor teammate, if one has been purchased.
	var/datum/antagonist/traitor/contractor_support/contractor_teammate
	/// List of currently active bombs that exist
	var/list/bomb_implants = list()
	/// The id of the contract currently tracked on the minimap - only one at a time, null if none.
	var/tracked_contract_id
	/// Weakref to the mob whose blip is on the minimap, used to clear it when switching or untracking.
	var/datum/weakref/tracked_target_ref
