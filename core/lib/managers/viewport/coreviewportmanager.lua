core:module( "CoreViewportManager" )

core:import( "CoreApp" )
core:import( "CoreCode" )
core:import( "CoreEvent" )
core:import( "CoreManagerBase" )
core:import( "CoreScriptViewport" )
core:import( "CoreEnvironmentCache" )

ViewportManager = ViewportManager or class(CoreManagerBase.ManagerBase)

----------------------------------------------------------------------------
--    S E T U P
----------------------------------------------------------------------------
	
function ViewportManager:init( aspect_ratio )
	ViewportManager.super.init( self, 'viewport' )
	assert(type(aspect_ratio) == 'number')
	self._aspect_ratio = aspect_ratio
	self._resolution_changed_event_handler = CoreEvent.CallbackEventHandler:new()
	self._environment_cache = CoreEnvironmentCache.EnvironmentCache:new()
	Global.render_debug.render_sky = true -- Not sure about this...
	
	self._current_camera_position = Vector3()
end

function ViewportManager:update( t, dt )
	for i,svp in ipairs( self:_all_really_active() ) do
		svp:_update( i, t, dt )
	end
end

function ViewportManager:paused_update( t, dt )
	self:update( t, dt )
end

function ViewportManager:render()
	for i,svp in ipairs( self:_all_really_active() ) do
		svp:_render(i)
	end
end

function ViewportManager:end_frame( t, dt )
	if( self._render_settings_change_map ) then
		local is_resolution_changed = ( self._render_settings_change_map.resolution ~= nil )

		for setting_name, setting_value in pairs( self._render_settings_change_map ) do
			RenderSettings[ setting_name ] = setting_value
		end
		
		self._render_settings_change_map = nil

		Application:apply_render_settings()
		Application:save_render_settings()

		if( is_resolution_changed ) then
			self:resolution_changed()
		end
	end
	self._current_camera = nil
	-- self._current_camera_position = nil
	self._current_camera_position_updated = nil
	self._current_camera_rotation = nil
end

function ViewportManager:destroy()
	for _,svp in pairs( self:_all_ao() ) do
		svp:destroy()
	end
end

----------------------------------------------------------------------------
--    P U B L I C
----------------------------------------------------------------------------

function ViewportManager:new_vp(x, y, width, height, name, priority)
	local name = name or ''
	local prio = priority or CoreManagerBase.PRIO_DEFAULT
	local svp = CoreScriptViewport._ScriptViewport:new(x, y, width, height, self, name)
	self:_add_accessobj(svp, prio)
	return svp
end

function ViewportManager:vp_by_name( name )
	return self:_ao_by_name(name)
end

function ViewportManager:active_viewports()
	return self:_all_active_requested_by_prio(CoreManagerBase.PRIO_DEFAULT)
end

function ViewportManager:all_really_active_viewports()
	return self:_all_really_active()
end

function ViewportManager:num_active_viewports()
	return #self:active_viewports()
end

function ViewportManager:first_active_viewport()
	local all_active = self:_all_really_active()
	return #all_active > 0 and all_active[1] or nil
end

function ViewportManager:viewports()
	return self:_all_ao()
end

function ViewportManager:add_resolution_changed_func( func )
	self._resolution_changed_event_handler:add( func )
	return func
end

function ViewportManager:remove_resolution_changed_func( func )
	self._resolution_changed_event_handler:remove( func )
end

function ViewportManager:resolution_changed()
	managers.gui_data:resolution_changed() -- Need to update workspace values first, PD2
	-- managers.menu:_setup_workspace_data() -- Need to update workspace values first, PD2
	-- This is a hijack hack to update all scale and font sizes if the resolution changes between "high" and "low" /Martin
	if rawget( _G, "tweak_data" ).resolution_changed then
		rawget( _G, "tweak_data" ):resolution_changed()
	end
	for i,svp in ipairs( self:viewports() ) do
		svp:_resolution_changed(i)
	end
	self._resolution_changed_event_handler:dispatch()
end

function ViewportManager:preload_environment( name )
	self._environment_cache:preload_environment( name )
end

function ViewportManager:get_environment_cache()
	return self._environment_cache
end


----------------------------------------------------------------------------
--    C O R E   I N T E R N A L
----------------------------------------------------------------------------

