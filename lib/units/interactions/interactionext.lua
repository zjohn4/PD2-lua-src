BaseInteractionExt = BaseInteractionExt or class()

BaseInteractionExt.SKILL_IDS = {}
BaseInteractionExt.SKILL_IDS.none = 1
BaseInteractionExt.SKILL_IDS.basic = 2
BaseInteractionExt.SKILL_IDS.aced = 3

BaseInteractionExt.INFO_IDS = { 1, 2, 4, 8, 16, 32, 64, 128 }

function BaseInteractionExt:init( unit )
	self._unit = unit
	self._unit:set_extension_update_enabled( Idstring( "interaction" ), false )
	
	self:refresh_material()
	
	self:set_tweak_data( self.tweak_data )
	self:set_active( self._tweak_data.start_active or (self._tweak_data.start_active == nil and true ) )
		
	-- managers.interaction:add_object( unit )
	
	-- self:set_contour( "standard_color", 0.5 )
	self._interact_obj = self._interact_object and self._unit:get_object( Idstring( self._interact_object ) )
	self._interact_position = self._interact_obj and self._interact_obj:position() or self._unit:position()
	local rotation = self._interact_obj and self._interact_obj:rotation() or self._unit:rotation()
	self._interact_axis = self._tweak_data.axis and ( rotation[self._tweak_data.axis]( rotation ) ) or nil
	self:_update_interact_position()
	self:_setup_ray_objects()
end

local ids_material = Idstring( "material" )
function BaseInteractionExt:refresh_material()
	self._materials = self._unit:get_objects_by_type( ids_material )
end

function BaseInteractionExt:set_tweak_data( id )
	self.tweak_data = id
	self._tweak_data = tweak_data.interaction[ id ]
end

function BaseInteractionExt:interact_position()
	self:_update_interact_position()
	return self._interact_position
end

function BaseInteractionExt:interact_axis()
	self:_update_interact_axis()
	return self._interact_axis
end

function BaseInteractionExt:_setup_ray_objects()
	if self._ray_object_names then
		self._ray_objects = { self._interact_obj or self._unit:orientation_object() }
		for _, object_name in ipairs( self._ray_object_names ) do
			table.insert( self._ray_objects, self._unit:get_object( Idstring( object_name ) ) )
		end
	end
end

function BaseInteractionExt:ray_objects()
	return self._ray_objects
end

-- This make sure that the position only needs to be called on if the unit is moving 
function BaseInteractionExt:_update_interact_position()
	if self._unit:moving() or self._tweak_data.force_update_position then
		self._interact_position = self._interact_obj and self._interact_obj:position() or self._unit:position() 
	end
end

-- This make sure that the position only needs to be called on if the unit is moving 
function BaseInteractionExt:_update_interact_axis()
	if self._tweak_data.axis and self._unit:moving() then
		local rotation = self._interact_obj and self._interact_obj:rotation() or self._unit:rotation()
		self._interact_axis = self._tweak_data.axis and ( rotation[self._tweak_data.axis]( rotation ) ) or nil
	end
end

function BaseInteractionExt:interact_distance()
	return self._tweak_data.interact_distance or tweak_data.interaction.INTERACT_DISTANCE
end

function BaseInteractionExt:update( distance_to_player )
end

local is_PS3 = SystemInfo:platform() == Idstring("PS3")
function BaseInteractionExt:_btn_interact()
	if not managers.menu:is_pc_controller() then -- is_PS3 then
		return nil
	end
	local type = managers.controller:get_default_wrapper_type()
	return "["..managers.controller:get_settings( type ):get_connection( "interact" ):get_input_name_list()[1].."]"
end

function BaseInteractionExt:can_select( player )
	if not self:_has_required_upgrade() then
		return false
	end

	if not self:_has_required_deployable() then
		return false
	end
	
	if not self:_is_in_required_state() then
		return false
	end
	
	if self._tweak_data.special_equipment_block and managers.player:has_special_equipment( self._tweak_data.special_equipment_block ) then
		return false
	end

	return true
end

function BaseInteractionExt:selected( player )
	if not self:can_select( player ) then
		return
	end
	











	local text_id = self._tweak_data.text_id or alive(self._unit) and self._unit:base().interaction_text_id and self._unit:base():interaction_text_id()
	local text = managers.localization:text( text_id, { BTN_INTERACT = self:_btn_interact() } )
	local icon = self._tweak_data.icon
	
	if self._tweak_data.special_equipment then
		if not managers.player:has_special_equipment( self._tweak_data.special_equipment ) then
			text = managers.localization:text( self._tweak_data.equipment_text_id, { BTN_INTERACT = self:_btn_interact() } )
			icon = (self.no_equipment_icon or self._tweak_data.no_equipment_icon) or icon
		end
	end
	self:set_contour( "selected_color" )
	managers.hud:show_interact( { text = text, icon = icon } )
	return true
end

function BaseInteractionExt:unselect()
	self:set_contour( "standard_color" )
end

function BaseInteractionExt:_has_required_upgrade()
	if self._tweak_data.requires_upgrade then
		local category = self._tweak_data.requires_upgrade.category
		local upgrade = self._tweak_data.requires_upgrade.upgrade
		return managers.player:has_category_upgrade( category, upgrade )
	end
	
	return true
end

function BaseInteractionExt:_has_required_deployable()
	if self._tweak_data.required_deployable then
		return managers.player:has_deployable_left( self._tweak_data.required_deployable )
	end
	
	return true
end


function BaseInteractionExt:_is_in_required_state()
	return true
end

function BaseInteractionExt:_interact_say( data )
	local player = data[1]
	local say_line = data[2]

	self._interact_say_clbk = nil
	player:sound():say( say_line, true )
end

function BaseInteractionExt:interact_start( player )
	local blocked, skip_hint = self:_interact_blocked( player )
	if blocked then
		if not skip_hint and self._tweak_data.blocked_hint then
			managers.hint:show_hint( self._tweak_data.blocked_hint )
		end
		return false
	end
	
	local has_equipment = (not self._tweak_data.special_equipment) and true or managers.player:has_special_equipment( self._tweak_data.special_equipment )
	local sound = has_equipment and (self._tweak_data.say_waiting or "") or self.say_waiting
	
	if sound and sound ~= "" then
		local delay = (self._tweak_data.timer or 0) * managers.player:toolset_value()
		delay = delay / 3 + math.random() * delay / 3
		
		local say_t = Application:time() + delay
		self._interact_say_clbk = "interact_say_waiting"
		managers.enemy:add_delayed_clbk( self._interact_say_clbk, callback( self, self, "_interact_say", { player, sound } ), say_t )
	end
	
	if self._tweak_data.timer then
		if not self:can_interact( player ) then
			if self._tweak_data.blocked_hint then
				managers.hint:show_hint( self._tweak_data.blocked_hint )
			end
			return false
		end
		local timer = self:_get_timer() -- self:_get_modified_timer() or self._tweak_data.timer * managers.player:toolset_value()
		if timer ~= 0 then
			self:_post_event( player, "sound_start" )
			self:_at_interact_start( player, timer )
			-- local timer = self:_get_timer() -- self:_get_modified_timer() or self._tweak_data.timer * managers.player:toolset_value()
			return false, timer
		end
	end
	
	return self:interact( player )
end

function BaseInteractionExt:_get_timer()
	local modified_timer = self:_get_modified_timer()
	if modified_timer then
		return modified_timer
	end
	
	local multiplier = 1
	if self._tweak_data.upgrade_timer_multiplier then
		multiplier = managers.player:upgrade_value( self._tweak_data.upgrade_timer_multiplier.category, self._tweak_data.upgrade_timer_multiplier.upgrade, 1 )
	end
	if managers.player:has_category_upgrade( "player", "level_interaction_timer_multiplier" ) then
		local data = managers.player:upgrade_value( "player", "level_interaction_timer_multiplier" ) or {}
		local player_level = managers.experience:current_level() or 0
		
		multiplier = multiplier * ( 1 - ( data[1] or 0 ) * math.ceil( player_level / ( data[2] or 1 ) ) )
	end
	return self._tweak_data.timer * multiplier * managers.player:toolset_value()
end

function BaseInteractionExt:_get_modified_timer()
	return nil
end

