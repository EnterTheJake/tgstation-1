/datum/dialogue_sound
	/// The sound file path to play.
	var/sound_path
	/// Volume for playback.
	var/volume = 100
	var/vary = FALSE
	/// Assigned by the owning dialogue component instance.
	var/channel = 0
	/// Relative selection chance used by the dialogue system.
	var/chance = 100
	/// If TRUE, the datum requires a valid sound path to be constructed.
	var/requires_sound_path = TRUE
	/// Estimated end time for the currently playing line on each dialogue channel.
	var/static/list/channel_busy_until = list()
	/// Priority of the currently active line per dialogue channel.
	var/static/list/channel_active_priority = list()
	/// Monotonic token per channel used to discard stale delayed play-after-fade callbacks.
	var/static/list/channel_replay_nonce = list()
	/// Volume preference for dialogue lines.
	var/datum/preference/numeric/volume/volume_preference = /datum/preference/numeric/volume/sound_dialogue
	/// Priority used when contesting a busy channel. Higher values can interrupt lower values.
	var/priority = 0
	/// Multiplier on sound length to determine line cooldown.
	var/length_multiplier = 1.5
	/// Flat delay added after the length-based cooldown.
	var/bonus_delay = 0
	COOLDOWN_DECLARE(line_cooldown)

/// A silent dialogue outcome used to represent RNG-based no-line results.
/datum/dialogue_sound/no_sound
	requires_sound_path = FALSE

/// Plays sound only to the specified player.
/datum/dialogue_sound/local

/datum/dialogue_sound/short
	length_multiplier = 1
	bonus_delay = 0

/datum/dialogue_sound/long
	length_multiplier = 1.3
	bonus_delay = 5

/datum/dialogue_sound/local/short
	length_multiplier = 1
	bonus_delay = 0

/datum/dialogue_sound/local/long
	length_multiplier = 1.3
	bonus_delay = 5

/datum/dialogue_sound/New(sound_path, volume, vary, priority, chance)
	. = ..()
	if(requires_sound_path && !sound_path)
		CRASH("Must provide a sound path to dialogue sound!")
	src.sound_path = sound_path
	if(!isnull(volume))
		src.volume = volume
	if(!isnull(vary))
		src.vary = vary
	if(!isnull(priority))
		src.priority = priority
	if(!isnull(chance))
		src.chance = chance

/datum/dialogue_sound/proc/delayed_play(mob/player, atom/location, delay)
	addtimer(CALLBACK(src, PROC_REF(play), player, location), delay, TIMER_UNIQUE)

/datum/dialogue_sound/proc/get_sound_length()
	var/sound_length = SSsounds.get_sound_length(sound_path)
	debug_to_chat(usr, "Sound length for [sound_path] is [sound_length].")
	if(!sound_length)
		CRASH("Dialogue sound has invalid sound length (0 or negative): [sound_path]")
	return sound_length

/datum/dialogue_sound/proc/mark_cooldown()
	COOLDOWN_START(src, line_cooldown, max(round((get_sound_length() * length_multiplier) + bonus_delay, 1), 1))
	debug_to_chat(usr, "[src]: cooldown started for [line_cooldown] ticks (length [get_sound_length()] * multiplier [length_multiplier] + bonus [bonus_delay]).")

/datum/dialogue_sound/proc/can_play(mob/player, atom/location)
	if(!location)
		return FALSE
	if(!COOLDOWN_FINISHED(src, line_cooldown))
		return FALSE
	return TRUE

/datum/dialogue_sound/proc/prepare_playback(mob/player)
	if(player && channel)
		player.stop_sound_channel(channel)

/datum/dialogue_sound/proc/is_channel_busy()
	if(!channel)
		return FALSE
	return world.time < (channel_busy_until["[channel]"] || 0)

/datum/dialogue_sound/proc/mark_channel_busy()
	if(!channel)
		return
	channel_busy_until["[channel]"] = world.time + get_sound_length()
	channel_active_priority["[channel]"] = priority

