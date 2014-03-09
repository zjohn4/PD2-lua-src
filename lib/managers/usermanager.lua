core:module( "UserManager" )

core:import( "CoreEvent" )
core:import( "CoreTable" )

UserManager = UserManager or class()
UserManager.PLATFORM_CLASS_MAP = {}

function UserManager:new( ... )
	local platform = SystemInfo:platform()
	return ( self.PLATFORM_CLASS_MAP[ platform:key() ] or GenericUserManager ):new( ... )
end



GenericUserManager = GenericUserManager or class()
GenericUserManager.STORE_SETTINGS_ON_PROFILE = false
GenericUserManager.CAN_SELECT_USER = false
GenericUserManager.CAN_SELECT_STORAGE = false
GenericUserManager.NOT_SIGNED_IN_STATE = nil
GenericUserManager.CAN_CHANGE_STORAGE_ONLY_ONCE = true

function GenericUserManager:init()
	self._setting_changed_callback_handler_map = {}
	self._user_state_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._active_user_state_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._storage_changed_callback_handler = CoreEvent.CallbackEventHandler:new()

	if( not self:is_global_initialized() ) then
		Global.user_manager = {
								setting_map = {},
								setting_data_map = {},
								setting_data_id_to_name_map = {},
								user_map = {},
								user_index = nil,
								active_user_state_change_quit = nil,
								initializing = true,
								storage_changed = nil
							}

		self:setup_setting_map()
		self:update_all_users()

		Global.user_manager.initializing = nil
	end
end

function GenericUserManager:init_finalize() end

function GenericUserManager:is_global_initialized()
	return Global.user_manager and not Global.user_manager.initializing	-- Checks "initializing" so that it can be reloaded if it crashes during initialization.
end

local is_ps3 = SystemInfo:platform() == Idstring( "PS3" )
local is_x360 = SystemInfo:platform() == Idstring( "X360" )
function GenericUserManager:setup_setting_map()
	self:setup_setting( 1, "invert_camera_x", false )
	self:setup_setting( 2, "invert_camera_y", false )
	self:setup_setting( 3, "camera_sensitivity", 1 )
	self:setup_setting( 4, "rumble", true )
	self:setup_setting( 5, "music_volume", 100 )
	self:setup_setting( 6, "sfx_volume", 100 )
	self:setup_setting( 7, "subtitle", true )
	self:setup_setting( 8, "brightness", 1 )
	self:setup_setting( 9, "hold_to_steelsight", true )
	self:setup_setting( 10, "hold_to_run", not (is_ps3 or is_x360) and true ) -- False on ps3
	self:setup_setting( 11, "voice_volume", 100 )
	self:setup_setting( 12, "controller_mod", {} )
	self:setup_setting( 13, "alienware_mask", true )
	self:setup_setting( 14, "developer_mask", true )
	self:setup_setting( 15, "voice_chat", true )
	self:setup_setting( 16, "push_to_talk", true )
	self:setup_setting( 17, "hold_to_duck", false )
	self:setup_setting( 18, "video_color_grading", "color_off" )
	self:setup_setting( 19, "video_anti_alias", "AA" )
	self:setup_setting( 20, "video_animation_lod", 2 )
	self:setup_setting( 21, "video_streaks", true )
	self:setup_setting( 22, "mask_set", "clowns" )
	self:setup_setting( 23, "use_lightfx", false )
	self:setup_setting( 24, "fov_standard", 75 )	-- 75
	self:setup_setting( 25, "fov_zoom", 75 )	-- 60
	self:setup_setting( 26, "camera_zoom_sensitivity", 1 )
	self:setup_setting( 27, "enable_camera_zoom_sensitivity", false )
	self:setup_setting( 28, "light_adaption", true )
	self:setup_setting( 29, "menu_theme", "fire" )
	self:setup_setting( 30, "newest_theme", "fire" )
	self:setup_setting( 31, "hit_indicator", true )
	self:setup_setting( 32, "aim_assist", true )
	self:setup_setting( 33, "controller_mod_type", "pc" )
	self:setup_setting( 34, "objective_reminder", true )
	self:setup_setting( 35, "effect_quality", _G.tweak_data.EFFECT_QUALITY )
	self:setup_setting( 36, "fov_multiplier", 1 )
	self:setup_setting( 37, "southpaw", false )
	self:setup_setting( 38, "dof_setting", "standard" )
	self:setup_setting( 39, "fps_cap", 135 )
end