function BaseInteractionExt:interact_interupt( player, complete )
	self:_post_event( player, "sound_interupt" )
	
	if self._interact_say_clbk then
		managers.enemy:remove_delayed_clbk( self._interact_say_clbk )
		self._interact_say_clbk = nil
	end	
	
	self:_at_interact_interupt( player, complete )
end

function BaseInteractionExt:_post_event( player, sound_type )
	-- Only play these sound if it is the player who is interacting
	if not alive( player ) then
		return
	end
	if player ~= managers.player:player_unit() then
		return
	end
	if self._tweak_data[ sound_type ] then
		player:sound():play( self._tweak_data[ sound_type ] )
	end
end

function BaseInteractionExt:_at_interact_start()
end

function BaseInteractionExt:_at_interact_interupt( player, complete )
end

function BaseInteractionExt:interact( player )
	self:_post_event( player, "sound_done" )
end

function BaseInteractionExt:can_interact( player )
	if not self:_has_required_upgrade() then
		return false
	end
	if not self:_has_required_deployable() then
		return false
	end
	if self._tweak_data.special_equipment_block and managers.player:has_special_equipment( self._tweak_data.special_equipment_block ) then
		return false
	end
	if not self._tweak_data.special_equipment or self._tweak_data.dont_need_equipment then
		return true
	end

	return managers.player:has_special_equipment( self._tweak_data.special_equipment )
end

function BaseInteractionExt:_interact_blocked( player )
	return false
end

function BaseInteractionExt:active()
	return self._active
end

function BaseInteractionExt:set_active( active, sync, sync_by_id )
--	print( "BaseInteractionExt:set_active", active, sync, self._unit )
--	Application:stack_dump()

	if not active and self._active then
		managers.interaction:remove_object( self._unit )
		if not self._tweak_data.no_contour then
			managers.occlusion:add_occlusion( self._unit )
		end
	elseif active and not self._active then
		managers.interaction:add_object( self._unit )
		if not self._tweak_data.no_contour then
			managers.occlusion:remove_occlusion( self._unit )
		end
	end
	self._active = active
	self:set_contour( "standard_color" )
	if sync and managers.network:session() then
		if self._unit:id() == -1 then
			local u_data = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() )
			if u_data then
				managers.network:session():send_to_peers_synched( "sync_interaction_set_active_by_id", u_data.u_id, active, self.tweak_data )
			end
		elseif sync_by_id then
			managers.network:session():send_to_peers_synched( "sync_interaction_set_active_by_id", self._unit:id(), active, self.tweak_data )
		else
			managers.network:session():send_to_peers_synched( "sync_interaction_set_active", self._unit, active, self.tweak_data )
		end
	end
end

function BaseInteractionExt:set_assignment( name )
	self._assignment = name
end

local ids_contour_color = Idstring( "contour_color" )
local ids_contour_opacity = Idstring( "contour_opacity" )
function BaseInteractionExt:set_contour( color, opacity )
	-- local materials = self._unit:get_objects_by_type( ids_material )
	if self._tweak_data.no_contour or self._contour_override then
		return
	end
	for _,m in ipairs( self._materials ) do
		m:set_variable( ids_contour_color, tweak_data.contour[ self._tweak_data.contour or "interactable" ][ color ] )
		m:set_variable( ids_contour_opacity, opacity or ( self._active and 1 or 0 ) )
	end
end

function BaseInteractionExt:set_contour_override( state )
	self._contour_override = state
end

function BaseInteractionExt:save( data )
	local state = {}
	state.active = self._active
	data.InteractionExt = state
end

function BaseInteractionExt:load( data )
	local state = data.InteractionExt
	if state then
		self:set_active( state.active )
		-- self._active = state.active
	end
end

function BaseInteractionExt:remove_interact()
	if not managers.interaction:active_object() or self._unit == managers.interaction:active_object() then -- Only remove from hud if we are looking at the same as was interacted with
		managers.hud:remove_interact()
	end
end

function BaseInteractionExt:destroy()
	self:remove_interact()
	self:set_active( false, false )
	if self._unit == managers.interaction:active_object() then
		self:_post_event( managers.player:player_unit(), "sound_interupt" )
	end
	if not self._tweak_data.no_contour then
		managers.occlusion:add_occlusion( self._unit )
	end
	
	if self._interacting_units then
		for u_key, unit in pairs( self._interacting_units ) do
			if alive( unit ) then
				unit:base():remove_destroy_listener( self._interacting_unit_destroy_listener_key )
			end
		end
		self._interacting_units = nil
	end
end

--//--------------------

UseInteractionExt = UseInteractionExt or class( BaseInteractionExt )

function UseInteractionExt:unselect()
	UseInteractionExt.super.unselect( self )
	managers.hud:remove_interact()
end

function UseInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return
	end
	
	UseInteractionExt.super.interact( self, player )
	
	if self._tweak_data.equipment_consume then
		managers.player:remove_special( self._tweak_data.special_equipment )
		
		if self._tweak_data.special_equipment == "planks" and Global.level_data.level_id == "secret_stash" then
			UseInteractionExt._saviour_count = (UseInteractionExt._saviour_count or 0) + 1
			if UseInteractionExt._saviour_count >= 20 then
				managers.challenges:set_flag( "saviour" )
			end
		end
	end
		
	if self._tweak_data.deployable_consume then
		managers.player:remove_equipment( self._tweak_data.required_deployable )
	end
	
	if self._tweak_data.sound_event then
		player:sound():play( self._tweak_data.sound_event )
	end

--[[
	if self._unit:base() and self._unit:base().set_alert_radius then
		if managers.player:has_category_upgrade( "player", "silent_drill" ) then
			self._unit:base():set_alert_radius(nil)
		elseif managers.player:has_category_upgrade( "player", "drill_alert_rad" ) then
			local radius = managers.player:upgrade_value( "player", "drill_alert_rad", self._unit:base()._alert_radius )
			self._unit:base():set_alert_radius( radius )
		else
			self._unit:base():set_alert_radius( 2500 )
		end

		local autorepair_chance = managers.player:upgrade_value( "player", "drill_autorepair", 0 )
		if autorepair_chance > 0 and math.random() < autorepair_chance then
			self._unit:base():set_autorepair( true )
		else
			self._unit:base():set_autorepair( nil )
		end

		self._unit:timer_gui():set_timer_multiplier( managers.player:upgrade_value( "player", "drill_speed_multiplier", 1 ) )
	end
]]

	self:remove_interact()
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple( "interact", { unit = player } )
	end
	-- if Network:is_client() then
	
	--managers.money:perform_action_interact( self._unit:name() )
	--managers.experience:perform_action_interact( self._unit:name() )
	
	managers.network:session():send_to_peers_synched( "sync_interacted", self._unit, -2, self.tweak_data )
	-- end
	
	if self._assignment then
		managers.secret_assignment:interacted( self._assignment )
	end
	
	if self._global_event then
		managers.mission:call_global_event( self._global_event, player )
	end
	
	self:set_active( false )
end

function UseInteractionExt:sync_interacted( peer, skip_alive_check )
	local player = managers.network:game():member( peer:id() ):unit()
	if not skip_alive_check and not alive( player ) then
		return
	end

--[[
	if Network:is_server() and self._unit:base() and self._unit:base().set_alert_radius then
		if player:base():upgrade_value( "player", "silent_drill" ) then
			self._unit:base():set_alert_radius( nil )
		elseif player:base():upgrade_value( "player", "drill_alert_rad" ) then
			self._unit:base():set_alert_radius( player:base():upgrade_value( "player", "drill_alert_rad" ) )
		end

		if player:base():upgrade_value( "player", "drill_autorepair" ) then
			self._unit:base():set_autorepair( true )
		end
		local autorepair_chance = player:base():upgrade_value( "player", "drill_autorepair" )
		if autorepair_chance and math.random() < autorepair_chance then
			self._unit:base():set_autorepair( true )
		end

		if player:base():upgrade_value( "player", "drill_speed_multiplier" ) then
			self._unit:timer_gui():set_timer_multiplier( player:base():upgrade_value( "player", "drill_speed_multiplier" ) or 1 )
		end
	end
]]

	self:remove_interact()
	self:set_active( false )
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple( "interact", { unit = player } )
	end
end

function UseInteractionExt:destroy()
	-- self:remove_interact()
	UseInteractionExt.super.destroy( self )
end

--//--------------------

TripMineInteractionExt = TripMineInteractionExt or class( UseInteractionExt )

function TripMineInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return false
	end
	TripMineInteractionExt.super.super.interact( self, player )
	-- TripMineInteractionExt.super.interact( self, player )
	local armed = not self._unit:base():armed()
	self._unit:base():set_armed( armed )
	-- managers.network:session():send_to_peers_synched_no_target( "sync_trip_mine_set_armed", self._unit, armed  )
end

--//--------------------

ECMJammerInteractionExt = ECMJammerInteractionExt or class( UseInteractionExt )

function ECMJammerInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return false
	end
	ECMJammerInteractionExt.super.super.interact( self, player )
	
	self._unit:base():set_feedback_active()
	self:remove_interact()
end

function ECMJammerInteractionExt:can_interact( player )
	return ECMJammerInteractionExt.super.can_interact( self, player ) and self._unit:base():owner() == player
end

function ECMJammerInteractionExt:selected( player )
	if not self:can_interact( player ) then
		return
	end
	
	return ECMJammerInteractionExt.super.selected( self, player )
end

--//--------------------

-- This is a mp player husk extension
ReviveInteractionExt = ReviveInteractionExt or class( BaseInteractionExt )

function ReviveInteractionExt:init( unit, ... )
	self._wp_id = "ReviveInteractionExt"..unit:id()
	ReviveInteractionExt.super.init( self, unit, ... )
end

-----------------------------------------------------------------

function ReviveInteractionExt:_at_interact_start( player, timer )
	if self.tweak_data == "revive" then
		self:_at_interact_start_revive( player, timer )
	elseif self.tweak_data == "free" then
		self:_at_interact_start_free( player )
	end
		
	self:set_waypoint_paused( true )
	managers.network:session():send_to_peers_synched( "interaction_set_waypoint_paused", self._unit, true )
end

function ReviveInteractionExt:_at_interact_start_revive( player, timer )
	if self._unit:base().is_husk_player then
		local revive_rpc_params = { "start_revive_player", timer }
		self._unit:network():send_to_unit( revive_rpc_params )
	else -- AI
		self._unit:character_damage():pause_bleed_out()
	end
	
	if player:base().is_local_player then
		managers.achievment:set_script_data( "player_reviving", true )
	end
end

function ReviveInteractionExt:_at_interact_start_free( player )
	if self._unit:base().is_husk_player then
		local revive_rpc_params = { "start_free_player" }
		self._unit:network():send_to_unit( revive_rpc_params )
	else -- AI
		self._unit:character_damage():pause_arrested_timer()
	end
end

-----------------------------------------------------------------

function ReviveInteractionExt:_at_interact_interupt( player, complete )
	if self.tweak_data == "revive" then
		self:_at_interact_interupt_revive( player )
	elseif self.tweak_data == "free" then
		self:_at_interact_interupt_free( player )
	end
	
	self:set_waypoint_paused( false )
	if self._unit:id() ~= -1 then
		managers.network:session():send_to_peers_synched( "interaction_set_waypoint_paused", self._unit, false )
	end
end

function ReviveInteractionExt:_at_interact_interupt_revive( player )
	if self._unit:base().is_husk_player then
		local revive_rpc_params = { "interupt_revive_player" }
		self._unit:network():send_to_unit( revive_rpc_params )
	else -- AI
		self._unit:character_damage():unpause_bleed_out()
	end
	
	if player:base().is_local_player then
		managers.achievment:set_script_data( "player_reviving", false )
	end
end

function ReviveInteractionExt:_at_interact_interupt_free( player )
	if self._unit:base().is_husk_player then
		local revive_rpc_params = { "interupt_free_player" }
		self._unit:network():send_to_unit( revive_rpc_params )
	else -- AI
		self._unit:character_damage():unpause_arrested_timer()
	end
end

-----------------------------------------------------------------

function ReviveInteractionExt:set_waypoint_paused( paused )
	if self._active_wp then
		managers.hud:set_waypoint_timer_pause( self._wp_id, paused )
		managers.hud:pause_teammate_timer( self._panel_id, paused )
	end
	
end

function ReviveInteractionExt:get_waypoint_time( )
	if self._active_wp then
		local data = managers.hud:get_waypoint_data( self._wp_id )
		if data then
			return data.timer
		end
	end
	
	return nil
end

local is_win32 = SystemInfo:platform() == Idstring( "WIN32" )
function ReviveInteractionExt:set_active( active, sync, down_time )
	ReviveInteractionExt.super.set_active( self, active )
	if not managers.hud:exists( "guis/player_hud" ) then
		return
	end
	
	if managers.criminals:character_data_by_unit( self._unit ) then
		self._panel_id = managers.criminals:character_data_by_unit( self._unit ).panel_id
	end
	
	if self._active then
		local hint = self.tweak_data == "revive" and "teammate_downed" or "teammate_arrested" 
		
		if hint == "teammate_downed" then
			managers.achievment:set_script_data( "stand_together_fail", true )
		end
		
		local location_id = self._unit:movement():get_location_id()
		local location = location_id and (" "..managers.localization:text( location_id )) or ""
		managers.hint:show_hint( hint, nil, false, {TEAMMATE=self._unit:base():nick_name(), LOCATION=location} )
		
		if not self._active_wp then	
			down_time = down_time or 999
			local text = managers.localization:text( self.tweak_data == "revive" and "debug_team_mate_need_revive" or "debug_team_mate_need_free" )
			local icon = self.tweak_data == "revive" and "wp_revive" or "wp_rescue"
			local timer = self.tweak_data == "revive" and ((self._unit:base().is_husk_player and down_time or tweak_data.character[ self._unit:base()._tweak_table ].damage.DOWNED_TIME))
							or self._unit:base().is_husk_player and tweak_data.player.damage.ARRESTED_TIME or tweak_data.character[ self._unit:base()._tweak_table ].damage.ARRESTED_TIME
			managers.hud:add_waypoint( self._wp_id, { text = text, icon = icon, unit = self._unit, distance = is_win32, --[[position = self._unit:position()]] present_timer = 1, timer = timer } )
			self._active_wp = true
			
			managers.hud:start_teammate_timer( self._panel_id, timer )
		end
	elseif self._active_wp then
		managers.hud:remove_waypoint( self._wp_id )
		self._active_wp = false
		
		managers.hud:stop_teammate_timer( self._panel_id )
	end
end

function ReviveInteractionExt:unselect()
	managers.hud:remove_interact()
end

function ReviveInteractionExt:interact( reviving_unit )
	if reviving_unit and reviving_unit == managers.player:player_unit() then -- Some things are only done when the player does it
		if not self:can_interact( reviving_unit ) then
			return
		end
		
		if self._tweak_data.equipment_consume then
			managers.player:remove_special( self._tweak_data.special_equipment )
		end
		
		if self._tweak_data.sound_event then
			reviving_unit:sound():play( self._tweak_data.sound_event )
		end
		
		ReviveInteractionExt.super.interact( self, reviving_unit )
		managers.achievment:set_script_data( "player_reviving", false )
		
		managers.player:activate_temporary_upgrade( "temporary", "combat_medic_damage_multiplier" )
		managers.player:activate_temporary_upgrade( "temporary", "combat_medic_enter_steelsight_speed_multiplier" )
	end
		
	self:remove_interact()
	if self._unit:damage() then
		if self._unit:damage():has_sequence( "interact" ) then
			self._unit:damage():run_sequence_simple( "interact" )
		end
	end
		
	if self._unit:base().is_husk_player then	-- we are a player husk
		local revive_rpc_params = { "revive_player", managers.player:upgrade_value( "player", "revive_health_boost", 0 ) }
		managers.statistics:revived( { npc = false, reviving_unit = reviving_unit } )
		self._unit:network():send_to_unit( revive_rpc_params )
	else	-- we are an AI unit
		self._unit:character_damage():revive( reviving_unit )
		managers.statistics:revived( { npc = true, reviving_unit = reviving_unit } )
	end
	
	if Network:is_server() and reviving_unit:in_slot( managers.slot:get_mask( "criminals" ) ) then
		local hint = self.tweak_data == "revive" and 2 or 3 -- "teammate_helpedup" or "teammate_rescued"
		managers.network:session():send_to_peers_synched( "sync_teammate_helped_hint", hint, self._unit, reviving_unit )
		managers.trade:sync_teammate_helped_hint( self._unit, reviving_unit, hint )
	end
	
	if managers.blackmarket:equipped_mask().mask_id == tweak_data.achievement.witch_doctor.mask then
		managers.achievment:award_progress( tweak_data.achievement.witch_doctor.stat )
	end
	
	-- self:set_active( false )
