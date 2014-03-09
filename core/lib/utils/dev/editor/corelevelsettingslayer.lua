core:module( "CoreLevelSettingsLayer" )

core:import( "CoreLayer" )
core:import( "CoreEws" )

-- This layer should contain simple settings used by the level. Settings that doesn't fit anywhere else. It should
-- be exteneded to work towards some kind of level settings manager.
LevelSettingsLayer = LevelSettingsLayer or class( CoreLayer.Layer )
	
function LevelSettingsLayer:init( owner )
	LevelSettingsLayer.super.init( self, owner, "level_settings" )
	
	self._settings = {}
	self._settings_ctrlrs = {}		
end

function LevelSettingsLayer:get_layer_name()
	return "Level Settings"
end

function LevelSettingsLayer:get_setting( setting )
	return self._settings[ setting ]
end

function LevelSettingsLayer:get_mission_filter()
	local t = {}
	for i = 1, 5 do
		if self:get_setting( "mission_filter_"..i ) then
			table.insert( t, i )
		end
	end
	return t
end
	
function LevelSettingsLayer:load( world_holder, offset )
	self._settings = world_holder:create_world( "world", self._save_name, offset )
	for id,setting in pairs( self._settings_ctrlrs ) do
		if setting.type == "combobox" then
			CoreEws.change_combobox_value( setting.params, self._settings[ id ] )
		end
	end
end

function LevelSettingsLayer:save( save_params )
	local t = {
			entry 					= self._save_name,
			single_data_block 		= true,
			data					= {
										settings	= self._settings
									}
	}
	self:_add_project_save_data( t.data )
	
	managers.editor:add_save_data( t )
end


function LevelSettingsLayer:update( t, dt )
	
end

function LevelSettingsLayer:build_panel( notebook )
	cat_print( 'editor', 'LevelSettingsLayer:build_panel' )
	
	self._ews_panel = EWS:Panel( notebook, "", "TAB_TRAVERSAL");
	self._main_sizer = EWS:BoxSizer("HORIZONTAL")
	self._ews_panel:set_sizer(self._main_sizer)
	
	self._sizer = EWS:BoxSizer("VERTICAL")
							
		self:_add_simulation_level_id( self._sizer )
		self:_add_simulation_mission_filter( self._sizer )
	
	self._main_sizer:add( self._sizer, 1, 0, "EXPAND" )
		
	return self._ews_panel
end

function LevelSettingsLayer:_add_simulation_level_id( sizer )
	local id = "simulation_level_id"
	local params = {
		name 				= "Simulation level id:",
		panel 				= self._ews_panel,
		sizer 				= sizer,
		options				= rawget( _G, "tweak_data" ).levels:get_level_index(),
		-- options				= tweak_data.levels:get_level_index(),
		default				= "none",
		value 				= "none",
		tooltip 			= "Select a level id to use when simulating the level.",
		name_proportions 	= 1,
		ctrlr_proportions 	= 2,
		sorted				= true
	}
	local ctrlr = CoreEws.combobox( params )
	
	ctrlr:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "_set_data" ), { ctrlr = ctrlr, value = id } )
	self._settings_ctrlrs[ id ] = { params = params, ctrlr = ctrlr, default = "none", type = "combobox" }
end

function LevelSettingsLayer:_add_simulation_mission_filter( sizer )
	for i = 1, 5 do
		local id = "mission_filter_"..i
		local ctrlr = EWS:CheckBox( self._ews_panel, "Mission filter "..i, "" )
		ctrlr:set_value( false )
		ctrlr:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "_set_data" ), { ctrlr = ctrlr, value = id } )
		sizer:add( ctrlr, 0, 0, "EXPAND" )
		
		self._settings_ctrlrs[ id ] = { params = params, ctrlr = ctrlr, default = false, type = "checkbox" }
	end
	
	--[[local var_1 = EWS:CheckBox( self._ews_panel, "1", "" )
	var_1:set_value( false )
	-- var_1:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = var_1, value = 1 } )
	var_1:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "_set_data" ), { ctrlr = var_1, value = "var_1" } )
	sizer:add( var_1, 0, 0, "EXPAND" )
	
	self._settings_ctrlrs[ "var_1" ] = { params = params, ctrlr = var_1, default = false, type = "checkbox" }
	]]
end

function LevelSettingsLayer:_set_data( data )
	self._settings[ data.value ] = data.ctrlr:get_value()
	self._settings[ data.value ] = tonumber( self._settings[ data.value ] ) or self._settings[ data.value ] -- Convert string back to number
end

function LevelSettingsLayer:add_triggers()
	LevelSettingsLayer.super.add_triggers( self )
	local vc = self._editor_data.virtual_controller

	-- vc:add_trigger( Idstring( "rmb" ), callback( self, self, "add_point" ) )
end

function LevelSettingsLayer:activate()
	LevelSettingsLayer.super.activate( self )
end

function LevelSettingsLayer:deactivate()
	LevelSettingsLayer.super.deactivate( self )
end

function LevelSettingsLayer:clear()
	LevelSettingsLayer.super.clear( self )
	
	for id,setting in pairs( self._settings_ctrlrs ) do
		if setting.type == "combobox" then
			CoreEws.change_combobox_value( setting.params, setting.default )
		elseif setting.type == "checkbox" then
			setting.ctrlr:set_value( setting.default )
		end
	end
	self._settings = {}
end

--[[function LevelSettingsLayer:get_help( text )
	local t = '\t'
	local n = '\n'
	text = text .. 'Create point:        Right mouse btn' .. n
	text = text .. 'Move point:          Thumb mouse btn' .. n
	return text
end]]