/datum/dialogue_sound/proc/debug_to_chat(mob/player, message, is_warning = FALSE)
#ifdef TESTING
	if(!player)
		return
	if(is_warning)
		to_chat(player, span_warning(message))
	else
		to_chat(player, span_notice(message))
#endif

/datum/dialogue_sound/proc/fade_interrupting_line(mob/player)
	if(!player || !channel)
		return 0

	var/fade_duration = 1 SECONDS
	debug_to_chat(player, "[src]: fade start on channel [channel], duration [fade_duration] ticks.")
	var/fade_steps = 5
	var/step_delay = max(round(fade_duration / fade_steps, 1), 1)
	for(var/step in 1 to fade_steps)
		var/step_volume = round(volume * (1 - (step / fade_steps)), 1)
		addtimer(CALLBACK(player, TYPE_PROC_REF(/mob, set_sound_channel_volume), channel, step_volume), step * step_delay)

	addtimer(CALLBACK(player, TYPE_PROC_REF(/mob, stop_sound_channel), channel), fade_duration)
	debug_to_chat(player, "[src]: stop queued for channel [channel] at +[fade_duration] ticks.")
	return fade_duration

/datum/dialogue_sound/proc/play_after_fade(mob/player, atom/location, expected_nonce)
	debug_to_chat(player, "[src]: play_after_fade fired on channel [channel] at world.time=[world.time].")
	if(channel && channel_replay_nonce["[channel]"] != expected_nonce)
		debug_to_chat(player, "[src]: play_after_fade aborted (stale deferred playback).", TRUE)
		return FALSE
	if(!can_play(player, location))
		debug_to_chat(player, "[src]: play_after_fade aborted (can_play returned FALSE).", TRUE)
		return FALSE
	return execute_playback(player, location)