end

function ReviveInteractionExt:save( data )
	ReviveInteractionExt.super.save( self, data )
	local state = {}
	state.active_wp = self._active_wp
	state.wp_id = self._wp_id
	data.ReviveInteractionExt = state
end

function ReviveInteractionExt:load( data )
	local state = data.ReviveInteractionExt
	if state then
		 self._active_wp = state.active_wp
		 self._wp_id = state.wp_id
		 -- managers.hud._hud.waypoints[ "ReviveInteractionExt336" ].timer
	end
	ReviveInteractionExt.super.load( self, data )
	--[[local state = data.ReviveInteractionExt
	if state then
		 self._active_wp = state.active_wp
		 self._wp_id = state.wp_id
	end]]
end

--//--------------------

AmmoBagInteractionExt = AmmoBagInteractionExt or class( UseInteractionExt )

function AmmoBagInteractionExt:_interact_blocked( player )
	return not player:inventory():need_ammo()
end

function AmmoBagInteractionExt:interact( player )
	AmmoBagInteractionExt.super.super.interact( self, player )
	local interacted = self._unit:base():take_ammo( player )
	for id,weapon in pairs( player:inventory():available_selections() ) do
		managers.hud:set_ammo_amount( id, weapon.unit:base():ammo_info() )
	end
	--[[managers.hud:set_ammo_amount( unit:inventory():equipped_unit():base():selection_index(), player:inventory():equipped_unit():base():ammo_info() )
	for _,weapon in pairs( player:inventory():available_selections() ) do
		managers.hud:set_weapon_ammo_by_unit( weapon.unit )
	end]]
	return interacted
end

--//--------------------

GrenadeCrateInteractionExt = GrenadeCrateInteractionExt or class( UseInteractionExt )

function GrenadeCrateInteractionExt:_interact_blocked( player )
	return managers.player:got_max_grenades()
end

function GrenadeCrateInteractionExt:interact( player )
	GrenadeCrateInteractionExt.super.super.interact( self, player )
	return self._unit:base():take_grenade( player )
end

--//--------------------

DoctorBagBaseInteractionExt = DoctorBagBaseInteractionExt or class( UseInteractionExt )

function DoctorBagBaseInteractionExt:_interact_blocked( player )
	return player:character_damage():full_health()
end

function DoctorBagBaseInteractionExt:interact( player )
	DoctorBagBaseInteractionExt.super.super.interact( self, player )
	local interacted = self._unit:base():take( player )
	return interacted
end

--//--------------------

C4BagInteractionExt = C4BagInteractionExt or class( UseInteractionExt )

function C4BagInteractionExt:_interact_blocked( player )
	return not managers.player:can_pickup_equipment( "c4" )
end

function C4BagInteractionExt:interact( player )
	C4BagInteractionExt.super.super.interact( self, player )
	managers.player:add_special( { name = "c4" } )
	return true
end

--//--------------------

VeilInteractionExt = VeilInteractionExt or class( UseInteractionExt )

function VeilInteractionExt:_interact_blocked( player )
	return not managers.player:can_pickup_equipment( "blood_sample" )
end

function VeilInteractionExt:interact( player )
	VeilInteractionExt.super.super.interact( self, player )
	managers.player:add_special( { name = "blood_sample" } )
	return true
end

--//--------------------

VeilTakeInteractionExt = VeilTakeInteractionExt or class( UseInteractionExt )

function VeilTakeInteractionExt:_interact_blocked( player )
	return not managers.player:can_pickup_equipment( "blood_sample_verified" )
end

function VeilTakeInteractionExt:interact( player )
	VeilTakeInteractionExt.super.interact( self, player )
	managers.player:add_special( { name = "blood_sample_verified" } )
	if self._unit:damage():has_sequence( "got_blood_sample" ) then
		self._unit:damage():run_sequence_simple( "got_blood_sample" )
	end
	return true
end

function VeilTakeInteractionExt:sync_interacted()
	if self._unit:damage():has_sequence( "got_blood_sample" ) then
		self._unit:damage():run_sequence_simple( "got_blood_sample" )
	end
	VeilTakeInteractionExt.super.sync_interacted( self )
end

--//--------------------

SmallLootInteractionExt = SmallLootInteractionExt or class( UseInteractionExt )

function SmallLootInteractionExt:interact( player )
	if not self._unit:damage() or not self._unit:damage():has_sequence( "interact" ) then
		SmallLootInteractionExt.super.super.interact( self, player )
	else
		SmallLootInteractionExt.super.interact( self, player )
	end 
	--[[if self._unit:damage() then
		if self._unit:damage():has_sequence( "interact" ) then
			SmallLootInteractionExt.super.interact( self, player )
		else
			SmallLootInteractionExt.super.super.interact( self, player )
		end
	else
		SmallLootInteractionExt.super.super.interact( self, player )
	end]]
	self._unit:base():take( player )
end

--//--------------------

MoneyWrapInteractionExt = MoneyWrapInteractionExt or class( UseInteractionExt )

function MoneyWrapInteractionExt:interact( player )
	MoneyWrapInteractionExt.super.super.interact( self, player )
	self._unit:base():take_money( player )
end

DiamondInteractionExt = DiamondInteractionExt or class( UseInteractionExt )

function DiamondInteractionExt:interact( player )
	DiamondInteractionExt.super.interact( self, player )
	self._unit:base():take_money( player )
end

--//--------------------

IntimitateInteractionExt = IntimitateInteractionExt or class( BaseInteractionExt )

function IntimitateInteractionExt:init( unit, ... )
	IntimitateInteractionExt.super.init( self, unit, ... )
	self._nbr_interactions = 0
end

function IntimitateInteractionExt:unselect()
	UseInteractionExt.super.unselect( self )
	managers.hud:remove_interact()
end

function IntimitateInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return
	end
	
	local has_equipment = managers.player:has_special_equipment( self._tweak_data.special_equipment )
	if self._tweak_data.equipment_consume and has_equipment then
		managers.player:remove_special( self._tweak_data.special_equipment )
	end
	
	if self._tweak_data.sound_event then
		player:sound():play( self._tweak_data.sound_event )
	end
		
	self:remove_interact()
	if self._unit:damage() then
		if self._unit:damage():has_sequence( "interact" ) then
			self._unit:damage():run_sequence_simple( "interact" )
		end
	end
	
	if self.tweak_data == "corpse_alarm_pager" then
		self._unit:base():set_material_state( true )
		if Network:is_server() then
			self._nbr_interactions = 0

			local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
			managers.network:session():send_to_peers_synched( "alarm_pager_interaction", u_id, self.tweak_data, 3 )

			self._unit:brain():on_alarm_pager_interaction( "complete", player )
			
			if alive( managers.interaction:active_object() ) then
				managers.interaction:active_object():interaction():selected()
			end
		else
			local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
			managers.network:session():send_to_host( "alarm_pager_interaction", u_id, self.tweak_data, 3 ) -- 2=interrupted, 3=complete
		end
	elseif self.tweak_data == "corpse_dispose" then
		
		managers.player:set_carry( "person", 1 )
	
		local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
		if Network:is_server() then
			self:remove_interact()
			self:set_active( false, true )
			self._unit:set_slot( 0 )
			managers.network:session():send_to_peers_synched( "remove_corpse_by_id", u_id )
		else
			managers.network:session():send_to_host( "sync_interacted_by_id", u_id, self.tweak_data ) -- Should this be something own?
			player:movement():set_carry_restriction( true )
		end
		
	elseif self._tweak_data.dont_need_equipment and not has_equipment then
		self:set_active( false )
		self._unit:brain():on_tied( player, true )
	elseif self.tweak_data == "hostage_trade" then
		-- Give experience?
		-- Play sound?
		self._unit:brain():on_trade( player )
		
		if managers.blackmarket:equipped_mask().mask_id == tweak_data.achievement.relation_with_bulldozer.mask then
			managers.achievment:award_progress( tweak_data.achievement.relation_with_bulldozer.stat )
		end
		
		managers.challenges:set_flag( "diplomatic" )
		managers.statistics:trade( { name = self._unit:base()._tweak_table } )
	elseif self.tweak_data == "hostage_convert" then
		if Network:is_server() then
			self:remove_interact()
			self:set_active( false, true )
			managers.groupai:state():convert_hostage_to_criminal( self._unit )
		else
			managers.network:session():send_to_host( "sync_interacted", self._unit, self._unit:id(), self.tweak_data )
		end
	else
		-- local money = tweak_data.character[ self._unit:base()._tweak_table ].money.cable_tie
		-- managers.money:perform_action( money )
		-- local action = tweak_data.character[ self._unit:base()._tweak_table ].experience.cable_tie
		-- managers.experience:perform_action( action )
		self:set_active( false )
		player:sound():play( "cable_tie_apply" )
		self._unit:brain():on_tied( player )
	end
