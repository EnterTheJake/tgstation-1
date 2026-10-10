#define OFF_STATION_GRACE (20 SECONDS)
#define OFF_STATION_FUSE (1 MINUTES)
#define OFF_STATION_MAX_TRIPS 3

/// logs and tells admins when and why a contractor bomb reacted to something
/obj/item/contractor_bomb/proc/log_countermeasure(mob/living/carbon/human/victim, reason)
	victim.investigate_log("had their contractor bomb implant react: [reason].", INVESTIGATE_DEATHS)
	message_admins("[ADMIN_LOOKUPFLW(victim)] had their contractor bomb implant react: [reason] at [ADMIN_VERBOSEJMP(victim)].")

/obj/item/contractor_bomb/proc/tamper_detonate(reason)
	if(detonating || isnull(owner))
		return
	log_countermeasure(owner, "[reason], detonating")
	explosion_flags |= CONTRACTOR_EXPLOSION_TAMPERED
	pre_explosion()

// catch-all: whatever pulls the bomb out of its victim sets it off, no ability list to keep updated
/obj/item/contractor_bomb/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(owner && loc != owner && loc?.loc != owner)
		tamper_detonate("the bomb was removed from their body ([loc ? "moved to [loc]" : "deleted or in nullspace"])")

/// Steps out of a chest that's coming off, since some swaps delete the old chest (and its contents) before the new one is on
/obj/item/contractor_bomb/proc/on_owner_limb_removed(mob/living/carbon/source, obj/item/bodypart/lost_limb, special, dismembered)
	SIGNAL_HANDLER
	if(lost_limb == loc)
		forceMove(source)

/// Hops into the replacement chest once it's attached
/obj/item/contractor_bomb/proc/on_owner_limb_attached(mob/living/carbon/source, obj/item/bodypart/new_limb, special, lazy)
	SIGNAL_HANDLER
	if(new_limb.body_zone == BODY_ZONE_CHEST)
		forceMove(new_limb)

/obj/item/contractor_bomb/proc/on_species_gained(mob/living/carbon/source, datum/species/new_species, datum/species/old_species)
	SIGNAL_HANDLER
	if(new_species.type != old_species?.type)
		tamper_detonate("they changed species from [old_species?.name] to [new_species.name]")

/obj/item/contractor_bomb/proc/on_mind_swapped(mob/living/source)
	SIGNAL_HANDLER
	tamper_detonate("their mind was swapped")

/obj/item/contractor_bomb/proc/on_owner_deleted(mob/living/source)
	SIGNAL_HANDLER
	if(!detonating)
		log_countermeasure(owner, "their body was deleted, detonating")
	actually_explode()

/obj/item/contractor_bomb/proc/on_owner_z_changed(mob/living/source, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER
	if(isnull(new_turf) || detonating)
		return
	if(is_station_level(new_turf.z))
		off_station = FALSE
		deltimer(off_station_timer)
		off_station_timer = null
		return
	if(is_centcom_level(new_turf.z) || is_reserved_level(new_turf.z) || off_station)
		return
	off_station = TRUE
	off_station_trips++
	if(off_station_trips > OFF_STATION_MAX_TRIPS)
		tamper_detonate("they left the station for the [off_station_trips]th time")
		return
	log_countermeasure(source, "they left the station (trip [off_station_trips] of [OFF_STATION_MAX_TRIPS]), grace period started")
	off_station_timer = addtimer(CALLBACK(src, PROC_REF(arm_for_leaving)), OFF_STATION_GRACE, TIMER_STOPPABLE)
	to_chat(source, span_userdanger("Your implant chirps: you left the station. Get back in [DisplayTimeText(OFF_STATION_GRACE)] or it arms. Leaving [OFF_STATION_MAX_TRIPS - off_station_trips + 1] more times sets it off."))

/obj/item/contractor_bomb/proc/arm_for_leaving()
	off_station_timer = null
	if(detonating)
		return
	arm()
	COOLDOWN_START(src, detonation_timer, min(COOLDOWN_TIMELEFT(src, detonation_timer), OFF_STATION_FUSE))

/obj/item/contractor_bomb/proc/on_self_transform(mob/living/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(warn_before_transform), source)
	return COMPONENT_BLOCK_SELF_TRANSFORM

/obj/item/contractor_bomb/proc/warn_before_transform(mob/living/victim)
	var/choice = tgui_alert(victim, "This seems like a really bad idea... are ya sure about this?", "Uh oh...", list("Cancel", "Do it anyway"))
	if(owner != victim)
		return
	victim.investigate_log("was warned by their contractor bomb implant before transforming and chose: [choice || "nothing"].", INVESTIGATE_DEATHS)
	if(choice == "Do it anyway")
		// yes rico, kaboom.
		tamper_detonate("they went through with a self-transformation after the warning")

#undef OFF_STATION_GRACE
#undef OFF_STATION_FUSE
#undef OFF_STATION_MAX_TRIPS
