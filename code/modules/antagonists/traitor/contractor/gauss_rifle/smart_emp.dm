/obj/item/ammo_casing/energy/gauss/emp
	name = "smart EMP gauss round"
	icon_state = "emp"
	projectile_type = /obj/projectile/bullet/gauss/emp
	select_name = "smart EMP"
	e_cost = GAUSS_NANITES(3)
	charged_e_cost = GAUSS_NANITES(5)
	charged_cooldown_time = 5 SECONDS

/obj/projectile/bullet/gauss/emp
	name = "smart EMP gauss round"
	icon_state = "emp_projectile"
	damage = 0
	speed = 3
	wound_bonus = CANT_WOUND
	sharpness = NONE
	embed_type = null
	/// Tiles that catch a heavy pulse. A hip shot is too gentle to produce any.
	var/heavy_emp_range = 0
	/// Tiles that catch a light pulse.
	var/light_emp_range = 2
	/// How long the resonation disables each APC in range.
	var/apc_lockout = 5 MINUTES

/obj/projectile/bullet/gauss/emp/empower(charge_ratio, atom/target)
	heavy_emp_range = 4
	light_emp_range = 6

//TODO: guarantee malfunctions on mechs
/obj/projectile/bullet/gauss/emp/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	empulse(target, heavy_emp_range, light_emp_range, emp_source = src)
	// Gauss EMP rounds are designed to keep APCs disabled for extended periods
	for(var/obj/machinery/power/apc/apc in range(max(heavy_emp_range, light_emp_range), target))
		addtimer(CALLBACK(apc, TYPE_PROC_REF(/obj/machinery/power/apc, reset), APC_RESET_EMP), apc_lockout, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)