end

function IntimitateInteractionExt:_at_interact_start( player, timer )
	IntimitateInteractionExt.super._at_interact_start( self )
	
	if self.tweak_data == "corpse_alarm_pager" then
		if Network:is_server() then
			self._nbr_interactions = self._nbr_interactions + 1
		end

		if self._in_progress then
			return
		end
		self._in_progress = true
		
		player:sound():say( "dsp_radio_checking_1", true, true )
		
		-- TO DO: play conversation voice
		if Network:is_server() then
			self._unit:brain():on_alarm_pager_interaction( "started" )
		else
			local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
			managers.network:session():send_to_host( "alarm_pager_interaction", u_id, self.tweak_data, 1 ) -- 1=started
		end
	end
end

function IntimitateInteractionExt:_at_interact_interupt( player, complete )
	IntimitateInteractionExt.super._at_interact_interupt( self, player, complete )
	if self.tweak_data == "corpse_alarm_pager" then
		if not self._in_progress then
			return
		end
		
		player:sound():say( "dsp_stop_all", false, true )
		
		if not complete then
			-- TO DO: play conversation voice
			self._unit:base():set_material_state( true )
			if Network:is_server() then
				self._nbr_interactions = self._nbr_interactions - 1
				if self._nbr_interactions == 0 then
					self._in_progress = nil
					self._unit:brain():on_alarm_pager_interaction( "interrupted", player )
				end
			else
				self._in_progress = nil
				local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
				managers.network:session():send_to_host( "alarm_pager_interaction", u_id, self.tweak_data, 2 ) -- 2=interrupted, 3=complete
			end
		end
	end
end

function IntimitateInteractionExt:sync_interacted( peer, status )
	local _get_unit = function()
		local member = managers.network:game():member( peer:id() )
		local unit = member and member:unit()
		if not unit then
			print( "[IntimitateInteractionExt:sync_interacted] missing unit", inspect(peer) )
		end
		return unit
	end
	
	if self.tweak_data == "corpse_alarm_pager" then
		if Network:is_server() then
			self._interacting_unit_destroy_listener_key = "IntimitateInteractionExt_" .. tostring( self._unit:key() )
			if status == "started" then
				local husk_unit = _get_unit()
				if husk_unit then
					husk_unit:base():add_destroy_listener( self._interacting_unit_destroy_listener_key, callback( self, self, "on_interacting_unit_destroyed", peer ) )
					self._interacting_units = self._interacting_units or {}
					self._interacting_units[ husk_unit:key() ] = husk_unit
				end
				
				self._nbr_interactions = self._nbr_interactions + 1

				if self._in_progress then
					return
				end
				self._in_progress = true

				self._unit:brain():on_alarm_pager_interaction( status, _get_unit() )
			else
				if not self._in_progress then
					return
				end
				
				local husk_unit = _get_unit()
				if husk_unit then
					husk_unit:base():remove_destroy_listener( self._interacting_unit_destroy_listener_key )
					self._interacting_units[ husk_unit:key() ] = nil
					if not next( self._interacting_units ) then
						self._interacting_units = nil
					end
				end
				
				if status == "complete" then
					self._nbr_interactions = 0

					local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
					managers.network:session():send_to_peers_synched_except( peer:id(), "alarm_pager_interaction", u_id, self.tweak_data, 3 )
				else
					self._nbr_interactions = self._nbr_interactions - 1
				end

				if self._nbr_interactions == 0 then
					self._in_progress = nil
			
					self._unit:base():set_material_state( true )
					self:remove_interact()
					self._unit:brain():on_alarm_pager_interaction( status, _get_unit() )
				end
			end
		else
			self._unit:base():set_material_state( true )
		end
	elseif self.tweak_data == "corpse_dispose" then
		self:remove_interact()
		self:set_active( false, true )
		local u_id = managers.enemy:get_corpse_unit_data_from_key( self._unit:key() ).u_id
		self._unit:set_slot( 0 )
		managers.network:session():send_to_peers_synched( "remove_corpse_by_id", u_id )
	elseif self.tweak_data == "hostage_convert" then
		self:remove_interact()
		self:set_active( false, true )
		managers.groupai:state():convert_hostage_to_criminal( self._unit, _get_unit() )
	end
end

function IntimitateInteractionExt:_interact_blocked( player )
	if self.tweak_data == "corpse_dispose" then
		if managers.player:is_carrying() then
			return true
		end
		
		local has_upgrade = managers.player:has_category_upgrade( "player", "corpse_dispose" )
		if not has_upgrade then
			return true
		end
		
		return not managers.player:can_carry( "person" )
	elseif self.tweak_data == "hostage_convert" then
		return not (managers.player:has_category_upgrade( "player", "convert_enemies" ) and not managers.player:chk_minion_limit_reached() )
	end
end

function IntimitateInteractionExt:_is_in_required_state()
	if self.tweak_data == "corpse_dispose" and not managers.groupai:state():whisper_mode() then
		return false
	end

	return true
end

function IntimitateInteractionExt:on_interacting_unit_destroyed( peer, player )
	self:sync_interacted( peer, "interrupted" )
end

--//--------------------

CarryInteractionExt = CarryInteractionExt or class( UseInteractionExt )

function CarryInteractionExt:_interact_blocked( player )
	local by_cooldown = managers.player:carry_blocked_by_cooldown()
	if managers.player:is_carrying() or by_cooldown then
		return true, by_cooldown
	end
	return not managers.player:can_carry( self._unit:carry_data():carry_id() )
end

function CarryInteractionExt:can_select( player )
	if managers.player:is_carrying() or managers.player:carry_blocked_by_cooldown() then
		return false
	end
	return CarryInteractionExt.super.can_select( self, player )
end








function CarryInteractionExt:interact( player )
	CarryInteractionExt.super.super.interact( self, player )
	
	if self._has_modified_timer then -- Means that is is in air
		managers.achievment:award( "murphys_laws" ) -- This is actually reciever
	end
	-- switch player movement state.
	-- sync my carry info to other peers 
	managers.player:set_carry( self._unit:carry_data():carry_id(), self._unit:carry_data():value(), self._unit:carry_data():dye_pack_data() )
	
	managers.network:session():send_to_peers_synched( "sync_interacted", self._unit, self._unit:id(), self.tweak_data )
	self:sync_interacted( nil, player )
	
	if Network:is_client() then
		-- managers.network:session():send_to_host( "sync_interacted", self._unit, self._unit:id(), self.tweak_data ) -- Should this be something own?
		player:movement():set_carry_restriction( true )
	else
		-- I am server, I execute the interaction synchronously
		--[[if self._unit:damage():has_sequence( "load" ) then
			self._unit:damage():run_sequence_simple( "load", { unit = player } )
		end
		
		if self._remove_on_interact then
			self:remove_interact()
			self:set_active( false, true )
			self._unit:carry_data():trigger_load( player )
			self._unit:set_slot( 0 )
		end]]
	end
	
	return true
end

-- I am server and a client wants me to verify that he is allowed to interact
function CarryInteractionExt:sync_interacted( peer, player )
	player = player or managers.network:game():member( peer:id() ):unit()
	
	if self._unit:damage():has_sequence( "interact" ) then
		self._unit:damage():run_sequence_simple( "interact", { unit = player } )
	end
	
	if self._unit:damage():has_sequence( "load" ) then
		self._unit:damage():run_sequence_simple( "load", { unit = player } )
	end
	
	if self._global_event then
		managers.mission:call_global_event( self._global_event, player )
	end

	if Network:is_server() then
		if self._remove_on_interact then
			if self._unit == managers.interaction:active_object() then
				self:interact_interupt( managers.player:player_unit(), false )
			end
			self:remove_interact()
			self:set_active( false, true )
			if alive( player ) then
				self._unit:carry_data():trigger_load( player )
			end
			self._unit:set_slot( 0 )
		end
		
		if peer then
			managers.player:set_carry_approved( peer )
		end
	end
