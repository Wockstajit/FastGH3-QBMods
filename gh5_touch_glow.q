// GHWT/GH5-style touch-strip lane glow for the static highway.
//
// The animated tap trail is a separate system.  These sprites use the three
// highway_slide materials and are parented to the existing highway geometry,
// just like the reference guitar_highway.q implementation.

// Native gh5Slider.dll writes the current touch-strip lane masks here. Keep
// these globals in this mod so the bridge exists whenever the glow is enabled.
gh5_touch_glow_mask_p1 = 0
gh5_touch_glow_mask_p2 = 0

gh5_touch_glow_props = [
	{
		mat = highway_slide_01
		rot_offset = 1.2
		rgba = [ 0 165 130 255 ]
	}
	{
		mat = highway_slide_02
		rot_offset = 0.5
		rgba = [ 230 80 90 255 ]
	}
	{
		mat = highway_slide_03
		rot_offset = 0.73
		rgba = [ 240 240 0 255 ]
	}
	{
		mat = highway_slide_02
		rot_offset = -0.5
		rgba = [ 0 135 210 255 ]
		flip_v = 1
	}
	{
		mat = highway_slide_01
		rot_offset = -1.2
		rgba = [ 220 160 25 255 ]
		flip_v = 1
	}
]

gh5_touch_glow_ready = [ 0 0 ]
gh5_touch_glow_on = [ 0 0 0 0 0 0 0 0 0 0 ]

// Optional visual test mode: include the frets currently held by either a
// player or the autoplay input handler.  This is deliberately read-only;
// note-hit and slider injection remain in gh5Slider.dll.  Keep it disabled
// for the real touch-strip behavior; set to 1 only for bot/autoplay checks.
gh5_touch_glow_show_held_frets = 0
gh5_touch_glow_fret_mask = 69905 // 0x11111: green|red|yellow|blue|orange

gh5_touch_glow_fade_in_alpha = 0.85
gh5_touch_glow_fade_in_time = 0.0
gh5_touch_glow_fade_out_time = 0.05

script gh5_touch_glow_destroy_player \{ Player = 1 }
	FormatText checksumName = player_status 'player%i_status' i = <Player> AddToStringLookup = true
	FormatText textname = player_text 'p%i' i = <Player> AddToStringLookup = true
	ExtendCrc gem_container ($<player_status>.text) out = container_id

	i = 0
	begin
		Color = ($gem_colors[<i>])
		FormatText checksumName = glow_id '%s_touch_glow%p' s = ($button_up_models.<Color>.name_string) p = <player_text> AddToStringLookup = true
		if ScreenElementExists id = <glow_id>
			DestroyScreenElement id = <glow_id>
		endif
		SetArrayElement ArrayName = gh5_touch_glow_on GlobalArray index = ((<Player> - 1) * 5 + <i>) NewValue = 0
		Increment \{i}
	repeat 5
	SetArrayElement ArrayName = gh5_touch_glow_ready GlobalArray index = (<Player> - 1) NewValue = 0
endscript

script gh5_touch_glow_create_player \{ Player = 1 }
	printf 'GH5 touch glow: create p%i begin' i = <Player>
	gh5_touch_glow_destroy_player Player = <Player>

	FormatText checksumName = player_status 'player%i_status' i = <Player> AddToStringLookup = true
	FormatText textname = player_text 'p%i' i = <Player> AddToStringLookup = true
	ExtendCrc gem_container ($<player_status>.text) out = container_id
	if NOT ScreenElementExists id = <container_id>
		printf 'GH5 touch glow: p%i container missing' i = <Player>
		return
	endif
	printf 'GH5 touch glow: p%i container ready' i = <Player>

	<string_scale> = (($string_scale_x * (1.0, 0.0)) + ($string_scale_y * (0.0, 1.0)))
	i = 0
	begin
		Color = ($gem_colors[<i>])
		printf 'GH5 touch glow: p%i lane %l begin' i = <Player> l = <i>
		FormatText checksumName = glow_id '%s_touch_glow%p' s = ($button_up_models.<Color>.name_string) p = <player_text> AddToStringLookup = true
		if ($<player_status>.lefthanded_button_ups = 1)
			pos = ($button_up_models.<Color>.left_pos_2d)
			angle = ($button_models.<Color>.left_angle)
		else
			pos = ($button_up_models.<Color>.pos_2d)
			angle = ($button_models.<Color>.angle)
		endif

		flip_params = { }
		if StructureContains structure = ($gh5_touch_glow_props[<i>]) Name = flip_v
			flip_params = { flip_v }
		endif
		CreateScreenElement {
			Type = SpriteElement
			parent = <container_id>
			id = <glow_id>
			material = ($gh5_touch_glow_props[<i>].mat)
			rgba = ($gh5_touch_glow_props[<i>].rgba)
			Scale = <string_scale>
			rot_angle = (<angle> + ($gh5_touch_glow_props[<i>].rot_offset))
			Pos = <pos>
			just = [ center bottom ]
			z_priority = 3
			alpha = 0.0
			<flip_params>
		}
		printf 'GH5 touch glow: p%i lane %l created' i = <Player> l = <i>
		Increment \{i}
	repeat 5
	SetArrayElement ArrayName = gh5_touch_glow_ready GlobalArray index = (<Player> - 1) NewValue = 1
	printf 'GH5 touch glow: create p%i complete' i = <Player>