function GenericUserManager:setup_setting( id, name, default_value )
	assert( not Global.user_manager.setting_data_map[ name ], "[UserManager] Setting name \"" .. tostring( name ) .. "\" already exists." )
	assert( not Global.user_manager.setting_data_id_to_name_map[ id ], "[UserManager] Setting id \"" .. tostring( id ) .. "\" already exists." )

	local setting_data = { id = id, default_value = self:get_clone_value( default_value ) }
	Global.user_manager.setting_data_map[ name ] = setting_data
	Global.user_manager.setting_data_id_to_name_map[ id ] = name

	Global.user_manager.setting_map[ id ] = self:get_default_setting( name )
end

function GenericUserManager:reset_setting_map()
	for name in pairs( Global.user_manager.setting_data_map ) do
		self:set_setting( name, self:get_default_setting( name ) )
	end
end

function GenericUserManager:get_clone_value( value )
	if( type( value ) == "table" ) then
		return CoreTable.deep_clone( value )
	else
		return value
	end
end

function GenericUserManager:get_setting( name )
	local setting_data = Global.user_manager.setting_data_map[ name ]

	assert( setting_data, "[UserManager] Tried to get non-existing setting \"" .. tostring( name ) .. "\"." )

	return Global.user_manager.setting_map[ setting_data.id ]
end

function GenericUserManager:get_default_setting( name )
	local setting_data = Global.user_manager.setting_data_map[ name ]

	assert( setting_data, "[UserManager] Tried to get non-existing default setting \"" .. tostring( name ) .. "\"." )

	return self:get_clone_value( setting_data.default_value )
end

function GenericUserManager:set_setting( name, value, force_change )
	local setting_data = Global.user_manager.setting_data_map[ name ]

	if not setting_data then
		Application:error( "[UserManager] Tried to set non-existing default setting \"" .. tostring( name ) .. "\"." )
		return
	end
	-- assert( setting_data, "[UserManager] Tried to set non-existing default setting \"" .. tostring( name ) .. "\"." )

	local old_value = Global.user_manager.setting_map[ setting_data.id ]
	Global.user_manager.setting_map[ setting_data.id ] = value
	
	if( self:has_setting_changed( old_value, value ) or force_change) then
		managers.savefile:setting_changed()

		local callback_handler = self._setting_changed_callback_handler_map[ name ]

		if( callback_handler ) then
			callback_handler:dispatch( name, old_value, value )
		end
	end
end

function GenericUserManager:add_setting_changed_callback( setting_name, callback_func, trigger_changed_from_default_now )
	assert( Global.user_manager.setting_data_map[ setting_name ], "[UserManager] Tried to add setting changed callback for non-existing setting \"" .. tostring( setting_name ) .. "\"." )

	local callback_handler = self._setting_changed_callback_handler_map[ setting_name ] or CoreEvent.CallbackEventHandler:new()
	self._setting_changed_callback_handler_map[ setting_name ] = callback_handler
	callback_handler:add( callback_func )

	if( trigger_changed_from_default_now ) then
		local value = self:get_setting( setting_name )
		local default_value = self:get_default_setting( setting_name )

		if( self:has_setting_changed( default_value, value ) ) then
			callback_func( setting_name, default_value, value )
		end
	end
end

function GenericUserManager:remove_setting_changed_callback( setting_name, callback_func )
	local callback_handler = self._setting_changed_callback_handler_map[ setting_name ]
	assert( Global.user_manager.setting_data_map[ name ], "[UserManager] Tried to remove setting changed callback for non-existing setting \"" .. tostring( setting_name ) .. "\"." )
	assert( callback_handler, "[UserManager] Tried to remove non-existing setting changed callback for setting \"" .. tostring( setting_name ) .. "\"." )

	callback_handler:remove( callback_func )
end

function GenericUserManager:has_setting_changed( old_value, new_value )
	if( ( type( old_value ) == "table" ) and ( type( new_value ) == "table" ) ) then
		for k,old_sub_value in pairs( old_value ) do
			if( self:has_setting_changed( new_value[ k ], old_sub_value ) ) then
				return true
			end
		end

		for k,new_sub_value in pairs( new_value ) do
			if( self:has_setting_changed( new_sub_value, old_value[ k ] ) ) then
				return true
			end
		end

		return false
	else
		return old_value ~= new_value
	end
end

function GenericUserManager:update_all_users() end

function GenericUserManager:update_user( user_index, ignore_username_change ) end

function GenericUserManager:add_user_state_changed_callback( callback_func )
	self._user_state_changed_callback_handler:add( callback_func )
end
function GenericUserManager:remove_user_state_changed_callback( callback_func )
	self._user_state_changed_callback_handler:remove( callback_func )
end

