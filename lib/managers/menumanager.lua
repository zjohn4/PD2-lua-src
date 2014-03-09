core:import( "CoreMenuManager" )
core:import( "CoreMenuCallbackHandler" )
--require "lib/managers/menu/CoreMenuManager"
require "lib/managers/menu/MenuInput"
require "lib/managers/menu/MenuRenderer"
require "lib/managers/menu/MenuLobbyRenderer"
require "lib/managers/menu/MenuPauseRenderer"
require "lib/managers/menu/MenuKitRenderer"
require "lib/managers/menu/MenuHiddenRenderer"
-- require "lib/managers/menu/items/MenuItemTest"
require "lib/managers/menu/items/MenuItemColumn"
require "lib/managers/menu/items/MenuItemLevel"
require "lib/managers/menu/items/MenuItemChallenge"
require "lib/managers/menu/items/MenuItemKitSlot"
require "lib/managers/menu/items/MenuItemUpgrade"
require "lib/managers/menu/items/MenuItemMultiChoice"
require "lib/managers/menu/items/MenuItemChat"
require "lib/managers/menu/items/MenuItemFriend"
require "lib/managers/menu/items/MenuItemCustomizeController"
require "lib/managers/menu/nodes/MenuNodeTable"
require "lib/managers/menu/nodes/MenuNodeServerList"

core:import( "CoreEvent" )

MenuManager = MenuManager or class( CoreMenuManager.Manager )
MenuCallbackHandler = MenuCallbackHandler or class( CoreMenuCallbackHandler.CallbackHandler )

require "lib/managers/MenuManagerPD2"

MenuManager.ONLINE_AGE = 17
MenuManager.IS_NORTH_AMERICA = true

require "lib/managers/MenuManagerDialogs"

function MenuManager:init( is_start_menu )
	MenuManager.super.init( self )

	self._is_start_menu = is_start_menu
	self._active = false
	self._debug_menu_enabled = Global.DEBUG_MENU_ON or Application:production_build()

	self:create_controller()

	if( is_start_menu ) then
		local menu_main =
		{
			name				= "menu_main",
			id					= "start_menu",
			content_file		= "gamedata/menus/start_menu",
			callback_handler	= MenuCallbackHandler:new(),
			input				= "MenuInput",
			renderer			= "MenuRenderer"
		}
		self:register_menu( menu_main )
	else
		local menu_pause =
		{
			name				= "menu_pause",
			id					= "pause_menu",
			content_file		= "gamedata/menus/pause_menu",
			callback_handler	= MenuCallbackHandler:new(),
			input				= "MenuInput",
			renderer			= "MenuPauseRenderer"
		}
		self:register_menu( menu_pause )

		local kit_menu =
		{
			name				= "kit_menu",
			id					= "kit_menu",
			content_file		= "gamedata/menus/kit_menu",
			callback_handler	= MenuCallbackHandler:new(),
			input				= "MenuInput",
			renderer			= "MenuKitRenderer"
		}
		self:register_menu( kit_menu )
		
		local mission_end_menu =
		{
			name				= "mission_end_menu",
			id					= "mission_end_menu",
			content_file		= "gamedata/menus/mission_end_menu",
			callback_handler	= MenuCallbackHandler:new(),
			input				= "MenuInput",
			renderer			= "MenuHiddenRenderer"
		}
		self:register_menu( mission_end_menu )
		
		local loot_menu =
		{
			name				= "loot_menu",
			id					= "loot_menu",
			content_file		= "gamedata/menus/loot_menu",
			callback_handler	= MenuCallbackHandler:new(),
			input				= "MenuInput",
			renderer			= "MenuHiddenRenderer"
		}
		self:register_menu( loot_menu )
	end

	self._controller:add_trigger( "toggle_menu", callback( self, self, "toggle_menu_state" ) )

	if MenuCallbackHandler:is_pc_controller() then
		self._controller:add_trigger( "toggle_chat", callback( self, self, "toggle_chatinput" ) )
	end
	if SystemInfo:platform() == Idstring( "WIN32" ) then
		self._controller:add_trigger( "push_to_talk", callback( self, self, "push_to_talk", true ) )
		self._controller:add_release_trigger( "push_to_talk", callback( self, self, "push_to_talk", false ) )
	end

	self._active_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
	
	
	
	
	managers.user:add_setting_changed_callback( "brightness", callback( self, self, "brightness_changed" ), true )
	managers.user:add_setting_changed_callback( "camera_sensitivity", callback( self, self, "camera_sensitivity_changed" ), true )
	managers.user:add_setting_changed_callback( "camera_zoom_sensitivity", callback( self, self, "camera_sensitivity_changed" ), true )
	managers.user:add_setting_changed_callback( "rumble", callback( self, self, "rumble_changed" ), true )
	managers.user:add_setting_changed_callback( "invert_camera_x", callback( self, self, "invert_camera_x_changed" ), true )
	managers.user:add_setting_changed_callback( "invert_camera_y", callback( self, self, "invert_camera_y_changed" ), true )
	managers.user:add_setting_changed_callback( "southpaw", callback( self, self, "southpaw_changed" ), true )
	managers.user:add_setting_changed_callback( "subtitle", callback( self, self, "subtitle_changed" ), true )
	managers.user:add_setting_changed_callback( "music_volume", callback( self, self, "music_volume_changed" ), true )
	managers.user:add_setting_changed_callback( "sfx_volume", callback( self, self, "sfx_volume_changed" ), true )
	managers.user:add_setting_changed_callback( "voice_volume", callback( self, self, "voice_volume_changed" ), true )
	managers.user:add_setting_changed_callback( "use_lightfx", callback( self, self, "lightfx_changed" ), true )
	managers.user:add_setting_changed_callback( "effect_quality", callback( self, self, "effect_quality_changed" ), true )
	managers.user:add_setting_changed_callback( "dof_setting", callback( self, self, "dof_setting_changed" ), true )
	managers.user:add_setting_changed_callback( "fps_cap", callback( self, self, "fps_limit_changed" ), true )
	managers.user:add_active_user_state_changed_callback( callback( self, self, "on_user_changed" ) )
	managers.user:add_storage_changed_callback( callback( self, self, "on_storage_changed" ) )

	managers.savefile:add_active_changed_callback( callback( self, self, "safefile_manager_active_changed" ) )
	

	self._delayed_open_savefile_menu_callback = nil
	self._save_game_callback = nil
	
	-- A little hack to really set the loaded brightness value
	self:brightness_changed( nil, nil, managers.user:get_setting( "brightness" ) )
	self:effect_quality_changed( nil, nil, managers.user:get_setting( "effect_quality" ) )

	self:fps_limit_changed( nil, nil, managers.user:get_setting( "fps_cap" ) )
	
	self:invert_camera_y_changed( "invert_camera_y", nil, managers.user:get_setting( "invert_camera_y" ) )
	self:southpaw_changed( "southpaw", nil, managers.user:get_setting( "southpaw" ) )

	self:dof_setting_changed( "dof_setting", nil, managers.user:get_setting( "dof_setting" ) )
	
	managers.system_menu:add_active_changed_callback( callback( self, self, "system_menu_active_changed" ) )
	
	self._sound_source = SoundDevice:create_source( "MenuManager" )
end

function MenuManager:post_event( event )
	-- local test_callback = function( instance, event_type, unit, sound_source, label, identifier, position ) Application:debug( instance, event_type, unit, inspect(sound_source), label, identifier, position ) end
	local event = self._sound_source:post_event( event ) -- , test_callback, self, "end_of_event", "end_of_dsi", "marker", "duration", "music_sync_beat", "music_sync_bar", "music_sync_entry", "music_sync_exit", "enable_get_position" )
end

function MenuManager:_cb_matchmake_found_game( game_id, created )
	print( "_cb_matchmake_found_game", game_id, created ) 
end

function MenuManager:_cb_matchmake_player_joined( player_info )
	print( "_cb_matchmake_player_joined" )
	-- print( inspect( player_info ) )
	
	-- if( self._lan == false ) then
		if managers.network.group:is_group_leader() then
			-- If we're the group leader we need an RPC to the connected client
			-- so we can inform him which level / mode have been selected
			-- And let connected client know the current setup
			-- player_info.rpc:setup(self._mode_index, self._map_index[self._mode_index], self._private_game, self._frag_limit_index, self._time_limit_index, self._flag_limit_index)
		end
	--[[else
		if( managers.network.systemlink:is_available() ) then
			player_info.rpc:setup(self._mode_index, self._map_index[self._mode_index], self._private_game, self._frag_limit_index, self._time_limit_index, self._flag_limit_index)
		end
	end]]
end

function MenuManager:destroy()
	MenuManager.super.destroy( self )
	self:destroy_controller()
end

function MenuManager:set_delayed_open_savefile_menu_callback( callback_func )
	self._delayed_open_savefile_menu_callback = callback_func
end

function MenuManager:set_save_game_callback( callback_func )
	self._save_game_callback = callback_func
end

function MenuManager:system_menu_active_changed( active )
	local active_menu = self:active_menu()
	if not active_menu then
		return
	end
	
	if active then
		active_menu.logic:accept_input( false )
	else
		active_menu.renderer:disable_input( 0.01 )
	end
end

function MenuManager:set_and_send_sync_state( state )
	if not managers.network or not managers.network:session() then
		return 
	end

	local index = tweak_data:menu_sync_state_to_index( state )
	if index then
		self:_set_peer_sync_state( managers.network:session():local_peer():id(), state )


		managers.network:session():send_to_peers_loaded( "set_menu_sync_state_index", index )
	end

end

function MenuManager:_set_peer_sync_state( peer_id, state )
	Application:debug( "MenuManager: " .. peer_id .. " sync state is now", state )

	self._peers_state = self._peers_state or {}
	self._peers_state[ peer_id ] = state

	if managers.menu_scene then
		managers.menu_scene:set_lobby_character_menu_state( peer_id, state )
	end
end

function MenuManager:set_peer_sync_state_index( peer_id, index )
	local state = tweak_data:index_to_menu_sync_state( index )
	self:_set_peer_sync_state( peer_id, state )
end

function MenuManager:get_all_peers_state()
	return self._peers_state
end

function MenuManager:get_peer_state( peer_id )
	return self._peers_state and self._peers_state[ peer_id ]
end

function MenuManager:_node_selected( menu_name, node )
	self:set_and_send_sync_state( node and node:parameters().sync_state )
end