endscript

script gh5_touch_glow_update_player \{ Player = 1 }
	FormatText checksumName = player_status 'player%i_status' i = <Player> AddToStringLookup = true
	FormatText textname = player_text 'p%i' i = <Player> AddToStringLookup = true
	ExtendCrc gem_container ($<player_status>.text) out = container_id
	if NOT ScreenElementExists id = <container_id>
		if ($gh5_touch_glow_ready[(<Player> - 1)] = 1)
			gh5_touch_glow_destroy_player Player = <Player>
		endif
		return
	endif

	if ($gh5_touch_glow_ready[(<Player> - 1)] = 0)
		gh5_touch_glow_create_player Player = <Player>
		return
	endif
	// A highway can be destroyed and recreated between two gameframes while
	// keeping the same container id.  Recreate if the child sprites disappeared
	// so a reload cannot leave a stale ready flag with no visible glow.
	Color = ($gem_colors[0])
	FormatText checksumName = glow_id '%s_touch_glow%p' s = ($button_up_models.<Color>.name_string) p = <player_text> AddToStringLookup = true
	if NOT ScreenElementExists id = <glow_id>
		gh5_touch_glow_create_player Player = <Player>
		return
	endif

	if (<Player> = 1)
		mask = ($gh5_touch_glow_mask_p1)
	else
		mask = ($gh5_touch_glow_mask_p2)
	endif
	if ($gh5_touch_glow_show_held_frets = 1)
		// GetHeldPattern follows player_status.controller, which is switched
		// to the bot input handler for autoplay.  Mask out open-note and other
		// engine-only bits so only the five visible fret lanes can light.
		GetHeldPattern controller = ($<player_status>.controller) nobrokenstring
		held_mask = (<hold_pattern> & $gh5_touch_glow_fret_mask)
		mask = (<mask> | <held_mask>)
	endif

	if ($<player_status>.lefthanded_button_ups = 1)
		lefty = 1
	else
		lefty = 0
	endif

	check_button = 65536
	i = 0
	begin
		on = 0
		if (<mask> & <check_button>)
			on = 1
		endif

		visual_i = <i>
		if (<lefty> = 1)
			visual_i = (4 - <i>)
		endif
		Color = ($gem_colors[<visual_i>])
		state_index = ((<Player> - 1) * 5 + <i>)
		if NOT (<on> = ($gh5_touch_glow_on[<state_index>]))
			FormatText checksumName = glow_id '%s_touch_glow%p' s = ($button_up_models.<Color>.name_string) p = <player_text> AddToStringLookup = true
			if ScreenElementExists id = <glow_id>
				if (<on> = 1)
					DoScreenElementMorph id = <glow_id> alpha = ($gh5_touch_glow_fade_in_alpha) rgba = ($gh5_touch_glow_props[<i>].rgba) time = ($gh5_touch_glow_fade_in_time)
				else
					DoScreenElementMorph id = <glow_id> alpha = 0.0 rgba = ($gh5_touch_glow_props[<i>].rgba) time = ($gh5_touch_glow_fade_out_time)
				endif
			endif
			SetArrayElement ArrayName = gh5_touch_glow_on GlobalArray index = <state_index> NewValue = <on>
		endif
		<check_button> = (<check_button> / 16)
		Increment \{i}
	repeat 5
endscript

script gh5_touch_glow_loop
	begin
		Player = 1
		begin
			gh5_touch_glow_update_player Player = <Player>
			Increment \{Player}
		repeat 2
		wait \{1 gameframe}
	repeat
endscript

script gh5_touch_glow_startup
	printf \{'GH5 touch glow: waiting for highway...'}
	begin
		if ScreenElementExists \{id = gem_containerp1}
			break
		endif
		if ScreenElementExists \{id = gem_containerp2}
			break
		endif
		wait \{1 gameframe}
	repeat
	wait \{30 gameframes}
	gh5_touch_glow_loop
endscript

gh5_touch_glow_mod_info = {
	name = 'GHWT Touch Strip Lane Glow'
	author = 'FastGH3'
	desc = 'Static GHWT-style highway slide streaks for the touch strip'
	version = '2.0'
}