function GenericUserManager:add_active_user_state_changed_callback( callback_func )
	self._active_user_state_changed_callback_handler:add( callback_func )
end
function GenericUserManager:remove_active_user_state_changed_callback( callback_func )
	self._active_user_state_changed_callback_handler:remove( callback_func )
end

function GenericUserManager:add_storage_changed_callback( callback_func )
	self._storage_changed_callback_handler:add( callback_func )
end
function GenericUserManager:remove_storage_changed_callback( callback_func )
	self._storage_changed_callback_handler:remove( callback_func )
end

-- Same as set_user but do not check user state change. PS3 and PC changed state twice when signing in at titlescreen, first on set user, then on set index.
function GenericUserManager:set_user_soft( user_index, platform_id, storage_id, username, signin_state, ignore_username_change )
	local old_user_data = self:_get_user_data( user_index )
	local user_data = { user_index = user_index, platform_id = platform_id, storage_id = storage_id, username = username, signin_state = signin_state }

	Global.user_manager.user_map[ user_index ] = user_data
end

function GenericUserManager:set_user( user_index, platform_id, storage_id, username, signin_state, ignore_username_change )
	local old_user_data = self:_get_user_data( user_index )
	local user_data = { user_index = user_index, platform_id = platform_id, storage_id = storage_id, username = username, signin_state = signin_state }

	Global.user_manager.user_map[ user_index ] = user_data

	self:check_user_state_change( old_user_data, user_data, ignore_username_change )
end

function GenericUserManager:check_user_state_change( old_user_data, user_data, ignore_username_change )
	local username = user_data and user_data.username
	local signin_state = user_data and user_data.signin_state or self.NOT_SIGNED_IN_STATE
	local old_signin_state = old_user_data and old_user_data.signin_state or self.NOT_SIGNED_IN_STATE
	local old_username = old_user_data and old_user_data.username
	local old_user_has_signed_out = old_user_data and old_user_data.has_signed_out 
	local user_changed, active_user_changed
	
	local was_signed_in = ( old_signin_state ~= self.NOT_SIGNED_IN_STATE )
	local is_signed_in = ( signin_state ~= self.NOT_SIGNED_IN_STATE )
	
	--[[if( ( old_signin_state ~= signin_state ) or not ignore_username_change and ( old_username ~= username ) or old_user_has_signed_out ) then
		Application:debug( "old_signin_state "..tostring(old_signin_state).." signin_state "..tostring(signin_state).." was_signed_in "..tostring(was_signed_in).." is_signed_in "..tostring(is_signed_in) )
		Application:debug( "________WOULD HAVE CAUSE A SIGN IN CHANGED________" )
		-- Application:set_pause( true )
		-- Application:throw_exception( "Wrong" )
	end]]
	-- if( ( old_signin_state ~= signin_state ) or not ignore_username_change and ( old_username ~= username ) or old_user_has_signed_out ) then
	-- Need to check username since a user can be switched in the loading screen:
	if( ( was_signed_in ~= is_signed_in ) or not ignore_username_change and ( old_username ~= username ) or old_user_has_signed_out ) then
		local user_index = ( user_data and user_data.user_index ) or ( old_user_data and old_user_data.user_index )
		if( user_index == self:get_index() ) then
			active_user_changed = true
		end

		if( Global.category_print.user_manager ) then
			if( active_user_changed ) then
				cat_print( "user_manager", "[UserManager] Active user changed." )
			else
				cat_print( "user_manager", "[UserManager] User index changed." )
			end

			cat_print( "user_manager", "[UserManager] Old user: " .. self:get_user_data_string( old_user_data ) .. "." )
			cat_print( "user_manager", "[UserManager] New user: " .. self:get_user_data_string( user_data ) .. "." )
		end
		--[[Application:debug( "USER HAS CHANGED" )
		print( inspect( old_user_data ) )
		print( inspect( user_data ) )
		Application:stack_dump()
		
		print( "was_signed_in", was_signed_in, "is_signed_in", is_signed_in )]]
		
		user_changed = true
	end

	--[[local storage_id = user_data and user_data.storage_id
	local old_storage_id = old_user_data and old_user_data.storage_id
	local ignore_storage_change = self.CAN_CHANGE_STORAGE_ONLY_ONCE and Global.user_manager.storage_changed
	if( not ignore_storage_change and ( active_user_changed or ( storage_id ~= old_storage_id ) ) ) then
		self:storage_changed( old_user_data, user_data )
		Global.user_manager.storage_changed = true
	end]]

	if( user_changed ) then
		if( active_user_changed ) then
			self:active_user_change_state( old_user_data, user_data )
		end

		self._user_state_changed_callback_handler:dispatch( old_user_data, user_data )
	end
	
	local storage_id = user_data and user_data.storage_id
	local old_storage_id = old_user_data and old_user_data.storage_id
	local ignore_storage_change = self.CAN_CHANGE_STORAGE_ONLY_ONCE and Global.user_manager.storage_changed
	if( not ignore_storage_change and ( active_user_changed or ( storage_id ~= old_storage_id ) ) ) then
		self:storage_changed( old_user_data, user_data )
		Global.user_manager.storage_changed = true
	end
