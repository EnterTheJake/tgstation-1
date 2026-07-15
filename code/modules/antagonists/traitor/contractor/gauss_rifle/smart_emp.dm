/obj/item/ammo_casing/energy/gauss/emp
	name = "smart EMP gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile unleashes its energy payload as ionized radiation bursts upon impact with a solid surface, disrupting electronic devices and synthetic lifeforms. \n\
		While the impact shatters the otherwise frail containment shell for the internal catalystic discharge array, causing no real harm to organic flesh, the resulting ionized particles fry machinery with ease. \n\
		The specialized resonation of these particles is particularly suited to shutting down Area Power Controller modules, rendering them completely inoperable for large periods of time. \n\
		It also has a tendency to prime electronic munitions and transfer valves, resulting in what Cybersun agents call a 'spontaneous clusterfuck' scenario. Use with care."
	icon_state = "emp"
	projectile_type = /obj/projectile/bullet/gauss/emp
	select_name = "smart EMP"

/obj/projectile/bullet/gauss/emp
	name = "smart EMP gauss round"
	icon_state = "emp_projectile"
	damage = 15
	speed = 3
	wound_bonus = CANT_WOUND
	sharpness = NONE
	embed_type = null

//TODO: guarantee malfunctions on mechs
/obj/projectile/bullet/gauss/emp/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	empulse(target, 3, 0, emp_source = src)
	// Gauss EMP rounds are designed to keep APCs disabled for extended periods
	for(var/obj/machinery/power/apc/apc in range(2, target))
		addtimer(CALLBACK(apc, TYPE_PROC_REF(/obj/machinery/power/apc, reset), APC_RESET_EMP), 5 MINUTES, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)