function MenuManager:active_menu( node_name, parameter_list )
	local active_menu = self._open_menus[ #self._open_menus ]
	if( active_menu ) then
		return active_menu
		-- active_menu.logic:select_node( node_name, true, unpack( parameter_list or {} ) )
	end
end

function MenuManager:open_menu( menu_name, position )
	MenuManager.super.open_menu( self, menu_name, position )
	self:activate()
end

function MenuManager:open_node( node_name, parameter_list )
	local active_menu = self._open_menus[ #self._open_menus ]
	if( active_menu ) then
		active_menu.logic:select_node( node_name, true, unpack( parameter_list or {} ) )
	end
end

function MenuManager:back( queue, skip_nodes )
	local active_menu = self._open_menus[ #self._open_menus ]

	if( active_menu ) then
		active_menu.input:back( queue, skip_nodes )
	end
end

function MenuManager:close_menu( menu_name )
	self:post_event( "menu_exit" )
	if Global.game_settings.single_player and menu_name == "menu_pause" then
		Application:set_pause( false )
		self:post_event( "game_resume" )
		SoundDevice:set_rtpc( "ingame_sound", 1 ) -- mute gameplay sounds
	end
	MenuManager.super.close_menu( self, menu_name )
end

function MenuManager:_menu_closed( menu_name )
	MenuManager.super._menu_closed( self, menu_name )
	self:deactivate()
end

function MenuManager:close_all_menus()
	local names = {}
	for _,menu in pairs( self._open_menus ) do
		table.insert( names, menu.name )
	end
	for _,name in ipairs( names ) do
		self:close_menu( name )
	end
end

function MenuManager:is_open( menu_name )
	for _,menu in ipairs( self._open_menus ) do
		if( menu.name == menu_name ) then
			return true
		end
	end
	return false
end

function MenuManager:is_in_root( menu_name )
	for _,menu in ipairs( self._open_menus ) do
		if( menu.name == menu_name ) then
			return #menu.renderer._node_gui_stack == 1
		end
	end
	return false
end

function MenuManager:is_pc_controller()
	return self:active_menu() and self:active_menu().input._controller.TYPE == "pc" or managers.controller:get_default_wrapper_type() == "pc"
end

function MenuManager:toggle_menu_state()
	if self._is_start_menu then
		return
	end
	
	-- Prevent if chat is in focus
	if managers.hud:chat_focus() then
		return
	end
		
	if( ( not Application:editor() or Global.running_simulation ) ) then
		if not managers.system_menu:is_active() then
			if( self:is_open( "menu_pause" ) ) then
				-- If we play o PC we only close the menu if we are at the root.
				if not self:is_pc_controller() or self:is_in_root( "menu_pause" ) then
					self:close_menu( "menu_pause" )
					managers.savefile:save_setting( true )
				end
			-- elseif( not self._active ) then
			else
				-- Only open if no other active menu or in root of the active menu
				if (not self:active_menu() or #self:active_menu().logic._node_stack == 1) and managers.menu_component:input_focus() ~= 1 then
					self:open_menu( "menu_pause" )
					if Global.game_settings.single_player then
						Application:set_pause( true )
						self:post_event( "game_pause_in_game_menu" )
						SoundDevice:set_rtpc( "ingame_sound", 0 ) -- mute gameplay sounds
						
						-- Force clear player controller input
						local player_unit = managers.player:player_unit()
						if alive( player_unit ) then
							if player_unit:movement():current_state().update_check_actions_paused then
								player_unit:movement():current_state():update_check_actions_paused()
							end
						end
					end
				end
			end
		end
	end
end

function MenuManager:push_to_talk( enabled )
	if managers.network and managers.network.voice_chat then
		managers.network.voice_chat:set_recording( enabled )
	end
end

function MenuManager:toggle_chatinput()
	if Global.game_settings.single_player or Application:editor() then
		return
	end
		
	if SystemInfo:platform() ~= Idstring( "WIN32" ) then
		return
	end
	
	if self:active_menu() then
		return
	end
	
	if not managers.network:session() then
		return
	end
	
	if managers.hud then
		managers.hud:toggle_chatinput()
		return true
	end
end

function MenuManager:set_slot_voice( peer, peer_id, active )
	local kit_menu = managers.menu:get_menu( "kit_menu" )
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:set_slot_voice( peer, peer_id, active )
	end
end

function MenuManager:create_controller()
	if( not self._controller ) then
		self._controller = managers.controller:create_controller( "MenuManager", nil, false )

		local setup = self._controller:get_setup()
		local look_connection = setup:get_connection( "look" )
		
		self._look_multiplier = look_connection:get_multiplier()
		
		if( not managers.savefile:is_active() ) then
			self._controller:enable()
		end
	end
end

function MenuManager:get_controller()
	return self._controller
end

function MenuManager:safefile_manager_active_changed( active )
	if( self._controller ) then
		if( active ) then
			self._controller:disable()
		else
			self._controller:enable()
		end
	end

	if( not active ) then
		if( self._delayed_open_savefile_menu_callback ) then
			self._delayed_open_savefile_menu_callback()
		end

		if( self._save_game_callback ) then
			self._save_game_callback()
		end
	end
end

function MenuManager:destroy_controller()
	if( self._controller ) then
		self._controller:destroy()
		self._controller = nil
	end
end

function MenuManager:activate()
	if #self._open_menus == 1 then
		managers.rumble:set_enabled( false )
		self._active_changed_callback_handler:dispatch( true )
		self._active = true
	end
end


function MenuManager:deactivate()
	if #self._open_menus == 0 then
		managers.rumble:set_enabled( managers.user:get_setting( "rumble" ) )
		self._active_changed_callback_handler:dispatch( false )
		self._active = false
	end
end


function MenuManager:is_active()
	return self._active
end


function MenuManager:add_active_changed_callback( callback_func )
	self._active_changed_callback_handler:add( callback_func )
end
function MenuManager:remove_active_changed_callback( callback_func )
	self._active_changed_callback_handler:remove( callback_func )
end



function MenuManager:brightness_changed( name, old_value, new_value )
	local brightness = math.clamp( new_value, _G.tweak_data.menu.MIN_BRIGHTNESS, _G.tweak_data.menu.MAX_BRIGHTNESS )
	Application:set_brightness( brightness )
end

function MenuManager:effect_quality_changed( name, old_value, new_value )
	-- print( "MenuManager:effect_quality_changed", name, old_value, new_value )
	-- World:effect_manager():set_quality( self.EFFECT_QUALITY )
	World:effect_manager():set_quality( new_value )
end

function MenuManager:set_mouse_sensitivity( zoomed )
	if self:is_console() then
		return
	end

	local sens = (zoomed and managers.user:get_setting( "enable_camera_zoom_sensitivity" )) and managers.user:get_setting( "camera_zoom_sensitivity" ) or managers.user:get_setting( "camera_sensitivity" )
	self._controller:get_setup():get_connection( "look" ):set_multiplier( sens * self._look_multiplier )
	managers.controller:rebind_connections()
end


function MenuManager:camera_sensitivity_changed( name, old_value, new_value )
	if self:is_console() then
		local setup = self._controller:get_setup()
		local look_connection = setup:get_connection( "look" )
		local look_mutliplier = new_value * self._look_multiplier
		
		look_connection:set_multiplier( look_mutliplier )
		
		managers.controller:rebind_connections()
		return
	end

	if alive( managers.player:player_unit() ) then
		local plr_state = managers.player:player_unit():movement():current_state()
		local weapon_id = alive( plr_state._equipped_unit ) and plr_state._equipped_unit:base():get_name_id()
		local stances = tweak_data.player.stances[ weapon_id ] or tweak_data.player.stances.default
		
		self:set_mouse_sensitivity( plr_state:in_steelsight() and stances.steelsight.zoom_fov )
	else
		self:set_mouse_sensitivity( false )
	end
end



function MenuManager:rumble_changed( name, old_value, new_value )
	managers.rumble:set_enabled( new_value )
end

function MenuManager:invert_camera_x_changed( name, old_value, new_value )
	local setup = self._controller:get_setup()
	local look_connection = setup:get_connection( "look" )
	local look_inversion = look_connection:get_inversion_unmodified()
	
	if( new_value ) then
		look_inversion = look_inversion:with_x( -1 )
	else
		look_inversion = look_inversion:with_x( 1 )
	end

	look_connection:set_inversion( look_inversion )
	
	managers.controller:rebind_connections()
end

function MenuManager:invert_camera_y_changed( name, old_value, new_value )
	local setup = self._controller:get_setup()
	local look_connection = setup:get_connection( "look" )
	local look_inversion = look_connection:get_inversion_unmodified()

	if( new_value ) then
		look_inversion = look_inversion:with_y( -1 )
	else
		look_inversion = look_inversion:with_y( 1 )
	end
	
	look_connection:set_inversion( look_inversion )
	
	managers.controller:rebind_connections()
end

function MenuManager:southpaw_changed( name, old_value, new_value )
	if not (self._controller.TYPE == "xbox360" or self._controller.TYPE == "ps3") then
		return
	end
	
	local setup = self._controller:get_setup()
	local look_connection = setup:get_connection( "look" )
	local move_connection = setup:get_connection( "move" )
	
	local look_input_name_list = look_connection:get_input_name_list()
	local move_input_name_list = move_connection:get_input_name_list()
	
	if Application:production_build() then
		local got_input_left = 0
		local got_input_right = 0
		
		for _, input_name in ipairs( look_input_name_list ) do
			if input_name == "left" then
				got_input_left = got_input_left + 1
			elseif input_name == "right" then
				got_input_right = got_input_right + 1
			else
				Application:error( "[MenuManager:southpaw_changed] Active controller got some other input other than left and right on look!", input_name )
			end
		end
		
		for _, input_name in ipairs( move_input_name_list ) do
			if input_name == "left" then
				got_input_left = got_input_left + 1
			elseif input_name == "right" then
				got_input_right = got_input_right + 1
			else
				Application:error( "[MenuManager:southpaw_changed] Active controller got some other input other than left and right on move!", input_name )
			end
		end
		
		if got_input_left~=1 or got_input_right~=1 then
			Application:error( "[MenuManager:southpaw_changed] Controller look and move are not binded as expected" , "got_input_left: "..tostring(got_input_left) , "got_input_right: "..tostring(got_input_right) , "look_input_name_list: "..inspect(look_input_name_list) , "move_input_name_list: "..inspect(move_input_name_list) )
		end
	end
	
	
	if new_value then -- southpaw
		move_connection:set_input_name_list( { "right" } )
		look_connection:set_input_name_list( { "left" } )
	else
		move_connection:set_input_name_list( { "left" } )
		look_connection:set_input_name_list( { "right" } )
	end
	
	managers.controller:rebind_connections()
end

function MenuManager:dof_setting_changed( name, old_value, new_value )
	managers.environment_controller:set_dof_setting( new_value )
end

function MenuManager:fps_limit_changed( name, old_value, new_value )
	if SystemInfo:platform() ~= Idstring( "WIN32" ) then
		return 
	end
	setup:set_fps_cap( new_value )
end

function MenuManager:subtitle_changed( name, old_value, new_value )
	managers.subtitle:set_visible( new_value )
end


function MenuManager:music_volume_changed( name, old_value, new_value )
	local tweak = _G.tweak_data.menu
	local percentage = ( new_value - tweak.MIN_MUSIC_VOLUME ) / ( tweak.MAX_MUSIC_VOLUME - tweak.MIN_MUSIC_VOLUME )
	managers.music:set_volume( percentage ) -- 0 to 1
end

function MenuManager:sfx_volume_changed( name, old_value, new_value )
	local tweak = _G.tweak_data.menu
	local percentage = ( new_value - tweak.MIN_SFX_VOLUME ) / ( tweak.MAX_SFX_VOLUME - tweak.MIN_SFX_VOLUME )
	SoundDevice:set_rtpc( "option_sfx_volume", percentage * 100 )
		
	managers.video:volume_changed( percentage )
end

function MenuManager:voice_volume_changed( name, old_value, new_value )
	if managers.network and managers.network.voice_chat then
		managers.network.voice_chat:set_volume( new_value )
	end
end

function MenuManager:lightfx_changed( name, old_value, new_value )
	if managers.network and managers.network.account then
		managers.network.account:set_lightfx()
	end
end


function MenuManager:set_debug_menu_enabled( enabled )
	self._debug_menu_enabled = enabled
end
function MenuManager:debug_menu_enabled()
	return self._debug_menu_enabled
end

-- For dynamicly created menues how wants a back button
function MenuManager:add_back_button( new_node )
	new_node:delete_item( "back" )
	local params = {
						name		= "back",
						text_id		= "menu_back",
						visible_callback	= "is_pc_controller",
							
						back 			= true,
						previous_node 	= true,
						}
	
	local new_item = new_node:create_item( nil, params )
	new_node:add_item( new_item )
	-- <item name="back" text_id="menu_back" previous_node="true" back="true" visible_callback="is_pc_controller"/>
end

-- Only in editor and production
function MenuManager:reload()
	self:_recompile( managers.database:root_path().."assets\\guis\\" )
end

function MenuManager:_recompile( dir )
	local source_files = self:_source_files( dir )
	local t = {
		platform = "win32",
		source_root = managers.database:root_path().."/assets",
		target_db_root = managers.database:root_path().."/packages/win32/assets",
		target_db_name="all",
		source_files = source_files,
		verbose = false,
		send_idstrings = false
		}
	Application:data_compile( t )
	DB:reload()
	managers.database:clear_all_cached_indices()
	for _,file in ipairs( source_files ) do
		PackageManager:reload( managers.database:entry_type( file ):id(), managers.database:entry_path( file ):id() ) 
	end
end

function MenuManager:_source_files( dir )
	local files = {}
	local entry_path = managers.database:entry_path( dir )..'/'
	for _,file in ipairs( SystemFS:list( dir ) ) do
		table.insert( files, entry_path..file )
	end
	for _,sub_dir in ipairs( SystemFS:list( dir, true ) ) do
		for _,file in ipairs( SystemFS:list( dir..'/'..sub_dir ) ) do
			table.insert( files, entry_path..sub_dir..'/'..file )
		end
	end

	return files
end

function MenuManager:progress_resetted()
	local dialog_data = {}
	dialog_data.title = "Dr Evil" -- managers.localization:text( "dialog_warning_title" )
	dialog_data.text = "HAHA, your progress is gone!" -- managers.localization:text( "dialog_are_you_sure_you_want_to_clear_progress" )

	local no_button = {}
	no_button.text = "Doh!" -- managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_progress_resetted_ok" )
	dialog_data.button_list = { no_button }

	managers.system_menu:show( dialog_data )
end

function MenuManager:_dialog_progress_resetted_ok()
end

function MenuManager:relay_chat_message( message, id )
	for _,menu in pairs( self._open_menus ) do
		if menu.renderer.sync_chat_message then
			menu.renderer:sync_chat_message( message, id )
		end
	end
	if self:is_console() then
		return
	end
	
	print( "relay_chat_message", message, id )
	
	if managers.hud then
		managers.hud:sync_say( message, id )
	end
end

function MenuManager:is_console()
	return self:is_ps3() or self:is_x360()
end

function MenuManager:is_ps3()
	return SystemInfo:platform() == Idstring( "PS3" )
end

function MenuManager:is_x360()
	return SystemInfo:platform() == Idstring( "X360" )
end

function MenuManager:is_na()
	return MenuManager.IS_NORTH_AMERICA
end

function MenuManager:open_sign_in_menu( cb )
	if self:is_ps3() then
		-- Temp placed callbacks
		managers.network.matchmake:register_callback("found_game", callback(self, self, "_cb_matchmake_found_game") )
		managers.network.matchmake:register_callback("player_joined", callback(self, self, "_cb_matchmake_player_joined") )
		
		self:open_ps3_sign_in_menu( cb )
	elseif self:is_x360() then
		if managers.network.account:signin_state() == "signed in"
			and managers.user:check_privilege( nil, "multiplayer_sessions") then
			self:open_x360_sign_in_menu( cb )
		else
			self:show_err_not_signed_in_dialog()
		end
		--[[if not managers.network.account:signin_state() == "signed in" 
			or not managers.user:check_privilege( nil, "multiplayer_sessions") then
				self:show_err_not_signed_in_dialog()
		else
			self:open_x360_sign_in_menu( cb )
		end]]
	else
		if managers.network.account:signin_state() == "signed in" then
			cb( true )
		else
			self:show_err_not_signed_in_dialog()
		end
	end
end

function MenuManager:open_ps3_sign_in_menu( cb )
	local success = true
	if(managers.network.account:signin_state()=="not signed in")then
		managers.network.account:show_signin_ui()
		if(managers.network.account:signin_state()=="signed in")then
			print( "SIGNED IN" ) -- , inspect( PSN:get_world_list() ) )
			if #PSN:get_world_list() == 0 then
				managers.network.matchmake:getting_world_list()	
			end
			success = self:_enter_online_menus()
		else
			success = false
		end
		--[[local f = function() 
			managers.menu._trad_screen_stack[1]:set_options({label=""})
			managers.menu:pop_screen()
			managers.network.account:show_signin_ui()
			if(managers.network.account:signin_state()=="signed in")then
				self._wait_for_ps3_rdv_connection = true
				PSN:set_online_callback(callback(self,self,"ps3_disconnect"))	
			end
		end		
		managers.menu:push_screen(DlgMessage,
			{
				label=managers.localizer:text("mpm_mm_xml_notloggedin"),
				text=managers.localizer:text("mpm_mm_xml_pleaselogin"),
				buttons=
				{
				{button="a", label=managers.localizer:text("mpm_mm_dlg_ok"), callback=f},
				{button="b", label=managers.localizer:text("mpm_mm_dlg_cancel"), callback=function() managers.menu._trad_screen_stack[1]:close() end}
				}
			}, true)]]			
	else
		-- self:ps3_connect_rdv()
		if #PSN:get_world_list() == 0 then -- Will this help initiate the world list if we are allready signed in?
			managers.network.matchmake:getting_world_list()
			PSN:init_matchmaking()
		end
		success = self:_enter_online_menus()
	end
	cb( success )
end

function MenuManager:open_x360_sign_in_menu( cb )
	local success = self:_enter_online_menus_x360()
	cb( success )
end

-- Called when loaded back to lobby, called from MenuMainState.lua
function MenuManager:external_enter_online_menus()
	if self:is_ps3() then
		self:_enter_online_menus()
	elseif self:is_x360() then
		self:_enter_online_menus_x360()
	else
	end
end

function MenuManager:_enter_online_menus()
	if PSN:user_age() < MenuManager.ONLINE_AGE and PSN:parental_control_settings_active() then -- AGE RESTRICTION CHECK
		Global.boot_invite = nil -- Nullify boot invite
		self:show_err_under_age()
		return false
	else
		managers.platform:set_presence( "Signed_in" )
		managers.network:ps3_determine_voice( false )
		managers.network.voice_chat:check_status_information()
		PSN:set_online_callback(callback(self,self,"ps3_disconnect"))
		return true
	end
end

function MenuManager:_enter_online_menus_x360()
	managers.platform:set_presence( "Signed_in" )
	managers.user:on_entered_online_menus()
	-- managers.network:ps3_determine_voice( false )
	-- managers.network.voice_chat:check_status_information()
	return true
end

function MenuManager:psn_disconnected()
	-- print( "psn_disconnected()" )
	if managers.network:session() then
		managers.network:queue_stop_network()
		managers.platform:set_presence( "Idle" )
		managers.network.matchmake:leave_game()
		managers.network.friends:psn_disconnected()
		managers.network.voice_chat:destroy_voice( true )
		self:exit_online_menues()
	end
	self:show_mp_disconnected_internet_dialog( { ok_func = nil } )
end

function MenuManager:steam_disconnected()
	-- print( "psn_disconnected()" )
	if managers.network:session() then
		managers.network:queue_stop_network()
		managers.platform:set_presence( "Idle" )
		managers.network.matchmake:leave_game()
		managers.network.voice_chat:destroy_voice( true )
		self:exit_online_menues()
	end
	self:show_mp_disconnected_internet_dialog( { ok_func = nil } )
end

function MenuManager:xbox_disconnected()
	print( "xbox_disconnected()" )
	if managers.network:session() then
		managers.network:queue_stop_network()
		managers.platform:set_presence( "Idle" )
		managers.network.matchmake:leave_game()
		managers.network.voice_chat:destroy_voice( true )
	end
	self:exit_online_menues()
	managers.user:on_exit_online_menus()
	self:show_mp_disconnected_internet_dialog( { ok_func = nil } )
end

function MenuManager:ps3_disconnect( connected )
	--print( "MenuManager ps3_disconnect", connected )
	if(not connected and not PSN:is_online())then
		-- managers.platform:set_presence( "Idle" )
		-- if managers.network:session() then
			managers.network:queue_stop_network()
			managers.platform:set_presence( "Idle" )
			managers.network.matchmake:leave_game()
			managers.network.friends:psn_disconnected()
			managers.network.voice_chat:destroy_voice( true )
			-- Global.multiplayer_private = nil
			-- self._wait_for_ps3_rdv_connection = nil
		-- end
		self:show_disconnect_message( true )
	end
	if managers.menu_component then
		managers.menu_component:refresh_player_profile_gui()
	end
end

function MenuManager:show_disconnect_message( requires_signin )
	if( self._showing_disconnect_message ) then
		return
	end

	if self:is_ps3() then
		PS3:abort_display_keyboard()
	end

	--[[local title = managers.localizer:text( "sl_error_dialog_title" )
	local text = managers.localizer:text( "igm_mp_disconnect_local" )

	if( requires_signin ) then
		text = text .. "\n" .. managers.localizer:text( "mpm_err_not_signed_in" )
	end

	local ok = managers.localizer:text( "mpm_mm_dlg_ok" )
	local exit_func = function()
						self._showing_disconnect_message = nil
					end]]
					
	self:exit_online_menues()

	self._showing_disconnect_message = true
	self:show_err_not_signed_in_dialog()
	-- managers.platform:show_dialog( nil, title, text, 1, exit_func, { ok }, managers.platform.DIALOG_TYPE_OK )
	
end

-- Should be called when lobby has been created correctly
function MenuManager:created_lobby()
	Global.game_settings.single_player = false
	managers.network:host_game()
	Network:set_multiplayer( true )
	Network:set_server()
	-- managers.menu:close_menu( "menu_main" )
	self:on_enter_lobby() -- In MenuManagerPD2
end

function MenuManager:exit_online_menues()
	-- print( ":exit_online_menues()" )
	managers.system_menu:force_close_all()
	Global.controller_manager.connect_controller_dialog_visible = nil
	self:_close_lobby_menu_components()
	if self:active_menu() then
		self:close_menu( self:active_menu().name )
	end
	self:open_menu( "menu_main" )
	if not managers.menu:is_pc_controller() then
		-- managers.menu:active_menu().input:deactivate_controller_mouse()
	end
	--[[if managers.network.shared_rdv then
		managers.network.shared_rdv:disconnect()
	end
	self._trad_pop_screen_count = #self._trad_screen_stack
	self._pop_all_screens = true
	while( #self._nodes > 2 ) do
		self:back(true)
	end]]
end

function MenuManager:leave_online_menu()
	if self:is_ps3() then
		PSN:set_online_callback( callback(self, self, "refresh_player_profile_gui") )
		-- PSN:set_online_callback( function()end )
	end
	if self:is_x360() then
		managers.user:on_exit_online_menus()
	end
end

function MenuManager:refresh_player_profile_gui()
	if managers.menu_component then
		managers.menu_component:refresh_player_profile_gui()
	end
end

function MenuManager:_close_lobby_menu_components()
	managers.menu_scene:hide_all_lobby_characters()
	managers.menu_component:remove_game_chat()
	managers.menu_component:close_lobby_profile_gui()
	managers.menu_component:close_contract_gui()
	managers.menu_component:close_chat_gui()
end

function MenuManager:on_leave_lobby()
	--[[managers.network:session():local_peer():set_in_lobby( false )
	local peer_id = managers.network:session():local_peer():id()
	managers.network:session():send_to_peers( "set_peer_left", peer_id )]]
	
	-- managers.network:queue_stop_network()
	local skip_destroy_matchmaking = self:is_ps3()
	managers.network:prepare_stop_network( skip_destroy_matchmaking )
	
	if self:is_x360() then
		managers.user:on_exit_online_menus()
	end
	managers.platform:set_rich_presence( "Idle" )
	
	managers.menu:close_menu( "menu_main" )
	managers.menu:open_menu( "menu_main" )
	-- managers.menu:active_menu().logic:navigate_back( true )
	-- managers.menu:open_menu( "menu_main" )
	
	managers.network.matchmake:leave_game()
	managers.network.voice_chat:destroy_voice()
		
	self:_close_lobby_menu_components()
	
	-- managers.menu_component:create_newsfeed_gui()

	-- Verify difficulty
	if Global.game_settings.difficulty == "overkill_145" and managers.experience:current_level() < 145 then
		Global.game_settings.difficulty = "overkill"
	end
	
	managers.job:deactivate_current_job()
end

function MenuManager:show_global_success( node )
	local node_gui
	if not node then
		local stack = managers.menu:active_menu().renderer._node_gui_stack
		node_gui = stack[ #stack ]
	
		if not node_gui.set_mini_info then
			print( "No mini info to set!" )
			return
		end
	end

	if not managers.network.account.get_win_ratio then
		if node_gui then
			node_gui:set_mini_info( "" )
		end
	
		return
	end

	local rate = managers.network.account:get_win_ratio( Global.game_settings.difficulty, Global.game_settings.level_id )
	
	if not rate then
		if node_gui then
			node_gui:set_mini_info( "" )
		end
		
		return
	end

	rate = rate * 100
	local rate_str
	
	if rate >= 10 then
		rate_str = string.format( "%.0f", rate )
	else
		rate_str = string.format( "%.1f", rate )
	end

	local diff_str = string.upper( managers.localization:text( "menu_difficulty_" .. Global.game_settings.difficulty ) )
	local heist_str = string.upper( managers.localization:text( tweak_data.levels[Global.game_settings.level_id].name_id ) )
	rate_str = managers.localization:text( "menu_global_success", { COUNT = rate_str, HEIST = heist_str, DIFFICULTY = diff_str } )
	
	
	if node then
		node.mini_info = rate_str
	else
		node_gui:set_mini_info( rate_str )
	end

end

function MenuManager:change_theme( theme )
	managers.user:set_setting( "menu_theme", theme )

	for _, menu in ipairs( self._open_menus ) do
		menu.renderer:refresh_theme()
	end
end

function MenuManager:on_storage_changed( old_user_data, user_data )
	-- print( "MenuManager:on_storage_changed" )
	-- print( "old_user_data", inspect( old_user_data ) )
	-- print( "user_data", inspect( user_data ) )
	-- Did we have an old user data with a storage ID, and is the new user data signed in
	if old_user_data and old_user_data.storage_id and (user_data and user_data.signin_state ~= "not_signed_in") and not old_user_data.has_signed_out then
		if managers.user:get_platform_id() == user_data.platform_id then
			-- Storage device has been removed, take actions
			self:show_storage_removed_dialog()
			print( "!!!!!!!!!!!!!!!!!!! STORAGE LOST" )
			managers.savefile:break_loading_sequence()
			if game_state_machine:current_state().on_storage_changed then
				game_state_machine:current_state():on_storage_changed( old_user_data, user_data )
			end
		end
	end
end

function MenuManager:on_user_changed( old_user_data, user_data )
	-- print( "MenuManager:on_user_changed?" )
	-- print( "old_user_data", inspect( old_user_data ) )
	-- print( "user_data", inspect( user_data ) )
	if old_user_data and (old_user_data.signin_state ~= "not_signed_in" or not old_user_data.username) then
		print( "MenuManager:on_user_changed(), clear save data" )
		if game_state_machine:current_state().on_user_changed then
			game_state_machine:current_state():on_user_changed( old_user_data, user_data )
		end
		-- print( "NEED CLEAR DATA" )
		self:reset_all_loaded_data() 
	end
end

function MenuManager:reset_all_loaded_data()
	self:do_clear_progress()
	managers.user:reset_setting_map()
	managers.statistics:reset()
end

function MenuManager:do_clear_progress()
	managers.skilltree:reset()
	managers.experience:reset()
	managers.money:reset()
	managers.challenges:reset_challenges()
	managers.blackmarket:reset()
	managers.dlc:on_reset_profile()
	managers.mission:on_reset_profile()
	managers.infamy:reset()
	
	managers.crimenet:reset_seed()
	
	-- Hack :\
	if Global.game_settings.difficulty == "overkill_145" then
		Global.game_settings.difficulty = "overkill"
	end
	
	managers.user:set_setting( "mask_set", "clowns" )
end

-- Called from UserManager when a load to start menu has been triggered from user change
function MenuManager:on_user_sign_out()
	print( "MenuManager:on_user_sign_out()" )
	if managers.network:session() then
		managers.network:queue_stop_network()
		managers.platform:set_presence( "Idle" )
		
		if managers.network:session():_local_peer_in_lobby() then
			managers.network.matchmake:leave_game()
		else
			managers.network.matchmake:destroy_game()
		end
		-- managers.network.friends:psn_disconnected()
		managers.network.voice_chat:destroy_voice( true )
	end
end


--------------------------------------------------------------------
-- Callback handler for the main menu

function MenuCallbackHandler:init()
	MenuCallbackHandler.super.init( self )
	self._sound_source = SoundDevice:create_source( "MenuCallbackHandler" )
end

function MenuCallbackHandler:trial_buy()
	print( "[MenuCallbackHandler:trial_buy]" )
	managers.dlc:buy_full_game()
end

function MenuCallbackHandler:dlc_buy_pc()
	print( "[MenuCallbackHandler:dlc_buy_pc]" )
	Steam:overlay_activate( "store", 218620 )
end

function MenuCallbackHandler:dlc_buy_gage_pack_pc()
	print( "[MenuCallbackHandler:dlc_buy_gage_pack_pc]" )
	Steam:overlay_activate( "store", 267380 )
end

function MenuCallbackHandler:dlc_buy_gage_pack_lmg_pc()
	print( "[MenuCallbackHandler:dlc_buy_gage_pack_lmg_pc]" )
	Steam:overlay_activate( "store", 275590 )
end

function MenuCallbackHandler:dlc_buy_armadillo_pc()
	print( "[MenuCallbackHandler:dlc_buy_armadillo_pc]" )
	Steam:overlay_activate( "store", 264610 )
end

function MenuCallbackHandler:dlc_buy_ps3()
	print( "[MenuCallbackHandler:dlc_buy_ps3]" )
	managers.dlc:buy_product( "dlc1" )
end

function MenuCallbackHandler:has_full_game()
	return managers.dlc:has_full_game()
end

function MenuCallbackHandler:is_trial()
	return managers.dlc:is_trial()
end

function MenuCallbackHandler:is_not_trial()
	return not self:is_trial()
end

function MenuCallbackHandler:has_preorder()
	return managers.dlc:has_preorder()
end

function MenuCallbackHandler:not_has_preorder()
	return not managers.dlc:has_preorder()
end

function MenuCallbackHandler:has_all_dlcs()
	return true --managers.dlc:has_preorder() -- preorder is not in-game purchaseable dlc
end

--------------------------------------------------------------------

function MenuCallbackHandler:is_dlc_latest_locked( check_dlc )
	local dlcs = { "gage_pack_lmg", "gage_pack", "armored_transport" }
	local dlc_tweak_data = tweak_data.dlc
	for _, dlc in ipairs( dlcs ) do
		if dlc_tweak_data[ dlc ] then
			local dlc_func = dlc_tweak_data[ dlc ].dlc
			if dlc_tweak_data[ dlc ].free then
				return false
			elseif dlc_func then
				if not managers.dlc[ dlc_func ]( managers.dlc, dlc_tweak_data[ dlc ] ) then
					return dlc == check_dlc
				end
			else
				Application:error( "[is_dlc_lastest_locked] DLC do not have a dlc check function tweak_data_dlc.dlc", dlc )
			end
			
			if dlc == check_dlc then
				break
			end
		else
			Application:error( "[is_dlc_lastest_locked] DLC do not exist in dlc tweak data", dlc )
		end
	end
	return false
end

function MenuCallbackHandler:visible_callback_armored_transport()
	return self:is_dlc_latest_locked( "armored_transport" )
end

function MenuCallbackHandler:visible_callback_gage_pack()
	return self:is_dlc_latest_locked( "gage_pack" )
end

function MenuCallbackHandler:visible_callback_gage_pack_lmg()
	return self:is_dlc_latest_locked( "gage_pack_lmg" )
end


function MenuCallbackHandler:not_has_all_dlcs()
	return not self:has_all_dlcs()
end

function MenuCallbackHandler:has_armored_transport()
	return managers.dlc:has_armored_transport()
end

function MenuCallbackHandler:not_has_armored_transport()
	return not self:has_armored_transport()
end

function MenuCallbackHandler:has_gage_pack()
	return managers.dlc:has_gage_pack()
end

function MenuCallbackHandler:not_has_gage_pack()
	return not self:has_gage_pack()
end

function MenuCallbackHandler:reputation_check( data )
	return managers.experience:current_level() >= data:value()
end

function MenuCallbackHandler:non_overkill_145( data )
	return true -- not (Global.game_settings.difficulty == "overkill_145")
end

function MenuCallbackHandler:to_be_continued()
	return true
end

function MenuCallbackHandler:is_level_145()
	return managers.experience:current_level() >= 145
end

function MenuCallbackHandler:is_level_100()
	return managers.experience:current_level() >= 100
end

function MenuCallbackHandler:is_level_50()
	return managers.experience:current_level() >= 50
end

function MenuCallbackHandler:is_win32()
	return SystemInfo:platform() == Idstring( "WIN32" )
end

function MenuCallbackHandler:voice_enabled()
	return self:is_ps3() or (self:is_win32() and managers.network and managers.network.voice_chat and managers.network.voice_chat:enabled())
end

function MenuCallbackHandler:customize_controller_enabled()
	return true -- Application:production_build()
end

function MenuCallbackHandler:is_win32_not_lan()
	return SystemInfo:platform() == Idstring( "WIN32" ) and not Global.game_settings.playing_lan
end

function MenuCallbackHandler:is_console()
	return self:is_ps3() or self:is_x360()
end

function MenuCallbackHandler:is_ps3()
	return SystemInfo:platform() == Idstring( "PS3" )
end

function MenuCallbackHandler:is_x360()
	return SystemInfo:platform() == Idstring( "X360" )
end

function MenuCallbackHandler:is_not_x360()
	return not self:is_x360()
end

function MenuCallbackHandler:is_not_xbox()
	return not self:is_x360()
end

function MenuCallbackHandler:is_na()
	return MenuManager.IS_NORTH_AMERICA
end

function MenuCallbackHandler:has_dropin()
	return NetworkManager.DROPIN_ENABLED
end

function MenuCallbackHandler:kicking_allowed()
	return Global.game_settings.kicking_allowed
end
 
-- Visibility callback
function MenuCallbackHandler:is_server()
	return Network:is_server()
end

function MenuCallbackHandler:is_not_server()
	return not self:is_server()
end

function MenuCallbackHandler:is_online()
	return managers.network.account:signin_state() == "signed in"
end

function MenuCallbackHandler:is_singleplayer()
	return Global.game_settings.single_player
end

function MenuCallbackHandler:is_multiplayer()
	return not Global.game_settings.single_player
end

function MenuCallbackHandler:is_prof_job()
	return managers.job:is_current_job_professional()
end

function MenuCallbackHandler:is_normal_job()
	return not self:is_prof_job()
end

function MenuCallbackHandler:is_not_max_rank()
	return managers.experience:current_rank() < #tweak_data.infamy.ranks
end

function MenuCallbackHandler:can_become_infamous()
	return self:is_level_100() and self:is_not_max_rank()
end

function MenuCallbackHandler:singleplayer_restart()
	return self:is_singleplayer() and self:has_full_game() and self:is_normal_job() and not managers.job:stage_success()
end

function MenuCallbackHandler:kick_player_visible()
	return self:is_server() and self:is_multiplayer() and managers.platform:presence() ~= "Mission_end" and Global.game_settings.kicking_allowed
end

function MenuCallbackHandler:abort_mission_visible()
	if not self:is_not_editor() or not self:is_server() or not self:is_multiplayer() then
		return false
	end

	if game_state_machine:current_state_name() == "disconnected" then
		return false
	end

	return true
end

function MenuCallbackHandler:lobby_exist()
	return managers.network.matchmake.lobby_handler
end

function MenuCallbackHandler:hidden()
	return false
end

function MenuCallbackHandler:chat_visible()
	return SystemInfo:platform() == Idstring( "WIN32" )
	-- return managers.menu:active_menu().input._controller.TYPE == "pc"
end

function MenuCallbackHandler:is_pc_controller()
	return managers.menu:is_pc_controller()  -- managers.menu._controller:get_type() == "pc"
	-- return SystemInfo:platform() == Idstring( "WIN32" )
end

function MenuCallbackHandler:is_not_pc_controller()
	return (not self:is_pc_controller())
end

function MenuCallbackHandler:is_not_editor()
	return not Application:editor()
end

function MenuCallbackHandler:show_credits()
	game_state_machine:change_state_by_name( "menu_credits" )
end

function MenuCallbackHandler:can_load_game()
	-- Check if any save files exists and make sure the menu is reloaded when a save is available since the menu system doesn't detect visible changes.
	return not Application:editor() and not Network:multiplayer()
end

function MenuCallbackHandler:can_save_game()
	return not Application:editor() and not Network:multiplayer()
end

function MenuCallbackHandler:is_not_multiplayer()
	return not Network:multiplayer()
end

function MenuCallbackHandler:debug_menu_enabled()
	return managers.menu:debug_menu_enabled()
end

function MenuCallbackHandler:leave_online_menu()
	-- if not managers.network:session() or managers.network:session():local_peer():id() == 1 then -- Otherwise we are closing the menu to join the lobby
	managers.menu:leave_online_menu()
	-- end
end

function MenuCallbackHandler:on_visit_forum()
	Steam:overlay_activate( "url", "http://forums.steampowered.com/forums/forumdisplay.php?f=1225" )
end

function MenuCallbackHandler:on_visit_gamehub()
	Steam:overlay_activate( "url", "http://steamcommunity.com/app/218620" )
end

function MenuCallbackHandler:on_buy_dlc1()
	Steam:overlay_activate( "store", 218620 )
end

function MenuCallbackHandler:quit_game()
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_are_you_sure_you_want_to_quit" )

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_quit_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_quit_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:_dialog_quit_yes()
	self:_dialog_save_progress_backup_no()

	--[[local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_ask_save_progress_backup" )
	dialog_data.focus_button = 1

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_save_progress_backup_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_save_progress_backup_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data ) ]]
end

function MenuCallbackHandler:_dialog_quit_no()
end

function MenuCallbackHandler:_dialog_save_progress_backup_yes()
	managers.savefile:save_progress( "local_hdd" )
	setup:quit()
end

function MenuCallbackHandler:_dialog_save_progress_backup_no()
	setup:quit()
end

function MenuCallbackHandler:toggle_god_mode( item )
	local god_mode_on = item:value() == "on"
	Global.god_mode = god_mode_on
	if( managers.player:player_unit() ) then
		managers.player:player_unit():character_damage():set_god_mode( god_mode_on )
	end
end

function MenuCallbackHandler:toggle_post_effects( item )
	local post_effects_on = item:value() == "on"
	Global.debug_post_effects_enabled = post_effects_on
	
	if not post_effects_on then
		managers.environment_controller:set_suppression_value( 0 )
	end
end

function MenuCallbackHandler:toggle_alienware_mask( item )
	local use_mask = item:value() == "on"
	
	if not (SystemInfo:platform() == Idstring( "WIN32" ) and managers.network.account:has_alienware()) then
		use_mask = false
	end

	managers.user:set_setting( "alienware_mask", use_mask )
end

function MenuCallbackHandler:toggle_developer_mask( item )
	local use_mask = item:value() == "on"
	
	if not (SystemInfo:platform() == Idstring( "WIN32" ) and managers.network.account:is_developer()) then
		use_mask = false
	end
	
	managers.user:set_setting( "developer_mask", use_mask )
end



function MenuCallbackHandler:toggle_ready( item )
	local ready = item:value() == "on"
		
	if not managers.network:session() then
		return
	end
	
	managers.network:session():local_peer():set_waiting_for_player_ready( ready )
	managers.network:session():chk_send_local_player_ready()
	
	if managers.menu:active_menu() and managers.menu:active_menu().renderer then
		if managers.menu:active_menu().renderer.set_ready_items_enabled then
			managers.menu:active_menu().renderer:set_ready_items_enabled( not ready )
		end
	end
	
	managers.network:game():on_set_member_ready( managers.network:session():local_peer():id(), ready, true )
end

function MenuCallbackHandler:freeflight( item )
	if setup:freeflight() then
		setup:freeflight():enable()
		self:resume_game()
	end
end

function MenuCallbackHandler:change_nr_players( item )
	local nr_players = item:value()

	Global.nr_players = nr_players
	managers.player:set_nr_players( nr_players )
end


function MenuCallbackHandler:toggle_rumble( item )
	local rumble = item:value() == "on"
	managers.user:set_setting( "rumble", rumble )
end

function MenuCallbackHandler:invert_camera_horisontally( item )
	local invert = item:value() == "on"
	managers.user:set_setting( "invert_camera_x", invert )
end

function MenuCallbackHandler:invert_camera_vertically( item )
	local invert = item:value() == "on"
	managers.user:set_setting( "invert_camera_y", invert )
end

function MenuCallbackHandler:toggle_southpaw( item )
	local southpaw = item:value() == "on"
	managers.user:set_setting( "southpaw", southpaw )
end

function MenuCallbackHandler:toggle_dof_setting( item )
	local dof_setting = item:value() == "on"
	managers.user:set_setting( "dof_setting", dof_setting and "standard" or "none" )
end

function MenuCallbackHandler:hold_to_steelsight( item )
	local hold = item:value() == "on"
	managers.user:set_setting( "hold_to_steelsight", hold )
end

function MenuCallbackHandler:hold_to_run( item )
	local hold = item:value() == "on"
	managers.user:set_setting( "hold_to_run", hold )
end

function MenuCallbackHandler:hold_to_duck( item )
	local hold = item:value() == "on"
	managers.user:set_setting( "hold_to_duck", hold )
end

function MenuCallbackHandler:toggle_fullscreen( item )
	local fullscreen = item:value() == "on"
	if RenderSettings.fullscreen == fullscreen then
		return
	end
	
	managers.viewport:set_fullscreen( fullscreen )
	managers.menu:show_accept_gfx_settings_dialog( 
	function()
		managers.viewport:set_fullscreen( not fullscreen )
		item:set_value( (not fullscreen) and "on" or "off" )
	end )
end

function MenuCallbackHandler:toggle_subtitle( item )
	local subtitle = item:value() == "on"
	managers.user:set_setting( "subtitle", subtitle )
end

function MenuCallbackHandler:toggle_hit_indicator( item )
	local on = item:value() == "on"
	managers.user:set_setting( "hit_indicator", on )
end

function MenuCallbackHandler:toggle_objective_reminder( item )
	local on = item:value() == "on"
	managers.user:set_setting( "objective_reminder", on )
end

function MenuCallbackHandler:toggle_aim_assist( item )
	local on = item:value() == "on"
	managers.user:set_setting( "aim_assist", on )
end

function MenuCallbackHandler:toggle_voicechat( item )
	local vchat = item:value() == "on"
	managers.user:set_setting( "voice_chat", vchat )
end

function MenuCallbackHandler:toggle_push_to_talk( item )
	local vchat = item:value() == "on"
	managers.user:set_setting( "push_to_talk", vchat )
end


function MenuCallbackHandler:toggle_team_AI( item )
	Global.game_settings.team_ai = item:value() == "on"
	managers.groupai:state():on_criminal_team_AI_enabled_state_changed()
end

function MenuCallbackHandler:toggle_coordinates( item )
	if item:value() == "off" then
		managers.hud:debug_hide_coordinates()
	else
		managers.hud:debug_show_coordinates()
	end
end

function MenuCallbackHandler:change_resolution( item )
	local old_resolution = RenderSettings.resolution
	if item:parameters().resolution == old_resolution then
		return
	end

	managers.viewport:set_resolution( item:parameters().resolution )
	managers.viewport:set_aspect_ratio( item:parameters().resolution.x/item:parameters().resolution.y )

	managers.menu:show_accept_gfx_settings_dialog( 
	function()
		managers.viewport:set_resolution( old_resolution )
		managers.viewport:set_aspect_ratio( old_resolution.x / old_resolution.y )	
	end )
end

function MenuCallbackHandler:choice_test( item )
	local test = item:value()
	print( "MenuCallbackHandler", test )
end


function MenuCallbackHandler:choice_mask( item )
	local mask_set = item:value()
	print( "[MenuCallbackHandler:choice_mask]", mask_set )

	managers.user:set_setting( "mask_set", mask_set )

	local peer = managers.network:session():local_peer()
	peer:set_mask_set( mask_set )

	if Global.game_settings.single_player then
		if managers.menu:active_menu().renderer.set_character then
			managers.menu:active_menu().renderer:set_character( peer:id(), peer:character() )
		end
	else	
		managers.menu:active_menu().renderer:set_character( peer:id(), peer:character() )
		managers.network:session():send_to_peers( "set_mask_set", peer:id(), mask_set )
	end
end

function MenuCallbackHandler:choice_premium_contact( item )
	if not managers.menu:active_menu() then
		return false
	end
	if not managers.menu:active_menu().logic then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node() then
		return false
	end
	
	
	
	managers.menu:active_menu().logic:selected_node():parameters().listed_contact = string.gsub( item:value(), "#", "" )
	
	local logic = managers.menu:active_menu().logic
	if logic then
		logic:refresh_node()
	end
end

function MenuCallbackHandler:choice_max_lobbies_filter( item )
	if not managers.crimenet then
		return 
	end

	local max_server_jobs_filter = item:value()

	managers.network.matchmake:set_lobby_return_count( max_server_jobs_filter )

	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_distance_filter( item )
	local dist_filter = item:value()
	
	if managers.network.matchmake:distance_filter() == dist_filter then
		return
	end

	managers.network.matchmake:set_distance_filter( dist_filter )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_difficulty_filter( item )
	local diff_filter = item:value()
	print( "diff_filter", diff_filter )

	if managers.network.matchmake:get_lobby_filter( "difficulty" ) == diff_filter then
		return
	end





	managers.network.matchmake:add_lobby_filter( "difficulty", diff_filter, "equal" )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_job_id_filter( item )
	local job_id_filter = item:value()

	if managers.network.matchmake:get_lobby_filter( "job_id" ) == job_id_filter then
		return
	end

	managers.network.matchmake:add_lobby_filter( "job_id", job_id_filter, "equal" )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_new_servers_only( item )
	local num_players_filter = item:value()

	if managers.network.matchmake:get_lobby_filter( "num_players" ) == num_players_filter then
		return
	end

	managers.network.matchmake:add_lobby_filter( "num_players", num_players_filter, "equal" )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_kicking_allowed( item )
	local kicking_filter = item:value()
	
	if managers.network.matchmake:get_lobby_filter( "kicking_allowed" ) == kicking_filter then
		return
	end

	managers.network.matchmake:add_lobby_filter( "kicking_allowed", kicking_filter, "equal" )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:choice_server_state_lobby( item )
	local state_filter = item:value()

	if managers.network.matchmake:get_lobby_filter( "state" ) == state_filter then
		return
	end

	managers.network.matchmake:add_lobby_filter( "state", state_filter, "equal" )
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end

function MenuCallbackHandler:refresh_node( item )
	local logic = managers.menu:active_menu().logic

	if logic then
		logic:refresh_node()
	end
end

function MenuCallbackHandler:open_contract_node( item )
	local is_professional = tweak_data.narrative.jobs[ item:parameters().id ].professional or false
	managers.menu:open_node( Global.game_settings.single_player and "crimenet_contract_singleplayer" or "crimenet_contract_host", {{job_id = item:parameters().id, difficulty = is_professional and "hard" or "normal", difficulty_id = is_professional and 3 or 2, professional = is_professional, customize_contract = true}} )
end

function MenuCallbackHandler:is_contract_difficulty_allowed( item )
	if not managers.menu:active_menu() then
		return false
	end
	if not managers.menu:active_menu().logic then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node() then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node():parameters().menu_component_data then
		return false
	end

	local job_data = managers.menu:active_menu().logic:selected_node():parameters().menu_component_data
	if not job_data.job_id then
		return false
	end
	if job_data.professional and item:value() < 3 then
		return false
	end

	local job_jc = tweak_data.narrative.jobs[ job_data.job_id ].jc
	local difficulty_jc = ( item:value() - 2 ) * 10

	return managers.job:get_max_jc_for_player() >= job_jc + difficulty_jc
end

function MenuCallbackHandler:buy_crimenet_contract( item, node )
	local job_data = item:parameters().gui_node.node:parameters().menu_component_data
	if not managers.money:can_afford_buy_premium_contract( job_data.job_id, job_data.difficulty_id or 3 ) then
		return 
	end

	local params = {}
	params.contract_fee = managers.experience:cash_string( managers.money:get_cost_of_premium_contract( job_data.job_id, job_data.difficulty_id or 3 ) )
	params.offshore = managers.experience:cash_string( managers.money:offshore() )

	params.yes_func = callback( self, self, "_buy_crimenet_contract", item, node )
	managers.menu:show_confirm_buy_premium_contract( params )
end

function MenuCallbackHandler:_buy_crimenet_contract( item, node )
	local job_data = item:parameters().gui_node.node:parameters().menu_component_data
	
	if not managers.money:can_afford_buy_premium_contract( job_data.job_id, job_data.difficulty_id or 3 ) then
		return
	end
	managers.money:on_buy_premium_contract( job_data.job_id, job_data.difficulty_id or 3 )
	
	
	managers.menu:active_menu().logic:navigate_back( true )
	managers.menu:active_menu().logic:navigate_back( true )
	
	self._sound_source:post_event( "item_buy" )
	if Global.game_settings.single_player then
		MenuCallbackHandler:start_single_player_job( job_data )
	else
		MenuCallbackHandler:start_job( job_data )
	end
	MenuCallbackHandler:save_progress()
end

function MenuCallbackHandler:crimenet_casino_secured_cards()
	local card1 = managers.menu:active_menu().logic:selected_node():item( "secure_card_1" ):value() == "on" and 1 or 0
	local card2 = managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):value() == "on" and 1 or 0
	local card3 = managers.menu:active_menu().logic:selected_node():item( "secure_card_3" ):value() == "on" and 1 or 0
	
	return card1 + card2 + card3
end

function MenuCallbackHandler:crimenet_casino_update( item )
	if item:enabled() then
		self:refresh_node()
	end
end

function MenuCallbackHandler:crimenet_casino_safe_card1( item )
	if managers.menu:active_menu().logic:selected_node():item( "secure_card_1" ):enabled() then
		if managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):value() == "on" then
			managers.menu:active_menu().logic:selected_node():item( "secure_card_1" ):set_value( "on" )
		end
		
		managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):set_value( "off" )
		managers.menu:active_menu().logic:selected_node():item( "secure_card_3" ):set_value( "off" )
		
		self:refresh_node()
	end
end

function MenuCallbackHandler:crimenet_casino_safe_card2( item )
	if managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):enabled() then
		if managers.menu:active_menu().logic:selected_node():item( "secure_card_3" ):value() == "on" then
			managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):set_value( "on" )
		end
		
		managers.menu:active_menu().logic:selected_node():item( "secure_card_1" ):set_value( "on" )
		managers.menu:active_menu().logic:selected_node():item( "secure_card_3" ):set_value( "off" )
		
		self:refresh_node()
	end
