CoreEnvEditor = CoreEnvEditor or class()

function CoreEnvEditor:create_interface()
	----------------------------------------- hdr_post_processor ----------------------------
		
	------------------------------------------ tone_mapping ---------------------------------
	
	-- We need to add a dummy for the simple interface mix parameter.
	self:add_post_processors_param("hdr_post_processor", "tone_mapping", "$template_mix", DummyWidget:new(""))
	
--	local gui = CustomCheckBox:new(self, self:get_tab("Post Processor"), "Disable Tone Mapping")
--	self:add_post_processors_param("hdr_post_processor", "exposure_sepia_levels", "disable_tone_mapping", gui)
--	self:add_post_processors_param("hdr_post_processor", "bloom_brightpass", "disable_tone_mapping", gui)
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")

--	gui = self:add_post_processors_param("hdr_post_processor", "tone_mapping", "luminance_clamp", Vector2Slider:new(self, self:get_tab("Post Processor"), "Luminance Clamp", nil, nil, 0, 32000, 1000, 32))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")
--	gui = self:add_post_processors_param("hdr_post_processor", "tone_mapping", "white_luminance", SingelSlider:new(self, self:get_tab("Post Processor"), "White Luminance", nil, 0, 32000, 1000, 32))		
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")
	
--	gui = self:add_post_processors_param("hdr_post_processor", "tone_mapping", "dark_to_bright_adaption_speed", SingelSlider:new(self, self:get_tab("Post Processor"), "Dark to Bright Adaption Speed", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")
--	gui = self:add_post_processors_param("hdr_post_processor", "tone_mapping", "bright_to_dark_adaption_speed", SingelSlider:new(self, self:get_tab("Post Processor"), "Bright to Dark Adaption Speed", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")		
	
--	gui = self:add_post_processors_param("hdr_post_processor", "tone_mapping", "middle_grey", SingelSlider:new(self, self:get_tab("Post Processor"), "Middle Grey", nil, 0, 1000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Tone Mapping")
	
	------------------------------------------ bloom_brightpass ---------------------------------		

--	gui = self:add_post_processors_param("hdr_post_processor", "bloom_brightpass", "middle_grey", SingelSlider:new(self, self:get_tab("Post Processor"), "Middle Grey", nil, 0, 1000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Bloom")		
--	gui = self:add_post_processors_param("hdr_post_processor", "bloom_brightpass", "white_luminance", SingelSlider:new(self, self:get_tab("Post Processor"), "White Luminance", nil, 0, 32000, 1000, 32))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Bloom")		
--	gui = self:add_post_processors_param("hdr_post_processor", "bloom_brightpass", "threshold", SingelSlider:new(self, self:get_tab("Post Processor"), "Threshold", nil, 0, 1000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Bloom")			
--	gui = self:add_post_processors_param("hdr_post_processor", "bloom_apply", "opacity", SingelSlider:new(self, self:get_tab("Post Processor"), "Opacity", nil, 0, 1000, 1000, 1000))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Bloom")				

	------------------------------------------- desaturate -----------------------------------		
	
	-- gui = self:add_post_processors_param("hdr_post_processor", "bloom_apply", "luminance_levels", Vector2Slider:new(self, self:get_tab("Post Processor"), "Desaturate Luminance Levels (min/max)", nil, nil, 0, 255, 255, 255))
	-- self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Desaturate")
	-- gui = self:add_post_processors_param("hdr_post_processor", "bloom_apply", "desaturate_clamp", Vector2Slider:new(self, self:get_tab("Post Processor"), "Desaturate Clamp (min/max)", nil, nil, 0, 255, 255, 255))
	-- self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Desaturate")

	------------------------------------------ depth of field ---------------------------------
	
--	gui = self:add_post_processors_param("hdr_post_processor", "dof", "near_focus_distance_max", SingelSlider:new(self, self:get_tab("Post Processor"), "Near Focus Distance", "depth", 0, 10000, 1))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Depth of Field")
--	gui = self:add_post_processors_param("hdr_post_processor", "dof", "near_focus_distance_min", SingelSlider:new(self, self:get_tab("Post Processor"), "Near Blur to Focus Fade Range", "depth", 0, 10000, 1))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Depth of Field")		
--	gui = self:add_post_processors_param("hdr_post_processor", "dof", "far_focus_distance_min", SingelSlider:new(self, self:get_tab("Post Processor"), "Far Focus Distance", "depth", 0, 50000, 1))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Depth of Field")
--	gui = self:add_post_processors_param("hdr_post_processor", "dof", "far_focus_distance_max", SingelSlider:new(self, self:get_tab("Post Processor"), "Far Focus to Blur Fade Range", "depth", 0, 50000, 1))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Depth of Field")
	
	
--	gui = self:add_post_processors_param("hdr_post_processor", "dof", "clamp", SingelSlider:new(self, self:get_tab("Post Processor"), "Clamp", nil, 0, 1000, 1000, 10))
--	self:add_gui_element(gui, "Post Processor", "HDR Post Processor", "Depth of Field")		

	----------------------------------------- fog_processor ----------------------------
		
	------------------------------------------ fog ---------------------------------
	
	local gui = self:add_post_processors_param("fog_processor", "fog", "start_color", EnvEdColorBox:new(self, self:get_tab("Post Processor"), "Color"))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "start_color_scale", SingelSlider:new(self, self:get_tab("Post Processor"), "Color Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "alpha0", SingelSlider:new(self, self:get_tab("Post Processor"), "Alpha Start", nil, 0, 1000, 1000, 10))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "alpha1", SingelSlider:new(self, self:get_tab("Post Processor"), "Alpha End", nil, 0, 1000, 1000, 10))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	--gui = self:add_post_processors_param("fog_processor", "fog", "color0", EnvEdColorBox:new(self, self:get_tab("Post Processor"), "Color0"))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	
	--gui = self:add_post_processors_param("fog_processor", "fog", "color0_scale", SingelSlider:new(self, self:get_tab("Post Processor"), "Color0 Scale", nil, 0, 10000, 1000, 1000))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")

	
	--gui = self:add_post_processors_param("fog_processor", "fog", "color1", EnvEdColorBox:new(self, self:get_tab("Post Processor"), "Color1"))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	--gui = self:add_post_processors_param("fog_processor", "fog", "color1_scale", SingelSlider:new(self, self:get_tab("Post Processor"), "Color1 Scale", nil, 0, 10000, 1000, 1000))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	--gui = self:add_post_processors_param("fog_processor", "fog", "color2", EnvEdColorBox:new(self, self:get_tab("Post Processor"), "Color2"))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	--gui = self:add_post_processors_param("fog_processor", "fog", "color2_scale", SingelSlider:new(self, self:get_tab("Post Processor"), "Color2 Scale", nil, 0, 10000, 1000, 1000))
	--self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "start", SingelSlider:new(self, self:get_tab("Post Processor"), "Start", nil, 0, 1000, 1000, 1000))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "end0", SingelSlider:new(self, self:get_tab("Post Processor"), "End", nil, 0, 1000, 1000, 1000))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	gui = self:add_post_processors_param("fog_processor", "fog", "end1", SingelSlider:new(self, self:get_tab("Post Processor"), "Curve", nil, 0, 1000, 1000, 250))
	self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	-- gui = self:add_post_processors_param("fog_processor", "fog", "end2", SingelSlider:new(self, self:get_tab("Post Processor"), "End2", "depth", 0, 100000, 1))
	-- self:add_gui_element(gui, "Post Processor", "Fog Post Processor")
	
	----------------------------------------- deferred ----------------------------
	------------------------------------------ shadow ---------------------------------
	
	gui = self:add_post_processors_param("deferred", "shadow", "fadeout_blend", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fadeout Blend", nil, 0, 1000, 1000, 10))
	self:add_gui_element(gui, "Global Illumination", "Shadow")

	------------------------------------------ ssao ---------------------------------
	
--	gui = self:add_post_processors_param("deferred", "ssao", "intensity", SingelSlider:new(self, self:get_tab("Global Illumination"), "Intensity", nil, 0, 1000, 1000, 10))
--	self:add_gui_element(gui, "Global Illumination", "SSAO")
	
--	gui = self:add_post_processors_param("deferred", "local_ssao", "intensity", SingelSlider:new(self, self:get_tab("Global Illumination"), "Local SSAO Intensity", nil, 0, 1000, 100, 10))
--	self:add_gui_element(gui, "Global Illumination", "SSAO")
	
--	gui = self:add_post_processors_param("deferred", "global_ssao", "intensity", SingelSlider:new(self, self:get_tab("Global Illumination"), "Global SSAO Intensity", nil, 0, 1000, 100, 10))
--	self:add_gui_element(gui, "Global Illumination", "SSAO")

	------------------------------------------ global lighting ---------------------------------
	-- TEST FOR TOBIAS gui = self:add_sky_param("sun_ray_color_scale", DBDropdown:new(self, self:get_tab("Global Illumination"), "Sun Scale", "LightIntensityDB"))
	
	-- SUN
	gui = self:add_sky_param("sun_ray_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Sun Color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")			
	gui = self:add_sky_param("sun_ray_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Sun Intensity", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")			
	
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sun_specular_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Sun Specular Color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sun_specular_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Sun Specular Color Intensity", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")	
	
	-- FOG
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_start_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Fog start color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_far_low_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Fog far low color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")	
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_far_high_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Fog far high color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")	
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_sun_scatter_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Fog sun scatter color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")	
	
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_sun_range", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fog Sun scatter range", nil, 0, 500000, 1, 1))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_min_range", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fog Min range", nil, 0, 5000, 1, 1))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_max_range", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fog Max range", nil, 0, 500000, 1, 1))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_height_range", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fog height", nil, 0, 500000, 1, 1))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "fog_curve", SingelSlider:new(self, self:get_tab("Global Illumination"), "Fog curve", nil, 0, 1000, 100, 100))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	
	
	-- SKY DOME LIGHT
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_top_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Ambient Top Color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_top_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Ambient Top Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_bottom_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Ambient Bottom Color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_bottom_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Ambient Bottom Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")

	-- AMBIENT
	gui = self:add_post_processors_param("deferred", "apply_ambient", "ambient_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Ambient color"))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")

