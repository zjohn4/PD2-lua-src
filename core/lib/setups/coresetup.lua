--[[ THIS IS TEST

C o r e S e t u p
-----------------

CoreSetup is a baseclass that Gameplay must override. It provides the
basic callbacks hooks from the Engine for updates, load, save, etc.

]]--

core:import( "CoreClass" )
core:import( "CoreEngineAccess" )
core:import( "CoreLocalizationManager" )
core:import( "CoreNewsReportManager" )
core:import( "CoreSubtitleManager" )
core:import( "CoreViewportManager" )
core:import( "CoreSequenceManager" )
core:import( "CoreMissionManager" )
core:import( "CoreControllerManager" )
core:import( "CoreListenerManager" )
core:import( "CoreSlotManager" )
core:import( "CoreCameraManager" )
core:import( "CoreExpressionManager" )
core:import( "CoreShapeManager" )
core:import( "CorePortalManager" )
core:import( "CoreDOFManager" )
core:import( "CoreRumbleManager" )
core:import( "CoreOverlayEffectManager" )
core:import( "CoreSessionManager" )
core:import( "CoreInputManager" )
core:import( "CoreGTextureManager" )
core:import( "CoreSmoketestManager" )
core:import( "CoreEnvironmentAreaManager" )
core:import( "CoreEnvironmentEffectsManager" )
core:import( 'CoreSlaveManager' )
core:import( "CoreHelperUnitManager" )

require "core/lib/managers/cutscene/CoreCutsceneManager"
require "core/lib/managers/CoreWorldCameraManager"
require "core/lib/managers/CoreSoundEnvironmentManager"
require "core/lib/managers/CoreMusicManager"
require "core/lib/utils/dev/editor/WorldHolder"
require "core/lib/managers/CoreEnvironmentControllerManager"

-- Core Unit Extensions (they need to be on global namespace...)
require "core/lib/units/CoreSpawnSystem"
require "core/lib/units/CoreUnitDamage"
require "core/lib/units/CoreEditableGui"
require "core/lib/units/data/CoreScriptUnitData"
require "core/lib/units/data/CoreWireData"
require "core/lib/units/data/CoreCutsceneData"

if Application:ews_enabled() then
	core:import("CoreLuaProfilerViewer")
	core:import("CoreDatabaseManager")
	core:import("CoreToolHub")
	core:import("CoreInteractionEditor")
	core:import( "CoreInteractionEditorConfig" )
	require "core/lib/utils/dev/tools/CoreUnitReloader"
	require "core/lib/utils/dev/tools/CoreUnitTestBrowser"
	require "core/lib/utils/dev/tools/CoreEnvEditor"
	require "core/lib/utils/dev/tools/CoreDatabaseBrowser"
	require "core/lib/utils/dev/tools/CoreLuaProfiler"
	require "core/lib/utils/dev/tools/CoreXMLEditor"
	require "core/lib/utils/dev/ews/CoreEWSDeprecated"
	require "core/lib/utils/dev/tools/CorePuppeteer"
	require "core/lib/utils/dev/tools/material_editor/CoreMaterialEditor"
	require "core/lib/utils/dev/tools/particle_editor/CoreParticleEditor"
	require "core/lib/utils/dev/tools/cutscene_editor/CoreCutsceneEditor"
end

if Application:production_build() then
	-- core:import("CoreDatabaseManager")
	core:import( "CoreDebugManager" )
	core:import( "CorePrefHud" )
end

if Global.DEBUG_MENU_ON or Application:production_build() then
	core:import( "CoreFreeFlight" )
end

if Application:editor() then
	require "core/lib/utils/dev/editor/CoreEditor"
end


-- ==================================================================
-- Class: C o r e S e t u p
--
-- ==================================================================

CoreSetup = CoreSetup or class()
local _CoreSetup = CoreSetup -- This is a HACK we can move this class into the module system...

-- ------------------------------------------------------------------
-- Functions to Override by Gameplay.
--
-- Please Note:
-- We the core team will do our very best to ensure that these
-- methods are kept with backward-compatibility between releases;
-- they are considered part of our system interface to GamePlay.
--
-- In this class there are also some methods starting with double 
-- underscore (__method). Those are considered to be completely
-- core internal. We reserve the right to modify those at any time
-- and without any notice. So if you decide to override those you
-- might be in for a rocky ride, be advised :-)
-- ------------------------------------------------------------------

