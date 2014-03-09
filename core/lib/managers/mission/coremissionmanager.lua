core:module( "CoreMissionManager" )
core:import( "CoreMissionScriptElement" )
core:import( "CoreEvent" )
core:import( "CoreClass" )
core:import( "CoreDebug" )
core:import( "CoreCode" )
-- require "core/managers/mission/CoreMissionScriptElement"
require "core/lib/managers/mission/CoreElementDebug"

MissionManager = MissionManager or CoreClass.class( CoreEvent.CallbackHandler )

function MissionManager:init()
	MissionManager.super.init( self )

	self._runned_unit_sequences_callbacks = {}
	
	self._scripts = {}
	self._active_scripts = {}
	
	self._area_instigator_categories = {}
	self:add_area_instigator_categories( "none" )
	self:set_default_area_instigator( "none" )
	
	self._workspace = Overlay:newgui():create_screen_workspace()
	self._workspace:set_timer( TimerManager:main() )
	self._fading_debug_output = self._workspace:panel():gui( Idstring("core/guis/core_fading_debug_output") )
	self._fading_debug_output:set_leftbottom( 0, self._workspace:height()/3 )
	self._fading_debug_output:script().configure( { font_size = 20, max_rows = 20 } )
	self._persistent_debug_output = self._workspace:panel():gui( Idstring("core/guis/core_persistent_debug_output") )
	self._persistent_debug_output:set_righttop( self._workspace:width(), 0 )
	self:set_persistent_debug_enabled( false )
	self:set_fading_debug_enabled( true )
	
	self._global_event_listener = rawget( _G, "EventListenerHolder"):new()
	self._global_event_list = {} 
end

-- This function loads a serialized mission file, and starts a script
function MissionManager:parse( params, stage_name, offset, file_type )
	local file_path, activate_mission
	if CoreClass.type_name( params ) == "table" then
		file_path 			= params.file_path
		file_type 			= params.file_type or "mission"
		activate_mission 	= params.activate_mission
		offset 				= params.offset
	else
		file_path = params
		file_type = file_type or "mission"
	end
	
	CoreDebug.cat_debug( "gaspode", "MissionManager", file_path, file_type, activate_mission )
	
	if not DB:has( file_type, file_path ) then
		Application:error( "Couldn't find", file_path, "(", file_type, ")" )
		return false
	end
	
	local reverse = string.reverse( file_path )
	local i = string.find( reverse, "/" )
	local file_dir = string.reverse( string.sub( reverse, i ) )
	
	local continent_files = self:_serialize_to_script( file_type, file_path )
	continent_files._meta = nil
	for name,data in pairs( continent_files ) do
		if not managers.worlddefinition:continent_excluded( name ) then
			self:_load_mission_file( file_dir, data )
		end
	end
			
	-- Activate mission(s), either provided a specific mission to start
	-- or start missions with the activate on parsed flag set
	self:_activate_mission( activate_mission )
	
	return true
end

function MissionManager:_serialize_to_script( type, name )
	if Application:editor() then
		return PackageManager:editor_load_script_data( type:id(), name:id() )
	else
		if not PackageManager:has( type:id(), name:id() ) then
			Application:throw_exception( "Script data file "..name.." of type "..type.." has not been loaded. Could be that old mission format is being loaded. Try resaving the level." )
		end
		return PackageManager:script_data( type:id(), name:id() )
	end
end

-- Locates a continent saved mission file and parses it
function MissionManager:_load_mission_file( file_dir, data )
	local file_path = file_dir..data.file
	local scripts = self:_serialize_to_script( "mission", file_path )
	scripts._meta = nil
	for name,data in pairs( scripts ) do
		data.name = name
		self:_add_script( data )
	end
end

-- Adds a script based on a data table
function MissionManager:_add_script( data ) 
	self._scripts[ data.name ] = MissionScript:new( data )
end

-- Returns all scripts
function MissionManager:scripts() 
	return self._scripts
end

-- Returns a script
function MissionManager:script( name )
	return self._scripts[ name ]
end

function MissionManager:_activate_mission( name )
	CoreDebug.cat_debug( "gaspode", "MissionManager:_activate_mission", name )
	if name then
		if self:script( name ) then
			self:activate_script( name )
		else
			Application:throw_exception( "There was no mission named "..name.. " availible to activate!" )
		end
	else
		for _,script in pairs( self._scripts ) do
			if script:activate_on_parsed() then
				self:activate_script( script:name() )
			end
		end
	end