function ViewportManager:_viewport_destroyed( vp )
	self:_del_accessobj(vp)
end

function ViewportManager:_get_environment_cache()
	return self._environment_cache
end

----------------------------------------------------------------------------
--    D E P R E C A T E D
----------------------------------------------------------------------------

function ViewportManager:first_active_world_viewport()
	for _,vp in ipairs( self:active_viewports() ) do
		if vp:is_rendering_scene( "World" ) then
			return vp
		end
	end
end

function ViewportManager:get_current_camera()
	if self._current_camera then -- Current camera is niled at the end of each frame
		return self._current_camera
	end
	
	local vps = self:_all_really_active()
	self._current_camera = #vps > 0 and vps[ 1 ]:camera()
	return self._current_camera
end

function ViewportManager:get_current_camera_position()
	if self._current_camera_position_updated then
		return self._current_camera_position
	end
		
	if self:get_current_camera() then
		self:get_current_camera():m_position( self._current_camera_position )
		self._current_camera_position_updated = true
	end
	return self._current_camera_position
end

function ViewportManager:get_current_camera_rotation()
	if self._current_camera_rotation then
		return self._current_camera_rotation
	end
	
	self._current_camera_rotation = self:get_current_camera() and self:get_current_camera():rotation()
	return self._current_camera_rotation
end

function ViewportManager:get_active_vp()
	return self:active_vp():vp()
end

function ViewportManager:active_vp()
	local vps = self:active_viewports()
	return #vps > 0 and vps[ 1 ]
end

local is_win32 = SystemInfo:platform() == Idstring( "WIN32" )
function ViewportManager:get_safe_rect()
	-- local a = 0.075
	local a = is_win32 and 0.032 or 0.075
	local b = 1 - a * 2
	return { x = a, y = a, width = b, height = b }
end

function ViewportManager:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	local safe_rect_scale = self:get_safe_rect()
	local safe_rect_pixels = {}

	safe_rect_pixels.x = math.round( safe_rect_scale.x * res.x )
	safe_rect_pixels.y = math.round( safe_rect_scale.y * res.y )
	safe_rect_pixels.width = math.round( safe_rect_scale.width * res.x )
	safe_rect_pixels.height = math.round( safe_rect_scale.height * res.y )

	return safe_rect_pixels
end

function ViewportManager:set_resolution( resolution )
	if( ( RenderSettings.resolution ~= resolution ) or ( self._render_settings_change_map and ( self._render_settings_change_map.resolution ~= resolution ) ) ) then
		self._render_settings_change_map = self._render_settings_change_map or {}
		self._render_settings_change_map.resolution = resolution
	end
end

function ViewportManager:set_fullscreen( fullscreen )
	if( ( not RenderSettings.fullscreen ~= not fullscreen ) or ( self._render_settings_change_map and ( not self._render_settings_change_map.fullscreen ~= not fullscreen ) ) ) then
		self._render_settings_change_map = self._render_settings_change_map or {}
		self._render_settings_change_map.fullscreen = not not fullscreen
	end
end

function ViewportManager:set_aspect_ratio( aspect_ratio )
	if( ( RenderSettings.aspect_ratio ~= aspect_ratio ) or ( self._render_settings_change_map and ( self._render_settings_change_map.aspect_ratio ~= aspect_ratio ) ) ) then
		self._render_settings_change_map = self._render_settings_change_map or {}
		self._render_settings_change_map.aspect_ratio = aspect_ratio
		self._aspect_ratio = aspect_ratio
	end
end

function ViewportManager:set_vsync( vsync )
	if( ( RenderSettings.v_sync ~= vsync ) or ( self._render_settings_change_map and ( self._render_settings_change_map.v_sync ~= vsync ) ) ) then
		self._render_settings_change_map = self._render_settings_change_map or {}
		self._render_settings_change_map.v_sync = vsync
		self._v_sync = vsync
	end
end


-- NOTE: THIS IS A TEMPORARY SOLUTION FOR THE ASPECT RATIO
-- UNTIL ANDREAS J. HAS FIXED IT! BETTER NOT TOUCH!
function ViewportManager:aspect_ratio()
	return self._aspect_ratio
end

function ViewportManager:set_aspect_ratio2(aspect_ratio)
	self._aspect_ratio = aspect_ratio
end