function CoreSetup:init()  -- Note: This is the init of the class, see init_game for the 'normal' init.
	CoreClass.close_override()
	self.__quit = false
	self.__exec = false
	self.__context = nil
	self.__firstupdate = true
end

function CoreSetup:init_category_print()
end

function CoreSetup:load_packages()
end

function CoreSetup:unload_packages()
end

function CoreSetup:start_boot_loading_screen()
end

function CoreSetup:init_managers( managers )
end

function CoreSetup:init_toolhub( toolhub )
end

function CoreSetup:init_game()
end

function CoreSetup:init_finalize()
end

function CoreSetup:start_loading_screen()
end

function CoreSetup:stop_loading_screen()
end

function CoreSetup:update( t, dt ) 		
end

function CoreSetup:paused_update( t, dt ) 
end

function CoreSetup:render()
end

function CoreSetup:end_frame( t, dt )
end

function CoreSetup:end_update( t, dt )
end

function CoreSetup:paused_end_update( t, dt )
end

function CoreSetup:save( data )
end

function CoreSetup:load( data )
end

function CoreSetup:destroy()
end

-- ------------------------------------------------------------------
-- Other Public Methods:
-- ------------------------------------------------------------------

function CoreSetup:freeflight()
	return self.__freeflight
end

-- ------------------------------------------------------------------
--  Methods for Execution Control:
-- ------------------------------------------------------------------

function CoreSetup:exec( context )
	self.__exec = true
	self.__context = context
end

function CoreSetup:quit()
	if not Application:editor() then
		self.__quit = true
	end
end

function CoreSetup:block_exec()
	return false
end

function CoreSetup:block_quit()
	return false
end

-- ------------------------------------------------------------------
-- Entry Point Methods:
-- ------------------------------------------------------------------

function CoreSetup:__pre_init()
	-- Aspects ratio and resolutio will be changes in the EVT_SIZE event of the application window
	-- Only sets it up here to get started.
	if Application:editor() then  -- not really needed, because pre_init only called in editor mode.
		managers.global_texture = CoreGTextureManager.GTextureManager:new()

		local frame_resolution = SystemInfo:desktop_resolution()
		local appwin_resolution = Vector3( frame_resolution.x*0.75, frame_resolution.y*0.75, 0)

		local frame = EWS:Frame( "World Editor", Vector3(0, 0, 0), frame_resolution, "CAPTION,CLOSE_BOX,MINIMIZE_BOX,MAXIMIZE_BOX,MAXIMIZE,SYSTEM_MENU,RESIZE_BORDER" )
		frame:set_icon(CoreEWS.image_path("world_editor_16x16.png"))
		local frame_panel = EWS:Panel( frame, "", "" )
		local appwin = EWS:AppWindow( frame_panel, appwin_resolution, "SUNKEN_BORDER" )
		appwin:set_max_size( Vector3( -1, -1, 0) )
		-- frame:set_max_size(Vector3(1280, 1024,0))
		appwin:connect( "EVT_LEAVE_WINDOW", callback( nil, _G, "leaving_window" ) )
		appwin:connect( "EVT_ENTER_WINDOW", callback( nil, _G, "entering_window" ) )
		appwin:connect( "EVT_KILL_FOCUS", callback( nil, _G, "kill_focus" ) )
		Application:set_ews_window(appwin )
		
		local top_sizer = EWS:BoxSizer( "VERTICAL" )

		-- local icon_menu_panel = EWS:Panel( frame_panel, "", "" )	
		-- local icon_menu_sizer = EWS:BoxSizer( "HORIZONTAL" )
		-- icon_menu_panel:set_sizer( icon_menu_sizer )	
		
		--	top_sizer:add( icon_menu_sizer, 0, 0, "EXPAND" )
		
			local main_sizer = EWS:BoxSizer( "HORIZONTAL" )
		
				local left_toolbar_sizer = EWS:BoxSizer( "VERTICAL" )
				main_sizer:add( left_toolbar_sizer, 0, 0, "EXPAND" )	
		
				local app_sizer = EWS:BoxSizer( "VERTICAL" )
				main_sizer:add( app_sizer, 4, 0, "EXPAND" )
				app_sizer:add( appwin, 5, 0, "EXPAND" )
		
			top_sizer:add( main_sizer, 1, 0, "EXPAND" )
		
		frame_panel:set_sizer( top_sizer )
		
		Global.main_sizer = main_sizer
		Global.v_sizer = app_sizer
		Global.frame = frame
		Global.frame_panel = frame_panel
		Global.application_window = appwin