end

function GenericUserManager:active_user_change_state( old_user_data, user_data )
	if( self:get_active_user_state_change_quit() or (is_x360 and managers.savefile:is_in_loading_sequence()) ) then
		print( "-- Cause loading", self:get_active_user_state_change_quit(), managers.savefile:is_in_loading_sequence() ) 
		local dialog_data = {}
		dialog_data.title = managers.localization:text( "dialog_signin_change_title" )
		dialog_data.text = managers.localization:text( "dialog_signin_change" )
		dialog_data.id = "user_changed"

		local ok_button = {}
		ok_button.text = managers.localization:text( "dialog_ok" )
		dialog_data.button_list = { ok_button }

		managers.system_menu:add_init_show( dialog_data )
		self:perform_load_start_menu()
		--[[managers.menu:on_user_sign_out()
		_G.setup:load_start_menu()

		_G.game_state_machine:set_boot_from_sign_out( true )
		self:set_active_user_state_change_quit( false )]]
	end

	self._active_user_state_changed_callback_handler:dispatch( old_user_data, user_data )
end

function GenericUserManager:perform_load_start_menu()
	managers.system_menu:force_close_all()
	managers.menu:on_user_sign_out()
	_G.setup:load_start_menu()

	_G.game_state_machine:set_boot_from_sign_out( true )
	self:set_active_user_state_change_quit( false )
end

function GenericUserManager:storage_changed( old_user_data, user_data )
	-- print( "GenericUserManager:storage_changed( old_user_data, user_data )" )
	-- Application:stack_dump()
	managers.savefile:storage_changed()
	self._storage_changed_callback_handler:dispatch( old_user_data, user_data )
end

function GenericUserManager:load_platform_setting_map( callback_func )
	if( callback_func ) then
		callback_func( nil )
	end
end

function GenericUserManager:get_user_string( user_index )
	local user_data = self:_get_user_data( user_index )
	return self:get_user_data_string( user_data )
end

function GenericUserManager:get_user_data_string( user_data )
	if( user_data ) then
		local user_index = tostring( user_data.user_index )
		local signin_state = tostring( user_data.signin_state )
		local username = tostring( user_data.username )
		local platform_id = tostring( user_data.platform_id )
		local storage_id = tostring( user_data.storage_id )

		return string.format( "User index: %s, Platform id: %s, Storage id: %s, Signin state: %s, Username: %s",
											user_index, platform_id, storage_id, signin_state, username )
	else
		return "nil"
	end
end

function GenericUserManager:get_index()
	return Global.user_manager.user_index
end

function GenericUserManager:set_index( user_index )
	if( Global.user_manager.user_index ~= user_index ) then
		local old_user_index = Global.user_manager.user_index

		cat_print( "user_manager", "[UserManager] Changed user index from " .. tostring( old_user_index ) .. " to " .. tostring( user_index ) .. "." )
		Global.user_manager.user_index = user_index

		local old_user_data = old_user_index and self:_get_user_data( old_user_index )
		if not user_index and old_user_data then
			old_user_data.storage_id = nil
		end
		if not user_index then -- Reset all selected storage devices, to allow reselect when two users on the same consoles fights about who should play with a host
			for _,data in pairs( Global.user_manager.user_map ) do
				data.storage_id = nil
			end
		end
		local user_data = self:_get_user_data( user_index )

		self:check_user_state_change( old_user_data, user_data, false )
	end
end

function GenericUserManager:get_active_user_state_change_quit()
	return Global.user_manager.active_user_state_change_quit
end

function GenericUserManager:set_active_user_state_change_quit( active_user_state_change_quit )
	if( not Global.user_manager.active_user_state_change_quit ~= not active_user_state_change_quit ) then
		cat_print( "user_manager", "[UserManager] User state change quits to title screen: " .. tostring( not not active_user_state_change_quit ) )
		Global.user_manager.active_user_state_change_quit = active_user_state_change_quit
	end
end