/datum/dialogue_sound/proc/emit_sound(mob/player, atom/location)
	playsound(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/local/can_play(mob/player, atom/location)
	if(!player)
		return FALSE
	return ..()

/datum/dialogue_sound/local/emit_sound(mob/player, atom/location)
	player.playsound_local(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/proc/execute_playback(mob/player, atom/location, should_prepare = TRUE)
	if(should_prepare)
		prepare_playback(player)
	emit_sound(player, location)
	mark_cooldown()
	mark_channel_busy()
	return TRUE

/datum/dialogue_sound/no_sound/can_play(mob/player, atom/location)
	return !!location

/datum/dialogue_sound/no_sound/is_channel_busy()
	return FALSE

/datum/dialogue_sound/no_sound/prepare_playback(mob/player)
	return

/datum/dialogue_sound/no_sound/emit_sound(mob/player, atom/location)
	return

/datum/dialogue_sound/no_sound/mark_cooldown()
	return

/datum/dialogue_sound/no_sound/mark_channel_busy()
	return

/datum/dialogue_sound/proc/play(mob/player, atom/location)
	if(!can_play(player, location))
		debug_to_chat(player, "[src]: play aborted (can_play returned FALSE).", TRUE)
		return FALSE
	if(is_channel_busy())
		var/current_priority = (channel_active_priority["[channel]"] || 0)
		if(priority <= current_priority)
			debug_to_chat(player, "[src]: play aborted (channel busy; priority [priority] <= active [current_priority]).", TRUE)
			return FALSE
		var/fade_duration = fade_interrupting_line(player)
		debug_to_chat(player, "[src]: channel busy, scheduling play_after_fade in [fade_duration + 1] ticks.")
		addtimer(CALLBACK(src, PROC_REF(play_after_fade), player, location), fade_duration + 1, TIMER_UNIQUE)
		return TRUE
	debug_to_chat(player, "[src]: channel free, executing playback now.")
	return execute_playback(player, location)

/datum/component/dialogue_system
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// List of signals to unregister from parent
	var/list/signals_to_unregister = list(COMSIG_ITEM_PICKUP, COMSIG_ITEM_DROPPED)
	/// Unique channel for this dialogue system instance.
	var/dialogue_channel
	/// Sounds played when the parent is picked up.
	var/list/pickup_sounds
	/// Sounds played when the parent is dropped.
	var/list/dropped_sounds
	/// Stoppable timer id for a pending delayed dropped line.
	var/drop_line_timerid

/datum/component/dialogue_system/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	setup_sound_lists()
	dialogue_channel = SSsounds.reserve_sound_channel_for_datum(src)
	apply_dialogue_channel()

/datum/component/dialogue_system/Destroy(force)
	if(drop_line_timerid)
		deltimer(drop_line_timerid)
		drop_line_timerid = null
	return ..()

/datum/component/dialogue_system/proc/setup_sound_lists()
	pickup_sounds = list()
	dropped_sounds = list()

/datum/component/dialogue_system/proc/apply_channel_to_sound_list(list/sounds)
	for(var/datum/dialogue_sound/sound as anything in sounds)
		sound.channel = dialogue_channel

/datum/component/dialogue_system/proc/apply_channel_to_sound_pool_list(list/sound_pools)
	for(var/list/sounds as anything in sound_pools)
		apply_channel_to_sound_list(sounds)

/datum/component/dialogue_system/proc/apply_dialogue_channel()
	if(!dialogue_channel)
		return
	apply_channel_to_sound_list(pickup_sounds)
	apply_channel_to_sound_list(dropped_sounds)

/datum/component/dialogue_system/proc/get_available_sounds(list/source_sounds, mob/player, atom/location)
	. = list()
	for(var/datum/dialogue_sound/sound as anything in source_sounds)
		if(sound.can_play(player, location))
			. += sound

/datum/component/dialogue_system/proc/pick_available_sound(list/source_sounds, mob/player, atom/location)
	var/list/available_sounds = get_available_sounds(source_sounds, player, location)
	if(!length(available_sounds))
		return null
	var/list/weighted_sounds = list()
	for(var/datum/dialogue_sound/sound as anything in available_sounds)
		weighted_sounds[sound] = max(sound.chance, 0)
	return pick_weight(weighted_sounds)

/datum/component/dialogue_system/RegisterWithParent()
	if(length(pickup_sounds))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	if(length(dropped_sounds))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/dialogue_system/UnregisterFromParent()
	UnregisterSignal(parent, signals_to_unregister)

/datum/component/dialogue_system/proc/on_pickup(obj/item/source, mob/taker)
	SIGNAL_HANDLER
	var/atom/atom_parent = parent
	if(!isturf(atom_parent.loc))
		return
	drop_line_timerid = addtimer(CALLBACK(src, PROC_REF(try_play_pickup_line), taker), 0.1 SECONDS, TIMER_STOPPABLE | TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/component/dialogue_system/proc/try_play_pickup_line(mob/taker)
	if(!taker?.is_holding(parent))
		return
	var/datum/dialogue_sound/sound = pick_available_sound(pickup_sounds, taker, parent)
	sound?.play(taker, parent)

/datum/component/dialogue_system/proc/on_dropped(obj/item/source, mob/user)
	SIGNAL_HANDLER
	var/atom/atom_parent = parent

	if(!isturf(atom_parent.loc))
		return
	drop_line_timerid = addtimer(CALLBACK(src, PROC_REF(try_play_dropped_line), user), 5 SECONDS, TIMER_STOPPABLE | TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/component/dialogue_system/proc/try_play_dropped_line(mob/user)
	drop_line_timerid = null
	var/atom/atom_parent = parent
	if(!isturf(atom_parent.loc))
		return

	var/datum/dialogue_sound/sound = pick_available_sound(dropped_sounds, user, atom_parent)
	sound?.play(user, atom_parent)