--	Global.icon_menu_panel = icon_menu_panel
--	Global.icon_menu_sizer = icon_menu_sizer
		Global.left_toolbar_sizer = left_toolbar_sizer
	end
end

function CoreSetup:__init()
	self:init_category_print()
	
	if not PackageManager:loaded( "core/packages/base" ) then
		PackageManager:load( "core/packages/base" )
	end

	if Application:ews_enabled() and not PackageManager:loaded("core/packages/editor") then
		PackageManager:load("core/packages/editor")
	end

	if( Application:production_build() and not PackageManager:loaded( "core/packages/debug" ) ) then
		PackageManager:load( "core/packages/debug" )
	end
	
	-- Just a quick hack to be able to use this in the load_packages() func
	managers.global_texture      = managers.global_texture or CoreGTextureManager.GTextureManager:new()

	if not Global.__coresetup_bootdone then
		self:start_boot_loading_screen()
		Global.__coresetup_bootdone = true
	end

	self:load_packages()

	World:set_raycast_bounds(Vector3( -50000, -80000, -20000 ), Vector3(90000, 50000, 30000))
	World:load(Application:editor() and "core/levels/editor/editor" or "core/levels/zone")

	min_exe_version("1.0.0.7000", "Core Systems")  -- The minimum exe version required for basic use of the Core. (Change this if needed.)

	rawset( _G, "UnitDamage", rawget( _G, "UnitDamage" ) or CoreUnitDamage ) -- How do we want to handle that a core based unit might want to use a heritance as extension?
	rawset( _G, "EditableGui", rawget( _G, "EditableGui" ) or CoreEditableGui )
	
	local aspect_ratio
	if Application:editor() then
		local frame_resolution = SystemInfo:desktop_resolution()
		aspect_ratio = frame_resolution.x/frame_resolution.y
	else
		if( SystemInfo:platform() == Idstring("WIN32") ) then
			aspect_ratio = RenderSettings.aspect_ratio
			if aspect_ratio == 0 then
				aspect_ratio = RenderSettings.resolution.x / RenderSettings.resolution.y
			end
		elseif SystemInfo:platform() == Idstring("X360") or SystemInfo:platform() == Idstring("PS3") and SystemInfo:widescreen() then
			aspect_ratio = RenderSettings.resolution.x / RenderSettings.resolution.y -- 16/9
		else
			aspect_ratio = RenderSettings.resolution.x / RenderSettings.resolution.y -- 4/3
		end
	end

	if Application:ews_enabled() then
		-- Other managers might need the database, so this goes first.
		managers.database = CoreDatabaseManager.DatabaseManager:new()
	end

	--[[if not Global.__coresetup_bootdone then
		self:start_boot_loading_screen()
		Global.__coresetup_bootdone = true
	end]]

	managers.localization        = CoreLocalizationManager.LocalizationManager:new()
	managers.controller          = CoreControllerManager.ControllerManager:new()
	managers.slot                = CoreSlotManager.SlotManager:new()
	managers.listener            = CoreListenerManager.ListenerManager:new()
	managers.viewport            = CoreViewportManager.ViewportManager:new(aspect_ratio)
	managers.mission 			 = CoreMissionManager.MissionManager:new()
	managers.expression          = CoreExpressionManager.ExpressionManager:new()
	managers.worldcamera         = CoreWorldCameraManager:new()
	managers.environment_effects = CoreEnvironmentEffectsManager.EnvironmentEffectsManager:new()
	managers.shape               = CoreShapeManager.ShapeManager:new()
	managers.portal              = CorePortalManager.PortalManager:new()
	managers.sound_environment   = CoreSoundEnvironmentManager:new()
	managers.environment_area    = CoreEnvironmentAreaManager.EnvironmentAreaManager:new()
	managers.cutscene            = CoreCutsceneManager:new()
	managers.rumble              = CoreRumbleManager.RumbleManager:new()
	managers.DOF                 = CoreDOFManager.DOFManager:new()
	managers.subtitle            = CoreSubtitleManager.SubtitleManager:new()
	managers.overlay_effect      = CoreOverlayEffectManager.OverlayEffectManager:new()
	managers.sequence            = CoreSequenceManager.SequenceManager:new()
	managers.camera              = CoreCameraManager.CameraTemplateManager:new()
	managers.slave               = CoreSlaveManager.SlaveManager:new()
	managers.music               = CoreMusicManager:new()
	managers.environment_controller	= CoreEnvironmentControllerManager:new()
	managers.helper_unit         = CoreHelperUnitManager.HelperUnitManager:new()
	self._input					 = CoreInputManager.InputManager:new()
	self._session				 = CoreSessionManager.SessionManager:new(self.session_factory, self._input)
	self._smoketest              = CoreSmoketestManager.Manager:new(self._session:session())
	
	
	managers.sequence:internal_load()

	if Application:production_build() then
		managers.prefhud = CorePrefHud.PrefHud:new()
		managers.debug   = CoreDebugManager.DebugManager:new()
		rawset( _G, "d", managers.debug )
	end

	self:init_managers( managers )
	
	if Application:ews_enabled() then
		managers.news = CoreNewsReportManager.NewsReportManager:new()
		managers.toolhub = CoreToolHub.ToolHub:new()
		managers.toolhub:add( "Environment Editor"         ,      CoreEnvEditor )
		-- managers.toolhub:add( CoreLuaProfilerViewer.TOOLHUB_NAME, CoreLuaProfilerViewer.LuaProfilerViewer ) Until it is fixed on the C side.
		managers.toolhub:add( CoreMaterialEditor.TOOLHUB_NAME,    CoreMaterialEditor )
		managers.toolhub:add( "LUA Profiler",                     CoreLuaProfiler )
		managers.toolhub:add( "Particle Editor",                  CoreParticleEditor )
		managers.toolhub:add( CorePuppeteer.EDITOR_TITLE,         CorePuppeteer )
		managers.toolhub:add( CoreCutsceneEditor.EDITOR_TITLE,    CoreCutsceneEditor )
		-- managers.toolhub:add( CoreInteractionEditorConfig.EDITOR_TITLE,    CoreInteractionEditor.InteractionEditor )

		if not Application:editor() then 
			managers.toolhub:add( "Unit Reloader", CoreUnitReloader ) 
		end

		self:init_toolhub( managers.toolhub )

		managers.toolhub:buildmenu()
	end

	self.__gsm = assert(self:init_game(), "self:init_game must return a GameStateMachine.")

	if Global.DEBUG_MENU_ON or Application:production_build() then
		self.__freeflight = CoreFreeFlight.FreeFlight:new( self.__gsm, managers.viewport, managers.controller )
	end

	if Application:editor() then
		managers.editor = (rawget(_G, "WorldEditor") or rawget(_G, "CoreEditor")):new(self.__gsm, self._session	:session())
		managers.editor:toggle()
	end

	managers.cutscene:post_init()
	self._smoketest:post_init()
	
	if not Application:editor() then
		PackageManager:unload_lua()	-- discards all lua source files from memory
	end
	
	self:init_finalize()