end

function MenuCallbackHandler:crimenet_casino_safe_card3( item )
	if managers.menu:active_menu().logic:selected_node():item( "secure_card_3" ):enabled() then
		managers.menu:active_menu().logic:selected_node():item( "secure_card_1" ):set_value( "on" )
		managers.menu:active_menu().logic:selected_node():item( "secure_card_2" ):set_value( "on" )
		
		self:refresh_node()
	end
end

function MenuCallbackHandler:not_customize_contract( item )
	return not self:customize_contract( item )
end

function MenuCallbackHandler:customize_contract( item )
	if not managers.menu:active_menu() then
		return false
	end
	if not managers.menu:active_menu().logic then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node() then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node():parameters().menu_component_data then
		return false
	end

	return managers.menu:active_menu().logic:selected_node():parameters().menu_component_data.customize_contract
end

function MenuCallbackHandler:change_contract_difficulty( item )
	managers.menu_component:set_crimenet_contract_difficulty_id( item:value() )

	if not managers.menu:active_menu().logic then
		return false
	end
	if not managers.menu:active_menu().logic:selected_node() then
		return false
	end

	local job_data = item:parameters().gui_node.node:parameters().menu_component_data
	if not job_data or not job_data.job_id then
		return false
	end

	local buy_contract_item = managers.menu:active_menu().logic:selected_node():item( "buy_contract" )
	if not buy_contract_item then
		return false
	end

	local can_afford = managers.money:can_afford_buy_premium_contract( job_data.job_id, job_data.difficulty_id or 3 )

	buy_contract_item:parameters().text_id = can_afford and "menu_cn_premium_buy_accept" or "menu_cn_premium_cannot_buy"
	buy_contract_item:set_enabled( can_afford )

	self:refresh_node()
end



function MenuCallbackHandler:choice_difficulty_filter_ps3( item )
	local diff_filter = item:value()
	print( "diff_filter", diff_filter )
	if managers.network.matchmake:difficulty_filter() == diff_filter then
		return
	end

	managers.network.matchmake:set_difficulty_filter( diff_filter )
	managers.network.matchmake:start_search_lobbys( managers.network.matchmake:searching_friends_only() )
end


-- Lobby difficulty affects what levels can be chosen.
function MenuCallbackHandler:choice_lobby_difficulty( item )
	local difficulty = item:value()
	Global.game_settings.difficulty = difficulty
	
	--local difficulty = item:selected_option():parameters().difficulty
	--local lobby_campaign_item = managers.menu:active_menu().logic:get_item( "lobby_campaign" )
	--lobby_campaign_item = lobby_campaign_item or managers.menu:active_menu().logic:get_item( "single_player_campaign" ) -- If it is single player
	--[[
	local current_index = lobby_campaign_item:current_index()
	for i,option in ipairs( lobby_campaign_item:options() ) do
		option:parameters().exclude = ( option:parameters().difficulty > difficulty )
		if option:parameters().exclude then
			if current_index == i then
				current_index = 1
			end
		end
	end
	]]
	if managers.menu:active_menu().renderer.update_difficulty then
		managers.menu:active_menu().renderer:update_difficulty()
	end
	
	-- lobby_campaign_item:set_current_index( current_index )
	--[[
	if Global.game_settings.level_id ~= lobby_campaign_item:value() then
		Global.game_settings.level_id = lobby_campaign_item:value()
		if managers.menu:active_menu().renderer.update_level_id then
			managers.menu:active_menu().renderer:update_level_id( Global.game_settings.level_id )
		end
	end
	]]
	
	
	if difficulty == "overkill_145" and Global.game_settings.reputation_permission < 145 then
		local item_reputation_permission = managers.menu:active_menu().logic:selected_node():item( "lobby_reputation_permission" )

		if item_reputation_permission and item_reputation_permission:visible() then
			item_reputation_permission:set_value( 145 )
			item_reputation_permission:trigger()
		end
	end
	
	managers.menu:show_global_success()
	
	self:update_matchmake_attributes()
end

function MenuCallbackHandler:choice_lobby_campaign( item )
	if not item:enabled() then
		return
	end


	Global.game_settings.level_id = item:parameter( "level_id" )
	MenuManager.refresh_level_select( managers.menu:active_menu().logic:selected_node(), true )
	
	if managers.menu:active_menu().renderer.update_level_id then
		managers.menu:active_menu().renderer:update_level_id( Global.game_settings.level_id )
	end
	
	if managers.menu:active_menu().renderer.update_difficulty then
		managers.menu:active_menu().renderer:update_difficulty()
	end
	
	managers.menu:show_global_success()
	
	self:update_matchmake_attributes()
end

function MenuCallbackHandler:choice_lobby_mission( item )
	if not item:enabled() then
		return
	end
	Global.game_settings.mission = item:value()
	-- print( "MenuCallbackHandler:choice_lobby_mission", item, item:value() )
end


function MenuCallbackHandler:choice_friends_only( item )
	local choice_friends_only = item:value() == "on"
	Global.game_settings.search_friends_only = choice_friends_only
	-- self:update_matchmake_attributes()
end


function MenuCallbackHandler:choice_lobby_permission( item )
	local permission = item:value()
	local level_id = item:value()
	Global.game_settings.permission = permission
	self:update_matchmake_attributes()
end

function MenuCallbackHandler:choice_lobby_reputation_permission( item )
	local reputation_permission = item:value()
	Global.game_settings.reputation_permission = reputation_permission
	
	--[[if reputation_permission < 145 and Global.game_settings.difficulty == "overkill_145" then
		Global.game_settings.difficulty = "overkill"
		
		local item_difficulty = managers.menu:active_menu().logic:selected_node():item( "lobby_difficulty" )
		if item_difficulty then
			item_difficulty:set_value( Global.game_settings.difficulty )
			item_difficulty:trigger()
		end
		
		if managers.menu:active_menu().renderer.update_difficulty then
			managers.menu:active_menu().renderer:update_difficulty()
		end
	end]]
	
	self:update_matchmake_attributes()
end

function MenuCallbackHandler:choice_team_ai( item )
	local team_ai = item:value() == "on"
	Global.game_settings.team_ai = team_ai
end

function MenuCallbackHandler:choice_drop_in( item )
	local choice_drop_in = item:value() == "on"
	Global.game_settings.drop_in_allowed = choice_drop_in
	self:update_matchmake_attributes()
	
	if managers.network:session() then
		managers.network:session():chk_server_joinable_state()
	end
end

---------------------------------------------------------------

function MenuCallbackHandler:choice_kicking_option( item )
	local kick_option = item:value() == "on"
	Global.game_settings.kicking_allowed = kick_option
end

function MenuCallbackHandler:choice_crimenet_lobby_permission( item )
	local permission = item:value()
	Global.game_settings.permission = permission
end

function MenuCallbackHandler:choice_crimenet_lobby_reputation_permission( item )
	local reputation_permission = item:value()
	Global.game_settings.reputation_permission = reputation_permission
end

function MenuCallbackHandler:choice_crimenet_team_ai( item )
	local team_ai = item:value() == "on"
	Global.game_settings.team_ai = team_ai
end

function MenuCallbackHandler:choice_crimenet_drop_in( item )
	local choice_drop_in = item:value() == "on"
	Global.game_settings.drop_in_allowed = choice_drop_in
	
	if managers.network:session() then
		managers.network:session():chk_server_joinable_state()
	end
end


function MenuCallbackHandler:accept_crimenet_contract( item, node )
	managers.menu:active_menu().logic:navigate_back( true )
	local job_data = item:parameters().gui_node.node:parameters().menu_component_data
	
	if job_data.server then
		managers.network.matchmake:join_server_with_check( job_data.room_id, false, job_data )
	elseif Global.game_settings.single_player then
		MenuCallbackHandler:start_single_player_job( job_data )
	else -- Multiplayer
		MenuCallbackHandler:start_job( job_data )
	end
end

function MenuCallbackHandler:kit_menu_ready()
	managers.menu:close_menu( "kit_menu" )
end

function MenuCallbackHandler:set_lan_game()
	Global.game_settings.playing_lan = true
end

function MenuCallbackHandler:set_not_lan_game()
	Global.game_settings.playing_lan = nil
end

function MenuCallbackHandler:get_matchmake_attributes()
	local level_id = tweak_data.levels:get_index_from_level_id( Global.game_settings.level_id )
	local difficulty_id = tweak_data:difficulty_to_index( Global.game_settings.difficulty )
	local permission_id = tweak_data:permission_to_index( Global.game_settings.permission )
	local min_lvl = Global.game_settings.reputation_permission or 0
	local drop_in = Global.game_settings.drop_in_allowed and 1 or 0
	local job_id = tweak_data.narrative:get_index_from_job_id( managers.job:current_job_id() )
	local kicking_allowed = Global.game_settings.kicking_allowed and 1 or 0
	
	
	return { numbers = { level_id+(1000*job_id), difficulty_id, permission_id, nil, nil, drop_in, min_lvl, kicking_allowed } }
end


function MenuCallbackHandler:update_matchmake_attributes()
	managers.network.matchmake:set_server_attributes( self:get_matchmake_attributes() )
end

function MenuCallbackHandler:create_lobby()
	managers.network.matchmake:create_lobby( self:get_matchmake_attributes() )
