/atom/movable/screen/gauss_ammo_display
	name = "gauss ammo display"
	icon_state = "normal_hud"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_hud.dmi'
	screen_loc = ui_contractor_gun_hud
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	/// Current mob this display is shown for.
	var/mob/current_owner
	/// Cached number overlay so it can be replaced cleanly.
	var/mutable_appearance/shots_overlay

/atom/movable/screen/gauss_ammo_display/Destroy()
	hide_from_owner()
	return ..()

/atom/movable/screen/gauss_ammo_display/proc/on_gun_ammo_changed(obj/item/gun/energy/gauss_rifle/source, shots_left, max_shots, mode_prefix)
	SIGNAL_HANDLER
	refresh_display(shots_left, max_shots, mode_prefix)

/atom/movable/screen/gauss_ammo_display/proc/show_for(mob/new_owner)
	if(!new_owner?.client)
		return

	if(new_owner == current_owner)
		if(!(src in new_owner.client.screen))
			new_owner.client.screen += src
		return

	hide_from_owner()
	current_owner = new_owner
	current_owner.client.screen += src

/atom/movable/screen/gauss_ammo_display/proc/hide_from_owner()
	if(current_owner)
		current_owner.client?.screen -= src
	current_owner = null

/atom/movable/screen/gauss_ammo_display/proc/refresh_display(shots_left, max_shots, mode_prefix = "normal")
	icon_state = get_hud_icon_state(mode_prefix)

	if(shots_overlay)
		cut_overlay(shots_overlay)
		shots_overlay = null

	if(shots_left <= 0)
		return

	var/prefix = get_number_prefix(mode_prefix)
	var/number_state = "[prefix]_[shots_left]"
	if(!icon_exists(icon, number_state))
		var/fallback_max = max(shots_left, max_shots, 1)
		for(var/i in fallback_max to 1 step -1)
			if(icon_exists(icon, "[prefix]_[i]"))
				number_state = "[prefix]_[i]"
				break

	shots_overlay = mutable_appearance(icon, number_state)
	add_overlay(shots_overlay)

/atom/movable/screen/gauss_ammo_display/proc/get_hud_icon_state(mode_prefix)
	var/state = "[mode_prefix]_hud"
	if(icon_exists(icon, state))
		return state
	return "normal_hud"