end

function CoreSetup:__destroy()
	self:destroy()
	self.__gsm:destroy()
	managers.global_texture:destroy()
	managers.cutscene:destroy()
	managers.subtitle:destroy()
	managers.viewport:destroy()
	managers.worldcamera:destroy()
	managers.overlay_effect:destroy()
	
	if Application:ews_enabled() then
		managers.toolhub:destroy()
	end
	
	if Application:production_build() then
		managers.prefhud:destroy()
		managers.debug:destroy()
	end

	if Application:editor() then 
		managers.editor:destroy()
	end
	
	self._session:destroy()
	self._input:destroy()
	self._smoketest:destroy()
	
end

function CoreSetup:loading_update(t, dt)
end

function CoreSetup:__update( t, dt )
	-- local w_id = Profiler:start( "__update" )

	if self.__firstupdate then
		self:stop_loading_screen()
		self.__firstupdate = false
	end
	
	-- local id = Profiler:start( "controller" )
	managers.controller:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "cutscene" )
	managers.cutscene:update()  -- The cutscene system has its own timer, see cutscene:set_timer(timer)
	-- Profiler:stop( id )
	-- local id = Profiler:start( "sequence" )
	managers.sequence:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "worldcamera" )
	managers.worldcamera:update( t, dt)
	-- Profiler:stop( id )
	-- local id = Profiler:start( "environment_effects" )
	managers.environment_effects:update( t, dt)
	-- Profiler:stop( id )
	-- local id = Profiler:start( "sound_environment" )
	managers.sound_environment:update( t, dt)
	-- Profiler:stop( id )
	-- local id = Profiler:start( "environment_area" )
	managers.environment_area:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "expression" )
	managers.expression:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "global_texture" )
	managers.global_texture:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "subtitle" )
	managers.subtitle:update( TimerManager:game_animation():time(), TimerManager:game_animation():delta_time() )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "overlay_effect" )
	managers.overlay_effect:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "viewport" )
	managers.viewport:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "mission" )
	managers.mission:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "slave" )
	managers.slave:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "_session" )
	self._session:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "_input" )
	self._input:update( t, dt )
	-- Profiler:stop( id )
	-- local id = Profiler:start( "_smoketest" )
	self._smoketest:update( t, dt )
	-- Profiler:stop( id )
	
	-- local id = Profiler:start( "environment_controller" )
	managers.environment_controller:update( t, dt )
	-- Profiler:stop( id )
	
	if Application:production_build() then
		managers.prefhud:update( t, dt )
		managers.debug:update( TimerManager:wall():time(), TimerManager:wall():delta_time() )
	end
	if Global.DEBUG_MENU_ON or Application:production_build() then
		self.__freeflight:update( t, dt )
	end
	if Application:ews_enabled() then
		managers.toolhub:update( t, dt )
	end
	
	if Application:editor() then 
		managers.editor:update( t, dt )
	end

	-- Profiler:stop( w_id )
	self:update( t, dt )