function GenericUserManager:get_platform_id( user_index )
	local user_data = self:_get_user_data( user_index )
	return user_data and user_data.platform_id
end

function GenericUserManager:is_signed_in( user_index )
	local user_data = self:_get_user_data( user_index )
	return user_data and ( user_data.signin_state ~= self.NOT_SIGNED_IN_STATE )
end

function GenericUserManager:signed_in_state( user_index )
	local user_data = self:_get_user_data( user_index )
	return user_data and ( user_data.signin_state )
end

function GenericUserManager:get_storage_id( user_index )
	local user_data = self:_get_user_data( user_index )
	return user_data and user_data.storage_id
end

function GenericUserManager:is_storage_selected( user_index )
	if( self.CAN_SELECT_STORAGE ) then
		local user_data = self:_get_user_data( user_index )
		return user_data and not not user_data.storage_id
	else
		return true
	end
end

function GenericUserManager:_get_user_data( user_index )
	local user_index = user_index or self:get_index()
	return user_index and Global.user_manager.user_map[ user_index ]
end

function GenericUserManager:check_user( callback_func, show_select_user_question_dialog )
	if( not self.CAN_SELECT_USER or self:is_signed_in( nil ) ) then
		if( callback_func ) then
			callback_func( true )
		end
	else
		local confirm_callback = callback( self, self, "confirm_select_user_callback", callback_func )
		if( show_select_user_question_dialog ) then
			self._active_check_user_callback_func = callback_func -- Used to identify sign in from Xbox Guide while sign in question is shown.
			local dialog_data = {}
			dialog_data.id = "show_select_user_question_dialog"
			dialog_data.title = managers.localization:text( "dialog_signin_title" )
			dialog_data.text = managers.localization:text( "dialog_signin_question" )
			dialog_data.focus_button = 1

			local yes_button = {}
			yes_button.text = managers.localization:text( "dialog_yes" )
			yes_button.callback_func = callback( self, self, "_success_callback", confirm_callback )

			local no_button = {}
			no_button.text = managers.localization:text( "dialog_no" )
			no_button.callback_func = callback( self, self, "_fail_callback", confirm_callback )
			dialog_data.button_list = { yes_button, no_button }

			managers.system_menu:show( dialog_data )
		else
			confirm_callback( true )
		end
	end
end

function GenericUserManager:_success_callback( callback_func )
	if( callback_func ) then
		callback_func( true )
	end
end
function GenericUserManager:_fail_callback( callback_func )
	if( callback_func ) then
		callback_func( false )
	end
end

function GenericUserManager:confirm_select_user_callback( callback_func, success )
	self._active_check_user_callback_func = nil
	if( success ) then
		managers.system_menu:show_select_user( { count = 1, callback_func = callback( self, self, "select_user_callback", callback_func ) } )
	elseif( callback_func ) then
		callback_func( false )
	end
end

function GenericUserManager:select_user_callback( callback_func )
	self:update_all_users()

	if( callback_func ) then
		self._active_check_user_callback_func = nil
		callback_func( self:is_signed_in( nil ) )
	end
end

function GenericUserManager:check_storage( callback_func, auto_select )
	if( not self.CAN_SELECT_STORAGE or self:get_storage_id( nil ) ) then
		if( callback_func ) then
			callback_func( true )
		end
	else
		local wrapped_callback_func = function( success, result, ... )
				if( success ) then
					self:update_all_users()
				end

				if( callback_func ) then
					callback_func( success, result, ... )
				end
			end
		managers.system_menu:show_select_storage( { min_bytes = managers.savefile.RESERVED_BYTES, count = 1, callback_func = wrapped_callback_func, auto_select = auto_select } )
	end
end

function GenericUserManager:get_setting_map()
	return CoreTable.deep_clone( Global.user_manager.setting_map )
end

function GenericUserManager:set_setting_map( setting_map )
	for id,value in pairs( setting_map ) do
		local name = Global.user_manager.setting_data_id_to_name_map[ id ]
		self:set_setting( name, value )
	end
end



function GenericUserManager:save_setting_map( setting_map, callback_func )
	if( callback_func ) then
		Appliction:error( "[UserManager] Setting map cannot be saved on this platform." )
		callback_func( false )
	end
end


function GenericUserManager:save( data )
	local state = self:get_setting_map()
	data.UserManager = state
	
	if Global.DEBUG_MENU_ON then
		data.debug_post_effects_enabled = Global.debug_post_effects_enabled
	end
end