end

-- Activates a script
function MissionManager:activate_script( name, ... )
	CoreDebug.cat_debug( "gaspode", "MissionManager:activate_script", name )
	if not self._scripts[ name ] then
		if Global.running_simulation then
			managers.editor:output_error( "Can't activate mission script "..name..". It doesn't exist." )
			return
		else
			Application:throw_exception( "Can't activate mission script "..name..". It doesn't exist." )
		end
	end
	self._scripts[ name ]:activate( ... )
end

-- The update function
function MissionManager:update( t, dt )
	for _,script in pairs( self._scripts ) do
		script:update( t, dt )
	end
end

-- Called when stopping a simulation
function MissionManager:stop_simulation( ... )
	self:pre_destroy()
	for _,script in pairs( self._scripts ) do
		script:stop_simulation( ... )
	end
	
	self._scripts = {}
	self._runned_unit_sequences_callbacks = {}
	
	self._global_event_listener = rawget( _G, "EventListenerHolder"):new()
end

-- This is a library for all run unit sequence trigger callbacks
function MissionManager:add_runned_unit_sequence_trigger( id, sequence, callback )
	if self._runned_unit_sequences_callbacks[ id ] then
		if self._runned_unit_sequences_callbacks[ id ][ sequence ] then
			table.insert( self._runned_unit_sequences_callbacks[ id ][ sequence ], callback )
		else
			self._runned_unit_sequences_callbacks[ id ][ sequence ] = { callback }
		end
	else
		local t = {}
		t[ sequence ] = { callback }
		self._runned_unit_sequences_callbacks[ id ] = t
	end
end

-- This function should be called from the sequence manager everytime a unit runs a sequence
function MissionManager:runned_unit_sequence( unit, sequence, params )
	-- print( "runned_unit_sequence", unit, sequence, inspect( params ) )
	-- print( " ", alive( unit ), unit:unit_data() )
	if alive( unit ) and unit:unit_data() then
		local id = unit:unit_data().unit_id
		id = (id ~= 0 and id) or unit:editor_id()
		-- print( "check for callback id", id, self._runned_unit_sequences_callbacks[ id ] )
		-- print( "iii", inspect( self._runned_unit_sequences_callbacks[ id ] ) )
		if self._runned_unit_sequences_callbacks[ id ] then
			if self._runned_unit_sequences_callbacks[ id ][ sequence ] then
				for _,call in ipairs( self._runned_unit_sequences_callbacks[ id ][ sequence ] ) do
					call( params and params.unit ) -- self:default_instigator() )
				end
			end
		end
	end
end

function MissionManager:add_area_instigator_categories( category )
	table.insert( self._area_instigator_categories, category )
end

-- Returns the table containing the area instigator categories
function MissionManager:area_instigator_categories()
	return self._area_instigator_categories
end

-- Set default area instiagtor
function MissionManager:set_default_area_instigator( default )
	self._default_area_instigator = default
end

-- returns default area instiagtor
function MissionManager:default_area_instigator()
	return self._default_area_instigator
end