end

function CoreSetup:__paused_update( t, dt )
	managers.viewport:paused_update( t, dt )
	managers.controller:paused_update( t, dt )
	managers.cutscene:paused_update( t, dt )
	managers.overlay_effect:paused_update( t, dt )
	managers.global_texture:paused_update( t, dt )
	managers.slave:paused_update( t, dt )
	self._session:update( t, dt )
	self._input:update( t ,dt )
	self._smoketest:update( t, dt )

	if Application:production_build() then
		managers.debug:paused_update( TimerManager:wall():time(), TimerManager:wall():delta_time() )
	end
	
	if Global.DEBUG_MENU_ON or Application:production_build() then
		self.__freeflight:update( t, dt )
	end
	
	if Application:ews_enabled() then
		managers.toolhub:paused_update( t, dt )
	end
	
	if Application:editor() then
		managers.editor:update( t, dt )
	end

	self:paused_update( t, dt )
end

function CoreSetup:__end_update( t, dt )
	managers.camera:update( t, dt )
	self._session:end_update( t, dt )
	
	self:end_update( t, dt )
	self.__gsm:end_update( t, dt )
	managers.viewport:end_update( t, dt )
	managers.controller:end_update( t, dt )
	managers.DOF:update( t, dt )

	if Application:ews_enabled() then
		managers.toolhub:end_update( t, dt )
	end
end

function CoreSetup:__paused_end_update( t, dt )
	self:paused_end_update( t, dt ) 

	self.__gsm:end_update( t, dt )
	managers.DOF:paused_update( t, dt )
end

function CoreSetup:__render()
	managers.portal:render()
	managers.viewport:render()
	managers.overlay_effect:render()
	self:render()
end

function CoreSetup:__end_frame( t, dt )
	self:end_frame( t, dt )
	
	managers.viewport:end_frame( t, dt )

	if self.__quit then
		if( not self:block_quit() ) then
			CoreEngineAccess._quit()
		end
	elseif self.__exec and not self:block_exec() then
		if managers.network and managers.network:session() then
			managers.network:save()
		end
		
		if managers.mission then
			managers.mission:destroy()
		end
		if managers.menu_scene then
			managers.menu_scene:pre_unload()
		end
		World:unload_all_units()
		if managers.menu_scene then
			managers.menu_scene:unload()
		end
		if managers.worlddefinition then
			managers.worlddefinition:flush_remaining_lights_textures()
		end
		if managers.blackmarket then
			managers.blackmarket:release_preloaded_blueprints()
		end
		if managers.dyn_resource and not managers.dyn_resource:is_ready_to_close() then -- items can have been added during World:unload_all_units()
			Application:cleanup_thread_garbage()
			managers.dyn_resource:update()
		end
		
		if managers.sound_environment then
			managers.sound_environment:destroy()
		end
		self:start_loading_screen() -- we cannot call World:unload_all_units() during the loading environment. it can crash due to thread-unsafe functions 
		managers.music:stop()
		SoundDevice:stop()
		if managers.worlddefinition then
			managers.worlddefinition:unload_packages()
		end
		self:unload_packages()
		managers.menu:destroy()
		Overlay:newgui():destroy_all_workspaces()
		Application:cleanup_thread_garbage()
		PackageManager:reload_lua()
		managers.music:post_event( "loadout_music" )
		CoreEngineAccess._exec( "core/lib/CoreEntry", self.__context )
	end