function GenericUserManager:load( data, cache_version )
	if cache_version == 0 then
		self:set_setting_map( data )
	else
		self:set_setting_map( data.UserManager )
	end


	if SystemInfo:platform() ~= Idstring( "PS3" ) then
		local NEWEST_THEME = "zombie"
		if self:get_setting( "newest_theme" ) ~= NEWEST_THEME then
			self:set_setting( "newest_theme", NEWEST_THEME )
			self:set_setting( "menu_theme", NEWEST_THEME )
		end
	end
	
	if Global.DEBUG_MENU_ON then
		Global.debug_post_effects_enabled = data.debug_post_effects_enabled ~= false
	else
		Global.debug_post_effects_enabled = true
	end
end



Xbox360UserManager = Xbox360UserManager or class( GenericUserManager )
Xbox360UserManager.NOT_SIGNED_IN_STATE = "not_signed_in"
Xbox360UserManager.STORE_SETTINGS_ON_PROFILE = true
Xbox360UserManager.CAN_SELECT_USER = true
Xbox360UserManager.CAN_SELECT_STORAGE = true
Xbox360UserManager.CUSTOM_PROFILE_VARIABLE_COUNT = 3
Xbox360UserManager.CUSTOM_PROFILE_VARIABLE_CHAR_COUNT = 999
Xbox360UserManager.CAN_CHANGE_STORAGE_ONLY_ONCE = false
UserManager.PLATFORM_CLASS_MAP[ Idstring( "X360" ):key() ] = Xbox360UserManager

function Xbox360UserManager:init()
	self._platform_setting_conversion_func_map = { gamer_control_sensitivity = callback( self, self, "convert_gamer_control_sensitivity" ) }

	GenericUserManager.init( self )

	managers.platform:add_event_callback( "signin_changed", callback( self, self, "signin_changed_callback" ) )
	managers.platform:add_event_callback( "profile_setting_changed", callback( self, self, "profile_setting_changed_callback" ) )
	managers.platform:add_event_callback( "storage_devices_changed", callback( self, self, "storage_devices_changed_callback" ) )
	managers.platform:add_event_callback( "disconnect", callback( self, self, "disconnect_callback" ) )
	managers.platform:add_event_callback( "connect", callback( self, self, "connect_callback" ) )
	
	self._setting_map_save_counter = 0

	--[[ Used variables:
	self._setting_map_save_success = nil
	]]
end

function Xbox360UserManager:disconnect_callback( reason )
	print( "  Xbox360UserManager:disconnect_callback", reason, XboxLive:signin_state( 0 ) )
	
	if Global.game_settings.single_player then
		return
	end
	
	if managers.network:session() and managers.network:session():_local_peer_in_lobby() then
		managers.menu:xbox_disconnected()
	elseif self._in_online_menu then
		print( "leave crimenet" )
		managers.menu:xbox_disconnected()
	elseif managers.network:game() then
		managers.network:game():xbox_disconnected()
	end
end

function Xbox360UserManager:connect_callback()
	-- print( "  Xbox360UserManager:connect_callback", XboxLive:signin_state( 0 ) )
end

function Xbox360UserManager:on_entered_online_menus()
	self._in_online_menu = true
end

function Xbox360UserManager:on_exit_online_menus()
	self._in_online_menu = false
end

function Xbox360UserManager:setup_setting_map()
	local platform_default_type_map = {}

	platform_default_type_map[ "invert_camera_y" ] = "gamer_yaxis_inversion"
	platform_default_type_map[ "camera_sensitivity" ] = "gamer_control_sensitivity"

	Global.user_manager.platform_setting_map = nil
	Global.user_manager.platform_default_type_map = platform_default_type_map

	GenericUserManager.setup_setting_map( self )
end

function Xbox360UserManager:convert_gamer_control_sensitivity( value )
	if( value == "low" ) then
		return 0.5
	elseif( value == "medium" ) then
		return 1
	else
		return 1.5
	end
end

function Xbox360UserManager:get_default_setting( name )
	if( Global.user_manager.platform_setting_map ) then
		local platform_default_type = Global.user_manager.platform_default_type_map[ name ]

		if( platform_default_type ) then
			local platform_default = Global.user_manager.platform_setting_map[ platform_default_type ]
			local conversion_func = self._platform_setting_conversion_func_map[ platform_default_type ]

			if( conversion_func ) then
				return conversion_func( platform_default )
			else
				return platform_default
			end
		end
	end

	return GenericUserManager.get_default_setting( self, name )
end

function Xbox360UserManager:active_user_change_state( old_user_data, user_data )
	Global.user_manager.platform_setting_map = nil

	managers.savefile:active_user_changed()

	GenericUserManager.active_user_change_state( self, old_user_data, user_data )
end