end

-- Supposed to be a offline single player situation
-- Still need to set it up as if it is a lan base multiplayer.
function MenuCallbackHandler:play_single_player()
	Global.game_settings.single_player = true 
	managers.network:host_game()
	-- Network:set_multiplayer( true )
	Network:set_server()
end

function MenuCallbackHandler:play_online_game()
	Global.game_settings.single_player = false
end

function MenuCallbackHandler:play_safehouse( params )
	local yes_func = function()
		self:play_single_player()
		-- Global.game_settings.level_id = "apartment"
		-- Global.game_settings.difficulty = "normal"
		Global.mission_manager.has_played_tutorial = true
		self:start_single_player_job( { job_id = "safehouse", difficulty = "normal" } )

	 end

	if params.skip_question then
		yes_func()
		return 
	end
	managers.menu:show_play_safehouse_question( { yes_func = yes_func } )
end

function MenuCallbackHandler:_increase_infamous()
	managers.menu_scene:destroy_infamy_card()
	
	if managers.experience:current_level() < 100 or managers.experience:current_rank() >= #tweak_data.infamy.ranks then
		return
	end
	
	local rank = managers.experience:current_rank() + 1
	
	managers.experience:reset()
	managers.experience:set_current_rank( rank )
	
	managers.money:deduct_from_total( managers.money:total() )
	managers.money:deduct_from_offshore( Application:digest_value( tweak_data.infamy.ranks[ rank ], false ) )
	
	managers.skilltree:reset()
	managers.blackmarket:reset_equipped()
	if managers.menu_component then
		managers.menu_component:refresh_player_profile_gui()
	end
	
	local logic = managers.menu:active_menu().logic
	if logic then
		logic:refresh_node()
		logic:select_item( "crimenet" )
	end
	
	if rank <= #tweak_data.achievement.infamous then
		managers.achievment:award( tweak_data.achievement.infamous[ rank ] )
	end
	
	managers.savefile:save_progress()
	managers.savefile:save_setting( true )
	
	self._sound_source:post_event( "infamous_player_join_stinger" )
end

function MenuCallbackHandler:become_infamous( params )
	local infamous_cost = Application:digest_value( tweak_data.infamy.ranks[ managers.experience:current_rank() + 1], false )
	
	local params = {}
	params.cost = managers.experience:cash_string( infamous_cost )
	
	if managers.money:offshore() >= infamous_cost and managers.experience:current_level() >= 100 then
		params.yes_func = function()
			local rank = managers.experience:current_rank() + 1
			managers.menu:open_node( "blackmarket_preview_node", { { back_callback = callback( self, self, "_increase_infamous" ) } } )
			managers.menu_scene:spawn_infamy_card( rank )
			self._sound_source:post_event( "infamous_stinger_level_" .. ( rank < 10 and "0" or "" ) .. tostring( rank ) )
		end
	end
	
	managers.menu:show_confirm_become_infamous( params )
end

function MenuCallbackHandler:choice_choose_character( item )
	-- Need to check with server what is ok, and options need to be server based
	local character = item:value()
	-- local id = managers.network:session():local_peer():id()
	-- managers.menu:active_menu().renderer:set_character( id, character )
	
	local peer_id = managers.network:session():local_peer():id()
	-- managers.menu:active_menu().renderer:set_character( peer_id, character )
	if Network:is_server() then
		managers.network:game():on_peer_request_character( peer_id, character )
	else
		if managers.network:session():server_peer() and not managers.network:session():server_peer():loading() then
			managers.network:session():send_to_host( "request_character", peer_id, character )
		end
	end
	
	-- if managers.menu:active_menu().renderer.update_level_id then
	--	managers.menu:active_menu().renderer:update_level_id( Global.game_settings.level_id )
	-- end
end



function MenuCallbackHandler:choice_choose_texture_quality( item )
	RenderSettings[ "texture_quality_default" ] = item:value()

	Application:apply_render_settings()
	Application:save_render_settings()
end


function MenuCallbackHandler:choice_choose_anisotropic( item )
	RenderSettings[ "max_anisotropy" ] = item:value()
		
	Application:apply_render_settings()
	Application:save_render_settings()
end

function MenuCallbackHandler:choice_fps_cap( item )
	setup:set_fps_cap( item:value() )
	managers.user:set_setting( "fps_cap", item:value() )
end

function MenuCallbackHandler:choice_choose_color_grading( item )
	managers.user:set_setting( "video_color_grading", item:value() )
	
	if managers.environment_controller then
		managers.environment_controller:refresh_render_settings()
	end
end

function MenuCallbackHandler:choice_choose_menu_theme( item )
	managers.menu:change_theme( item:value() )
end

function MenuCallbackHandler:choice_choose_anti_alias( item )
	managers.user:set_setting( "video_anti_alias", item:value() )
	
	if managers.environment_controller then
		managers.environment_controller:refresh_render_settings()
	end
end

function MenuCallbackHandler:choice_choose_anim_lod( item )
	managers.user:set_setting( "video_animation_lod", item:value() )
end

function MenuCallbackHandler:toggle_vsync( item )
	managers.viewport:set_vsync( item:value() == "on" )
end

function MenuCallbackHandler:toggle_streaks( item )
	managers.user:set_setting( "video_streaks", item:value() == "on" )
	
	if managers.environment_controller then
		managers.environment_controller:refresh_render_settings()
	end
end

function MenuCallbackHandler:toggle_light_adaption( item )
	managers.user:set_setting( "light_adaption", item:value() == "on" )
	
	if managers.environment_controller then
		managers.environment_controller:refresh_render_settings()
	end
end


function MenuCallbackHandler:toggle_lightfx( item )
	managers.user:set_setting( "use_lightfx", item:value() == "on" )
end

function MenuCallbackHandler:set_fov_multiplier( item )
	local fov_multiplier = item:value()
	managers.user:set_setting( "fov_multiplier", fov_multiplier )
	
	if alive( managers.player:player_unit() ) then
		managers.player:player_unit():movement():current_state():update_fov_external()
	end
end


function MenuCallbackHandler:set_fov_standard( item )
	do return end
	local fov = item:value()
	managers.user:set_setting( "fov_standard", fov )
	
	local item_fov_zoom = managers.menu:active_menu().logic:selected_node():item( "fov_zoom" )
	if item_fov_zoom:value() > fov then
		item_fov_zoom:set_value( fov )
		item_fov_zoom:trigger()
	end
	
	if alive( managers.player:player_unit() ) then
		local plr_state = managers.player:player_unit():movement():current_state()
		local stance = (plr_state:in_steelsight() and "steelsight") or (plr_state._state_data.ducking and "crouched" or "standard")
		plr_state._camera_unit:base():set_stance_fov_instant( stance )
	end
end

function MenuCallbackHandler:set_fov_zoom( item )
	do return end
	local fov = item:value()
	managers.user:set_setting( "fov_zoom", fov )

	local item_fov_standard = managers.menu:active_menu().logic:selected_node():item( "fov_standard" )
	if item_fov_standard:value() < fov then
		item_fov_standard:set_value( fov )
		item_fov_standard:trigger()
	end

	if alive( managers.player:player_unit() ) then
		local plr_state = managers.player:player_unit():movement():current_state()
		local stance = (plr_state:in_steelsight() and "steelsight") or (plr_state._state_data.ducking and "crouched" or "standard")
		plr_state._camera_unit:base():set_stance_fov_instant( stance )
	end
end

-- Also called from restart in singleplayer
function MenuCallbackHandler:retry_job_stage()
	managers.loot:on_retry_job_stage()
	managers.job:on_retry_job_stage()
	managers.mission:on_retry_job_stage()
	self:lobby_start_the_game()
end

function MenuCallbackHandler:on_stage_success()
	managers.mission:on_stage_success()
end

function MenuCallbackHandler:lobby_start_the_game()
	--[[
	if Global.game_settings.difficulty == "overkill_145" then
		if managers.network:session() then
			for _, peer in pairs( managers.network:session():peers() ) do
				if peer:level() < 145 then
					managers.menu:show_too_low_level_ovk145()
					return
				end
			end
		end
	end
	]]	

	-- print( "MenuCallbackHandler:lobby_start_the_game()" )
	-- managers.network:host_game()
	local level_id = Global.game_settings.level_id -- "bank" -- item:parameters().level_id
	local level_name = level_id and tweak_data.levels[ level_id ].world_name

	if Global.boot_invite then
		Global.boot_invite.used = true
		Global.boot_invite.pending = false
	end
	
	local mission = (Global.game_settings.mission ~= "none" and Global.game_settings.mission) or nil
	
	managers.network:session():load_level( level_name, mission, nil, nil, level_id ) -- , video_goto_time )
end

function MenuCallbackHandler:leave_lobby()
	if game_state_machine:current_state_name() == "ingame_lobby_menu" then
		self:end_game()
		return
	end
	--[[managers.menu:close_menu( "lobby_menu" )
	managers.menu:open_menu( "menu_main" )
	if true then return end]]
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_are_you_sure_you_want_leave" )
	dialog_data.id = "leave_lobby"

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_leave_lobby_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_leave_lobby_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:_dialog_leave_lobby_yes()
	--[[ if server then
			migrate lobby? or send people away
		if client then
			tell everyone that he left
	]]
	if managers.network:session() then
		managers.network:session():local_peer():set_in_lobby( false )
		local peer_id = managers.network:session():local_peer():id()
		managers.network:session():send_to_peers( "set_peer_left", peer_id )
	end
	
	managers.menu:on_leave_lobby()
	
	--[[managers.network:queue_stop_network()
	managers.menu:close_menu( "lobby_menu" )
	managers.menu:open_menu( "menu_main" )
	
	managers.network.matchmake:leave_game()
	managers.network.voice_chat:destroy_voice()]]
end

function MenuCallbackHandler:_dialog_leave_lobby_no()
end

function MenuCallbackHandler:connect_to_host_rpc( item )
	local f = function( res )
		if res == "JOINED_LOBBY" then
			-- managers.menu:close_menu( "menu_main" )
			-- managers.menu:open_menu( "lobby_menu" )
			self:on_enter_lobby() -- In MenuManagerPD2
		elseif res == "JOINED_GAME" then	-- The desired host has answered positively. load the level
			local level_id = tweak_data.levels:get_level_name_from_world_name( item:parameters().level_name )
			managers.network:session():load_level( item:parameters().level_name, nil, nil, nil, level_id, nil )
		elseif res == "KICKED" then
			managers.menu:show_peer_kicked_dialog()
		else
			Application:error("[MenuCallbackHandler:connect_to_host_rpc] FAILED TO START MULTIPLAYER!")
		end
	end
	
	managers.network:join_game_at_host_rpc( item:parameters().rpc, f )
end

function MenuCallbackHandler:host_multiplayer( item )
	managers.network:host_game()
	local level_id = item:parameters().level_id
	local level_name = level_id and tweak_data.levels[ level_id ].world_name
	level_id = level_id or tweak_data.levels:get_level_name_from_world_name( item:parameters().level ) -- Fallback lookup for level id based on "world name"
	level_name = level_name or item:parameters().level or "bank"
	Global.game_settings.level_id = level_id -- Fix for campaign start level, otherwise clients would load bank
	--[[local movie = item:parameters().movie
	local video_goto_time
	if movie then
		movie:set_visible( true )
		video_goto_time = movie:frame_num()/30
		movie:play()
		video_goto_time = movie:frame_num()/30
	end]]
		
	managers.network:session():load_level( level_name, nil, nil, nil, level_id ) -- , video_goto_time )
end

function MenuCallbackHandler:join_multiplayer()
	local f = function( new_host_rpc )
		if new_host_rpc then
			managers.menu:active_menu().logic:refresh_node( "select_host" )
			-- local hosts = managers.network:session():discovered_hosts()
			-- managers.menu:back()
			-- managers.menu:open_node( "select_host" )
		--else
			--print( "MenuMPHostBrowser:modify_node(). found no hosts" )
		end
	end
	managers.network:discover_hosts( f )
end

function MenuCallbackHandler:find_lan_games()
	if self:is_win32() then
		local f = function( new_host_rpc )
			if new_host_rpc then
				managers.menu:active_menu().logic:refresh_node( "play_lan" )
			end
		end
		managers.network:discover_hosts( f )
	end
end

function MenuCallbackHandler:find_online_games_with_friends()
	self:_find_online_games( true )
end

function MenuCallbackHandler:find_online_games()
	self:_find_online_games()
end

function MenuCallbackHandler:_find_online_games( friends_only )
	if self:is_win32() then
		local f = function( info )
			print( "info in function" )
			print( inspect( info ) )
			managers.network.matchmake:search_lobby_done()
			managers.menu:active_menu().logic:refresh_node( "play_online", true, info, friends_only )
		end
		
		managers.network.matchmake:register_callback( "search_lobby", f )
		managers.network.matchmake:search_lobby( friends_only )
		
		
		local usrs_f = function( success, amount )
			print( "usrs_f", success, amount )
		
			if success then
				local stack = managers.menu:active_menu().renderer._node_gui_stack
				local node_gui = stack[ #stack ]
				
				if node_gui.set_mini_info then
					node_gui:set_mini_info( managers.localization:text( "menu_players_online", { COUNT = amount } ) )
				end
			end
		end
		
		Steam:sa_handler():concurrent_users_callback( usrs_f )
		Steam:sa_handler():get_concurrent_users()
	end
	
	-- print( "MenuCallbackHandler:play_online_multiplayer()" )
	
	if self:is_ps3() then
		if #PSN:get_world_list() == 0 then
			return
		end
		
		local f = function( info_list )
			print( "info_list in function" )
			print( inspect( info_list ) )
			managers.network.matchmake:search_lobby_done()
			managers.menu:active_menu().logic:refresh_node( "play_online", true, info_list, friends_only )
		end
		
		managers.network.matchmake:register_callback( "search_lobby", f )
		managers.network.matchmake:start_search_lobbys( friends_only )
			
		--[[local f = function( info )
			-- print( "info in function" )
			-- print( inspect( info ) )
			managers.network.matchmake:search_lobby_done()
			managers.menu:active_menu().logic:refresh_node( "play_online", true, info, friends_only )
		end
		
		PSN:set_matchmaking_callback( "session_search", f )
		
		managers.network.matchmake:search_lobby()]]
	end
end

-- PS3 connect to lobby, need to pass the room id as parameter in item
function MenuCallbackHandler:connect_to_lobby( item )
	-- print( "MenuCallbackHandler:connect_to_lobby()" )
	-- print( inspect( item:parameters() ) )
	managers.network.matchmake:join_server_with_check( item:parameters().room_id )
end

function MenuCallbackHandler:stop_multiplayer()
	-- if self:is_ps3() then
		-- return
	-- end
	
	Global.game_settings.single_player = false
	if managers.network:session() and managers.network:session():local_peer():id() == 1 then -- Otherwise we are closing the menu to join the lobby
		managers.network:stop_network( true )
	end
end

function MenuCallbackHandler:find_friends()
	-- print( "find_friends" )
	
end

function MenuCallbackHandler:invite_friends()

	if managers.network.matchmake.lobby_handler then
		Steam:overlay_activate( "invite", managers.network.matchmake.lobby_handler:id() )
	end
	--Steam:overlay_activate ( "game", "LobbyInvite" ) 
end

function MenuCallbackHandler:invite_friend( item )
	-- print( "MenuCallbackHandler:invite_friend", inspect( item ) )
	-- print( inspect( item:parameters() ) )
	if item:parameters().signin_status ~= "signed_in" then
		return
	end
	managers.network.matchmake:send_join_invite( item:parameters().friend )
end

--[[function MenuCallbackHandler:invite_friend_x360( item )
	print( "MenuCallbackHandler:invite_friend_x360", inspect( item ) )
	if item:parameters().signin_status ~= "signed_in" then
		return
	end
		
	XboxLive:send_invite( managers.user:get_platform_id(), item:parameters().xuid, managers.localization:text("dialog_mp_invite_message" ) )
	
	InviteFriendsX360:update_node()
end]]

function MenuCallbackHandler:invite_friends_X360()
	local platform_id = managers.user:get_platform_id()
	XboxLive:show_friends_ui( platform_id )
end

function MenuCallbackHandler:invite_xbox_live_party()
	local platform_id = managers.user:get_platform_id()
	XboxLive:show_party_ui( platform_id )
end

function MenuCallbackHandler:view_invites()
	print( "View invites" )
	print( PSN:display_message_invitation() )
	-- Would be nice to get true/false depending if there where any invites
	-- managers.menu:show_no_invites_message()
end

function MenuCallbackHandler:kick_player( item )
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_mp_kick_player_title" )
	dialog_data.text = managers.localization:text( "dialog_mp_kick_player_message", { PLAYER = item:parameters().peer:name() } )
	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = (function()
										local peer = item:parameters().peer
										managers.network:session():send_to_peers( "kick_peer", peer:id() )
										managers.network:session():on_peer_kicked( peer, peer:id() )
										managers.menu:back( true )
								end)
		
	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }
	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:mute_player( item )
	if managers.network.voice_chat then
		managers.network.voice_chat:mute_player( item:parameters().peer, item:value() == "on" )
		item:parameters().peer:set_muted( item:value() == "on" )
	end
end

function MenuCallbackHandler:mute_xbox_player( item )
	if managers.network.voice_chat then
		managers.network.voice_chat:set_muted( item:parameters().xuid, item:value() == "on" )
		item:parameters().peer:set_muted( item:value() == "on" )
	end
end

function MenuCallbackHandler:view_gamer_card( item )
	XboxLive:show_gamer_card_ui( managers.user:get_platform_id(), item:parameters().xuid )
end

function MenuCallbackHandler:save_settings()
	managers.savefile:save_setting( true )
end

function MenuCallbackHandler:save_progress()
	managers.savefile:save_progress()
end

function MenuCallbackHandler:debug_level_jump( item )
	local param_map = item:parameters()
	managers.network:host_game()
	local level_id = tweak_data.levels:get_level_name_from_world_name( param_map.level )
	managers.network:session():load_level( param_map.level, param_map.mission, param_map.world_setting, param_map.level_class_name, level_id, nil )
end

function MenuCallbackHandler:save_game( item )
	if( not managers.savefile:is_active() ) then
		local param_map = item:parameters()
		managers.savefile:save_game( param_map.slot, false )

		if( managers.savefile:is_active() ) then
			managers.menu:set_save_game_callback( callback( self, self, "save_game_callback" ) )
		else
			self:save_game_callback()
		end
	end
end

function MenuCallbackHandler:save_game_callback()
	managers.menu:set_save_game_callback( nil )
	managers.menu:back()
end

function MenuCallbackHandler:restart_game( item )
	managers.menu:show_restart_game_dialog( { yes_func = function()
												if managers.job:stage_success() then
													print("No restart after stage success")
													return 
												end
												managers.statistics:stop_session()
												managers.savefile:save_progress()
												managers.groupai:state():set_AI_enabled( false )
												if Network:multiplayer() and managers.network:game() and Global.local_member then
													Global.local_member:delete()
												end
												self:retry_job_stage()
												-- self:lobby_start_the_game() 
												end } )
end

function MenuCallbackHandler:start_credits( item )
	managers.timeline:debug_level_jump( "credits_fortress2", nil, nil, "CreditsFotressLevel" )
end

function MenuCallbackHandler:set_music_volume( item )
	local volume = item:value()
	local old_volume = managers.user:get_setting( "music_volume" )
		
	managers.user:set_setting( "music_volume", volume )
	
	if( volume > old_volume ) then
		self._sound_source:post_event( "menu_music_increase" )
	elseif( volume < old_volume ) then
		self._sound_source:post_event( "menu_music_decrease" )
	end
end

function MenuCallbackHandler:set_sfx_volume( item )
	local volume = item:value()
	local old_volume = managers.user:get_setting( "sfx_volume" )
	
	managers.user:set_setting( "sfx_volume", volume )
	
	if( volume > old_volume ) then
		self._sound_source:post_event( "menu_sfx_increase" )
	elseif( volume < old_volume ) then
		self._sound_source:post_event( "menu_sfx_decrease" )
	end
end

function MenuCallbackHandler:set_voice_volume( item )
	local volume = item:value()
	managers.user:set_setting( "voice_volume", volume )
end

function MenuCallbackHandler:set_brightness( item )
	local brightness = item:value()
	managers.user:set_setting( "brightness", brightness )
end

function MenuCallbackHandler:set_effect_quality( item )
	local effect_quality = item:value()
	-- print( "effect_quality", effect_quality )
	managers.user:set_setting( "effect_quality", effect_quality )
end

function MenuCallbackHandler:set_camera_sensitivity( item )
	local value = item:value()
	managers.user:set_setting( "camera_sensitivity", value )
	
	if not managers.user:get_setting( "enable_camera_zoom_sensitivity" ) then
		local item_other_sens = managers.menu:active_menu().logic:selected_node():item( "camera_zoom_sensitivity" )
		if item_other_sens and item_other_sens:visible() and math.abs( value - item_other_sens:value() ) > 0.001 then
			item_other_sens:set_value( value )
			item_other_sens:trigger()
		end
	end 
end

function MenuCallbackHandler:set_camera_zoom_sensitivity( item )
	local value = item:value()
	managers.user:set_setting( "camera_zoom_sensitivity", value )
	
	if not managers.user:get_setting( "enable_camera_zoom_sensitivity" ) then
		local item_other_sens = managers.menu:active_menu().logic:selected_node():item( "camera_sensitivity" )
		if item_other_sens and item_other_sens:visible() and math.abs( value - item_other_sens:value() ) > 0.001 then
			item_other_sens:set_value( value )
			item_other_sens:trigger()
		end
	end 
end

function MenuCallbackHandler:toggle_zoom_sensitivity( item )
	local value = item:value() == "on"
	managers.user:set_setting( "enable_camera_zoom_sensitivity", value )
	
	if value == false then
		local item_sens = managers.menu:active_menu().logic:selected_node():item( "camera_sensitivity" )
		local item_sens_zoom = managers.menu:active_menu().logic:selected_node():item( "camera_zoom_sensitivity" )
		item_sens_zoom:set_value( item_sens:value() )
		item_sens_zoom:trigger()
	end 
end

function MenuCallbackHandler:is_current_resolution( item )
	return item:name() == string.format( "%d x %d", RenderSettings.resolution.x, RenderSettings.resolution.y )
end


function MenuCallbackHandler:end_game()
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_are_you_sure_you_want_to_leave_game" )

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_end_game_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_end_game_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:_dialog_end_game_yes()
	managers.statistics:stop_session()
	managers.savefile:save_progress()
	managers.job:deactivate_current_job()
		
	if( Network:multiplayer() ) then
		Network:set_multiplayer( false )
		local peer_id = managers.network:session():local_peer():id()
		managers.network:session():send_to_peers( "set_peer_left", peer_id )
		managers.network:queue_stop_network()
	end
	
	-- managers.network.matchmake:leave_game()
	
	managers.network.matchmake:destroy_game()
	managers.network.voice_chat:destroy_voice()
	
	managers.groupai:state():set_AI_enabled( false )
	
	managers.menu:post_event( "menu_exit" )
	managers.menu:close_menu( "menu_pause" )
	setup:load_start_menu()
end

function MenuCallbackHandler:leave_safehouse()
	local yes_func = function() -- Global.load_to_crimenet = true 
								self:_dialog_end_game_yes()
							end
	managers.menu:show_leave_safehouse_dialog( { yes_func = yes_func } )
end

function MenuCallbackHandler:abort_mission()
	if game_state_machine:current_state_name() == "disconnected" then
		return
	end

	local yes_func = function()
								if game_state_machine:current_state_name() ~= "disconnected" then
									self:load_start_menu_lobby()
								end
							end
	managers.menu:show_abort_mission_dialog( { yes_func = yes_func } )
end

