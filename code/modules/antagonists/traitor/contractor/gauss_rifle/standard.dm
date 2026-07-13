/obj/item/ammo_casing/energy/gauss
	name = "standard gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile delivers enough kinetic energy into an impacted surface to liquify surrounding organic matter it passes through or render vehicles inoperable if aimed towards an engine block or battery pack."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard"
	caliber = CALIBER_GAUSS
	projectile_type = /obj/projectile/bullet/gauss
	select_name = "standard"

/obj/projectile/bullet/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard_projectile"
	damage = 40
	armour_penetration = 35
	speed = 2
	wound_bonus = -20