function Xbox360UserManager:load_platform_setting_map( callback_func )
	cat_print( "user_manager", "[UserManager] Loading platform setting map." )
	XboxLive:read_profile_settings( self:get_platform_id( nil ), callback( self, self, "_load_platform_setting_map_callback", callback_func ) )
end

function Xbox360UserManager:_load_platform_setting_map_callback( callback_func, platform_setting_map )
	cat_print( "user_manager", "[UserManager] Done loading platform setting map. Success: " .. tostring( not not platform_setting_map ) )
	Global.user_manager.platform_setting_map = platform_setting_map
	self:reset_setting_map()

	if( callback_func ) then
		callback_func( platform_setting_map )
	end
end

function Xbox360UserManager:save_platform_setting( setting_name, setting_value, callback_func )
	cat_print( "user_manager", "[UserManager] Saving platform setting \"" .. tostring( setting_name ) .. "\": " .. tostring( setting_value ) )
	XboxLive:write_profile_setting( self:get_platform_id( nil ), setting_name, setting_value, callback( self, self, "_save_platform_setting_callback", callback_func ) )
end

-- function Xbox360UserManager:_save_platform_setting_callback( callback_func, setting_name, success )
function Xbox360UserManager:_save_platform_setting_callback( callback_func, success )
	-- cat_print( "user_manager", "[UserManager] Done saving platform setting \"" .. tostring( setting_name ) .. "\". Success: " .. tostring( success ) )
	cat_print( "user_manager", "[UserManager] Done saving platform setting \"" .. tostring( "Dont get setting name in callback" ) .. "\". Success: " .. tostring( success ) )
	if( callback_func ) then
		-- callback_func( setting_name, success )
		callback_func( success )
	end
end

function Xbox360UserManager:get_setting_map()
	local platform_setting_map = Global.user_manager.platform_setting_map
	local setting_map

	if( platform_setting_map ) then
		local packed_string_value = ""

		for i=1, self.CUSTOM_PROFILE_VARIABLE_COUNT do
			local setting_name = "title_specific" .. i
			packed_string_value = packed_string_value .. ( platform_setting_map[ setting_name ] or "" )
		end

		setting_map = Utility:unpack( packed_string_value ) or {}
	end

	return setting_map
end

function Xbox360UserManager:save_setting_map( callback_func )
	if( self._setting_map_save_counter > 0 ) then
		Appliction:error( "[UserManager] Tried to set setting map again before it was done with previous set." )

		if( callback_func ) then
			callback_func( false )
			return
		end
	end

	local complete_setting_value = Utility:pack( Global.user_manager.setting_map )
	local current_char = 1
	local char_count = #complete_setting_value
	local setting_count = 1
	local max_char_count = self.CUSTOM_PROFILE_VARIABLE_COUNT * self.CUSTOM_PROFILE_VARIABLE_CHAR_COUNT

	if( char_count > max_char_count ) then
		Application:stack_dump_error( "[UserManager] Exceeded (" .. char_count .. ") maximum character count that can be stored in the profile (" .. max_char_count .. ")." )
		callback_func( false )
		return
	end

	self._setting_map_save_success = true

	repeat
		local setting_name = "title_specific" .. setting_count
		local end_char = math.min( current_char + self.CUSTOM_PROFILE_VARIABLE_CHAR_COUNT - 1, char_count )
		local setting_value = string.sub( complete_setting_value, current_char, end_char )
		cat_print( "save_manager", "[UserManager] Saving profile setting \"" .. setting_name .. "\" (" .. current_char .. " to " .. end_char .. " of " .. char_count .. " characters)." )
		Global.user_manager.platform_setting_map[ setting_name ] = setting_value
		self._setting_map_save_counter = self._setting_map_save_counter + 1
		self:save_platform_setting( setting_name, setting_value, callback( self, self, "_save_setting_map_callback", callback_func ) )
		current_char = end_char + 1
		setting_count = setting_count + 1
	until( current_char >= char_count )
end

-- function Xbox360UserManager:_save_setting_map_callback( callback_func, setting_name, success )
function Xbox360UserManager:_save_setting_map_callback( callback_func, success )
	self._setting_map_save_success = self._setting_map_save_success and success
	self._setting_map_save_counter = self._setting_map_save_counter - 1

	if( callback_func and ( self._setting_map_save_counter == 0 ) ) then
		callback_func( self._setting_map_save_success )
	end
end

