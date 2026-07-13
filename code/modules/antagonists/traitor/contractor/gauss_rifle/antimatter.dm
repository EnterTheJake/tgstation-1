/obj/item/ammo_casing/energy/gauss/antimatter
	name = "antimatter gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile contains a translocated microscopic antimatter sliver into which the additional kinetic energy is diverted into upon impact with a surface. \n\
		This destabilization creates what is effectively a localized eruption of energy, blossoming outwards in a flash of light. \n\
		Against flesh or steel, the effect is often devastating and gruesome, leading this round to be viewed less as a weapon of war and more as a weapon of terror. \n\
		Cybersun is not above using this round when the situation calls for either need."
	icon_state = "antimatter"
	projectile_type = /obj/projectile/bullet/gauss/antimatter
	select_name = "antimatter"
	var/currently_charging = FALSE
	var/charge_time = 4 SECONDS

/obj/item/ammo_casing/energy/gauss/antimatter/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
	if(!loaded_projectile)
		return
	if(!check_charge(user))
		return
	. = ..()
	var/obj/item/gun/energy/gauss_rifle/gun = astype(loc)
	gun?.overheat()

/obj/item/ammo_casing/energy/gauss/antimatter/proc/check_charge(mob/living/user)
	var/obj/item/gun/energy/gauss_rifle/gun = loc
	if(!isliving(user) || !istype(gun))
		return TRUE
	if(currently_charging)
		user.balloon_alert(user, "already charging!")
		return FALSE

	// Purple recolour of the voltaic heart's lightning overlay, worn by the shooter while charging.
	var/mutable_appearance/charge_overlay = mutable_appearance('icons/effects/effects.dmi', "lightning")
	charge_overlay.color = COLOR_PURPLE
	user.add_overlay(charge_overlay)
	gun.set_antimatter_charging(TRUE)
	user.balloon_alert(user, "charging...")
	user.playsound_local(get_turf(user), 'sound/effects/magic/lightning_chargeup.ogg', 70, TRUE)
	currently_charging = TRUE
	. = do_after(user, charge_time, user, IGNORE_USER_LOC_CHANGE)
	currently_charging = FALSE
	if(!QDELETED(user))
		user.cut_overlay(charge_overlay)
	if(!QDELETED(gun))
		gun.set_antimatter_charging(FALSE)

	if(!.)
		user.balloon_alert(user, "interrupted!")
	return .

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
	var/recoil_distance = 6

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
	// Unscoped fire recoils the shooter, but like every other effect it waits for the discharge.
	var/effective_recoil = (isliving(firer) && !HAS_TRAIT(firer, TRAIT_USER_SCOPED)) ? recoil_distance : 0
	new /datum/antimatter_discharge(get_line(starting, end_turf), firer, angle2dir_cardinal(angle), effective_recoil)

	return ..()

/datum/antimatter_discharge
	var/list/turf/beam_turfs
	var/datum/weakref/firer_ref
	var/beam_dir
	var/damage = 70
	var/wound_bonus = 40
	var/pull_radius = 1
	/// Delay from firing to discharge, synced to the frame the gauss_antimatter tracer's effect lands.
	var/discharge_delay = 0.8 SECONDS
	var/beam_lifetime = 2 SECONDS
	var/pulse_interval = 0.3 SECONDS
	var/knockback_cooldown = 0.5 SECONDS
	var/discharging = FALSE
	var/turf/end_turf
	/// Distance the shooter is recoiled at discharge (0 = braced/scoped, no recoil).
	var/recoil_distance = 0
	var/list/struck_victims
	var/list/knockback_cooldowns

/datum/antimatter_discharge/New(list/turf/path, mob/firer, dir, recoil_distance = 0)
	beam_turfs = path
	firer_ref = WEAKREF(firer)
	beam_dir = dir
	end_turf = length(path) ? path[length(path)] : null
	src.recoil_distance = recoil_distance
	struck_victims = list()
	knockback_cooldowns = list()
	addtimer(CALLBACK(src, PROC_REF(discharge)), discharge_delay, TIMER_CLIENT_TIME)

/datum/antimatter_discharge/proc/discharge()
	discharging = TRUE
	var/turf/origin = length(beam_turfs) ? beam_turfs[1] : null
	var/turf/endpoint = length(beam_turfs) ? beam_turfs[length(beam_turfs)] : null
	if(origin)
		playsound(origin, 'sound/effects/magic/lightningbolt.ogg', 80, TRUE)
	if(recoil_distance > 0)
		var/mob/living/shooter = firer_ref?.resolve()
		if(isliving(shooter))
			shooter.balloon_alert(shooter, "recoil!")
			shooter.safe_throw_at(get_edge_target_turf(shooter, REVERSE_DIR(beam_dir)), recoil_distance, 3, shooter, force = MOVE_FORCE_STRONG)
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
	var/dealt_damage = iscarbon(victim) ? damage : damage * 2
	victim.apply_damage(dealt_damage, BRUTE, blocked = 0, forced = TRUE, spread_damage = TRUE, wound_bonus = wound_bonus)
	victim.soundbang_act(1 SECONDS)
	// Only frail-quirk holders escalate (to Super Frail, then a gib on the next hit). Everyone else stays
	// plain Frail forever - the Frail status never counts toward escalation, so it can't stack up to a gib.
	if(victim.has_quirk(/datum/quirk/frail))
		victim.apply_status_effect(/datum/status_effect/frail/super)
	else
		victim.apply_status_effect(/datum/status_effect/frail)

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