end

function CarryInteractionExt:_get_modified_timer()
	-- print( "CarryInteractionExt:_get_modified_timer()" )
	if self._has_modified_timer then -- self._unit:moving() then
		return 0
		--[[if managers.player:has_category_upgrade( "carry", "catch_interaction_speed" ) then
			return managers.player:upgrade_value( "carry", "catch_interaction_speed" )
		end]]
	end
		
	if managers.player:has_category_upgrade( "carry", "interact_speed_multiplier" ) then
		return self._tweak_data.timer * managers.player:upgrade_value( "carry", "interact_speed_multiplier", 1 )
	end
	
	return nil
end

function CarryInteractionExt:register_collision_callbacks()
	-- print( "CarryInteractionExt:register_collision_callbacks" )
	self._unit:set_body_collision_callback( callback( self, self, "_collision_callback" ) )
	self._has_modified_timer = true
	self._air_start_time = Application:time()
	for i = 0, self._unit:num_bodies() - 1 do
		local body = self._unit:body( i )
		body:set_collision_script_tag( Idstring( "throw" ) )
		body:set_collision_script_filter( 1 )
		body:set_collision_script_quiet_time( 1 )		
	end
end

function CarryInteractionExt:_collision_callback( tag, unit, body, other_unit, other_body, position, normal, velocity, ... )
	if self._has_modified_timer then
		self._has_modified_timer = nil
	end
	
	local air_time = Application:time() - self._air_start_time
	
	self._unit:carry_data():check_explodes_on_impact( velocity, air_time )
	self._air_start_time = Application:time()
	
	
	if self._unit:carry_data():can_explode() and not self._unit:carry_data():explode_sequence_started() then
		return 
	end
	
	
	for i = 0, self._unit:num_bodies() - 1 do
		local body = self._unit:body( i )
		body:set_collision_script_tag( Idstring( "" ) )
	end
end

--//--------------------

LootBankInteractionExt = LootBankInteractionExt or class( UseInteractionExt )

function LootBankInteractionExt:_interact_blocked( player )
	return not managers.player:is_carrying()
end

function LootBankInteractionExt:interact( player )
	LootBankInteractionExt.super.super.interact( self, player )
	-- managers.player:set_carry( self._carry_id )
	if Network:is_client() then
		managers.network:session():send_to_host( "sync_interacted", self._unit, -2, self.tweak_data ) -- Should this be something own?
	else
		self:sync_interacted( nil, player )
	end
	managers.player:bank_carry()
	return true
end

function LootBankInteractionExt:sync_interacted( peer, player )
	local player = player or managers.network:game():member( peer:id() ):unit()
	self._unit:damage():run_sequence_simple( "unload", { unit = player } )
end

--//--------------------

EventIDInteractionExt = EventIDInteractionExt or class( UseInteractionExt )

function EventIDInteractionExt:show_blocked_hint( player, skip_hint )
	local unit_base = alive( self._unit ) and self._unit:base()
	if unit_base and unit_base.show_blocked_hint then
		unit_base:show_blocked_hint( self._tweak_data, player, skip_hint )
	end
end

function EventIDInteractionExt:_interact_blocked( player )
	local unit_base = alive( self._unit ) and self._unit:base()
	if unit_base and unit_base.check_interact_blocked then
		return unit_base:check_interact_blocked( player )
	end
	return false
end

function EventIDInteractionExt:interact_start( player )
	local blocked, skip_hint = self:_interact_blocked(player)
	if blocked then
		self:show_blocked_hint( player, skip_hint )
		return false
	end
	
	local has_equipment = not self._tweak_data.special_equipment and true or managers.player:has_special_equipment( self._tweak_data.special_equipment )
	local sound = has_equipment and ( self._tweak_data.say_waiting or "" ) or self.say_waiting
	
	if sound and sound ~= "" then
		local delay = ( self._tweak_data.timer or 0 ) * managers.player:toolset_value()
		delay = delay / 3 + math.random() * delay / 3
		
		local say_t = Application:time() + delay
		self._interact_say_clbk = "interact_say_waiting"
		managers.enemy:add_delayed_clbk( self._interact_say_clbk, callback( self, self, "_interact_say", { player, sound } ), say_t )
	end
	
	if self._tweak_data.timer then
		if not self:can_interact( player ) then
			self:show_blocked_hint( player )
			return false
		end
		local timer = self:_get_timer()
		if timer ~= 0 then
			self:_post_event( player, "sound_start" )
			self:_at_interact_start( player, timer )
			
			return false, timer
		end
	end
	
	return self:interact( player )
end

function EventIDInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return false
	end
	
	local event_id = alive( self._unit ) and self._unit:base() and self._unit:base().get_net_event_id and self._unit:base():get_net_event_id( player ) or 1
	if event_id then
		managers.network:session():send_to_peers_synched( "sync_unit_event_id_8", self._unit, "interaction", event_id )
		self:sync_net_event( event_id, player )
	end
end

function EventIDInteractionExt:can_interact( player )
	if not EventIDInteractionExt.super.can_interact( self, player ) then
		return false
	end
	return alive( self._unit ) and self._unit:base() and self._unit:base().can_interact and self._unit:base():can_interact( player )
end

function EventIDInteractionExt:sync_net_event( event_id, player )
	local unit_base = alive( self._unit ) and self._unit:base()
	if unit_base and unit_base.sync_net_event then
		unit_base:sync_net_event( event_id, player )
	end
end

--//--------------------

-- Clients tells server that they want to place/interact with a device. Server does it for them and sends back a result.
MissionDoorDeviceInteractionExt = MissionDoorDeviceInteractionExt or class( UseInteractionExt )

function MissionDoorDeviceInteractionExt:interact( player )
	if not self:can_interact( player ) then
		return
	end
	
	-- MissionDoorDeviceInteractionExt.super.interact( self, player )
	MissionDoorDeviceInteractionExt.super.super.interact( self, player ) -- This basicly plays the end sound for an interaction
	
	-- local is_drill = self._unit:base() and self._unit:base().set_alert_radius

	if Network:is_client() then
--[[
		if is_drill then
			if managers.player:has_category_upgrade( "player", "silent_drill" ) then
				self._unit:timer_gui():set_skill( BaseInteractionExt.SKILL_IDS.aced )
			elseif managers.player:has_category_upgrade( "player", "drill_alert_rad" ) then
				self._unit:timer_gui():set_skill( BaseInteractionExt.SKILL_IDS.basic )
			end
		end
]]
		managers.network:session():send_to_host( "server_place_mission_door_device", self._unit, player )
	else
		local result = self:server_place_mission_door_device( player )
		self:result_place_mission_door_device( result )
--[[
		if is_drill then
			if managers.player:has_category_upgrade( "player", "silent_drill" ) then
				self._unit:base():set_alert_radius( nil )
			elseif managers.player:has_category_upgrade( "player", "drill_alert_rad" ) then
				local radius = managers.player:upgrade_value( "player", "drill_alert_rad", self._unit:base()._alert_radius )
				self._unit:base():set_alert_radius( radius )
			else
				self._unit:base():set_alert_radius( 2500 )
			end
			
			local autorepair_chance = managers.player:upgrade_value( "player", "drill_autorepair", 0 )
			if autorepair_chance > 0 and math.random() < autorepair_chance then
				self._unit:base():set_autorepair( true )
			else
				self._unit:base():set_autorepair( nil )
			end
		end
]]
	end