function MenuCallbackHandler:load_start_menu_lobby()
	--[[managers.statistics:stop_session()
	managers.savefile:save_progress()
	managers.job:deactivate_current_job()]]
		
	--[[if( Network:multiplayer() ) then
		Network:set_multiplayer( false )
		local peer_id = managers.network:session():local_peer():id()
		managers.network:session():send_to_peers( "set_peer_left", peer_id )
		managers.network:queue_stop_network()
	end]]
	
	-- managers.network.matchmake:leave_game()
	
	-- managers.network.matchmake:destroy_game()
	-- managers.network.voice_chat:destroy_voice()
	
	--[[managers.groupai:state():set_AI_enabled( false )
	
	self._sound_source:post_event( "menu_exit" )
	managers.menu:close_menu( "lobby_menu" )
	managers.menu:close_menu( "menu_pause" )]]
	
	managers.network:session():load_lobby()
	-- setup:load_start_menu_lobby()
end

function MenuCallbackHandler:_dialog_end_game_no()
end

function MenuCallbackHandler:set_default_options()
	managers.menu:show_default_option_dialog() -- in MenuManagerDialog.lua
end

function MenuCallbackHandler:resume_game()
	managers.menu:close_menu( "menu_pause" )
end

function MenuCallbackHandler:change_upgrade( menu_item )
	cat_print( "johan", "change upgrade" )
end

function MenuCallbackHandler:delayed_open_savefile_menu( item )
	if( not self._delayed_open_savefile_menu_callback ) then
		if( managers.savefile:is_active() ) then
			managers.menu:set_delayed_open_savefile_menu_callback( callback( self, self, "open_savefile_menu", item ) )
		else
			self:open_savefile_menu( item )
		end
	end
end

function MenuCallbackHandler:open_savefile_menu( item )
	managers.menu:set_delayed_open_savefile_menu_callback( nil )

	local parameter_map = item:parameters()
	managers.menu:open_node( parameter_map.delayed_node, { parameter_map } )
end

function MenuCallbackHandler:give_weapon()
	local player = managers.player:player_unit()
	if player then
		player:inventory():add_unit_by_name( Idstring("units/weapons/mp5/mp5"), false )
		-- player:inventory():add_unit_by_name( Idstring("units/weapons/r870_shotgun/r870_shotgun"), false )
	end
end

function MenuCallbackHandler:give_experience()
	if managers.job:has_active_job() then
		managers.experience:debug_add_points( managers.experience:get_xp_dissected( true, 1 ) )
	else
		managers.experience:debug_add_points( 2500, true )
	end
end

function MenuCallbackHandler:give_more_experience()
	managers.experience:debug_add_points( 2500 * 100, false )
end

function MenuCallbackHandler:give_max_experience()
	managers.experience:debug_add_points( 2500 * 40000, false )
end

function MenuCallbackHandler:debug_next_stage()
	game_state_machine:change_state_by_name( "victoryscreen", { num_winners = 2, personal_win = alive( managers.player:player_unit() ) } )
end

function MenuCallbackHandler:debug_give_alot_of_lootdrops()
	for i=1, 4 do
		managers.lootdrop:new_debug_drop( 100, true, i )
	end
end

function MenuCallbackHandler:debug_give_money()
	managers.money:debug_job_completed( 3 )
end

function MenuCallbackHandler:debug_give_alot_of_money()
	for stars=1, 7 do
		for i = 1, 10 do
			managers.money:debug_job_completed( stars )
		end
	end
end

function MenuCallbackHandler:debug_show_marketplace_ui()
	XboxLive:show_marketplace_ui(0)
end

function MenuCallbackHandler:hide_huds()
	managers.hud:set_disabled()
end

function MenuCallbackHandler:toggle_hide_huds( item )
	if item:value() == "on" then
		managers.hud:set_disabled()
	else
		managers.hud:set_enabled()
	end
end

function MenuCallbackHandler:toggle_mission_fading_debug_enabled( item )
	managers.mission:set_fading_debug_enabled( item:value() == "off" )
end

function MenuCallbackHandler:clear_progress()
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_are_you_sure_you_want_to_clear_progress" )

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_clear_progress_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_clear_progress_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:_dialog_clear_progress_yes()
	managers.menu:do_clear_progress()
	
	if managers.menu_component then
		managers.menu_component:refresh_player_profile_gui()
	end
	
	managers.savefile:save_progress()
	managers.savefile:save_setting( true )
end

function MenuCallbackHandler:_dialog_clear_progress_no()
end
 
function MenuCallbackHandler:reset_statistics()
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "dialog_warning_title" )
	dialog_data.text = managers.localization:text( "dialog_are_you_sure_you_want_to_reset_statistics" )

	local yes_button = {}
	yes_button.text = managers.localization:text( "dialog_yes" )
	yes_button.callback_func = callback( self, self, "_dialog_reset_statistics_yes" )

	local no_button = {}
	no_button.text = managers.localization:text( "dialog_no" )
	no_button.callback_func = callback( self, self, "_dialog_reset_statistics_no" )
	no_button.cancel_button = true
	dialog_data.button_list = { yes_button, no_button }

	managers.system_menu:show( dialog_data )
end

function MenuCallbackHandler:_dialog_reset_statistics_yes()
	managers.statistics:reset()
	managers.savefile:save_progress()
end

function MenuCallbackHandler:_dialog_reset_statistics_no()
end

function MenuCallbackHandler:set_default_controller( item )
	managers.controller:load_settings( "settings/controller_settings" )
	managers.controller:clear_user_mod()
	
	managers.menu:back( true )
end

function MenuCallbackHandler:debug_modify_challenge( item )
	managers.challenges:debug_set_amount( item:parameters().challenge, item:parameters().count - 1 )
	
	managers.menu:back( true )
	managers.menu:open_node( "modify_active_challenges" )
end

function MenuCallbackHandler:clear_local_steam_stats()
	managers.statistics:clear_statistics()
	managers.statistics:clear_skills_statistics()
end

function MenuCallbackHandler:print_local_steam_stats()
	managers.statistics:debug_print_stats( false, 1 )
end

function MenuCallbackHandler:print_local_steam_stats_7days()
	managers.statistics:debug_print_stats( false, 7 )
end

function MenuCallbackHandler:print_local_steam_stats_30days()
	managers.statistics:debug_print_stats( false, 30 )
end

function MenuCallbackHandler:print_global_steam_stats()
	managers.statistics:debug_print_stats( true, 1 )
end

function MenuCallbackHandler:print_global_steam_stats_7days()
	managers.statistics:debug_print_stats( true, 7 )
end

function MenuCallbackHandler:print_global_steam_stats_30days()
	managers.statistics:debug_print_stats( true, 30 )
end

function MenuCallbackHandler:print_global_steam_stats_alltime()
	managers.statistics:debug_print_stats( true )
end
----------------------------------------------------------------------

-- MenuChallenges modify class --------------

MenuChallenges = MenuChallenges or class()

function MenuChallenges:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	
	-- for name,data in pairs( Global.challenges_manager.active ) do
	for _,data in pairs( managers.challenges:get_near_completion() ) do
		local title_text = managers.challenges:get_title_text( data.id )
		local description_text = managers.challenges:get_description_text( data.id )
		local params = {
						name				= data.id,
						text_id				= string.upper( title_text ),
						description_text	= string.upper( description_text ),
						localize			= "false",
						challenge			= data.id
						}

		local new_item = new_node:create_item( { type = "MenuItemChallenge" }, params )
		new_node:add_item( new_item )
	end

	managers.menu:add_back_button( new_node )
	
	return new_node
end



MenuChallengesAwarded = MenuChallengesAwarded or class()

function MenuChallengesAwarded:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	
	-- for name,data in pairs( Global.challenges_manager.active ) do
	for _,data in pairs( managers.challenges:get_completed() ) do
		local params = {
						name				= data.id,
						text_id				= string.upper( data.name ),
						description_text	= string.upper( data.description ),
						localize			= "false",
						challenge			= data.id,
						awarded				= true
						}

		local new_item = new_node:create_item( { type = "MenuItemChallenge" }, params )
		new_node:add_item( new_item )
	end

	managers.menu:add_back_button( new_node )
	
	return new_node
end

MenuModifyActiveChallenges = MenuModifyActiveChallenges or class()

function MenuModifyActiveChallenges:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	
	-- for name,data in pairs( Global.challenges_manager.active ) do
	for _,data in pairs( managers.challenges:get_near_completion() ) do
		if data.count > 1 then
			local title_text = managers.challenges:get_title_text( data.id )
			local description_text = managers.challenges:get_description_text( data.id )
			local params = {
							name				= data.id,
							text_id				= string.upper( title_text ),
							description_text	= string.upper( description_text ),
							localize			= "false",
							challenge			= data.id,
							count 				= data.count,
							callback			= "debug_modify_challenge",
							}
	
			local new_item = new_node:create_item( { type = "MenuItemChallenge" }, params )
			new_node:add_item( new_item )
		end
	end

	managers.menu:add_back_button( new_node )
	
	return new_node
end


-- MenuUpgrades modify class --------------

MenuUpgrades = MenuUpgrades or class()

function MenuUpgrades:modify_node( node, up, ... )
	local new_node = up and node or deep_clone( node )
		
	local tree = new_node:parameters().tree
	
	local first_locked = true
	for i,upgrade_id in ipairs( tweak_data.upgrades.progress[ tree ] ) do
		-- local name = managers.upgrades:complete_title( upgrade_id, "single" ) or managers.upgrades:name( upgrade_id )
		local title = managers.upgrades:title( upgrade_id ) or managers.upgrades:name( upgrade_id )
		local subtitle = managers.upgrades:subtitle( upgrade_id )
		local params = {
							step		= i,
							tree		= tree,
							name		= upgrade_id,
							upgrade_id	= upgrade_id,
							text_id		= string.upper( title and subtitle or title ),
							topic_text	= subtitle and title and string.upper( title ),
							localize	= "false",
							}

		if tweak_data.upgrades.visual.upgrade[ upgrade_id ] and not tweak_data.upgrades.visual.upgrade[ upgrade_id ].base then
			if managers.upgrades:progress_by_tree( tree ) >= i then
				params.callback = "toggle_visual_upgrade"
			end
		end
		
		if managers.upgrades:is_locked( i ) and first_locked then
			first_locked = false
			
			new_node:add_item( new_node:create_item( { type = "MenuItemUpgrade" }, 
				{
					name			= "upgrade_lock",
					text_id			= managers.localization:text( "menu_upgrades_locked", { LEVEL = managers.upgrades:get_level_from_step( i ) } ),
					localize		= "false",
					upgrade_lock	= true
				}))			
		end
		
	
		local new_item = new_node:create_item( { type = "MenuItemUpgrade" }, params )
		new_node:add_item( new_item )
	end 
	
	managers.menu:add_back_button( new_node )
	
	return new_node
end

function MenuCallbackHandler:toggle_visual_upgrade( item )
	managers.upgrades:toggle_visual_weapon_upgrade( item:parameters().upgrade_id )
	managers.upgrades:setup_current_weapon()
	
	if managers.upgrades:visual_weapon_upgrade_active( item:parameters().upgrade_id ) then
		self._sound_source:post_event( "box_tick" )
	else
		self._sound_source:post_event( "box_untick" )
	end
	
	print( "Toggled", item:parameters().upgrade_id )
end



InviteFriendsPSN = InviteFriendsPSN or class()

-- THIS WILL ACTUALLY DELETE ITEMS, CAN BE REMOVED PERHAPS TO HAVE A BETTER LIST
function InviteFriendsPSN:modify_node( node, up )
	-- print( "InviteFriendsPSN:modify_node" )
	local new_node = up and node or deep_clone( node )
	
	--[[local f = function( friend )
		managers.menu:active_menu().logic:refresh_node( "invite_friends", true, friend )
	end]]
	
	local f2 = function( friends )
		managers.menu:active_menu().logic:refresh_node( "invite_friends", true, friends )
	end
	
	managers.network.friends:register_callback( "get_friends_done", f2 )
	-- managers.network.friends:register_callback( "status_change", f )
	managers.network.friends:register_callback( "status_change", function() end )
	managers.network.friends:get_friends( new_node )
		
	return new_node
end

function InviteFriendsPSN:refresh_node( node, friends )
	
	for i,friend in ipairs( friends ) do
		if i < 103 then
			local name = tostring( friend._name )
			local signin_status = friend._signin_status
			local item = node:item( name )
			-- print( "item", item )
			if not item then
				local params = {
								name			= name,
								friend			= friend._id,
								text_id			= utf8.to_upper( friend._name ),
								signin_status 	= signin_status,
								callback		= "invite_friend",
								localize		= "false"
								}
			
				local new_item = node:create_item( { type = "MenuItemFriend" }, params )
				node:add_item( new_item )
			else
				-- print( "had that item", item:parameters().signin_status ~= signin_status, signin_status )
				if item:parameters().signin_status ~= signin_status then
					-- print( "  signin_status changed" ) 
					item:parameters().signin_status = signin_status
				end
			end
			
		end
	end

	return node

	--[[print( "InviteFriendsPSN:refresh_node" )
	print( "friend", inspect( friend ) )
		
	local name = tostring( friend._name )
	local signin_status = friend._signin_status
	local item = node:item( name )
	if not item then
		local params = {
						name			= name,
						friend			= friend._id,
						text_id			= string.upper( friend._name ),
						signin_status 	= signin_status,
						callback		= "invite_friend",
						localize		= "false"
						}
	
		local new_item = node:create_item( { type = "MenuItemFriend" }, params )
		node:add_item( new_item )
	else
		-- print( "had that item" )
		if item:parameters().signin_status ~= signin_status then
			-- print( "signin_status changed" ) 
			item:parameters().signin_status = signin_status
		end
	end
	
	-- managers.menu:add_back_button( node )
	
	return node]]
end

function InviteFriendsPSN:update_node( node )
	if self._update_friends_t then
		if self._update_friends_t > Application:time() then
			return
		end
	end
	self._update_friends_t = Application:time() + 2
	managers.network.friends:get_friends()
end

-----------------------------------------------------------------------

--[[InviteFriendsX360 = InviteFriendsX360 or class()

-- THIS WILL ACTUALLY DELETE ITEMS, CAN BE REMOVED PERHAPS TO HAVE A BETTER LIST
function InviteFriendsX360:modify_node( node, up )
	-- print( "InviteFriendsPSN:modify_node" )
	local new_node = up and node or deep_clone( node )
			
	local friends = managers.network.friends:get_friends_by_name()
	managers.menu:active_menu().logic:refresh_node( "invite_friends", true, friends )
		
	return new_node
end

function InviteFriendsX360:_signin_status( name, friend )
	if managers.network:session() and managers.network:session():is_peer_name_in_session( name ) then
		return "in_group"
	end
	
	if managers.network:session() and managers.network:session():is_kicked( name ) then
		return "banned"
	end
	
	if friend.sent_invite then
		return "invite_sent"
	end
	
	if friend.online then
		return "signed_in"
	end
	
	return "not_signed_in"
end
	
function InviteFriendsX360:refresh_node( node, friends )
	-- Invite Xbox LIVE Party
	local party = true
	if party then
		local name = "xbox_live_party_xbox_live_party" -- Long so no conflict with player names 
		if not node:item( name ) then
				local params = {
								name			= name,
								text_id			= "menu_friends_xbox_live_party",
								callback		= "invite_xbox_live_party",
							}
			
			local new_item = node:create_item( nil, params )
			node:add_item( new_item )
			new_item:set_enabled( false )
		end
		
		-- return node
	end
	
	local i = 0
	for name,friend in pairs( friends ) do
		if i < 103 then
			local name = tostring( name )
			-- in_group
			-- kicked
			local signin_status = self:_signin_status( name, friend )
			local item = node:item( name )
			-- print( "item", item )
			if not item then
				local params = {
								name			= tostring( name ),
								xuid			= friend.xuid,
								text_id			= tostring( name ),
								signin_status 	= signin_status,
								callback		= "invite_friend_x360",
								localize		= "false"
								}
			
				local new_item = node:create_item( { type = "MenuItemFriend" }, params )
				node:add_item( new_item )
			else
				-- print( "had that item", item:parameters().signin_status ~= signin_status, signin_status )
				if item:parameters().signin_status ~= signin_status then
					-- print( "  signin_status changed" ) 
					item:parameters().signin_status = signin_status
				end
			end
			
		end
		i = i + 1
	end

	return node	
end

function InviteFriendsX360:update_node( node )
	if self._update_friends_t then
		if self._update_friends_t > Application:time() then
			return
		end
	end
	self._update_friends_t = Application:time() + 2
	local friends = managers.network.friends:get_friends_by_name()
	managers.menu:active_menu().logic:refresh_node( "invite_friends", true, friends )
end]]

-----------------------------------------------------------------------

InviteFriendsSTEAM = InviteFriendsSTEAM or class()

function InviteFriendsSTEAM:modify_node( node, up )
	return node
end

function InviteFriendsSTEAM:refresh_node( node, friend )
	return node
end

function InviteFriendsSTEAM:update_node( node )
end

-- KickPlayer modify class --------------
KickPlayer = KickPlayer or class()

function KickPlayer:modify_node( node, up )
	local new_node = deep_clone( node )
	if managers.network:session() then
		for _,peer in pairs( managers.network:session():peers() ) do
			local params = {
							name			= peer:name(),
							-- text_id			= utf8.to_upper( peer:name() ),
							text_id			= peer:name(),
							callback		= "kick_player",
							to_upper		= false,
							localize		= "false",
							rpc				= peer:rpc(),
							peer			= peer,
							}
		
			local new_item = node:create_item( nil, params )
			new_node:add_item( new_item )
		end
	end
	
	managers.menu:add_back_button( new_node )
	
	return new_node
end

-- MutePlayer modify class --------------
MutePlayer = MutePlayer or class()

function MutePlayer:modify_node( node, up )
	local new_node = deep_clone( node )
	if managers.network:session() then
		for _,peer in pairs( managers.network:session():peers() ) do
		-- for _,peer in pairs( { managers.network:session():local_peer() } ) do
			local params = {
							name			= peer:name(),
							--text_id		= utf8.to_upper( peer:name() ),
							text_id			= peer:name(),
							callback		= "mute_player",
							to_upper		= false,
							localize		= "false",
							rpc				= peer:rpc(),
							peer			= peer,
							}
							
			local data = { type = "CoreMenuItemToggle.ItemToggle",
						{ _meta = "option", icon = "guis/textures/menu_tickbox", value = "on", x = 24, y = 0, w = 24, h = 24, s_icon = "guis/textures/menu_tickbox", s_x = 24, s_y = 24, s_w = 24, s_h = 24 },
						{ _meta = "option", icon = "guis/textures/menu_tickbox", value = "off", x = 0, y = 0, w = 24, h = 24, s_icon = "guis/textures/menu_tickbox", s_x = 0, s_y = 24, s_w = 24, s_h = 24 }
						}
		
			local new_item = node:create_item( data, params )
			
			-- Set value here to on or off, depending if player is muted or not.
			new_item:set_value( peer:is_muted( ) and "on" or "off" )
			
			new_node:add_item( new_item )
		end
	end
	
	managers.menu:add_back_button( new_node )
	
	return new_node
end

MutePlayerX360 = MutePlayerX360 or class()

function MutePlayerX360:modify_node( node, up )
	local new_node = deep_clone( node )
	if managers.network:session() then
		for _,peer in pairs( managers.network:session():peers() ) do
			local params = {
							name			= peer:name(),
							-- text_id			= utf8.to_upper( peer:name() ),
							text_id			= peer:name(),
							callback		= "mute_xbox_player",
							to_upper		= false,
							localize		= "false",
							rpc				= peer:rpc(),
							peer			= peer,
							xuid			= peer:xuid(),
							}
							
			local data = { type = "CoreMenuItemToggle.ItemToggle",
						{ _meta = "option", icon = "guis/textures/menu_tickbox", value = "on", x = 24, y = 0, w = 24, h = 24, s_icon = "guis/textures/menu_tickbox", s_x = 24, s_y = 24, s_w = 24, s_h = 24 },
						{ _meta = "option", icon = "guis/textures/menu_tickbox", value = "off", x = 0, y = 0, w = 24, h = 24, s_icon = "guis/textures/menu_tickbox", s_x = 0, s_y = 24, s_w = 24, s_h = 24 }
						}
		
			local new_item = node:create_item( data, params )
			
			-- Set value here to on or off, depending if player is muted or not.
			new_item:set_value( peer:is_muted( ) and "on" or "off" )
			
			new_node:add_item( new_item )
		end
	end
	
	managers.menu:add_back_button( new_node )
	
	return new_node
end

-- ViewGamerCard modify class --------------
ViewGamerCard = ViewGamerCard or class()

function ViewGamerCard:modify_node( node, up )
	local new_node = deep_clone( node )
	if managers.network:session() then
		for _,peer in pairs( managers.network:session():peers() ) do
			local params = {
							name			= peer:name(),
							-- text_id			= utf8.to_upper( peer:name() ),
							text_id			= peer:name(),
							callback		= "view_gamer_card",
							to_upper		= false,
							localize		= "false",
							xuid			= peer:xuid(),
							}
			
			local new_item = node:create_item( nil, params )
			new_node:add_item( new_item )
		end
	end
		
	managers.menu:add_back_button( new_node )
	
	return new_node
end

-- MenuPSNHostBrowser modify class --------------
MenuPSNHostBrowser = MenuPSNHostBrowser or class()

-- THIS WILL ACTUALLY DELETE ITEMS, CAN BE REMOVED PERHAPS TO HAVE A BETTER LIST
function MenuPSNHostBrowser:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	-- local new_node = node
	return new_node
end

function MenuPSNHostBrowser:update_node( node )
	if #PSN:get_world_list() == 0 then
		return
	end
	
	managers.network.matchmake:start_search_lobbys( managers.network.matchmake:searching_friends_only() )
end

function MenuPSNHostBrowser:add_filter( node )
	if node:item( "difficulty_filter" ) then
		return
	end
	
	
	local params = 
	{
		name		= "difficulty_filter",
		text_id		= "menu_diff_filter",
		help_id		= "menu_diff_filter_help",
--		visible_callback = "is_pc_controller",
		visible_callback = "is_ps3",
		callback	= "choice_difficulty_filter_ps3",
		filter 		= true,
	}

	local data_node = { type = "MenuItemMultiChoice", 
			{ _meta = "option", text_id = "menu_all", value = 0 },
			{ _meta = "option", text_id = "menu_difficulty_easy", value = 1 },
			{ _meta = "option", text_id = "menu_difficulty_normal", value = 2 }, 
			{ _meta = "option", text_id = "menu_difficulty_hard", value = 3 },
			{ _meta = "option", text_id = "menu_difficulty_overkill", value = 4 }
	}
	
	if managers.experience:current_level() >= 145 then
		table.insert( data_node, { _meta = "option", text_id = "menu_difficulty_overkill_145", value = 5 } )
	end	
	

	local new_item = node:create_item( data_node, params )
	new_item:set_value( managers.network.matchmake:difficulty_filter() )
	
	
	node:add_item( new_item )
end