/atom/movable/screen/gauss_ammo_display/proc/get_number_prefix(mode_prefix)
	if(icon_exists(icon, "[mode_prefix]_1"))
		return mode_prefix
	return "normal"

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	alpha = 0
	var/obj/item/gun/energy/gauss_rifle/source_gun
	var/atom/movable/screen/gauss_scope_visual/scope_visual
	var/list/fading_visuals
	var/atom/movable/screen/fullscreen/gauss_fisheye_source/fisheye_source
	var/atom/movable/screen/fullscreen/gauss_scope_vignette/vignette
	var/matrix/vignette_base
	var/matrix/reticle_base
	var/atom/movable/screen/gauss_scope_range/range_display
	var/last_range = -1
	var/previous_sound_environment
	var/fisheye_filter_key = "gauss_scope_fisheye"
	var/tint_filter_key = "gauss_scope_tint"
	var/fisheye_size = 10
	var/punch_in_time = 0.2 SECONDS
	var/punch_out_time = 0.15 SECONDS
	var/open_scale = 1.3
	var/kick_distance = 12
	var/kick_time = 0.05 SECONDS
	var/kick_settle_time = 0.4 SECONDS
	var/kick_vignette_ratio = 0.35
	var/vignette_overscan = 1.08

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/assign_to_mob(mob/new_owner, range_modifier, obj/item/source_item)
	. = ..()
	source_gun = source_item
	update_scope_visuals()
	apply_scope_effects()
	muffle_audio()
	if(isliving(new_owner))
		RegisterSignal(new_owner, SIGNAL_REMOVETRAIT(TRAIT_USER_SCOPED), PROC_REF(on_scope_removed))
	if(source_gun)
		RegisterSignals(source_gun, list(COMSIG_GAUSS_RIFLE_MODE_CHANGED, COMSIG_GAUSS_RIFLE_SCOPE_REFRESH), PROC_REF(on_gun_mode_changed))
		RegisterSignal(source_gun, COMSIG_GAUSS_RIFLE_SCOPE_KICK, PROC_REF(on_gun_fired))

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/Destroy()
	if(owner)
		UnregisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_USER_SCOPED))
	if(source_gun)
		UnregisterSignal(source_gun, list(COMSIG_GAUSS_RIFLE_MODE_CHANGED, COMSIG_GAUSS_RIFLE_SCOPE_REFRESH, COMSIG_GAUSS_RIFLE_SCOPE_KICK))
	clear_scope_effects()
	clear_visuals(immediate = TRUE)
	source_gun = null
	return ..()

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/on_scope_removed(datum/source)
	SIGNAL_HANDLER
	begin_scope_exit()
	clear_visuals(immediate = FALSE)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/muffle_audio()
	if(isnull(owner))
		return
	previous_sound_environment = owner.sound_environment_override
	owner.playsound_local(owner, 'sound/machines/click.ogg', 40, TRUE)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/restore_audio()
	if(isnull(owner) || isnull(previous_sound_environment))
		return
	previous_sound_environment = null

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/apply_scope_effects()
	var/mob/viewer = owner
	if(isnull(viewer?.client) || isnull(viewer.hud_used))
		return

	if(isnull(fisheye_source))
		fisheye_source = new(null, viewer.hud_used)
		fisheye_source.render_target = "*gauss_fisheye_[REF(src)]"
		fisheye_source.update_for_view(viewer.client.view)
		viewer.client.screen += fisheye_source

	if(isnull(vignette))
		vignette = new(null, viewer.hud_used)
		vignette.update_for_view(viewer.client.view)
		SET_PLANE_EXPLICIT(vignette, initial(vignette.plane), viewer)
		vignette_base = matrix(vignette.transform).Scale(vignette_overscan)
		viewer.client.screen += vignette

	if(isnull(range_display))
		range_display = new(null, viewer.hud_used)
		SET_PLANE_EXPLICIT(range_display, initial(range_display.plane), viewer)
		viewer.client.screen += range_display

	for(var/atom/movable/screen/plane_master/game_plane as anything in viewer.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
		game_plane.add_filter(fisheye_filter_key, 1, displacement_map_filter(render_source = fisheye_source.render_target, size = 0))
		game_plane.add_filter(tint_filter_key, 3, color_matrix_filter(list(
			1.05, 0, 0, 0,
			0, 1.09, 0, 0,
			0, 0, 1.14, 0,
			0, 0, 0, 1,
			-0.045, -0.045, -0.045, 0,
		)))
		var/warp = game_plane.get_filter(fisheye_filter_key)
		if(warp)
			animate(warp, size = fisheye_size, time = punch_in_time, easing = CUBIC_EASING|EASE_OUT)

	vignette.alpha = 0
	vignette.transform = matrix(vignette_base).Scale(open_scale)
	animate(vignette, alpha = 255, transform = matrix(vignette_base), time = punch_in_time, easing = CUBIC_EASING|EASE_OUT)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/begin_scope_exit()
	restore_audio()

	var/mob/viewer = owner
	if(isnull(viewer?.hud_used))
		clear_scope_effects()
		return

	if(vignette && vignette_base)
		animate(vignette, alpha = 0, transform = matrix(vignette_base).Scale(open_scale), time = punch_out_time)
	for(var/atom/movable/screen/plane_master/game_plane as anything in viewer.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
		var/warp = game_plane.get_filter(fisheye_filter_key)
		if(warp)
			animate(warp, size = 0, time = punch_out_time)
	addtimer(CALLBACK(src, PROC_REF(clear_scope_effects)), punch_out_time)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/on_gun_fired(datum/source, mob/living/user)
	SIGNAL_HANDLER
	scope_kick()

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/scope_kick()
	var/angle = rand(0, 359)
	var/kick_x = kick_distance * sin(angle)
	var/kick_y = kick_distance * cos(angle)
	if(scope_visual && reticle_base)
		animate(scope_visual, transform = matrix(reticle_base).Translate(kick_x, kick_y), time = kick_time, flags = ANIMATION_PARALLEL)
		animate(transform = matrix(reticle_base), time = kick_settle_time, easing = BACK_EASING|EASE_OUT)
	if(vignette && vignette_base)
		animate(vignette, transform = matrix(vignette_base).Translate(kick_x * kick_vignette_ratio, kick_y * kick_vignette_ratio), time = kick_time, flags = ANIMATION_PARALLEL)
		animate(transform = matrix(vignette_base), time = kick_settle_time, easing = BACK_EASING|EASE_OUT)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/calculate_params()
	. = ..()
	update_range_display()

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/update_range_display()
	if(isnull(range_display) || isnull(given_turf) || isnull(owner))
		return
	var/range = max(get_dist(owner, given_turf), 0)
	if(range == last_range)
		return
	last_range = range
	range_display.set_range(range)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/clear_scope_effects()
	restore_audio()
	last_range = -1
	if(range_display)
		if(owner?.client)
			owner.client.screen -= range_display
		QDEL_NULL(range_display)
	if(fisheye_source)
		if(owner?.client)
			owner.client.screen -= fisheye_source
		QDEL_NULL(fisheye_source)
	if(vignette)
		if(owner?.client)
			owner.client.screen -= vignette
		QDEL_NULL(vignette)
	var/mob/viewer = owner
	if(isnull(viewer?.hud_used) || HAS_TRAIT(viewer, TRAIT_USER_SCOPED))
		return
	for(var/atom/movable/screen/plane_master/game_plane as anything in viewer.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
		game_plane.remove_filter(list(fisheye_filter_key, tint_filter_key))

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/on_gun_mode_changed(datum/source)
	SIGNAL_HANDLER
	update_scope_visuals()
	owner?.playsound_local(owner, 'sound/machines/click.ogg', 35, TRUE)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/clear_visuals(immediate = FALSE)
	// Drop anything left from an earlier fade, so swapping modes mid-fade can't stack overlays
	// or strand one in vis_contents.
	for(var/atom/movable/screen/gauss_scope_visual/stale as anything in fading_visuals)
		vis_contents -= stale
		qdel(stale)
	fading_visuals = null

	var/atom/movable/screen/gauss_scope_visual/leaving = scope_visual
	scope_visual = null
	if(isnull(leaving))
		return

	if(immediate || !punch_out_time)
		vis_contents -= leaving
		qdel(leaving)
		return

	LAZYADD(fading_visuals, leaving)
	animate(leaving, alpha = 0, time = punch_out_time)
	addtimer(CALLBACK(src, PROC_REF(finish_fade), leaving), punch_out_time)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/finish_fade(atom/movable/screen/gauss_scope_visual/faded)
	LAZYREMOVE(fading_visuals, faded)
	if(QDELETED(faded))
		return
	vis_contents -= faded
	qdel(faded)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/update_scope_visuals()
	if(!owner?.client || !source_gun)
		return

	clear_visuals(immediate = TRUE)

	var/scope_state = source_gun.get_scope_icon_state(source_gun.get_current_mode_prefix())
	var/stretch = source_gun.scope_overlay_stretches

	scope_visual = new(null, null, scope_state, stretch)
	SET_PLANE_EXPLICIT(scope_visual, initial(scope_visual.plane), owner)
	reticle_base = matrix(scope_visual.transform)
	scope_visual.alpha = 0
	animate(scope_visual, alpha = 255, time = punch_in_time)
	vis_contents += scope_visual

/atom/movable/screen/fullscreen/gauss_fisheye_source
	icon = 'code/modules/antagonists/traitor/contractor/icons/scope_fisheye.dmi'
	icon_state = "fisheye"
	plane = FULLSCREEN_PLANE
	needs_offsetting = FALSE

/atom/movable/screen/gauss_scope_range
	name = "range"
	icon = null
	icon_state = null
	screen_loc = "EAST-2,NORTH-1"
	plane = ABOVE_HUD_PLANE
	layer = FULLSCREEN_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_width = 64
	maptext_height = 16
	maptext_x = -16
	var/font_family = "Pixellari"
	var/font_size = "12pt"
	var/font_colour = "#93e0c8"
	var/font_outline = "1px black"

/atom/movable/screen/gauss_scope_range/proc/set_range(distance)
	maptext = "<span style='font-family: \"[font_family]\"; font-size: [font_size]; -dm-text-outline: [font_outline]; color: [font_colour]'>[distance] m</span>"

/atom/movable/screen/fullscreen/gauss_scope_vignette
	icon = 'code/modules/antagonists/traitor/contractor/icons/scope_vignette.dmi'
	icon_state = "vignette"

/atom/movable/screen/gauss_scope_visual
	name = "gauss scope"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_hud.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	layer = FULLSCREEN_LAYER
	appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM

/atom/movable/screen/gauss_scope_visual/Initialize(mapload, datum/hud/hud_owner, new_state, stretch_fullscreen = FALSE)
	. = ..()
	if(new_state)
		icon_state = new_state
	if(stretch_fullscreen)
		var/list/view_size = getviewsize(world.view)
		transform = matrix(view_size[1]/FULLSCREEN_OVERLAY_RESOLUTION_X, 0, 0, 0, view_size[2]/FULLSCREEN_OVERLAY_RESOLUTION_Y, 0)
	else
		var/icon/probe = icon(icon, icon_state)
		var/icon_width = probe.Width()
		var/icon_height = probe.Height()
		pixel_x = round((FULLSCREEN_OVERLAY_RESOLUTION_X * ICON_SIZE_X - icon_width) * 0.5)
		pixel_y = round((FULLSCREEN_OVERLAY_RESOLUTION_Y * ICON_SIZE_Y - icon_height) * 0.5)