--[[
	if Network:is_client() then
		managers.network:session():send_to_host( "sync_placed_mission_door_device", self._unit )
	else
		self:sync_placed_mission_door_device()
	end
]]
end

	--[[ FLOW: Client(c) Server(s) Interacter(*) Anyone(+)
		CLIENT INTERACTS: 
					(c*)MissionDoorDeviceInteractionExt:interact -> 
					(c*)send_to_host("server_place_mission_door_device") -> 
					(s+)UnitNetworkHandler:server_place_mission_door_device ->
					(s+)MissionDoorDeviceInteractionExt:server_place_mission_door_device (Sequence on server updates TimerGui) ->
					(s+)send_to_peers_synched("sync_interacted") ->
					(c+)UnitNetworkHandler:sync_interacted ->
					(c+)MissionDoorDeviceInteractionExt:sync_interacted (peer is sender, sender is server) (Sequence on client updates TimerGui)
		
		SERVER INTERACTS:
					(s*)MissionDoorDeviceInteractionExt:interact -> 
					(s*)MissionDoorDeviceInteractionExt:server_place_mission_door_device (Sequence on server updates TimerGui) ->
					(s*)send_to_peers_synched("sync_interacted") ->
					(c+)UnitNetworkHandler:sync_interacted ->
					(c+)MissionDoorDeviceInteractionExt:sync_interacted (peer is sender, sender is server) (Sequence on client updates TimerGui)
	]]
function MissionDoorDeviceInteractionExt:sync_interacted( peer )
	MissionDoorDeviceInteractionExt.super.sync_interacted( self, peer, true )
--[[
	if self._unit:timer_gui() and self._unit:base() and self._unit:timer_gui()._upgrade_tweak_data and self._unit:base().get_skill_upgrades then
		local player_info_id = self:get_player_info_id()
		local player_info_table = self:split_info_id( player_info_id )
		
		local unit_info_table = self._unit:base():get_skill_upgrades()
		
		for i in pairs( player_info_table ) do
			if not unit_info_table[ i ] then
				self:set_tweak_data( self._unit:timer_gui()._upgrade_tweak_data )
				self:set_active( true )
				break
			end
		end
	end
]]
	
	self:check_for_upgrade()
--[[
	if is_drill then
		print( "MissionDoorDeviceInteractionExt:sync_interacted" )
		if player:base():upgrade_value( "player", "drill_speed_multiplier" ) then
			print( "has upgrade value", player:base():upgrade_value( "player", "drill_speed_multiplier" ) )
		end
	end
]]
	
--[[
	local player = managers.network:game():member( peer:id() ):unit()
	if not alive( player ) then
		return
	end
]]
	
--[[
	if player:base():upgrade_value( "player", "silent_drill" ) or player:base():upgrade_value( "player", "drill_alert_rad" ) or player:base():upgrade_value( "player", "drill_autorepair" ) or player:base():upgrade_value( "player", "drill_autorepair" ) then
		Application:debug( "MissionDoorDeviceInteractionExt:sync_interacted: peer upgrade checks out,", peer )
	end
]]

--[[
	local is_drill = self._unit:base() and self._unit:base().set_alert_radius
	if is_drill then
		if player:base():upgrade_value( "player", "silent_drill" ) then
			self._unit:base():set_alert_radius( nil )
		elseif player:base():upgrade_value( "player", "drill_alert_rad" ) then
			self._unit:base():set_alert_radius( player:base():upgrade_value( "player", "drill_alert_rad" ) )
		end
		
		if player:base():upgrade_value( "player", "drill_autorepair" ) then
			self._unit:base():set_autorepair( true )
		end
		local autorepair_chance = player:base():upgrade_value( "player", "drill_autorepair" )
		if autorepair_chance and math.random() < autorepair_chance then
			self._unit:base():set_autorepair( true )
		end
	end
]]
end















function MissionDoorDeviceInteractionExt:server_place_mission_door_device( player )
	local can_place = not self._unit:mission_door_device() or self._unit:mission_door_device():can_place()
	local info_id = self:get_player_info_id( player )
	
	self:remove_interact()
	
	self:set_info_id( info_id )
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple( "interact", { unit = player } )
	end
	
	
	managers.network:session():send_to_peers_synched( "sync_interaction_info_id", self._unit, info_id )
	managers.network:session():send_to_peers_synched( "sync_interacted", self._unit, -2, self.tweak_data )
	--managers.network:session():send_to_peers_synched( "sync_unit_event_id_8", self._unit, "interaction", skill )
	
	
	self:set_active( false )
	
--[[
	if self._unit:timer_gui() and self._unit:base() and self._unit:timer_gui()._upgrade_tweak_data and self._unit:base().get_skill_upgrades then
		local player_info_id = self:get_player_info_id()
		local player_info_table = self:split_info_id( player_info_id )
		
		local unit_info_table = self._unit:base():get_skill_upgrades()
		
		for i in pairs( player_info_table ) do
			if not unit_info_table[ i ] then
				self:set_tweak_data( self._unit:timer_gui()._upgrade_tweak_data )
				self:set_active( true )
				break
			end
		end
	end
]]
	self:check_for_upgrade()
	
	if self._unit:mission_door_device() then
		self._unit:mission_door_device():placed()
	end
		
	if self._tweak_data.sound_event then
		player:sound():play( self._tweak_data.sound_event )
	end
	
	
	return can_place
end

function MissionDoorDeviceInteractionExt:result_place_mission_door_device( placed )
	if placed then
		-- print( "I placed it, remove special", self._tweak_data.special_equipment )
		if self._tweak_data.equipment_consume then
			managers.player:remove_special( self._tweak_data.special_equipment )
		end
		if self._tweak_data.deployable_consume then
			managers.player:remove_equipment( self._tweak_data.required_deployable )
		end
	else
		-- print( "DIDn't place it", self._tweak_data.special_equipment )
	end
end

function MissionDoorDeviceInteractionExt:check_for_upgrade()
	if self._unit:timer_gui() and self._unit:base() and self._unit:timer_gui()._upgrade_tweak_data and self._unit:base().get_skill_upgrades then
		local player_info_id = self:get_player_info_id()
		local player_info_table = self:split_info_id( player_info_id )
		
		local unit_info_table = self._unit:base():get_skill_upgrades()
		
		for i in pairs( player_info_table ) do
			if not unit_info_table[ i ] then
				self:set_tweak_data( self._unit:timer_gui()._upgrade_tweak_data )
				self:set_active( true )
				break
			end
		end
	end
end

function MissionDoorDeviceInteractionExt:get_player_info_id( player )
	local INFO_IDS = BaseInteractionExt.INFO_IDS
	local info_id = 0
	
	local is_saw = self._unit:base() and self._unit:base().is_saw
	local is_hacking = self._unit:base() and self._unit:base().is_hacking_device
	local is_drill = self._unit:base() and self._unit:base().is_drill
	local is_local_player = not player or player:base().is_local_player

	if is_saw then
		local saw_speed_upgrade_level = 0
		
		if is_local_player then
			saw_speed_upgrade_level = managers.player:upgrade_level( "player", "saw_speed_multiplier", 0 )
		else
			saw_speed_upgrade_level = player:base():upgrade_level( "player", "saw_speed_multiplier" ) or 0
		end
		
		if saw_speed_upgrade_level == 1 then
			info_id = info_id + INFO_IDS[1]
		elseif saw_speed_upgrade_level == 2 then
			info_id = info_id + INFO_IDS[1] + INFO_IDS[2]
		elseif saw_speed_upgrade_level >= 3 then
			info_id = info_id + INFO_IDS[1] + INFO_IDS[2]
			Application:debug( "MissionDoorDeviceInteractionExt:set_player_info_id", "saw speed upgrade level is above 2, syncing only supports 2 upgrade levels" )
		end
	elseif is_hacking then
	
	elseif is_drill then
		local drill_speed_upgrade_level = 0
		
		local got_reduced_alert = false
		local got_silent_drill = false
		local got_auto_repair = false

		if is_local_player then
			drill_speed_upgrade_level = managers.player:upgrade_level( "player", "drill_speed_multiplier", 0 )
			
			got_reduced_alert = managers.player:has_category_upgrade( "player", "drill_alert_rad" )
			got_silent_drill = managers.player:has_category_upgrade( "player", "silent_drill" )
			got_auto_repair = managers.player:has_category_upgrade( "player", "drill_autorepair" )
		else
			drill_speed_upgrade_level = player:base():upgrade_level( "player", "drill_speed_multiplier" ) or 0
			
			got_reduced_alert = player:base():upgrade_level( "player", "drill_alert_rad" ) == 1
			got_silent_drill = player:base():upgrade_level( "player", "silent_drill" ) == 1
			got_auto_repair = player:base():upgrade_level( "player", "drill_autorepair" ) == 1
		end
		
		if drill_speed_upgrade_level == 1 then
			info_id = info_id + INFO_IDS[1]
		elseif drill_speed_upgrade_level == 2 then
			info_id = info_id + INFO_IDS[1] + INFO_IDS[2]
		elseif drill_speed_upgrade_level >= 3 then
			info_id = info_id + INFO_IDS[1] + INFO_IDS[2]
			Application:debug( "MissionDoorDeviceInteractionExt:set_player_info_id", "drill speed upgrade level is above 2, syncing only supports 2 upgrade levels" )
		end
		
		if got_reduced_alert then
			info_id = info_id + INFO_IDS[3]
		end
		
		if got_silent_drill then
			info_id = info_id + INFO_IDS[4]
		end
		
		if got_auto_repair then
			info_id = info_id + INFO_IDS[5]
		end
	else
	end
	return info_id