function MenuPSNHostBrowser:refresh_node( node, info_list, friends_only )
	-- print( "MenuPSNHostBrowser:refresh_node" )
	-- print( "info_list" )
	-- print( inspect( info_list ) )
	

	local new_node = node
	
	if not friends_only then
		self:add_filter( new_node )
	end
	
	
	if not info_list then
		return new_node
	end
	
	local dead_list = {}
	for _,item in ipairs( node:items() ) do
		if not item:parameters().filter then
			dead_list[ item:parameters().name ] = true
		end
	end	
	
	
	for _,info in ipairs( info_list ) do
		local room_list = info.room_list
		local attribute_list = info.attribute_list -- { { numbers = { 2, 1, 1, 1 } }, { numbers = { 3, 2, 2, 2 } }, { numbers = { 4, 3, 1, 1 } } } -- info.attribute_list
		
		for i,room in ipairs( room_list ) do
			-- print( "room", friends_only, room.owner_id, not friends_only or managers.network.friends:is_friend( room.owner_id ) )
			local name_str = tostring( room.owner_id )
			local friend_str = room.friend_id and tostring( room.friend_id )
			local attributes_numbers = attribute_list[ i ].numbers
			if managers.network.matchmake:is_server_ok( friends_only, room.owner_id, attributes_numbers ) then
				dead_list[ name_str ] = nil
				
				local host_name = name_str
				local level_id = attributes_numbers and tweak_data.levels:get_level_name_from_index( attributes_numbers[ 1 ]%1000 )
				local name_id = (level_id and tweak_data.levels[ level_id ] and tweak_data.levels[ level_id ].name_id ) or "N/A"
				local level_name = name_id and managers.localization:text( name_id ) or "LEVEL NAME ERROR"
				local difficulty = attributes_numbers and tweak_data:index_to_difficulty( attributes_numbers[2] ) or "N/A"

				
				local state_string_id = attributes_numbers and tweak_data:index_to_server_state( attributes_numbers[4] ) or nil
				local state_name = state_string_id and managers.localization:text( "menu_lobby_server_state_"..state_string_id ) or "N/A"
				-- local state_name = attributes_numbers[4] == 1 and managers.localization:text( "menu_lobby_server_state_in_lobby" ) or managers.localization:text( "menu_lobby_server_state_in_game" )
				local state = attributes_numbers or "N/A"
				local item = new_node:item( name_str )
				local num_plrs = attributes_numbers and attributes_numbers[8] or 1
				
				if not item then -- ..i ) then
					-- print( "ADD", name_str )
					local params = 
					{
						name		= name_str, --..i,
						text_id		= name_str,
						room_id		= room.room_id,
						-- columns		= { "" .. j, host_data.host_name, level_name, state_name }, -- host_rpc:to_string() },
						columns		= { string.upper( friend_str or host_name ), string.upper( level_name ), string.upper( state_name ), tostring( num_plrs ) .. "/4 " },
						-- rpc			= host_rpc,
						level_name  = level_id or "N/A", -- host_data.level_name,
						real_level_name = level_name,
						level_id	= level_id,
						state_name	= state_name,
						difficulty	= difficulty,
						host_name	= host_name,
						state		= state,
						num_plrs 	= num_plrs,
						callback	= "connect_to_lobby",
						localize	= "false"
					}
					
					local new_item = new_node:create_item( { type = "ItemServerColumn" }, params )
					new_node:add_item( new_item )
				else
					if item:parameters().real_level_name ~= level_name then
						item:parameters().columns[2] = string.upper( level_name )
						item:parameters().level_name = level_id
						item:parameters().level_id = level_id
						item:parameters().real_level_name = level_name
					end
					
					if item:parameters().state ~= state then
						item:parameters().columns[3] = state_name
						item:parameters().state = state
						item:parameters().state_name = state_name
					end
					
					if item:parameters().difficulty ~= difficulty then
						item:parameters().difficulty = difficulty
					end
					
					if item:parameters().room_id ~= room.room_id then
						item:parameters().room_id = room.room_id
					end
					
					if item:parameters().num_plrs ~= num_plrs then
						item:parameters().num_plrs = num_plrs
						item:parameters().columns[4] = tostring( num_plrs ) .. "/4 "
					end
				end
			end
		end
	
	end
		
	for name,_ in pairs( dead_list ) do
		new_node:delete_item( name )
	end
	
	return new_node
end

-- MenuSTEAMHostBrowser modify class --------------
MenuSTEAMHostBrowser = MenuSTEAMHostBrowser or class()

-- THIS WILL ACTUALLY DELETE ITEMS, CAN BE REMOVED PERHAPS TO HAVE A BETTER LIST
function MenuSTEAMHostBrowser:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	return new_node
end

function MenuSTEAMHostBrowser:update_node( node )
--[[
	if #PSN:get_world_list() == 0 then
		return
	end
]]
	managers.network.matchmake:search_lobby( managers.network.matchmake:search_friends_only() )
end


function MenuSTEAMHostBrowser:add_filter( node )
	if node:item( "server_filter" ) then
		return
	end
	
	local params = 
	{
		name		= "server_filter",
		text_id		= "menu_dist_filter",
		help_id		= "menu_dist_filter_help",
		visible_callback = "is_pc_controller",
		callback	= "choice_distance_filter",
		filter 		= true,
	}

	local data_node = { type = "MenuItemMultiChoice", 
			{ _meta = "option", text_id = "menu_dist_filter_close", value = -1 },
			{ _meta = "option", text_id = "menu_dist_filter_far", value = 2 },
			{ _meta = "option", text_id = "menu_dist_filter_worldwide", value = 3 } 
	}

	local new_item = node:create_item( data_node, params )
	new_item:set_value( managers.network.matchmake:distance_filter() )
	
	node:add_item( new_item )
	
	local params = 
	{
		name		= "difficulty_filter",
		text_id		= "menu_diff_filter",
		help_id		= "menu_diff_filter_help",
		visible_callback = "is_pc_controller",
		callback	= "choice_difficulty_filter",
		filter 		= true,
	}

	local data_node = { type = "MenuItemMultiChoice", 
			{ _meta = "option", text_id = "menu_all", value = 0 },
			{ _meta = "option", text_id = "menu_difficulty_easy", value = 1 },
			{ _meta = "option", text_id = "menu_difficulty_normal", value = 2 }, 
			{ _meta = "option", text_id = "menu_difficulty_hard", value = 3 },
			{ _meta = "option", text_id = "menu_difficulty_overkill", value = 4 }
	}
	
	if managers.experience:current_level() >= 145 then
		table.insert( data_node, { _meta = "option", text_id = "menu_difficulty_overkill_145", value = 5 } )
	end	
	

	local new_item = node:create_item( data_node, params )
	new_item:set_value( managers.network.matchmake:difficulty_filter() )
	
	node:add_item( new_item )
end


function MenuSTEAMHostBrowser:refresh_node( node, info, friends_only )
	local new_node = node
	-- print( "MenuSTEAMHostBrowser:refresh_node" )
	-- print( "info" )
	-- print( inspect( info ) )
	
	if not friends_only then
		self:add_filter( new_node )
	end
	
	if not info then
		managers.menu:add_back_button( new_node )
		return new_node
	end
	
	
	
	local room_list = info.room_list
	local attribute_list = info.attribute_list -- { { numbers = { 2, 1, 1, 1 } }, { numbers = { 3, 2, 2, 2 } }, { numbers = { 4, 3, 1, 1 } } } -- info.attribute_list
	
	local dead_list = {}
	for _,item in ipairs( node:items() ) do
		if not item:parameters().back and not item:parameters().filter and not item:parameters().pd2_corner then
			dead_list[ item:parameters().room_id ] = true
		end
	end	
	
	for i,room in ipairs( room_list ) do
		-- print( "room", friends_only, room.owner_id, not friends_only or managers.network.friends:is_friend( room.owner_id ) )
		local name_str = tostring( room.owner_name )
		local attributes_numbers = attribute_list[ i ].numbers
		-- local server_ok = self:_is_server_ok( friends_only, room, attributes_numbers )
		-- dead_list[ name_str ] = server_ok or nil
		if managers.network.matchmake:is_server_ok( friends_only, room.owner_id, attributes_numbers ) then
			dead_list[ room.room_id ] = nil
		-- if not friends_only or managers.network.friends:is_friend( room.owner_id ) then
		
			-- print( i, inspect( room ) )
			-- print( i, inspect( attribute_list[ i ] ) )
					
			 --local host_rpc = host_data.rpc
			local host_name = name_str
			local level_id = tweak_data.levels:get_level_name_from_index( attributes_numbers[ 1 ]%1000 )
			local name_id = level_id and tweak_data.levels[ level_id ] and tweak_data.levels[ level_id ].name_id
			local level_name = name_id and managers.localization:text( name_id ) or "LEVEL NAME ERROR"
			local difficulty = tweak_data:index_to_difficulty( attributes_numbers[2] )
			-- local permission = tweak_data:index_to_permission( attributes_numbers[3] )
			-- print( host_rpc:ping_at_index(0), host_rpc:ping_at_index(1) )
			-- print( host_rpc:num_peers(), host_rpc:ping_at_index(0) )
					
			local state_string_id = tweak_data:index_to_server_state( attributes_numbers[4] )
			local state_name = state_string_id and managers.localization:text( "menu_lobby_server_state_"..state_string_id ) or "blah"
			-- local state_name = attributes_numbers[4] == 1 and managers.localization:text( "menu_lobby_server_state_in_lobby" ) or managers.localization:text( "menu_lobby_server_state_in_game" )
			local state = attributes_numbers[4]
			local num_plrs = attributes_numbers[5]
			
			local item = new_node:item( room.room_id )
			if not item then -- ..i ) then
				print( "ADD", name_str )
				local params = 
				{
					name		= room.room_id, --..i,
					text_id		= name_str,
					room_id		= room.room_id,
					-- columns		= { "" .. j, host_data.host_name, level_name, state_name }, -- host_rpc:to_string() },
					columns		= { utf8.to_upper( host_name ), utf8.to_upper( level_name ), utf8.to_upper( state_name ), tostring( num_plrs ) .. "/4 " },
					-- rpc			= host_rpc,
					level_name  = level_id, -- host_data.level_name,
					real_level_name = level_name,
					level_id	= level_id,
					state_name	= state_name,
					difficulty	= difficulty,
					host_name	= host_name,
					state		= state,
					num_plrs	= num_plrs,
					callback	= "connect_to_lobby",
					localize	= "false"
				}
				
				local new_item = new_node:create_item( { type = "ItemServerColumn" }, params )
				new_node:add_item( new_item )
			else
				if item:parameters().real_level_name ~= level_name then
					item:parameters().columns[2] = utf8.to_upper( level_name )
					item:parameters().level_name = level_id
					item:parameters().level_id = level_id
					item:parameters().real_level_name = level_name
				end
				
				if item:parameters().state ~= state then
					item:parameters().columns[3] = state_name
					item:parameters().state = state
					item:parameters().state_name = state_name
				end
				
				if item:parameters().difficulty ~= difficulty then
					item:parameters().difficulty = difficulty
				end
				
				if item:parameters().room_id ~= room.room_id then
					item:parameters().room_id = room.room_id
				end
				
				if item:parameters().num_plrs ~= num_plrs then
					item:parameters().num_plrs = num_plrs
					item:parameters().columns[4] = tostring( num_plrs ) .. "/4 "
				end
			end
		end
	end
		
	for name,_ in pairs( dead_list ) do
		new_node:delete_item( name )
	end
	
	managers.menu:add_back_button( new_node )
	
	return new_node
end




-- MenuLANHostBrowser modify class --------------
MenuLANHostBrowser = MenuLANHostBrowser or class()

-- THIS WILL ACTUALLY DELETE ITEMS, CAN BE REMOVED PERHAPS TO HAVE A BETTER LIST
function MenuLANHostBrowser:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	return new_node
end

function MenuLANHostBrowser:refresh_node( node )
	local new_node = node
	local hosts = managers.network:session():discovered_hosts()
		
	for _, host_data in ipairs( hosts ) do
		local host_rpc = host_data.rpc
		local name_str = host_data.host_name..", "--[[..host_data.level_name..", "]]..host_rpc:to_string()
		local level_id = tweak_data.levels:get_level_name_from_world_name( host_data.level_name )
		local name_id = level_id and tweak_data.levels[ level_id ] and tweak_data.levels[ level_id ].name_id
		local level_name = name_id and managers.localization:text( name_id ) or host_data.level_name
		local state_name = host_data.state == 1 and managers.localization:text( "menu_lobby_server_state_in_lobby" ) or managers.localization:text( "menu_lobby_server_state_in_game" )
		
		local item = new_node:item( name_str )
		if not item then
			local params = 
			{
				name		= name_str, --..i,
				text_id		= name_str,
				columns		= { string.upper( host_data.host_name ), string.upper( level_name ), string.upper( state_name ) },
				rpc			= host_rpc,
				level_name  = host_data.level_name,
				real_level_name = level_name,
				level_id	= level_id,
				state_name	= state_name,
				difficulty	= host_data.difficulty,
				host_name	= host_data.host_name,
				state		= host_data.state,
				callback	= "connect_to_host_rpc",
				localize	= "false"
			}
			
			local new_item = new_node:create_item( { type = "ItemServerColumn" }, params )
			new_node:add_item( new_item )
		else
			if item:parameters().real_level_name ~= level_name then
				item:parameters().columns[2] = string.upper( level_name )
				item:parameters().level_name = host_data.level_name
				item:parameters().real_level_name = level_name
			end
			
			if item:parameters().state ~= host_data.state then
				item:parameters().columns[3] = state_name
				item:parameters().state = host_data.state
			end
			
			if item:parameters().difficulty ~= host_data.difficulty then
				item:parameters().difficulty = host_data.difficulty
			end
		end
	end
	
	managers.menu:add_back_button( new_node )
		
	return new_node
end

-- MenuMPHostBrowser modify class --------------

MenuMPHostBrowser = MenuMPHostBrowser or class()

function MenuMPHostBrowser:modify_node( node, up )
	local new_node = up and node or deep_clone( node )
	--[[new_node:clean_items()
	local hosts = managers.network:session():discovered_hosts()
	for _, host_data in pairs( hosts ) do
		local host_rpc = host_data.rpc
		local name_str = host_data.name..", "..host_rpc:to_string()
		-- add host to list
		local params = {
					name		= name_str,
					text_id		= name_str,
					rpc	= host_rpc,
					callback	= "connect_to_host_rpc",
					localize	= "false"
					}
		local new_item = new_node:create_item( nil, params )
		new_node:add_item( new_item )
	end]]
	managers.menu:add_back_button( new_node )
	
	return new_node
end

function MenuMPHostBrowser:refresh_node( node )
	local new_node = node
	-- new_node:clean_items()
	local hosts = managers.network:session():discovered_hosts()
	local j = 1
	
	--[[print( inspect( hosts ) )
	print( inspect( new_node:items() ) )
	for _,item in ipairs( clone( new_node:items() ) ) do
		local remove = true
		print( item:name() )
		if item:name() ~= "back" then
			for _, host_data in ipairs( hosts ) do
				local host_rpc = host_data.rpc
				local name_str = host_data.host_name..", "..host_rpc:to_string()
				if name_str == item:name() then
					print( "DNT REMOVE", name_str )
					remove = false
				end
			end
			if remove then
				print( "REMOVE", item:name() )
				new_node:delete_item( item:name() )
			end
		end
	end]]
	
	for _, host_data in ipairs( hosts ) do
		-- for i = 1, 20 do
		local host_rpc = host_data.rpc
		local name_str = host_data.host_name..", "--[[..host_data.level_name..", "]]..host_rpc:to_string()
		local level_id = tweak_data.levels:get_level_name_from_world_name( host_data.level_name )
		local name_id = level_id and tweak_data.levels[ level_id ] and tweak_data.levels[ level_id ].name_id
		local level_name = name_id and managers.localization:text( name_id ) or host_data.level_name
		-- print( host_rpc:ping_at_index(0), host_rpc:ping_at_index(1) )
		-- print( host_rpc:num_peers(), host_rpc:ping_at_index(0) )
				
		local state_name = host_data.state == 1 and managers.localization:text( "menu_lobby_server_state_in_lobby" ) or managers.localization:text( "menu_lobby_server_state_in_game" )
		
		local item = new_node:item( name_str )
		if not item then -- ..i ) then
			-- print( "ADD", name_str )
			local params = 
			{
				name		= name_str, --..i,
				text_id		= name_str,
				-- columns		= { "" .. j, host_data.host_name, level_name, state_name }, -- host_rpc:to_string() },
				columns		= { string.upper( host_data.host_name ), string.upper( level_name ), string.upper( state_name ) },
				rpc			= host_rpc,
				level_name  = host_data.level_name,
				real_level_name = level_name,
				level_id	= level_id,
				state_name	= state_name,
				difficulty	= host_data.difficulty,
				host_name	= host_data.host_name,
				state		= host_data.state,
				callback	= "connect_to_host_rpc",
				localize	= "false"
			}
			
			local new_item = new_node:create_item( { type = "ItemServerColumn" }, params )
			new_node:add_item( new_item )
		else
			-- print( "UPDATE", item:name() )
			if item:parameters().real_level_name ~= level_name then
				print( "Update level_name - ", level_name )
				item:parameters().columns[2] = string.upper( level_name )
				item:parameters().level_name = host_data.level_name
				item:parameters().real_level_name = level_name
			end
			
			if item:parameters().state ~= host_data.state then
--				print( "Update node - ", name_str )
				item:parameters().columns[3] = state_name
				item:parameters().state = host_data.state
			end
			
			if item:parameters().difficulty ~= host_data.difficulty then
				item:parameters().difficulty = host_data.difficulty
			end
		end
		j = j + 1
		-- end
	end
	
	managers.menu:add_back_button( new_node )
		
	return new_node
end


MenuResolutionCreator = MenuResolutionCreator or class()

function MenuResolutionCreator:modify_node( node )
	local new_node = deep_clone( node )
	
	if( SystemInfo:platform() == Idstring( "WIN32" ) ) then
		for _,res in ipairs( RenderSettings.modes ) do
			-- local res_string = string.format( "%d x %d, %d Hz", res.x, res.y, res.z )
			local res_string = string.format( "%d x %d", res.x, res.y )
	
			if not new_node:item( res_string ) then
				local params = {
								name			= res_string,
								text_id			= res_string,
								resolution		= res,
								callback		= "change_resolution",
								localize		= "false",
								icon			= "guis/textures/scrollarrow",
								icon_rotation		= 90,
								icon_visible_callback	= "is_current_resolution"
								}
		
				local new_item = new_node:create_item( nil, params )
				new_node:add_item( new_item )
			end
		end
	end
	
	managers.menu:add_back_button( new_node )
	return new_node
end

MenuSoundCreator = MenuSoundCreator or class()
function MenuSoundCreator:modify_node( node )
	local music_item = node:item( "music_volume" )
	if music_item then
		music_item:set_min( _G.tweak_data.menu.MIN_MUSIC_VOLUME )
		music_item:set_max( _G.tweak_data.menu.MAX_MUSIC_VOLUME )
		music_item:set_step( _G.tweak_data.menu.MUSIC_CHANGE )
		music_item:set_value( managers.user:get_setting( "music_volume" ) )
	end

	local sfx_item = node:item( "sfx_volume" )
	if sfx_item then
		sfx_item:set_min( _G.tweak_data.menu.MIN_SFX_VOLUME )
		sfx_item:set_max( _G.tweak_data.menu.MAX_SFX_VOLUME )
		sfx_item:set_step( _G.tweak_data.menu.SFX_CHANGE )
		sfx_item:set_value( managers.user:get_setting( "sfx_volume" ) )
	end
	
	local voice_item = node:item( "voice_volume" )
	if voice_item then
		voice_item:set_min( _G.tweak_data.menu.MIN_VOICE_VOLUME )
		voice_item:set_max( _G.tweak_data.menu.MAX_VOICE_VOLUME )
		voice_item:set_step( _G.tweak_data.menu.VOICE_CHANGE )
		voice_item:set_value( managers.user:get_setting( "voice_volume" ) )
	end
	
	
	local option_value = "on"
	local st_item = node:item( "toggle_voicechat" )
	if st_item then
		if( not managers.user:get_setting( "voice_chat" ) ) then
			option_value = "off"
		end
		st_item:set_value( option_value )
	end


	option_value = "on"
	local st_item = node:item( "toggle_push_to_talk" )
	if st_item then
		if( not managers.user:get_setting( "push_to_talk" ) ) then
			option_value = "off"
		end
		st_item:set_value( option_value )
	end
	

	return node
end