-- The project should choose to override this function and give a default instigator (it is required for network code 
-- which needs a unit even if it isn't really applied, worldcamera trigger for example). This is not a great sollution /Martin 
function MissionManager:default_instigator()
	return nil
end

-- Returns the persistent debug enabled value
function MissionManager:persistent_debug_enabled()
	return self._persistent_debug_enabled
end

-- Sets the persistent debug enabled value and hides or shows the gui
function MissionManager:set_persistent_debug_enabled( enabled )
	self._persistent_debug_enabled = enabled
	if enabled then
		self._persistent_debug_output:show()
	else
		self._persistent_debug_output:hide()
	end
end

-- Adds text to the persistent debug (could be called with a color as second parameter)
function MissionManager:add_persistent_debug_output( debug, color )
	if not self._persistent_debug_enabled then
		return
	end
	self._persistent_debug_output:script().log( debug, color )
end

-- Sets the persistent debug enabled value and hides or shows the gui
function MissionManager:set_fading_debug_enabled( enabled )
	self._fading_debug_enabled = enabled
	if enabled then
		self._fading_debug_output:show()
	else
		self._fading_debug_output:hide()
	end
end

-- Adds a text to the fading debug output. Mainly used as placeholder for events from the debug element.
function MissionManager:add_fading_debug_output( debug, color, as_subtitle )
	if not Application:production_build() then
		return
	end
	if not self._fading_debug_enabled then
		return
	end
	
	if as_subtitle then
		self:_show_debug_subtitle( debug, color )
	else
		local stuff = { " -", " \\", " |", " /" }
		self._fade_index = ( self._fade_index or 0 ) + 1
		self._fade_index = ( self._fade_index > #stuff ) and ( self._fade_index and 1 ) or self._fade_index
		self._fading_debug_output:script().log( stuff[ self._fade_index ] .. " " .. debug, color, nil )
	end
end

function MissionManager:_show_debug_subtitle( debug, color )
	self._debug_subtitle_text = self._debug_subtitle_text or self._workspace:panel():text( { font="core/fonts/diesel", font_size=24, text=debug, word_wrap=true, wrap=true, align="center", halign="center", valign="center", color=color or Color.white } )
	self._debug_subtitle_text:set_size( self._workspace:panel():w() / 2, 24 )
	self._debug_subtitle_text:set_text( debug )
	local subtitle_time = math.max( 4, utf8.len( debug ) * 0.04 )
	local _, _, w, h = self._debug_subtitle_text:text_rect()
	self._debug_subtitle_text:set_size( w, h )
	self._debug_subtitle_text:set_center_x( self._workspace:panel():w() / 2 )	self._debug_subtitle_text:set_bottom( self._workspace:panel():h() / 1.4 )
	self._debug_subtitle_text:set_color( color or Color.white )
	self._debug_subtitle_text:set_alpha( 1 )
	self._debug_subtitle_text:stop()
	self._debug_subtitle_text:animate( function( o ) _G.wait( subtitle_time ) self._debug_subtitle_text:set_alpha( 0 ) end )
end

function MissionManager:get_element_by_id( id )
	for name,script in pairs( self._scripts ) do
		if script:element( id ) then
			return script:element( id )
		end
	end
end

-------------------------------------------------------------------

-- Add a global event listener, the events should preferably by from the global event list 
function MissionManager:add_global_event_listener( key, events, clbk )
	self._global_event_listener:add( key, events, clbk )
end

-- Remove a global event listener
function MissionManager:remove_global_event_listener( key )
	self._global_event_listener:remove( key )
end

-- Called from whoever wants to perform a global event
function MissionManager:call_global_event( event, ... )
	self._global_event_listener:call( event, ... )
end

-- Should be set from the project (Mission manager inheritance for example
function MissionManager:set_global_event_list( list )
	self._global_event_list = list
end

-- Returns the project event list
function MissionManager:get_global_event_list()
	return self._global_event_list
end

-------------------------------------------------------------------

function MissionManager:save( data )
	local state = {}
	for _,script in pairs( self._scripts ) do
		script:save( state )
	end
	data.MissionManager = state
end

function MissionManager:load( data )
	local state = data.MissionManager
	for _,script in pairs( self._scripts ) do
		script:load( state )
	end
end

function MissionManager:pre_destroy()
	for _,script in pairs( self._scripts ) do
		script:pre_destroy()
	end
end

function MissionManager:destroy()
	for _,script in pairs( self._scripts ) do
		script:destroy()
	end
end

------------------------------------------------------------------------------------------

MissionScript = MissionScript or CoreClass.class( CoreEvent.CallbackHandler )

function MissionScript:init( data )
	MissionScript.super.init( self )

	self._elements 				= {}
	self._element_groups 		= {}
	
	self._name 					= data.name
	self._activate_on_parsed 	= data.activate_on_parsed
	
	CoreDebug.cat_debug( "gaspode", "New MissionScript:", self._name )
	
	for _,element in ipairs( data.elements ) do
		local class = element.class
		local new_element = self:_element_class( element.module, class ):new( self, element )
		self._elements[ element.id ] = new_element
		
		self._element_groups[ class ] = self._element_groups[ class ] or {}
		table.insert( self._element_groups[ class ], new_element )
	end
	
	self._updators = {}
	self._save_states = {}
	
	self:_on_created()
end

-- Returns if the mission should be activated on parsed/loaded
function MissionScript:activate_on_parsed()
	return self._activate_on_parsed
end

-- Goes through all mission elements and calls on created. This can be used if an element needs to access another
-- before it is actually executed.
function MissionScript:_on_created()
	for _,element in pairs( self._elements ) do
		element:on_created()
	end
end

-- First check if the class i global
-- Secondly check if it is located in a module
-- Thirdly return the base class CoreMissionScriptElement.MissionScriptElement
function MissionScript:_element_class( module_name, class_name )
	local element_class = rawget( _G, class_name )-- or rawget( module_name, class_name )
	if not element_class and module_name and module_name~= "none" then
		element_class = core:import( module_name )[ class_name ]
	end
	if not element_class then
		element_class = CoreMissionScriptElement.MissionScriptElement
		Application:error( "[MissionScript]SCRIPT ERROR: Didn't find class", class_name, module_name )
	end
	
	return element_class
end

function MissionScript:activate( ... )
	managers.mission:add_persistent_debug_output( "" )
	managers.mission:add_persistent_debug_output( "Activate mission "..self._name, Color( 1, 0, 1, 0 ) )
	for _,element in pairs( self._elements ) do
		element:on_script_activated()
	end
	for _,element in pairs( self._elements ) do
		if element:value( "execute_on_startup" ) then
			element:on_executed( ... )
		end
	end
end

function MissionScript:add_updator( id, updator )
	self._updators[ id ] = updator	
end

function MissionScript:remove_updator( id )
	self._updators[ id ] = nil
end

-- The update function, will update the inherited callback handler
function MissionScript:update( t, dt )
	MissionScript.super.update( self, dt )
	for _,updator in pairs( self._updators ) do
		updator( t, dt )
	end
end

-- Returns the name of this mission
function MissionScript:name()
	return self._name
end

-- Returns the table containing all element groups
function MissionScript:element_groups()
	return self._element_groups
end

-- Returns a table containing all elements based on class name
function MissionScript:element_group( name )
	return self._element_groups[ name ]
end

-- Returns all the elements in the mission
function MissionScript:elements()
	return self._elements
end

-- Returns an element in the mission
function MissionScript:element( id )
	return self._elements[ id ]
end

-- Function to output debug info, could be to console or to a onscreen gui
function MissionScript:debug_output( debug, color )
	managers.mission:add_persistent_debug_output( Application:date( "%X" ) .. ": " .. debug, color )
	CoreDebug.cat_print( "editor", debug )
end

-- Returns if we are running in debug or not (returns true for now)
function MissionScript:is_debug()
	return true
end

-- Can be called from en mission element to let know that it has something to save
function MissionScript:add_save_state_cb( id )
	self._save_states[ id ] = true
end

-- Can be called from en mission element to let know that it no longer has anything to save
function MissionScript:remove_save_state_cb( id )
	self._save_states[ id ] = nil
end

-- Saves all registered mission element
function MissionScript:save( data )
	local state = {}
	
	for id,_ in pairs( self._save_states ) do
		state[ id ] = {}
		self._elements[ id ]:save( state[ id ] )
	end
	
	--[[data[ self._name ] = state
	state.core_save = {}
	state.save_state = {}]]
	
	--[[for id,element in pairs( self._elements ) do
		state.core_save[ id ] = {}
		element:core_save( state.core_save[ id ] )
	end]]
	
	--[[for id,_ in pairs( self._save_states ) do
		state.save_state[ id ] = {}
		self._elements[ id ]:save( state.save_state[ id ] )
	end
	]]
	
	data[ self._name ] = state
end

-- Loads all registered mission elements
function MissionScript:load( data )
	local state = data[ self._name ]
	
	for id,mission_state in pairs( state ) do
		self._elements[ id ]:load( mission_state )
	end
	
	--[[local core_save = state.core_save
	local save_state = state.save_state]]
	
	--[[for id,core_state in pairs( core_save ) do
		self._elements[ id ]:core_load( core_state )
	end]]
	
	--[[for id,mission_state in pairs( save_state ) do
		self._elements[ id ]:load( mission_state )
	end]]
end

-- Called when the simulation is stopped
function MissionScript:stop_simulation( ... )
	for _,element in pairs( self._elements ) do
		element:stop_simulation( ... )
	end
	MissionScript.super.clear( self )
end

-- Should be called in a early when stoping a game (for example when stopping the network in Stonecold) 
function MissionScript:pre_destroy( ... )
	for _,element in pairs( self._elements ) do
		element:pre_destroy( ... )
	end
	MissionScript.super.clear( self )
end

-- Called when leaving a game
function MissionScript:destroy( ... )
	for _,element in pairs( self._elements ) do
		element:destroy( ... )
	end
	MissionScript.super.clear( self )
end

------------------------------------------------------------------------------------------
