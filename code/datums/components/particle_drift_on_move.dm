/**
 * Attaches a particle emitter to a movable and briefly drifts its motes in the direction of
 * movement after each step. Pass a particle type and drift tuning. Lifecycle is driven by signals:
 * COMSIG_PARTICLE_DRIFT_WIND_DOWN fades it out and removes it, COMSIG_PARTICLE_DRIFT_RESUME revives it.
 */
/datum/component/particle_drift_on_move
	var/obj/effect/abstract/particle_holder/holder
	var/atom/movable/tracked_mob
	var/list/rest_gravity
	var/drift_strength
	var/drift_time
	var/reset_timer
	/// Spawn rate restored when the effect is resumed after a wind-down.
	var/base_spawning
	var/winddown_timer

/datum/component/particle_drift_on_move/Initialize(particle_type = /particles/smoke, drift_strength = 1.2, drift_time = 0.6 SECONDS, list/rest_gravity = list(0, 0.95))
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	src.drift_strength = drift_strength
	src.drift_time = drift_time
	src.rest_gravity = rest_gravity
	holder = new /obj/effect/abstract/particle_holder(parent, particle_type, PARTICLE_ATTACH_MOB)
	base_spawning = holder.particles?.spawning
	update_tracked()

/datum/component/particle_drift_on_move/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))
	RegisterSignal(parent, COMSIG_PARTICLE_DRIFT_WIND_DOWN, PROC_REF(on_wind_down))
	RegisterSignal(parent, COMSIG_PARTICLE_DRIFT_RESUME, PROC_REF(on_resume))

/datum/component/particle_drift_on_move/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARTICLE_DRIFT_WIND_DOWN, COMSIG_PARTICLE_DRIFT_RESUME))
	set_tracked(null)

/datum/component/particle_drift_on_move/Destroy(force)
	set_tracked(null)
	if(reset_timer)
		deltimer(reset_timer)
	if(winddown_timer)
		deltimer(winddown_timer)
	QDEL_NULL(holder)
	return ..()

/// Stops spawning new motes, lets the existing ones fade out, then removes the holder.
/datum/component/particle_drift_on_move/proc/on_wind_down(datum/source)
	SIGNAL_HANDLER
	var/particles/smoke = holder?.particles
	if(!smoke)
		qdel(src)
		return
	smoke.spawning = 0
	if(winddown_timer)
		deltimer(winddown_timer)
	winddown_timer = addtimer(CALLBACK(src, PROC_REF(finish_winddown)), smoke.lifespan + smoke.fade, TIMER_STOPPABLE)

/datum/component/particle_drift_on_move/proc/finish_winddown()
	winddown_timer = null
	qdel(src)

/// Cancels a pending wind-down and restores the spawn rate.
/datum/component/particle_drift_on_move/proc/on_resume(datum/source)
	SIGNAL_HANDLER
	if(winddown_timer)
		deltimer(winddown_timer)
		winddown_timer = null
	if(holder?.particles)
		holder.particles.spawning = base_spawning
	return PARTICLE_DRIFT_RESUMED

/datum/component/particle_drift_on_move/proc/on_parent_moved(datum/source, atom/oldloc, direction)
	SIGNAL_HANDLER
	update_tracked()
	// Parent moving on its own (dropped/thrown) rather than carried: trail off its own motion.
	if(direction && oldloc && !tracked_mob)
		drift(direction, source)

/datum/component/particle_drift_on_move/proc/update_tracked()
	var/atom/movable/movable_parent = parent
	set_tracked(ismob(movable_parent.loc) ? movable_parent.loc : null)

/datum/component/particle_drift_on_move/proc/set_tracked(atom/movable/new_mob)
	if(new_mob == tracked_mob)
		return
	if(tracked_mob)
		UnregisterSignal(tracked_mob, COMSIG_MOVABLE_MOVED)
	tracked_mob = new_mob
	if(tracked_mob)
		RegisterSignal(tracked_mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_moved))

/datum/component/particle_drift_on_move/proc/on_mob_moved(datum/source, atom/oldloc, direction)
	SIGNAL_HANDLER
	drift(direction, source)

/datum/component/particle_drift_on_move/proc/drift(direction, atom/movable/mover)
	var/particles/smoke = holder?.particles
	if(!smoke || !direction)
		return
	// Particle space runs opposite screen space on both axes, so the drift is negated against the move dir.
	var/dx = (direction & EAST) ? -drift_strength : ((direction & WEST) ? drift_strength : 0)
	var/dy = (direction & NORTH) ? -drift_strength : ((direction & SOUTH) ? drift_strength : 0)
	smoke.gravity = list(dx, rest_gravity[2] + dy)
	if(reset_timer)
		deltimer(reset_timer)
	// Extend the drift by the mover's tile-crossing (glide) time, so it tracks how fast they're moving.
	var/glide_time = (mover?.glide_size > 0) ? (world.tick_lag * ICON_SIZE_ALL / mover.glide_size) : 0
	reset_timer = addtimer(CALLBACK(src, PROC_REF(reset_drift)), drift_time + glide_time, TIMER_STOPPABLE)

/datum/component/particle_drift_on_move/proc/reset_drift()
	reset_timer = null
	var/particles/smoke = holder?.particles
	if(smoke)
		smoke.gravity = rest_gravity.Copy()
