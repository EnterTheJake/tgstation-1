/obj/item/ammo_casing/energy/gauss/antimatter
	name = "antimatter gauss round"
	icon_state = "antimatter"
	projectile_type = /obj/projectile/bullet/gauss/antimatter
	select_name = "antimatter"
	e_cost = GAUSS_NANITES(15)
	// The channel stays long at any range. This round has no hip fired version.
	charge_time = 4 SECONDS
	seconds_per_distance = 0
	max_charge_time = 4 SECONDS
	scope_only = TRUE
	charged_cooldown_time = 5 MINUTES
	charge_alert = "charging..."
	charge_sound = 'sound/effects/magic/lightning_chargeup.ogg'
	/// How long the rifle stays overheated after it translocates a sliver of antimatter.
	var/antimatter_overheat = 15 SECONDS
	/// Purple recolor of the voltaic heart lightning overlay. The shooter wears it while charging.
	var/mutable_appearance/charge_overlay

/obj/item/ammo_casing/energy/gauss/antimatter/on_charge_started(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	charge_overlay = mutable_appearance('icons/effects/effects.dmi', "lightning")
	charge_overlay.color = COLOR_PURPLE
	user.add_overlay(charge_overlay)
	rifle.set_antimatter_charging(TRUE)

/obj/item/ammo_casing/energy/gauss/antimatter/on_charge_ended(mob/living/user, obj/item/gun/energy/gauss_rifle/rifle)
	if(!QDELETED(user))
		user.cut_overlay(charge_overlay)
	charge_overlay = null
	if(!QDELETED(rifle))
		rifle.set_antimatter_charging(FALSE)

/obj/item/ammo_casing/energy/gauss/antimatter/on_empowered_fire(mob/living/user)
	. = ..()
	var/obj/item/gun/energy/gauss_rifle/rifle = astype(loc)
	if(isnull(rifle))
		return
	rifle.overheat(antimatter_overheat)
	// The translocation scavenges every nanite left in the magazine. It always leaves the magazine dry.
	rifle.cell?.use(rifle.cell.charge, force = TRUE)

/obj/projectile/bullet/gauss/antimatter
	name = "antimatter gauss round"
	icon_state = "antimatter_projectile"
	damage = 0
	armour_penetration = 100
	speed = 3
	range = 30
	hitsound = null
	hitscan = TRUE
	tracer_type = /obj/effect/projectile/tracer/gauss_antimatter
	tracer_use_pixel_scale = TRUE
	embed_type = null
	projectile_phasing = PASSTABLE | PASSGLASS | PASSGRILLE | PASSCLOSEDTURF | PASSMACHINE | PASSSTRUCTURE | PASSDOORS
	projectile_piercing = PASSMOB
	phasing_ignore_direct_target = TRUE

/// The channel is the only firing mode of this round. Empowerment adds nothing.
/obj/projectile/bullet/gauss/antimatter/empower(charge_ratio, atom/target)
	return

/obj/projectile/bullet/gauss/antimatter/fire(fire_angle, atom/direct_target)
	var/turf/starting = get_turf(src)
	if(isnum(fire_angle))
		set_angle(fire_angle)
	else if(isnull(angle))
		if(isnull(xo) || isnull(yo))
			qdel(src)
			return
		var/turf/offset_target = locate(clamp(starting.x + xo, 1, world.maxx), clamp(starting.y + yo, 1, world.maxy), starting.z)
		set_angle(get_angle(src, offset_target))

	var/end_x = clamp(round(starting.x + sin(angle) * range), 1, world.maxx)
	var/end_y = clamp(round(starting.y + cos(angle) * range), 1, world.maxy)
	var/turf/end_turf = locate(end_x, end_y, starting.z)
	new /datum/antimatter_discharge(get_line(starting, end_turf), firer, angle2dir_cardinal(angle))

	return ..()

/datum/antimatter_discharge
	var/list/turf/beam_turfs
	var/datum/weakref/firer_ref
	var/beam_dir
	var/damage = 30
	/// Damage multiplier for non-carbon targets.
	var/inorganic_damage_mult = 4
	var/wound_bonus = 40
	/// How long the detonation deafens a victim.
	var/deafening_duration = 1 MINUTES
	/// How long the narrowed vision lasts after the beam catches a victim.
	var/vision_narrow_duration = 15 SECONDS
	var/pull_radius = 1
	/// Delay from firing to discharge, synced to the frame the gauss_antimatter tracer's effect lands.
	var/discharge_delay = 0.8 SECONDS
	var/beam_lifetime = 2 SECONDS
	var/pulse_interval = 0.3 SECONDS
	var/knockback_cooldown = 0.5 SECONDS
	var/discharging = FALSE
	var/turf/end_turf
	var/list/struck_victims
	var/list/knockback_cooldowns

/datum/antimatter_discharge/New(list/turf/path, mob/firer, dir)
	beam_turfs = path
	firer_ref = WEAKREF(firer)
	beam_dir = dir
	end_turf = length(path) ? path[length(path)] : null
	struck_victims = list()
	knockback_cooldowns = list()
	addtimer(CALLBACK(src, PROC_REF(discharge)), discharge_delay, TIMER_CLIENT_TIME)

/datum/antimatter_discharge/proc/discharge()
	discharging = TRUE
	var/turf/origin = length(beam_turfs) ? beam_turfs[1] : null
	var/turf/endpoint = length(beam_turfs) ? beam_turfs[length(beam_turfs)] : null
	if(origin)
		playsound(origin, 'sound/effects/magic/lightningbolt.ogg', 80, TRUE)
	spawn_pull_field()
	for(var/turf/beam_turf as anything in beam_turfs)
		for(var/mob/living/bystander in view(1, beam_turf))
			bystander.flash_act(1)
	if(endpoint)
		new /obj/effect/temp_visual/antimatter_anomaly(endpoint)
		new /obj/effect/temp_visual/circle_wave/gravity(endpoint)
		playsound(endpoint, 'sound/effects/magic/cosmic_energy.ogg', 60, TRUE)
	pulse_beam()
	addtimer(CALLBACK(src, PROC_REF(end_discharge)), beam_lifetime)

/// Rings the beam with gravity motes on the tiles beside it, each drifting inward onto the beam.
/datum/antimatter_discharge/proc/spawn_pull_field()
	var/list/turf/zone = list()
	for(var/turf/beam_turf as anything in beam_turfs)
		for(var/step_dir in GLOB.cardinals)
			var/turf/side = get_step(beam_turf, step_dir)
			if(side && !(side in beam_turfs))
				zone[side] = TRUE
	for(var/turf/zone_turf as anything in zone)
		var/turf/sink = get_closest_beam_turf(zone_turf)
		if(!sink || sink == zone_turf)
			continue
		new /obj/effect/temp_visual/antimatter_field(zone_turf, dir_to_gravity(get_dir(zone_turf, sink)))

/datum/antimatter_discharge/proc/dir_to_gravity(dir)
	// Particle x runs opposite screen x, so east/west are flipped here.
	var/dx = (dir & EAST) ? -1.5 : ((dir & WEST) ? 1.5 : 0)
	var/dy = (dir & NORTH) ? 1.5 : ((dir & SOUTH) ? -1.5 : 0)
	return list(dx, dy)

/datum/antimatter_discharge/proc/pulse_beam()
	if(!discharging)
		return
	var/mob/firer = firer_ref?.resolve()
	var/list/mob/living/seen = list()
	for(var/turf/beam_turf as anything in beam_turfs)
		for(var/mob/living/victim in range(pull_radius, beam_turf))
			if(victim == firer || (victim in seen))
				continue
			seen += victim
			// Off the beam: nudge one tile onto it (gravity-anomaly style), then strike + throw in the
			// same pulse if now on it, so the forward launch doesn't lag a tick behind the pull-in.
			if(!(get_turf(victim) in beam_turfs))
				var/turf/anchor = get_closest_beam_turf(victim)
				if(anchor)
					step_towards(victim, anchor)
			if(get_turf(victim) in beam_turfs)
				process_victim(victim, firer)
	addtimer(CALLBACK(src, PROC_REF(pulse_beam)), pulse_interval)

/datum/antimatter_discharge/proc/get_closest_beam_turf(atom/to_atom)
	var/turf/closest
	var/closest_dist = INFINITY
	for(var/turf/beam_turf as anything in beam_turfs)
		var/dist = get_dist(to_atom, beam_turf)
		if(dist < closest_dist)
			closest_dist = dist
			closest = beam_turf
	return closest

/datum/antimatter_discharge/proc/process_victim(mob/living/victim, mob/firer)
	if(!(victim in struck_victims))
		struck_victims += victim
		strike_victim(victim)
		if(QDELETED(victim))
			return
	var/victim_ref = REF(victim)
	if(knockback_cooldowns[victim_ref] && world.time < knockback_cooldowns[victim_ref])
		return
	knockback_cooldowns[victim_ref] = world.time + knockback_cooldown
	// Launch along the line toward the true endpoint (beam_dir is only a cardinal, wrong for diagonal beams).
	var/throw_dir = (end_turf && get_turf(victim) != end_turf) ? get_dir(victim, end_turf) : beam_dir
	victim.safe_throw_at(get_edge_target_turf(victim, throw_dir), length(beam_turfs), 5, firer, force = MOVE_FORCE_EXTREMELY_STRONG)

/datum/antimatter_discharge/proc/strike_victim(mob/living/victim)
	if(QDELETED(victim) || victim.stat == DEAD)
		return
	if(victim.has_status_effect(/datum/status_effect/frail/super))
		victim.investigate_log("was gibbed by an antimatter gauss round while Super Frail.", INVESTIGATE_DEATHS)
		victim.gib()
		return
	var/dealt_damage = iscarbon(victim) ? damage : damage * inorganic_damage_mult
	victim.apply_damage(dealt_damage, BRUTE, blocked = 0, forced = TRUE, spread_damage = TRUE, wound_bonus = wound_bonus)
	// The blast beats standard ear protection. It also narrows the vision of the survivor.
	victim.soundbang_act(SOUNDBANG_STRONG, stun_pwr = 0, damage_pwr = 5, deafen_pwr = deafening_duration)
	narrow_vision(victim)
	// Only frail-quirk holders escalate (to Super Frail, then a gib on the next hit). Everyone else stays
	// plain Frail forever - the Frail status never counts toward escalation, so it can't stack up to a gib.
	if(victim.has_quirk(/datum/quirk/frail))
		victim.apply_status_effect(/datum/status_effect/frail/super)
	else
		victim.apply_status_effect(/datum/status_effect/frail)

/**
 * Narrows the field of vision of the victim for a short time after the flash.
 *
 * Glasses cannot correct it, because the flash damages the eyes directly. The effect uses a grouped
 * status rather than a timed one, so a timer must remove it.
 */
/datum/antimatter_discharge/proc/narrow_vision(mob/living/victim)
	victim.assign_nearsightedness(GAUSS_ANTIMATTER_TRAIT, 2, FALSE)
	addtimer(CALLBACK(victim, TYPE_PROC_REF(/mob/living, remove_status_effect), /datum/status_effect/grouped/nearsighted, GAUSS_ANTIMATTER_TRAIT), vision_narrow_duration)

/datum/antimatter_discharge/proc/end_discharge()
	discharging = FALSE
	qdel(src)

/datum/antimatter_discharge/Destroy()
	beam_turfs = null
	struck_victims = null
	knockback_cooldowns = null
	firer_ref = null
	return ..()

/// One pull-zone tile: emits a single burst of gravity motes that stream toward the beam.
/obj/effect/temp_visual/antimatter_field
	icon = null
	icon_state = null
	duration = 1.5 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/antimatter_field/Initialize(mapload, list/pull_gravity)
	. = ..()
	particles = new /particles/antimatter_pull
	if(pull_gravity)
		particles.gravity = pull_gravity
	addtimer(CALLBACK(src, PROC_REF(stop_spawning)), 0.2 SECONDS)

/obj/effect/temp_visual/antimatter_field/proc/stop_spawning()
	if(particles)
		particles.spawning = 0

/// The beam's terminus, wearing the gravitational anomaly's wibbly warp.
/obj/effect/temp_visual/antimatter_anomaly
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	duration = 2 SECONDS
	alpha = 160
	color = COLOR_PURPLE
	randomdir = FALSE

/obj/effect/temp_visual/antimatter_anomaly/Initialize(mapload)
	. = ..()
	apply_wibbly_filters(src)

/particles/antimatter_pull
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "cross"
	width = 64
	height = 64
	count = 8
	spawning = 8
	lifespan = 0.9 SECONDS
	fade = 0.5 SECONDS
	fadein = 0.15 SECONDS
	position = generator(GEN_CIRCLE, 0, 14, UNIFORM_RAND)
	gravity = list(0, -1.5)
	color = COLOR_PURPLE