function MenuManager.refresh_level_select( node, verify_dlc_owned )
	-- Verify level id (server might have had us change level_id to heist we don't have)
	if verify_dlc_owned and tweak_data.levels[ Global.game_settings.level_id ].dlc then
		local dlcs = string.split( managers.dlc:dlcs_string(), " " )
		if not table.contains( dlcs, tweak_data.levels[ Global.game_settings.level_id ].dlc ) then
			Global.game_settings.level_id = "bank"
		end
	end

	local min_difficulty = 0
	for _,item in ipairs( node:items() ) do
		local level_id = item:parameter( "level_id" )
		if level_id then
			if level_id == Global.game_settings.level_id then
				item:set_value( "on" )
				min_difficulty = tonumber( item:parameter( "difficulty" ) )
			elseif item:visible() then
				item:set_value( "off" )
			end
		end
	end
	
	Global.game_settings.difficulty = tweak_data:difficulty_to_index( Global.game_settings.difficulty ) > min_difficulty 
									  and Global.game_settings.difficulty or tweak_data:index_to_difficulty( min_difficulty )
	
	local item_difficulty = node:item( "lobby_difficulty" )
	if item_difficulty then
		for i,option in ipairs( item_difficulty:options() ) do
			option:parameters().exclude = ( tonumber( option:parameters().difficulty ) < min_difficulty )
		end

		item_difficulty:set_value( Global.game_settings.difficulty )
	end
	
	local lobby_mission_item = node:item( "lobby_mission" )
	local mission_data = tweak_data.levels[ Global.game_settings.level_id ].mission_data
	if lobby_mission_item then
			print( "lobby_mission_item" )
			local params = 
			{
				name		= "lobby_mission",
				text_id		= "menu_choose_mission",
				callback	= "choice_lobby_mission",
				localize 	= "false",
			}
			
			local data_node = { type = "MenuItemMultiChoice" }
						
			if mission_data then
				for _,data in ipairs( mission_data ) do
					table.insert( data_node, { _meta = "option", localize = false, text_id = data.mission, value = data.mission } )
				end
			else
				table.insert( data_node, { _meta = "option", localize = false, text_id = "none", value = "none" } )
			end
			
			lobby_mission_item:init( data_node, params )
			lobby_mission_item:set_callback_handler( MenuCallbackHandler:new() )
			lobby_mission_item:set_value( data_node[ 1 ].value )
	end
	
	Global.game_settings.mission = mission_data and mission_data[ 1 ] and mission_data[ 1 ].mission or "none"
end

MenuPSNPlayerProfileInitiator = MenuPSNPlayerProfileInitiator or class()
function MenuPSNPlayerProfileInitiator:modify_node( node )
	if managers.menu:is_ps3() and not managers.network:session() then
		PSN:set_online_callback( callback(managers.menu, managers.menu, "refresh_player_profile_gui") )
	end
	return node
end

GlobalSuccessRateInitiator = GlobalSuccessRateInitiator or class()
function GlobalSuccessRateInitiator:modify_node( node )
	managers.menu:show_global_success( node )
	return node
end


SinglePlayerOptionInitiator = SinglePlayerOptionInitiator or class()
function SinglePlayerOptionInitiator:modify_node( node )
	MenuManager.refresh_level_select( node, true )

	local item_lobby_toggle_ai = node:item( "toggle_ai" )
	item_lobby_toggle_ai:set_value( Global.game_settings.team_ai and "on" or "off" )


	local character_item = node:item( "choose_character" )
	if character_item then
		managers.network:game():on_peer_request_character( 1, character_item:value() )
	end	
	
	return node
end


LobbyOptionInitiator = LobbyOptionInitiator or class()
function LobbyOptionInitiator:modify_node( node )
	MenuManager.refresh_level_select( node, Network:is_server() )
	
	--[[if Global.game_settings.difficulty == "overkill_145" then
		Global.game_settings.reputation_permission = math.max( Global.game_settings.reputation_permission, 145 )
		print( "AUTO SET" )
		Application:stack_dump()
	end]]
	
	local item_permission_campaign = node:item( "lobby_permission" )
	if item_permission_campaign then
		item_permission_campaign:set_value( Global.game_settings.permission )
	end

	local item_lobby_toggle_drop_in = node:item( "toggle_drop_in" )
	if item_lobby_toggle_drop_in then
		item_lobby_toggle_drop_in:set_value( Global.game_settings.drop_in_allowed and "on" or "off" )
	end

	
	local item_lobby_toggle_ai = node:item( "toggle_ai" )
	if item_lobby_toggle_ai then
		item_lobby_toggle_ai:set_value( Global.game_settings.team_ai and "on" or "off" )
	end
	
	local character_item = node:item( "choose_character" )
	if character_item then
		local value = managers.network:session() and managers.network:session():local_peer():character() or "random"
		character_item:set_value( value )
	end	
	
	local reputation_permission_item = node:item( "lobby_reputation_permission" )
	if reputation_permission_item then
		print( "reputation_permission_item", "set value", Global.game_settings.reputation_permission, type_name( Global.game_settings.reputation_permission ) )
		reputation_permission_item:set_value( Global.game_settings.reputation_permission )
	end
	
	return node
end

VerifyLevelOptionInitiator = VerifyLevelOptionInitiator or class()
function VerifyLevelOptionInitiator:modify_node( node )
	MenuManager.refresh_level_select( node, true )
	return node
end

MaskOptionInitiator = MaskOptionInitiator or class()
function MaskOptionInitiator:modify_node( node )
	local choose_mask = node:item( "choose_mask" )
	
	if not choose_mask then -- THIS IS PAYDAY2
		return node
	end

	local params = 
	{
		name		= "choose_mask",
		text_id		= "menu_choose_mask",
		callback	= "choice_mask",
	}

	if choose_mask:parameters().help_id then	
		params.help_id = choose_mask:parameters().help_id
	end
	
	local data_node = { type = "MenuItemMultiChoice" }
	
	
	table.insert( data_node, { _meta = "option", text_id = "menu_mask_clowns", value = "clowns" } )
	
	if managers.network.account:has_mask( "developer" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_developer", value = "developer" } )
	end
	
	if managers.network.account:has_mask( "hockey_com" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_hockey_com", value = "hockey_com" } )
	end
	
	if managers.network.account:has_mask( "alienware" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_alienware", value = "alienware" } )
	end

	table.insert( data_node, { _meta = "option", text_id = "menu_mask_bf3", value = "bf3" } )
	
	if managers.network.account:has_mask( "santa" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_santa", value = "santa" } )
	end
	
	if managers.experience:current_level() >= 145 or managers.network.account:has_mask( "president" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_president", value = "president" } )
	end
	
	if managers.challenges:is_completed( "golden_boy" ) or managers.network.account:has_mask( "gold" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_gold", value = "gold" } )
	end

	-- SteamID: 500 - Left 4 Dead
	--          550 - Left 4 Dead 2
	if SystemInfo:platform() == Idstring( "WIN32" ) and ( Steam:is_product_owned( 500 ) or Steam:is_product_owned( 550 ) ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_zombie", value = "zombie" } )
	end

	if managers.network.account:has_mask( "troll" ) then
		table.insert( data_node, { _meta = "option", text_id = "menu_mask_troll", value = "troll" } )
	end

	
	choose_mask:init( data_node, params )
	choose_mask:set_callback_handler( MenuCallbackHandler:new() )
	choose_mask:set_value( managers.user:get_setting( "mask_set" ) )
	
	return node
end

---------------------------------------------------------------

DynamicLevelCreator = DynamicLevelCreator or class()

function DynamicLevelCreator:modify_node( node )
	print( "DynamicLevelCreator:modify_node", inspect( node ) )
	
	local single_player = node:parameters().single_player
	local new_node = deep_clone( node )
	
		--[[<item type="CoreMenuItemToggle.ItemToggle" difficulty="1" level_id="heist_bank" name="pick_heist_bank" title_id="menu_campaign" text_id="heist_bank" info_panel="lobby_campaign" callback="choice_lobby_campaign" visible_callback="has_full_game">
				<option icon="guis/textures/menu_radiobutton" value="on" x="24" y="0" w="24" h="24" s_icon="guis/textures/menu_radiobutton" s_x="24" s_y="24" s_w="24" s_h="24" />
				<option icon="guis/textures/menu_radiobutton" value="off" x="0" y="0" w="24" h="24" s_icon="guis/textures/menu_radiobutton" s_x="0" s_y="24" s_w="24" s_h="24" />
			</item>]]
			
	for _,level_id in ipairs( tweak_data.levels:get_level_index() ) do
		local level_data = tweak_data.levels[ level_id ]
		local params = {
			name		= "pick_"..level_id,
			level_id	= level_id,
			text_id		= managers.localization:text( level_data.name_id ), --string.upper( managers.localization:text( self.CONTROLS_INFO[ btn_name ].text_id ) ),
			difficulty	= 1,
			localize	= "false",
			callback	= "choice_lobby_campaign",
			info_panel	= "lobby_campaign",
			title_id	= "menu_campaign",
		}
		
		local data = { type = "CoreMenuItemToggle.ItemToggle",
							{ _meta = "option", icon="guis/textures/menu_radiobutton", value="on", x=24, y=0, w=24, h=24, s_icon="guis/textures/menu_radiobutton", s_x=24, s_y=24, s_w=24, s_h=24,},
							{ _meta = "option", icon="guis/textures/menu_radiobutton", value="off", x=0, y=0, w=24, h=24, s_icon="guis/textures/menu_radiobutton", s_x=0, s_y=24, s_w=24, s_h=24, }
					}
		local new_item = new_node:create_item( data, params )
		new_node:add_item( new_item )
	end
		
	if single_player then
		-- <item name="start_the_game" text_id="menu_start_the_game" help_id="menu_start_the_game_help" callback="lobby_start_the_game" />
		local params = {
			name		= "start_the_game",
			text_id		= "menu_start_the_game",
			help_id		= "menu_start_the_game_help",
			callback	= "lobby_start_the_game",
		}
					
		local new_item = new_node:create_item( nil, params )
		new_node:add_item( new_item )
	else
		-- <item name="create_lobby" text_id="menu_create_lobby" help_id="menu_start_lobby_help" callback="create_lobby" />
		local params = {
			name		= "create_lobby",
			text_id		= "menu_create_lobby",
			help_id		= "menu_start_lobby_help",
			callback	= "create_lobby",
		}
					
		local new_item = new_node:create_item( nil, params )
		new_node:add_item( new_item )
	end
	
	managers.menu:add_back_button( new_node )
	return new_node
end



MenuCustomizeControllerCreator = MenuCustomizeControllerCreator or class()
MenuCustomizeControllerCreator.CONTROLS = { "move", "primary_attack", "secondary_attack", 
											"primary_choice1", "primary_choice2", "switch_weapon", 
											"reload", "weapon_gadget", "weapon_firemode", "throw_grenade", "run", "jump", "duck", "melee", 
											"interact", "use_item", "toggle_chat", "push_to_talk", "continue" }
MenuCustomizeControllerCreator.AXIS_ORDERED = { move = { "up", "down", "left", "right" } }
MenuCustomizeControllerCreator.CONTROLS_INFO = {}
MenuCustomizeControllerCreator.CONTROLS_INFO.up 				= { text_id = "menu_button_move_forward" }
MenuCustomizeControllerCreator.CONTROLS_INFO.down 				= { text_id = "menu_button_move_back" }
MenuCustomizeControllerCreator.CONTROLS_INFO.left 				= { text_id = "menu_button_move_left" }
MenuCustomizeControllerCreator.CONTROLS_INFO.right				= { text_id = "menu_button_move_right" }
MenuCustomizeControllerCreator.CONTROLS_INFO.primary_attack		= { text_id = "menu_button_fire_weapon" }
MenuCustomizeControllerCreator.CONTROLS_INFO.secondary_attack 	= { text_id = "menu_button_aim_down_sight" }
MenuCustomizeControllerCreator.CONTROLS_INFO.primary_choice1 	= { text_id = "menu_button_weapon_slot1" }
MenuCustomizeControllerCreator.CONTROLS_INFO.primary_choice2 	= { text_id = "menu_button_weapon_slot2" }
-- MenuCustomizeControllerCreator.CONTROLS_INFO.primary_choice3 	= { text_id = "debug_weapon_slot3" }
MenuCustomizeControllerCreator.CONTROLS_INFO.switch_weapon 		= { text_id = "menu_button_switch_weapon" }
--[[MenuCustomizeControllerCreator.CONTROLS_INFO.next_weapon 		= { text_id = "menu_button_next_weapon" }
MenuCustomizeControllerCreator.CONTROLS_INFO.previous_weapon 	= { text_id = "menu_button_previous_weapon" }]]
MenuCustomizeControllerCreator.CONTROLS_INFO.reload 			= { text_id = "menu_button_reload" }
MenuCustomizeControllerCreator.CONTROLS_INFO.weapon_gadget 		= { text_id = "menu_button_weapon_gadget" }
MenuCustomizeControllerCreator.CONTROLS_INFO.run 				= { text_id = "menu_button_sprint" }
MenuCustomizeControllerCreator.CONTROLS_INFO.jump 				= { text_id = "menu_button_jump" }
MenuCustomizeControllerCreator.CONTROLS_INFO.duck 				= { text_id = "menu_button_crouch" }
MenuCustomizeControllerCreator.CONTROLS_INFO.melee 				= { text_id = "menu_button_melee" }
MenuCustomizeControllerCreator.CONTROLS_INFO.interact 			= { text_id = "menu_button_shout" }
MenuCustomizeControllerCreator.CONTROLS_INFO.use_item 			= { text_id = "menu_button_deploy" }
MenuCustomizeControllerCreator.CONTROLS_INFO.toggle_chat 		= { text_id = "menu_button_chat_message" }
MenuCustomizeControllerCreator.CONTROLS_INFO.push_to_talk 		= { text_id = "menu_button_push_to_talk" }
MenuCustomizeControllerCreator.CONTROLS_INFO.continue 			= { text_id = "menu_button_continue" }
MenuCustomizeControllerCreator.CONTROLS_INFO.throw_grenade		= { text_id = "menu_button_throw_grenade" }
MenuCustomizeControllerCreator.CONTROLS_INFO.weapon_firemode		= { text_id = "menu_button_weapon_firemode" }

function MenuCustomizeControllerCreator:modify_node( node )
	local new_node = deep_clone( node )
	
	local connections = managers.controller:get_settings( managers.controller:get_default_wrapper_type() ):get_connection_map()
	for _,name in ipairs( self.CONTROLS ) do
		local name_id = name
		local connection = connections[ name ]
		if connection._btn_connections then
			local ordered = self.AXIS_ORDERED[ name ]
			-- for btn_name,btn_connection in pairs( connection._btn_connections ) do
			for _,btn_name in ipairs( ordered ) do
				local btn_connection = connection._btn_connections[ btn_name ]
				if btn_connection then
					local name_id = name
					local params = {
						name		= btn_name,
						connection_name	= name,
						text_id		= utf8.to_upper( managers.localization:text( self.CONTROLS_INFO[ btn_name ].text_id ) ),
						binding 	= btn_connection.name,
						localize	= "false",
						axis 		= connection._name,
						button		= btn_name,
					}
					local new_item = new_node:create_item( { type = "MenuItemCustomizeController" }, params )
					new_node:add_item( new_item )
				end
			end
		else
			local params = {
						name		= name_id,
						connection_name	= name,
						text_id		= utf8.to_upper( managers.localization:text( self.CONTROLS_INFO[ name ].text_id ) ),
						binding 	= connection:get_input_name_list()[1],
						localize	= "false",
						button		= name,
					}
			local new_item = new_node:create_item( { type = "MenuItemCustomizeController" }, params )
			new_node:add_item( new_item )
		end
	end
	
	local params = {
				name		= "set_default_controller",
				text_id		= "menu_set_default_controller",
				-- 	help_id		= "menu_set_default_controller_help",
				callback	= "set_default_controller",
			}
	local new_item = new_node:create_item( nil, params )
	new_node:add_item( new_item )
	
	managers.menu:add_back_button( new_node )
	return new_node
end


MenuCrimeNetContractInitiator = MenuCrimeNetContractInitiator or class()
function MenuCrimeNetContractInitiator:modify_node( original_node, data )
	local node = deep_clone( original_node )
	
	if Global.game_settings.single_player then
		node:item( "toggle_ai" ):set_value( Global.game_settings.team_ai and "on" or "off" )
	elseif not data.server then
		
		node:item( "lobby_kicking_option" ):set_value( Global.game_settings.kicking_allowed and "on" or "off" )
		node:item( "lobby_permission" ):set_value( Global.game_settings.permission )
		node:item( "lobby_reputation_permission" ):set_value( Global.game_settings.reputation_permission )
		node:item( "toggle_drop_in" ):set_value( Global.game_settings.drop_in_allowed and "on" or "off" )
		node:item( "toggle_ai" ):set_value( Global.game_settings.team_ai and "on" or "off" )
	end
	
	if data.customize_contract then
		node:set_default_item_name( "buy_contract" )

		local job_data = data
		if job_data and job_data.job_id then
			local buy_contract_item = node:item( "buy_contract" )
			if buy_contract_item then
				local can_afford = managers.money:can_afford_buy_premium_contract( job_data.job_id, job_data.difficulty_id or 3 )

				buy_contract_item:parameters().text_id = can_afford and "menu_cn_premium_buy_accept" or "menu_cn_premium_cannot_buy"
				buy_contract_item:parameters().disabled_color = Color( 1, 0.6, 0.2, 0.2 )
				buy_contract_item:set_enabled( can_afford )
			end
		end
	end
	
	if( data and data.back_callback ) then
		table.insert( node:parameters().back_callback, data.back_callback )
	end
	
	node:parameters().menu_component_data = data
	return node
end

function MenuCallbackHandler:set_contact_info( item )
	local parameters = item:parameters() or {}
	local id = parameters.name
	local name_id = parameters.text_id
	local files = parameters.files
	
	local active_node_gui = managers.menu:active_menu().renderer:active_node_gui()
	if active_node_gui and active_node_gui.set_contact_info then
		if active_node_gui:get_contact_info() ~= item:name() then
			active_node_gui:set_contact_info( id, name_id, files, 1 )
		end
	end
	
	local logic = managers.menu:active_menu().logic
	if logic then
		logic:refresh_node()
	end
end

function MenuCallbackHandler:is_current_contact_info( item )
	local active_node_gui = managers.menu:active_menu().renderer:active_node_gui()
	if active_node_gui and active_node_gui.get_contact_info then
		return active_node_gui:get_contact_info() == item:name()
	end
	
	return false
end

MenuCrimeNetContactInfoInitiator = MenuCrimeNetContactInfoInitiator or class()
function MenuCrimeNetContactInfoInitiator:modify_node( original_node, data )
	local node = original_node
	
	local codex_data = {}
	local contacts = {}
	
	for _, codex_d in ipairs( tweak_data.gui.crime_net.codex ) do
		local codex = {}
		codex.id = codex_d.id
		codex.name_lozalized = managers.localization:to_upper_text( codex_d.name_id ).." ("..tostring( #codex_d )..")"
		for _, info_data in ipairs( codex_d ) do
			local data = {}
			
			data.id = info_data.id
			data.name_lozalized = managers.localization:to_upper_text( info_data.name_id )
			data.files = {}
			for page, file_data in ipairs( info_data ) do
				local file = {}
				file.desc_lozalized = file_data.desc_id and managers.localization:text( file_data.desc_id ) or ""
				file.post_event = file_data.post_event
				file.videos = file_data.videos and deep_clone( file_data.videos ) or {}
				file.lock = file_data.lock
				if file_data.video then
					table.insert( file.videos, file_data.video )
				end
				
				table.insert( data.files, file )
			end
			
			table.insert( codex, data )
		end
		table.insert( codex_data, codex )
	end
	--[[
	local x_id, y_id
	for i, codex in ipairs( codex_data ) do
		for i, info_data in ipairs( codex ) do
			table.sort( info_data, function( x, y )
				x_id = x.name_lozalized
				y_id = y.name_lozalized
				
				return x_id < y_id
			end )
		end
	end
	]]
	
	node:clean_items()
	for i, codex in ipairs( codex_data ) do
		self:create_divider( node, codex.id, codex.name_lozalized, nil, tweak_data.screen_colors.text )
		for i, info_data in ipairs( codex ) do
			self:create_item( node, info_data )
		end
		self:create_divider( node, i )
	end
	
	local params =
	{
		name = "back",
		text_id = "menu_back",
		previous_node = "true",
		visible_callback = "is_pc_controller",
		align = "left",
		last_item = "true",
		gui_node_custom = "true",
		pd2_corner = "true"
	}
	
	
	local data_node = {}
	local new_item = node:create_item( data_node, params )
	
	node:add_item( new_item )
	
	node:set_default_item_name( "bain" )
	node:select_item( "bain" )
	return node
end

function MenuCrimeNetContactInfoInitiator:refresh_node( node )
	return node
end


function MenuCrimeNetContactInfoInitiator:create_divider( node, id, text_id, size, color )
	local params =
	{
		name = "divider_"..id,
		no_text = not text_id,
		text_id = text_id,
		localize = "false",
		size = size or 8,
		color = color
	}
	
	local data_node = { type = "MenuItemDivider" }
	local new_item = node:create_item( data_node, params )
	
	node:add_item( new_item )
end

function MenuCrimeNetContactInfoInitiator:create_item( node, contact )
	local text_id = contact.name_lozalized
	local files = contact.files
	local video_id = contact.video
	local color_ranges
	
	local params =
	{
		name = contact.id,
		text_id = text_id,
		color_ranges = color_ranges,
		localize = "false",
		callback = "set_contact_info",
		files = files,
		icon = "guis/textures/scrollarrow",
		icon_rotation = 270,
		icon_visible_callback = "is_current_contact_info"
	}
	
	local data_node = {}
	local new_item = node:create_item( data_node, params )
	
	
	node:add_item( new_item )
end


MenuCrimeNetSpecialInitiator = MenuCrimeNetSpecialInitiator or class()
function MenuCrimeNetSpecialInitiator:modify_node( original_node, data )
	local node = original_node
	return self:setup_node( node )
end

function MenuCrimeNetSpecialInitiator:refresh_node( node )
	self:setup_node( node )
	return node
end

function MenuCrimeNetSpecialInitiator:setup_node( node )
	local listed_contact = node:parameters().listed_contact or "bain"
	
	node:clean_items()
	if not node:item( "divider_end" ) then
		local contacts = {}
		for contact in pairs( tweak_data.narrative.contacts ) do
			table.insert( contacts, contact )
		end
		table.sort( contacts, function( x, y ) return y > x end )
		
		local max_jc = managers.job:get_max_jc_for_player()

		local jobs = {}
		for index, job_id in ipairs( tweak_data.narrative:get_jobs_index() ) do
			local contact = tweak_data.narrative.jobs[ job_id ].contact

			if table.contains( contacts, contact ) then
				jobs[ contact ] = jobs[ contact ] or {}
				
				local dlc = tweak_data.narrative.jobs[ job_id ].dlc
				dlc = not dlc or tweak_data.dlc[ dlc ] and tweak_data.dlc[ dlc ].free or managers.dlc:has_dlc( dlc )
				
				table.insert( jobs[ contact ], { id=job_id, enabled= dlc and (( tweak_data.narrative.jobs[ job_id ].jc or 0 ) + ( tweak_data.narrative.jobs[ job_id ].professional and 1 or 0 ) <= max_jc and not tweak_data.narrative.jobs[ job_id ].wrapped_to_job ) } )
			end
		end
		
		
		local job_tweak = tweak_data.narrative.jobs
		for _, contracts in pairs( jobs ) do
			table.sort( contracts, function( x, y )
					if x.enabled ~= y.enabled then
						return x.enabled
					end
					
					local string_x = managers.localization:to_upper_text( job_tweak[ x.id ].name_id )
					local string_y = managers.localization:to_upper_text( job_tweak[ y.id ].name_id )
					local ids_x = Idstring( string_x )
					local ids_y = Idstring( string_y )
					if ids_x ~= ids_y then
						return string_x < string_y
					end
					
					if job_tweak[ x.id ].jc ~= job_tweak[ y.id ].jc then
						return job_tweak[ x.id ].jc <= job_tweak[ y.id ].jc
					end
					
					return false
				end
			)
		end
		
		
		local params = {
				
				name="contact_filter",
				text_id="menu_contact_filter",
				
				callback="choice_premium_contact",
				filter=true
				}
		
		
		local data_node = { type="MenuItemMultiChoice" }
		table.insert( data_node, { _meta="option", no_text=true, text_id="", value=contacts[ #contacts ] .. "#" } )
		for index, contact in ipairs( contacts ) do
			if jobs[ contact ] then
				table.insert( data_node, { _meta="option", text_id=tweak_data.narrative.contacts[ contact ].name_id, value=contact } )
			end
		end
		table.insert( data_node, { _meta="option", no_text=true, text_id="", value=contacts[ 1 ] .. "#" } )
		
		local new_item = node:create_item( data_node, params )
		new_item:set_value( listed_contact )
		
		node:add_item( new_item )
		
		self:create_divider( node, "1" )
		self:create_divider( node, "title", "menu_cn_premium_buy_title", nil, tweak_data.screen_colors.text )
		
--[[
		for _, contact in ipairs( contacts ) do
			if jobs[ contact ] then
				self:create_divider( node, contact, tweak_data.narrative.contacts[ contact ].name_id, nil, tweak_data.screen_colors.text )
				for _, contract in pairs( jobs[ contact ] ) do
					self:create_job( node, contract )
				end
				self:create_divider( node, contact .. "_end" )
			end
		end
]]
		
		
		if jobs[ listed_contact ] then
			for _, contract in pairs( jobs[ listed_contact ] ) do
				self:create_job( node, contract )
			end
		end
		
		
		self:create_divider( node, "end" )
	end
	
	-- if MenuCallbackHandler:is_win32() then
		local params = {
				
				name = "back",
				text_id = "menu_back",
				previous_node = "true",
				visible_callback = "is_pc_controller",
				align = "right",
				last_item = "true"
				}
		
		
		local data_node = {}
		local new_item = node:create_item( data_node, params )

		node:add_item( new_item )
	-- end
	node:set_default_item_name( "contact_filter" )
	node:select_item( "contact_filter" )
	
	return node
end


function MenuCrimeNetSpecialInitiator:create_divider( node, id, text_id, size, color )
	local params = {

			name = "divider_" .. id,
			no_text = not text_id,
			text_id = text_id,
			size = size or 8,
			color = color
			}

	local data_node = { type = "MenuItemDivider" }
	local new_item = node:create_item( data_node, params )

	node:add_item( new_item )
end

function MenuCrimeNetSpecialInitiator:create_job( node, contract )
	local id = contract.id
	local enabled = contract.enabled
	local job_tweak = tweak_data.narrative.jobs[ id ]
	
	local text_id = managers.localization:to_upper_text( job_tweak.name_id )
	local color_ranges = nil
	if job_tweak.dlc and tweak_data.dlc[ job_tweak.dlc ] and not tweak_data.dlc[ job_tweak.dlc ].free then
		local pro_text = "  DLC"
		local s_len = utf8.len( text_id )
		
		text_id = text_id .. pro_text
		local e_len = utf8.len( text_id )
		
		color_ranges = { {  start=s_len, stop=e_len, color=tweak_data.screen_colors.dlc_color } }
	end
	if job_tweak.professional then
		local pro_text = "  " .. managers.localization:to_upper_text( "cn_menu_pro_job" )
		local s_len = utf8.len( text_id )
		
		text_id = text_id .. pro_text
		local e_len = utf8.len( text_id )
		
		color_ranges = { {  start=s_len, stop=e_len, color=tweak_data.screen_colors.pro_color } }
	end
	
	local params = {

			name = "job_" .. id,
			text_id = text_id,
			color_ranges = color_ranges,
			localize = "false",

			callback = enabled and "open_contract_node",

			id = id,
			customize_contract = "true"
			}
	
	local data_node = {}
	local new_item = node:create_item( data_node, params )
	
	new_item:set_enabled( enabled )
	node:add_item( new_item )
end


MenuCrimeNetCasinoInitiator = MenuCrimeNetCasinoInitiator or class()
function MenuCrimeNetCasinoInitiator:modify_node( original_node, data )
	local node = deep_clone( original_node )
	
	if data and data.back_callback then
		table.insert( node:parameters().back_callback, data.back_callback )
	end
	
	self:_create_items( node )
	
	node:parameters().menu_component_data = data
	return node
end

function MenuCrimeNetCasinoInitiator:refresh_node( node )
	local options = {}
	
	options.preferred = node:item( "preferred_item" ):value()
	options.infamous = node:item( "increase_infamous" ):value()
	options.card1 = node:item( "secure_card_1" ):value()
	options.card2 = node:item( "secure_card_2" ):value()
	options.card3 = node:item( "secure_card_3" ):value()
	
	node:clean_items()
	self:_create_items( node, options )
	return node
end

function MenuCrimeNetCasinoInitiator:_create_items( node, options )
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local preferred_data = { type="MenuItemMultiChoice",
			{ _meta="option", text_id="menu_casino_option_prefer_none", value="none" },
			{ _meta="option", text_id="menu_casino_stat_weapon_mods", value="weapon_mods" },
			{ _meta="option", text_id="menu_casino_stat_masks", value="masks" },
			{ _meta="option", text_id="menu_casino_stat_materials", value="materials" },
			{ _meta="option", text_id="menu_casino_stat_textures", value="textures" },
			{ _meta="option", text_id="menu_casino_stat_colors", value="colors" }
			
			
	}
	
	local preferred_params = {
			
			name="preferred_item",
			text_id="",
			callback="crimenet_casino_update"
	}
	
	local preferred_item = node:create_item( preferred_data, preferred_params )
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 1 ) then
		preferred_item:set_value( "none" )
		preferred_item:set_enabled( false )
	else
		preferred_item:set_value( options and options.preferred or "none" )
	end
	
	node:add_item( preferred_item )
	
	
	
	local infamous_data = { type="CoreMenuItemToggle.ItemToggle",
			{ _meta="option", icon="guis/textures/menu_tickbox", value="on", x=24, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=24, s_y=24, s_w=24, s_h=24 },
			{ _meta="option", icon="guis/textures/menu_tickbox", value="off", x=0, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=0, s_y=24, s_w=24, s_h=24 },
	}
	
	local infamous_params = {
			
			name="increase_infamous",
			text_id="menu_casino_option_infamous_title",
			callback="crimenet_casino_update",
			disabled_color=Color( 0.25, 1, 1, 1 ),
			icon_by_text=true
	}
	
	local infamous_items = { weapon_mods=false, masks=true, materials=true, textures=true, colors=true }
	
	local preferred_value = preferred_item:value()
	local infamous_item = node:create_item( infamous_data, infamous_params )
	infamous_item:set_enabled( infamous_items[ preferred_value ] )
	if not infamous_item:enabled() then
		infamous_item:set_value( "off" )
	else
		infamous_item:set_value( options and options.infamous or "off" )
	end
	
	node:add_item( infamous_item )
	
	
	
	self:create_divider( node, "casino_divider_securecards" )
	
	
	
	local card1_data = { type="CoreMenuItemToggle.ItemToggle",
			{ _meta="option", icon="guis/textures/menu_tickbox", value="on", x=24, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=24, s_y=24, s_w=24, s_h=24 },
			{ _meta="option", icon="guis/textures/menu_tickbox", value="off", x=0, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=0, s_y=24, s_w=24, s_h=24 },
	}
	
	local card1_params = {
			
			name="secure_card_1",
			text_id="menu_casino_option_safecard1",
			callback="crimenet_casino_safe_card1",
			disabled_color=Color( 0.25, 1, 1, 1 ),
			icon_by_text=true
	}
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 1 ) then
		card1_params.disabled_color = Color( 1, 0.6, 0.2, 0.2 )
		card1_params.text_id = managers.localization:to_upper_text( "menu_casino_option_safecard1" ) .. " - " .. managers.localization:to_upper_text( "menu_casino_option_safecard_lock", { level=tweak_data:get_value( "casino", "secure_card_level", 1 ) } )
		card1_params.localize = "false"
	end
	
	local card1_item = node:create_item( card1_data, card1_params )
	card1_item:set_value( preferred_item:value() ~= "none" and options and options.card1 or "off" )
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 1 ) then
		card1_item:set_enabled( false )
	else
		card1_item:set_enabled( preferred_item:value() ~= "none" )
	end
	
	node:add_item( card1_item )
	
	
	
	local card2_data = { type="CoreMenuItemToggle.ItemToggle",
			{ _meta="option", icon="guis/textures/menu_tickbox", value="on", x=24, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=24, s_y=24, s_w=24, s_h=24 },
			{ _meta="option", icon="guis/textures/menu_tickbox", value="off", x=0, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=0, s_y=24, s_w=24, s_h=24 },
	}
	
	local card2_params = {
			
			name="secure_card_2",
			text_id="menu_casino_option_safecard2",
			callback="crimenet_casino_safe_card2",
			disabled_color=Color( 0.25, 1, 1, 1 ),
			icon_by_text=true
	}
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 2 ) then
		card2_params.disabled_color = Color( 1, 0.6, 0.2, 0.2 )
		card2_params.text_id = managers.localization:to_upper_text( "menu_casino_option_safecard2" ) .. " - " .. managers.localization:to_upper_text( "menu_casino_option_safecard_lock", { level=tweak_data:get_value( "casino", "secure_card_level", 2 ) } )
		card2_params.localize = "false"
	end
	
	local card2_item = node:create_item( card2_data, card2_params )
	card2_item:set_value( preferred_item:value() ~= "none" and options and options.card2 or "off" )
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 2 ) then
		card2_item:set_enabled( false )
	else
		card2_item:set_enabled( preferred_item:value() ~= "none" )
	end
	
	node:add_item( card2_item )
	
	
	
	local card3_data = { type="CoreMenuItemToggle.ItemToggle",
			{ _meta="option", icon="guis/textures/menu_tickbox", value="on", x=24, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=24, s_y=24, s_w=24, s_h=24 },
			{ _meta="option", icon="guis/textures/menu_tickbox", value="off", x=0, y=0, w=24, h=24, s_icon="guis/textures/menu_tickbox", s_x=0, s_y=24, s_w=24, s_h=24 },
	}
	
	local card3_params = {
			
			name="secure_card_3",
			text_id="menu_casino_option_safecard3",
			callback="crimenet_casino_safe_card3",
			disabled_color=Color( 0.25, 1, 1, 1 ),
			icon_by_text=true
	}
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 3 ) then
		card3_params.disabled_color = Color( 1, 0.6, 0.2, 0.2 )
		card3_params.text_id = managers.localization:to_upper_text( "menu_casino_option_safecard3" ) .. " - " .. managers.localization:to_upper_text( "menu_casino_option_safecard_lock", { level=tweak_data:get_value( "casino", "secure_card_level", 3 ) } )
		card3_params.localize = "false"
	end
	
	local card3_item = node:create_item( card3_data, card3_params )
	card3_item:set_value( preferred_item:value() ~= "none" and options and options.card3 or "off" )
	
	if managers.experience:current_level() < tweak_data:get_value( "casino", "secure_card_level", 3 ) then
		card3_item:set_enabled( false )
	else
		card3_item:set_enabled( preferred_item:value() ~= "none" )
	end
	
	node:add_item( card3_item )
	
	
	
	self:create_divider( node, "casino_cost" )
	
	
	
	local increase_infamous = infamous_item:value() == "on"
	local secured_cards = ( card1_item:value() == "on" and 1 or 0 ) + ( card2_item:value() == "on" and 1 or 0 ) + ( card3_item:value() == "on" and 1 or 0 )
	
	if options then
		managers.menu:active_menu().renderer:selected_node():set_update_values( preferred_item:value(), secured_cards, increase_infamous, infamous_item:enabled(), card1_item:enabled() )
		managers.menu_component:can_afford()
	end
end

function MenuCrimeNetCasinoInitiator:create_divider( node, id, text_id, size, color )
	local params = {
			
			name="divider_" .. id,
			no_text=not text_id,
			text_id=text_id,
			size=size or 8,
			color=color
	}
	
	local data_node = { type="MenuItemDivider" }
	local new_item = node:create_item( data_node, params )
	
	node:add_item( new_item )
end


MenuCrimeNetCasinoLootdropInitiator = MenuCrimeNetCasinoLootdropInitiator or class()
function MenuCrimeNetCasinoLootdropInitiator:modify_node( original_node, data )
	local node = deep_clone( original_node )
	
	if data and data.back_callback then
		table.insert( node:parameters().back_callback, data.back_callback )
	end
	
	node:parameters().menu_component_data = data
	return node
end


MenuCrimeNetFiltersInitiator = MenuCrimeNetFiltersInitiator or class()
function MenuCrimeNetFiltersInitiator:modify_node( original_node, data )
	local node = original_node
	--local node = deep_clone( original_node )
	node:item( "toggle_friends_only" ):set_value( Global.game_settings.search_friends_only and "on" or "off" )
	

	if MenuCallbackHandler:is_win32() then
		local matchmake_filters = managers.network.matchmake:lobby_filters()

		node:item( "toggle_new_servers_only" ):set_value( matchmake_filters.num_players and matchmake_filters.num_players.value or -1 )
		node:item( "toggle_server_state_lobby" ):set_value( matchmake_filters.state and matchmake_filters.state.value or -1 )

		node:item( "max_lobbies_filter" ):set_value( managers.network.matchmake:get_lobby_return_count() )

		node:item( "server_filter" ):set_value( managers.network.matchmake:distance_filter() )
		node:item( "difficulty_filter" ):set_value( matchmake_filters.difficulty and matchmake_filters.difficulty.value or -1 )

		self:add_filters( node )
	end
	
	if MenuCallbackHandler:is_win32() then
		local not_friends_only = not Global.game_settings.search_friends_only
		node:item( "toggle_new_servers_only" ):set_enabled( not_friends_only )
		node:item( "toggle_server_state_lobby" ):set_enabled( not_friends_only )
		node:item( "max_lobbies_filter" ):set_enabled( not_friends_only )
		node:item( "server_filter" ):set_enabled( not_friends_only )
		node:item( "difficulty_filter" ):set_enabled( not_friends_only )
		node:item( "kicking_allowed_filter" ):set_enabled( not_friends_only )
		node:item( "job_id_filter" ):set_enabled( not_friends_only )
	end
	
	if( data and data.back_callback ) then
		table.insert( node:parameters().back_callback, data.back_callback )
	end
	
	node:parameters().menu_component_data = data
	return node
end

function MenuCrimeNetFiltersInitiator:update_node( node )
	if MenuCallbackHandler:is_win32() then
		local not_friends_only = not Global.game_settings.search_friends_only
		node:item( "toggle_new_servers_only" ):set_enabled( not_friends_only )
		node:item( "toggle_server_state_lobby" ):set_enabled( not_friends_only )
		node:item( "max_lobbies_filter" ):set_enabled( not_friends_only )
		node:item( "server_filter" ):set_enabled( not_friends_only )
		node:item( "difficulty_filter" ):set_enabled( not_friends_only )
		node:item( "kicking_allowed_filter" ):set_enabled( not_friends_only )
		node:item( "job_id_filter" ):set_enabled( not_friends_only )
	end
end

function MenuCrimeNetFiltersInitiator:refresh_node( node )
	if MenuCallbackHandler:is_win32() then
		local not_friends_only = not Global.game_settings.search_friends_only
		node:item( "toggle_new_servers_only" ):set_enabled( not_friends_only )
		node:item( "toggle_server_state_lobby" ):set_enabled( not_friends_only )
		node:item( "max_lobbies_filter" ):set_enabled( not_friends_only )
		node:item( "server_filter" ):set_enabled( not_friends_only )
		node:item( "difficulty_filter" ):set_enabled( not_friends_only )
		node:item( "kicking_allowed_filter" ):set_enabled( not_friends_only )
		node:item( "job_id_filter" ):set_enabled( not_friends_only )
	end
end

function MenuCrimeNetFiltersInitiator:add_filters( node )
	if node:item( "divider_end" ) then
		return
	end
	
	local params = {
		
		name = "job_id_filter",
		text_id = "menu_job_id_filter",
		visible_callback = "is_multiplayer is_win32",
		callback = "choice_job_id_filter",
		filter = true
		}
	
	local data_node = {	type = "MenuItemMultiChoice",
				{ _meta = "option", text_id = "menu_any", value = -1 }
			}
	for index, job_id in ipairs( tweak_data.narrative:get_jobs_index() ) do
		table.insert( data_node, { _meta = "option", text_id = tweak_data.narrative.jobs[ job_id ].name_id, value = index, color = tweak_data.narrative.jobs[ job_id ].professional and tweak_data.screen_colors.pro_color or Color.white } )
	end
	
	local new_item = node:create_item( data_node, params )
	new_item:set_value( managers.network.matchmake:get_lobby_filter( "job_id") or -1 )
	
	node:add_item( new_item )
	
	
	
	
	local params = {
	
		name = "kicking_allowed_filter",
		text_id = "menu_kicking_allowed_filter",
		visible_callback = "is_multiplayer is_win32",
		callback = "choice_kicking_allowed",
		filter = true
		}
	local data_node = {	type = "MenuItemMultiChoice",
				{ _meta = "option", text_id = "menu_any", value = -1 }
			}
	
	local kick_filters = {
				{ text_id = "menu_kick_server", value = 1 },
				{ text_id = "menu_kick_disabled", value = 0 }
			}
	
	for index, filter in ipairs( kick_filters ) do
		table.insert( data_node, { _meta = "option", text_id = filter.text_id, value = filter.value } )
	end
	
	local new_item = node:create_item( data_node, params )
	new_item:set_value( managers.network.matchmake:get_lobby_filter( "kicking_allowed" ) or -1 )
	
	node:add_item( new_item )
	
	
	
	
	local params = {

				name = "divider_end",
				no_text = true,
				size = 8
			}
	
	local data_node = { type = "MenuItemDivider" }
	local new_item = node:create_item( data_node, params )
	
	node:add_item( new_item )
end



MenuOptionInitiator = MenuOptionInitiator or class()
function MenuOptionInitiator:modify_node( node )
	local node_name = node:parameters().name
	if( node_name == "resolution" ) then
		return self:modify_resolution( node )
	elseif( node_name == "video" ) then
		return self:modify_video( node )
	elseif( node_name == "adv_video" ) then
		return self:modify_adv_video( node )
	elseif( node_name == "controls" ) then
		return self:modify_controls( node )
	elseif( node_name == "debug" ) then
		return self:modify_debug_options( node )
	elseif( node_name == "options" ) then
		return self:modify_options( node )
	end
end


function MenuOptionInitiator:modify_resolution( node )
	if( SystemInfo:platform() == Idstring( "WIN32" ) ) then
		local res_name = string.format( "%d x %d", RenderSettings.resolution.x, RenderSettings.resolution.y )
		-- local res_name = string.format( "%d x %d, %d Hz", RenderSettings.resolution.x, RenderSettings.resolution.y, RenderSettings.resolution.z )
		node:set_default_item_name( res_name )
	end
	return node
end

function MenuOptionInitiator:modify_adv_video( node )
	node:item( "toggle_vsync" ):set_value( RenderSettings.v_sync and "on" or "off" )
	if node:item( "choose_streaks" ) then
		node:item( "choose_streaks" ):set_value( managers.user:get_setting( "video_streaks" ) and "on" or "off" )
	end
	if node:item( "choose_light_adaption" ) then
		node:item( "choose_light_adaption" ):set_value( managers.user:get_setting( "light_adaption" ) and "on" or "off" )
	end
	if node:item( "choose_anti_alias" ) then
		node:item( "choose_anti_alias" ):set_value( managers.user:get_setting( "video_anti_alias" ) )
	end
	node:item( "choose_anim_lod" ):set_value( managers.user:get_setting( "video_animation_lod" ) )
	if node:item( "choose_color_grading" ) then
		node:item( "choose_color_grading" ):set_value( managers.user:get_setting( "video_color_grading" ) )
	end
	node:item( "use_lightfx" ):set_value( managers.user:get_setting( "use_lightfx" ) and "on" or "off" )
	node:item( "choose_texture_quality" ):set_value( RenderSettings[ "texture_quality_default" ] )
	node:item( "choose_anisotropic" ):set_value( RenderSettings[ "max_anisotropy" ] )
	if node:item( "fov_multiplier" ) then
		node:item( "fov_multiplier" ):set_value( managers.user:get_setting( "fov_multiplier" ) )
	end
	node:item( "choose_fps_cap" ):set_value( managers.user:get_setting( "fps_cap" ) )

	local option_value = "off"
	local dof_setting_item = node:item( "toggle_dof" )
	if dof_setting_item then
		if managers.user:get_setting( "dof_setting" ) ~= "none" then
			option_value = "on"
		end
		dof_setting_item:set_value( option_value )
	end
	
	-- node:item( "fov_standard" ):set_value( managers.user:get_setting( "fov_standard" ) )
	-- node:item( "fov_zoom" ):set_value( managers.user:get_setting( "fov_zoom" ) )
	-- node:item( "choose_menu_theme" ):set_value( managers.user:get_setting( "menu_theme" ) )
	return node
end

function MenuOptionInitiator:modify_video( node )
	local option_value = "off"

	local fs_item = node:item( "toggle_fullscreen" )
	if fs_item then
		if( RenderSettings.fullscreen ) then
			option_value = "on"
		end
		fs_item:set_value( option_value )
	end


	option_value = "off"
	local st_item = node:item( "toggle_subtitle" )
	if st_item then
		if( managers.user:get_setting( "subtitle" ) ) then
			option_value = "on"
		end
		st_item:set_value( option_value )
	end
	
	option_value = "off"
	local hit_indicator_item = node:item( "toggle_hit_indicator" )
	if hit_indicator_item then
		if( managers.user:get_setting( "hit_indicator" ) ) then
			option_value = "on"
		end
		hit_indicator_item:set_value( option_value )
	end
	
	option_value = "off"
	local objective_reminder_item = node:item( "toggle_objective_reminder" )
	if objective_reminder_item then
		if( managers.user:get_setting( "objective_reminder" ) ) then
			option_value = "on"
		end
		objective_reminder_item:set_value( option_value )
	end
		
	local br_item = node:item( "brightness" )
	if br_item then
		br_item:set_min( _G.tweak_data.menu.MIN_BRIGHTNESS )
		br_item:set_max( _G.tweak_data.menu.MAX_BRIGHTNESS )
		br_item:set_step( _G.tweak_data.menu.BRIGHTNESS_CHANGE )
		option_value = managers.user:get_setting( "brightness" )
		br_item:set_value( option_value )	
	end
	
	local effect_quality_item = node:item( "effect_quality" )
	if effect_quality_item then
		option_value = managers.user:get_setting( "effect_quality" )
		effect_quality_item:set_value( option_value )
	end
	
	return node
end


function MenuOptionInitiator:modify_controls( node )
	local option_value = "off"

	local rumble_item = node:item( "toggle_rumble" )
	if rumble_item then
		if( managers.user:get_setting( "rumble" ) ) then
			option_value = "on"
		end
		rumble_item:set_value( option_value )
	end

	option_value = "off"
	local inv_cam_horizontally_item = node:item( "toggle_invert_camera_horisontally" )
	if inv_cam_horizontally_item then
		if( managers.user:get_setting( "invert_camera_x" ) ) then
			option_value = "on"
		end
		inv_cam_horizontally_item:set_value( option_value )
	end

	option_value = "off"
	local inv_cam_vertically_item = node:item( "toggle_invert_camera_vertically" )
	if inv_cam_vertically_item then
		if( managers.user:get_setting( "invert_camera_y" ) ) then
			option_value = "on"
		end
		inv_cam_vertically_item:set_value( option_value )
	end
	
	option_value = "off"
	local southpaw_item = node:item( "toggle_southpaw" )
	if southpaw_item then
		if( managers.user:get_setting( "southpaw" ) ) then
			option_value = "on"
		end
		southpaw_item:set_value( option_value )
	end
	
	option_value = "off"
	local hold_to_steelsight_item = node:item( "toggle_hold_to_steelsight" )
	if hold_to_steelsight_item then
		if( managers.user:get_setting( "hold_to_steelsight" ) ) then
			option_value = "on"
		end
		hold_to_steelsight_item:set_value( option_value )
	end
	
	option_value = "off"
	local hold_to_run_item = node:item( "toggle_hold_to_run" )
	if hold_to_run_item then
		if( managers.user:get_setting( "hold_to_run" ) ) then
			option_value = "on"
		end
		hold_to_run_item:set_value( option_value )
	end
	
	option_value = "off"
	local hold_to_duck_item = node:item( "toggle_hold_to_duck" )
	if hold_to_duck_item then
		if( managers.user:get_setting( "hold_to_duck" ) ) then
			option_value = "on"
		end
		hold_to_duck_item:set_value( option_value )
	end
	
	option_value = "off"
	local aim_assist_item = node:item( "toggle_aim_assist" )
	if aim_assist_item then
		if managers.user:get_setting( "aim_assist" ) then
			option_value = "on"
		end
		aim_assist_item:set_value( option_value )
	end
	
	local cs_item = node:item( "camera_sensitivity" )
	if cs_item then
		cs_item:set_min( tweak_data.player.camera.MIN_SENSITIVITY )
		cs_item:set_max( tweak_data.player.camera.MAX_SENSITIVITY )
		cs_item:set_step( ( tweak_data.player.camera.MAX_SENSITIVITY - tweak_data.player.camera.MIN_SENSITIVITY ) * 0.1 )
		cs_item:set_value( managers.user:get_setting( "camera_sensitivity" ) )
	end

	local czs_item = node:item( "camera_zoom_sensitivity" )
	if czs_item then
		czs_item:set_min( tweak_data.player.camera.MIN_SENSITIVITY )
		czs_item:set_max( tweak_data.player.camera.MAX_SENSITIVITY )
		czs_item:set_step( ( tweak_data.player.camera.MAX_SENSITIVITY - tweak_data.player.camera.MIN_SENSITIVITY ) * 0.1 )
		czs_item:set_value( managers.user:get_setting( "camera_zoom_sensitivity" ) )
	end

	node:item( "toggle_zoom_sensitivity" ):set_value( managers.user:get_setting( "enable_camera_zoom_sensitivity" ) and "on" or "off" )
	
	return node
end


function MenuOptionInitiator:modify_debug_options( node )
	local option_value = "off"

	local players_item = node:item( "toggle_players" )
	if players_item then
		-- We don't always have a players_item, it will be disabled upon milestone delivery
		players_item:set_value( Global.nr_players )
	end
	
	local god_mode_item = node:item( "toggle_god_mode" )
	if god_mode_item then
		local god_mode_value = Global.god_mode and "on" or "off" 
		god_mode_item:set_value( god_mode_value )
	end
	
	local post_effects_item = node:item( "toggle_post_effects" )
	if post_effects_item then
		local post_effects_value = Global.debug_post_effects_enabled and "on" or "off" 
		post_effects_item:set_value( post_effects_value )
	end
	
	local team_AI_mode_item = node:item( "toggle_team_AI" )
	if team_AI_mode_item then
		local team_AI_mode_value = managers.groupai:state():team_ai_enabled() and "on" or "off" 
		team_AI_mode_item:set_value( team_AI_mode_value )
	end
	
	return node
end


function MenuOptionInitiator:modify_options( node )
	return node
end