end

function MissionDoorDeviceInteractionExt:split_info_id( info_id )
	local INFO_IDS = BaseInteractionExt.INFO_IDS
	local info_table = {}
	
	local ids_left = info_id
	for i = #INFO_IDS, 1, -1 do
		local id = INFO_IDS[ i ]
		
		if id <= ids_left then
			ids_left = ids_left - id
			info_table[ i ] = true
		end
	end
	return info_table
end

function MissionDoorDeviceInteractionExt:set_info_id( info_id )
	local upgrades_gotten = self:split_info_id( info_id )
	
	local is_saw = self._unit:base() and self._unit:base().is_saw
	local is_hacking = self._unit:base() and self._unit:base().is_hacking_device
	local is_drill = self._unit:base() and self._unit:base().is_drill
	
	if is_saw then
		local saw_speed_tweak_data = tweak_data.upgrades.values.player.saw_speed_multiplier
		local timer_multiplier = 1
		if upgrades_gotten[2] then
			timer_multiplier = saw_speed_tweak_data[2]
		elseif upgrades_gotten[1] then
			timer_multiplier = saw_speed_tweak_data[1]
		end
		
		self._unit:timer_gui():set_timer_multiplier( timer_multiplier )
	elseif is_drill or is_hacking then
		self._unit:base():set_skill_upgrades( upgrades_gotten )
	end
end

function MissionDoorDeviceInteractionExt:sync_net_event( event_id )
	if self._unit:base() then
		self._unit:timer_gui():set_skill( event_id )
	end
end

--[[function MissionDoorDeviceInteractionExt:sync_placed_mission_door_device()
	if alive( self._unit ) then
		self._unit:mission_door_device():placed()
	end
end]]

--[[function MissionDoorDeviceInteractionExt:set_parent_door( unit )
	self._parent_door = unit
end]]

--//--------------------

SpecialEquipmentInteractionExt = SpecialEquipmentInteractionExt or class( UseInteractionExt )

function SpecialEquipmentInteractionExt:_interact_blocked( player )
	return not managers.player:can_pickup_equipment( self._special_equipment )
end

function SpecialEquipmentInteractionExt:interact( player )
	SpecialEquipmentInteractionExt.super.super.interact( self, player )
	managers.player:add_special( { name = self._special_equipment } )
		
	if self._remove_on_interact then
		self:remove_interact()
		self:set_active( false )
	end
	
	if Network:is_client() then
		managers.network:session():send_to_host( "sync_interacted", self._unit, -2, self.tweak_data ) -- Should this be something own?
	else
		self:sync_interacted( nil, player )
	end
	
	return true
end

function SpecialEquipmentInteractionExt:sync_interacted( peer, player )
	player = player or managers.network:game():member( peer:id() ):unit()
	if self._unit:damage():has_sequence( "load" ) then
		self._unit:damage():run_sequence_simple( "load" )
	end
	if self._global_event then
		managers.mission:call_global_event( self._global_event, player )
	end
	if self._remove_on_interact then
		self._unit:set_slot( 0 )
	end
end

--//--------------------

AccessCameraInteractionExt = AccessCameraInteractionExt or class( UseInteractionExt )

function AccessCameraInteractionExt:_interact_blocked( player )
	return false
end

function AccessCameraInteractionExt:interact( player )
	AccessCameraInteractionExt.super.super.interact( self, player )
	
	game_state_machine:change_state_by_name( "ingame_access_camera" )
	
	return true
end

-- Below this is from Fortress, left as reference
--//--------------------

NPCInteractionExt = NPCInteractionExt or class( BaseInteractionExt )

function NPCInteractionExt:init( unit )
	BaseInteractionExt.init( self, unit )

	self._ws = World:newgui():create_world_workspace( 150, 100, unit:position() + Vector3(-25,0,250), Vector3(50,0,0), Vector3(0,0,-50) )
	self._ws:set_billboard( self._ws.BILLBOARD_Y )
	self._panel = self._ws:panel()
	self._bg = self._panel:rect{ name="bg", x=0, y=0, w=150, h=100, color=Color.yellow }
	self._text = self._panel:text{ name="text", text=self:_default_text(), align="center", vertical="center", font="fonts/font_fortress_22", font_size = 60, color=Color.black, layer=2 }
	self._toggle = false
	
	self._panel:hide()
end

function NPCInteractionExt:destroy()
	if( alive( self._ws ) ) then
		World:newgui():destroy_workspace( self._ws )
	end
end

function NPCInteractionExt:update( distance_to_player )
	local t = 1-math.clamp( (distance_to_player-tweak_data.interaction.INTERACT_DISTANCE) / (tweak_data.interaction.CULLING_DISTANCE-tweak_data.interaction.INTERACT_DISTANCE), 0, 1 )
	if( t <= 0 and self._panel:visible() ) then
		self._panel:hide()
	end
	
	if( not self._panel:visible() ) then
		self._panel:show()
	end
	self._bg:set_color( self._bg:color():with_alpha( t ) )
	self._text:set_color( self._text:color():with_alpha( t ) )
end

function NPCInteractionExt:selected( player )
	self:_set_color( true )
	if( managers.player:current_state() ~= "dialog" and managers.player:current_state() ~= "minigame" ) then
		managers.player:set_player_state( "adventure" )
	end
end

function NPCInteractionExt:unselect()
	self:_set_color( false )
	managers.player:set_player_state( managers.player:default_player_state() )
end

function NPCInteractionExt:interact( player )
	self._unit:set_rotation( Rotation( (self._unit:position()-player:position()):with_z(0):normalized(), Vector3(0,0,1) ) )
	self._text:set_text(":)")
	self:_do_interact()
end

function NPCInteractionExt:_set_color( set )
	if( set == self._toggle ) then
		return
	end
	
	self._toggle = set
	self._bg:set_color( self._toggle and Color.green or Color.yellow )
	self._text:set_text( self._toggle and "!" or self:_default_text() )
end

--//--------------------

NPCDialogInteractionExt = NPCDialogInteractionExt or class( NPCInteractionExt )

function NPCDialogInteractionExt:_default_text()
	return "Talk"
end

function NPCDialogInteractionExt:_do_interact()
	managers.player:set_player_state( "dialog" )
end

NPCMinigameInteractionExt = NPCMinigameInteractionExt or class( NPCInteractionExt )

function NPCMinigameInteractionExt:_default_text()
	return "Game"
end

function NPCMinigameInteractionExt:_do_interact()
	managers.player:set_player_state( "minigame" )
end

--//--------------------

BoxInteractionExt = BoxInteractionExt or class( BaseInteractionExt )

function BoxInteractionExt:init( unit )
	BaseInteractionExt.init( self, unit )
end

function BoxInteractionExt:interact( player )
	self._unit:push( 10, Vector3(0,0,1) * 1000 )
end

--//--------------------

MimicInteractionExt = MimicInteractionExt or class( BaseInteractionExt )

function MimicInteractionExt:init( unit )
	BaseInteractionExt.init( self, unit )
end

function MimicInteractionExt:destroy()
end

function MimicInteractionExt:selected( player )
	if( managers.player:current_state() ~= "mimic" and managers.player:current_state() ~= "mimic_interaction" ) then
		managers.player:set_player_state( "mimic_interaction" )
		
		self._unit:mimic():set_mimic( "interaction" )
	end
end

function MimicInteractionExt:unselect()
	if( managers.player:current_state() ~= "mimic" ) then
		managers.player:set_player_state( managers.player:default_player_state() )
	end
end

function MimicInteractionExt:interact( player )
	self._unit:mimic():activate_mimic( "interaction" )
	self._unit:mimic():add_player_to_mimic( managers.player:player_unit() )
	
	managers.player:set_player_state( "mimic" )
end