end

function CoreSetup:__loading_update(t, dt)
	self._session:update(t, dt)
	self:loading_update()
end

function CoreSetup:__animations_reloaded()
end

function CoreSetup:__script_reloaded()
end

function CoreSetup:__entering_window(user_data, event_object)
	if Global.frame:is_active() then
		Global.application_window:set_focus()
		Input:keyboard():acquire()
	end
end

function CoreSetup:__leaving_window(user_data, event_object)
	if managers.editor._in_mixed_input_mode then -- Safety check, the the controller can be disabled when it shouldn't. This might fix that.
		Input:keyboard():unacquire()
	end
end

function CoreSetup:__kill_focus( user_data, event_object )
	if managers.editor and not managers.editor:in_mixed_input_mode() and not Global.running_simulation then
		managers.editor:set_in_mixed_input_mode( true )
	end
end

function CoreSetup:__save( data )
	self:save( data )
end

function CoreSetup:__load( data )
	self:load( data )
end

-- ==================================================================
-- Make Entrypoint...
-- ==================================================================

core:module( 'CoreSetup' )

CoreSetup = _CoreSetup  -- This is a HACK we can move this class into the module system...

function CoreSetup:make_entrypoint()
	if( not _G.CoreSetup.__entrypoint_is_setup ) then
		assert( nil == rawget( _G, 'pre_init' ) )
		assert( nil == rawget( _G, 'init' ) )
		assert( nil == rawget( _G, 'destroy' ) )
		assert( nil == rawget( _G, 'update' ) )
		assert( nil == rawget( _G, 'end_update' ) )
		assert( nil == rawget( _G, 'paused_update' ) )
		assert( nil == rawget( _G, 'paused_end_update' ) )
		assert( nil == rawget( _G, 'render' ) )
		assert( nil == rawget( _G, 'end_frame' ) )
		assert( nil == rawget( _G, 'animations_reloaded' ) )
		assert( nil == rawget( _G, 'script_reloaded' ) )
		assert( nil == rawget( _G, 'entering_window' ) )
		assert( nil == rawget( _G, 'leaving_window' ) )
		assert( nil == rawget( _G, 'kill_focus' ) )
		assert( nil == rawget( _G, 'save' ) )
		assert( nil == rawget( _G, 'load' ) )
		_G.CoreSetup.__entrypoint_is_setup = true
	end

	rawset( _G, 'pre_init',            callback( self, self, '__pre_init' ) )
	rawset( _G, 'init',                callback( self, self, '__init' ) )
	rawset( _G, 'destroy',             callback( self, self, '__destroy' ) )
	rawset( _G, 'update',              callback( self, self, '__update' ) )
	rawset( _G, 'end_update',          callback( self, self, '__end_update' ) )
	rawset( _G, 'loading_update',      callback( self, self, '__loading_update' ) )
	rawset( _G, 'paused_update',       callback( self, self, '__paused_update' ) )
	rawset( _G, 'paused_end_update',   callback( self, self, '__paused_end_update' ) )
	rawset( _G, 'render',              callback( self, self, '__render' ) )
	rawset( _G, 'end_frame',           callback( self, self, '__end_frame' ) )
	rawset( _G, 'animations_reloaded', callback( self, self, '__animations_reloaded' ) )
	rawset( _G, 'script_reloaded',     callback( self, self, '__script_reloaded' ) )
	rawset( _G, 'entering_window',     callback( self, self, '__entering_window' ) )
	rawset( _G, 'leaving_window',      callback( self, self, '__leaving_window' ) )
	rawset( _G, 'kill_focus',          callback( self, self, '__kill_focus' ) )
	rawset( _G, 'save',                callback( self, self, '__save' ) )
	rawset( _G, 'load',                callback( self, self, '__load' ) )
end