-- Debug values
	gui = self:add_post_processors_param("deferred", "apply_ambient", "ambient_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Debug A", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	gui = self:add_post_processors_param("deferred", "apply_ambient", "ambient_falloff_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Debug B", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_reflection_top_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Sky Reflection Top Color"))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_reflection_top_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Sky Reflection Top Scale", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_reflection_bottom_color", EnvEdColorBox:new(self, self:get_tab("Global Illumination"), "Sky Reflection Bottom Color"))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "sky_reflection_bottom_color_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Sky Reflection Bottom Scale", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")

--	gui = self:add_post_processors_param("deferred", "apply_ambient", "height_fade", Vector2Slider:new(self, self:get_tab("Global Illumination"), "Height Fade", "height", "height", -25000, 25000, 1))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "height_fade_intesity_clamp", Vector2Slider:new(self, self:get_tab("Global Illumination"), "Height Fade Intesity Clamp", nil, nil, 0, 1000, 1000, 10))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")		

--	gui = self:add_post_processors_param("deferred", "apply_ambient", "environment_map_intensity", SingelSlider:new(self, self:get_tab("Global Illumination"), "Environment Map Multiplier Sun", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")	
--	gui = self:add_post_processors_param("deferred", "apply_ambient", "environment_map_intensity_shadow", SingelSlider:new(self, self:get_tab("Global Illumination"), "Environment Map Multiplier Shadow", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")		
	
-- 	gui = self:add_post_processors_param("deferred", "apply_ambient", "effect_light_scale", SingelSlider:new(self, self:get_tab("Global Illumination"), "Effect Lighting Scale", nil, 0, 10000, 1000, 1000))
--	self:add_gui_element(gui, "Global Illumination", "Global Lighting")
	
	------------------------------------------------------------------------------
	--   O L D   U N D E R L A Y                                                --
	------------------------------------------------------------------------------
	
	local gui = self:add_underlay_param("sun", "sun_color", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Sun Color"))
	self:add_gui_element(gui, "Skydome", "Sun")
	
	gui = self:add_underlay_param("sun", "sun_color_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Sun Color Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Sun")
			
	----------------------------------------- sky ----------------------------
	
	gui = self:add_underlay_param("sky_top", "sky_intensity", SingelSlider:new(self, self:get_tab("Skydome"), "Sky top intensity", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Sky")	
	
	gui = self:add_underlay_param("sky_bottom", "sky_intensity", SingelSlider:new(self, self:get_tab("Skydome"), "Sky bottom intensity", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Sky")	
	
	gui = self:add_underlay_param("sky", "color0", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Color Top"))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_underlay_param("sky", "color0_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Color Top Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_underlay_param("sky", "color1", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Color Mid"))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	-- gui = self:add_underlay_param("sky", "color1_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Color Mid Scale", nil, 0, 10000, 1000, 1000))
	-- self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_underlay_param("sky", "color2", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Color Low"))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_underlay_param("sky", "color2_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Color Low Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Sky")

	----------------------------------------- cloud_overlay ----------------------------
	
	gui = self:add_underlay_param("cloud_overlay", "uv_velocity_rg_mask", Vector2Slider:new(self, self:get_tab("Skydome"), "UV Velocity RG Mask", nil, nil, 0, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "uv_velocity_b_mask", Vector2Slider:new(self, self:get_tab("Skydome"), "UV Velocity B Mask", nil, nil, 0, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "uv_scale_b_mask", SingelSlider:new(self, self:get_tab("Skydome"), "UV Scale B Mask", nil, 0, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "alpha_scale_sun", SingelSlider:new(self, self:get_tab("Skydome"), "Alpha Scale Sun", nil, 0, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "color_opposite_sun", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Color Opposite Sun"))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "color_opposite_sun_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Color Opposite Sun Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "alpha_scale_opposite_sun", SingelSlider:new(self, self:get_tab("Skydome"), "Alpha Scale Opposite Sun", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "color_sun", EnvEdColorBox:new(self, self:get_tab("Skydome"), "Color Sun"))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")
	
	gui = self:add_underlay_param("cloud_overlay", "color_sun_scale", SingelSlider:new(self, self:get_tab("Skydome"), "Color Sun Scale", nil, 0, 10000, 1000, 1000))
	self:add_gui_element(gui, "Skydome", "Cloud Overlay")

	------------------------------------------------------------------------------
	--   O L D   S K Y                                                          --
	------------------------------------------------------------------------------

	local gui = self:add_sky_param("underlay", PathBox:new(self, self:get_tab("Skydome"), "Underlay"))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_sky_param("sun_anim", SingelSlider:new(self, self:get_tab("Skydome"), "Sun Anim Y", nil, 0, 18000, 18000, 100, true))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_sky_param("sun_anim_x", SingelSlider:new(self, self:get_tab("Skydome"), "Sun Anim X", nil, 0, 36000, 36000, 100, true))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	gui = self:add_sky_param("global_texture", DBPickDialog:new(self, self:get_tab("Skydome"), "Global Cubemap", "texture"))
	self:add_gui_element(gui, "Skydome", "Sky")
	
	------------------------------------------------------------------------------
	--   F L A R E                                                              --
	------------------------------------------------------------------------------	

	gui = self:add_sky_param("flare_name", EnvEdEditBox:new(self, self:get_tab("Flare"), "Name"))
	self:add_gui_element(gui, "Flare", "Effect")
	
	gui = self:add_sky_param("flare_color", EnvEdColorBox:new(self, self:get_tab("Flare"), "Color"))
	self:add_gui_element(gui, "Flare", "Effect")
	
	gui = self:add_sky_param("flare_anim_y", SingelSlider:new(self, self:get_tab("Flare"), "Anim Y", nil, 0, 18000, 18000, 100))
	self:add_gui_element(gui, "Flare", "Effect")
	
	gui = self:add_sky_param("flare_anim_x", SingelSlider:new(self, self:get_tab("Flare"), "Anim X", nil, 0, 36000, 36000, 100))
	self:add_gui_element(gui, "Flare", "Effect")
	
	for i = 1, 8 do --managers.environment:num_flare_slices() do
		local num_str = tostring(i)

		gui = self:add_sky_param("flare_index_" .. num_str, SingelSlider:new(self, self:get_tab("Flare"), "Index", nil, 1, 4, 1, 1))
		self:add_gui_element(gui, "Flare", "Plane " .. num_str)
			
		gui = self:add_sky_param("flare_offset_" .. num_str, SingelSlider:new(self, self:get_tab("Flare"), "Offset", nil, -15000, 15000, 1000, 1000))
		self:add_gui_element(gui, "Flare", "Plane " .. num_str)
		
		gui = self:add_sky_param("flare_scale_" .. num_str, SingelSlider:new(self, self:get_tab("Flare"), "Scale", nil, 0, 10000, 1000, 1000))
		self:add_gui_element(gui, "Flare", "Plane " .. num_str)
		
		gui = self:add_sky_param("flare_alpha_" .. num_str, SingelSlider:new(self, self:get_tab("Flare"), "Alpha", nil, 0, 1000, 1000, 1000))
		self:add_gui_element(gui, "Flare", "Plane " .. num_str)
	end
end

function CoreEnvEditor:create_simple_interface()
	
end