function Xbox360UserManager:signin_changed_callback( ... )
	-- print( " -- Xbox360UserManager:signin_changed_callback", inspect( { ... } ) )
	for user_index,signed_in in ipairs( { ... } ) do
		local was_signed_in = self:is_signed_in( user_index )
		
		-- Save a has_signed_out flag to prevent other messages to happen (storage device removed)
		Global.user_manager.user_map[user_index].has_signed_out = (was_signed_in and not signed_in)
		
		-- This should be to check if we are showing the "would you like to sign in screen" 
		if Global.user_manager.user_index == user_index then
			if not was_signed_in and signed_in then
				if self._active_check_user_callback_func then
					print( "RUN ACTIVE USER CALLBACK FUNC" )
					managers.system_menu:close( "show_select_user_question_dialog" )
					self._active_check_user_callback_func( true )
					self._active_check_user_callback_func = nil
				end
			end
		end

		if( not signed_in ~= not was_signed_in ) then
			self:update_user( user_index, false )
		else
			-- print( "   XboxLive:signin_state", XboxLive:signin_state( user_index-1 ) )
			local platform_id = user_index - 1
			local signin_state = XboxLive:signin_state( platform_id )
		
			local old_signin_state = Global.user_manager.user_map[user_index].signin_state
			if old_signin_state ~= signin_state then
				Global.user_manager.user_map[user_index].signin_state = signin_state
			end
		end
	end
end

function Xbox360UserManager:profile_setting_changed_callback( ... )
	-- print( "   Xbox360UserManager:profile_setting_changed_callback( ... )", inspect( { ... } ) )
	-- Skip everything for now, it caused user changed sequence and that was not good /Martin
	--[[local user_list = { ... }

	for user_index,changed in ipairs( user_list ) do
		if( changed ) then
			self:update_user( user_index, true )
		end
	end]]
end

function Xbox360UserManager:update_all_users()
	for user_index=1, 4 do
		self:update_user( user_index, false )
	end
end

function Xbox360UserManager:update_user( user_index, ignore_username_change )
	local platform_id = user_index - 1
	local signin_state = XboxLive:signin_state( platform_id )
	local is_signed_in = ( signin_state ~= self.NOT_SIGNED_IN_STATE )
	local storage_id, username

	if( is_signed_in ) then
		username = XboxLive:name( platform_id )
		storage_id = Application:current_storage_device_id( platform_id )

		if( storage_id == 0 ) then
			storage_id = nil
		end
	end

	self:set_user( user_index, platform_id, storage_id, username, signin_state, ignore_username_change )
end

function Xbox360UserManager:storage_devices_changed_callback()
	self:update_all_users()
end

function Xbox360UserManager:check_privilege( user_index, privilege )
	local platform_id = self:get_platform_id( user_index )
	return XboxLive:check_privilege( platform_id, privilege )
end

function Xbox360UserManager:get_xuid( user_index )
	local platform_id = self:get_platform_id( user_index )
	return XboxLive:xuid( platform_id )
end

function Xbox360UserManager:invite_accepted_by_inactive_user()
	managers.platform:set_rich_presence( "Idle" ) -- Current active user will be Idle
	self:perform_load_start_menu()
	managers.menu:reset_all_loaded_data()
end

PS3UserManager = PS3UserManager or class( GenericUserManager )
UserManager.PLATFORM_CLASS_MAP[ Idstring( "PS3" ):key() ] = PS3UserManager

function PS3UserManager:init()
	self._init_finalize_index = not self:is_global_initialized()

	GenericUserManager.init( self )
end

function PS3UserManager:init_finalize()
	if( self._init_finalize_index ) then
		self:set_user( 1, nil, true, nil, true, false )
		self._init_finalize_index = nil
	end
end

function PS3UserManager:set_index( user_index )
	if( user_index ) then
		-- self:set_user( user_index, nil, true, nil, true, false )
		self:set_user_soft( user_index, nil, true, nil, true, false )
	end

	GenericUserManager.set_index( self, user_index )
end



WinUserManager = WinUserManager or class( GenericUserManager )
UserManager.PLATFORM_CLASS_MAP[ Idstring( "WIN32" ):key() ] = WinUserManager

function WinUserManager:init()
	self._init_finalize_index = not self:is_global_initialized()

	GenericUserManager.init( self )
end

function WinUserManager:init_finalize()
	if( self._init_finalize_index ) then
		self:set_user( 1, nil, true, nil, true, false )
		self._init_finalize_index = nil
	end
end

function WinUserManager:set_index( user_index )
	if( user_index ) then
		-- self:set_user( user_index, nil, true, nil, true, false )
		self:set_user_soft( user_index, nil, true, nil, true, false )
	end

	GenericUserManager.set_index( self, user_index )
end