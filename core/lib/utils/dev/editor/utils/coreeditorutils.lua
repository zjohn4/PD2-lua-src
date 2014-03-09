core:module( "CoreEditorUtils" )

core:import( "CoreEngineAccess" )
core:import( "CoreClass" )

-- Returns a table with all unit lights
function all_lights()
	local lights = {}
	local all_units = World:find_units_quick( "all" )
	for _,unit in ipairs( all_units ) do
		for _,light in ipairs( unit:get_objects_by_type( Idstring( "light" ) ) ) do
			table.insert( lights, light )
		end
	end	
	return lights
end

function get_editable_lights( unit )
	local lights = {}
	local object_file = CoreEngineAccess._editor_unit_data( unit:name():id() ):model()
	local node = DB:has( "object", object_file ) and DB:load_node("object", object_file )
	
	if node then
		for child in node:children() do
			if child:name() == "lights" then
				for light in child:children() do
					if light:has_parameter( "editable" ) then
						if light:parameter( "editable" ) == "true" then
							table.insert( lights, unit:get_object( Idstring( light:parameter( "name" ) ) ) )
						end
					end
				end
			end
		end
	end
	
	return lights
end

function has_projection_light( unit )
	-- local lights = {}
	local object_file = CoreEngineAccess._editor_unit_data( unit:name():id() ):model()
	local node = DB:has( "object", object_file ) and DB:load_node("object", object_file )
	
	if node then
		for child in node:children() do
			if child:name() == "lights" then
				for light in child:children() do
					if light:has_parameter( "projection" ) then
						if light:parameter( "projection" ) == "true" then
							-- return true
							return light:parameter( "name" )
							-- table.insert( lights, unit:get_object( Idstring( light:parameter( "name" ) ) ) )
						end
					end
				end
			end
		end
	end
	return nil
	-- return lights
end

-- Checks if the light is of type projection
function is_projection_light( unit, light )
	local object_file = CoreEngineAccess._editor_unit_data( unit:name():id() ):model()
	local node = DB:has( "object", object_file ) and DB:load_node("object", object_file )
	
	if node then
		for child in node:children() do
			if child:name() == "lights" then
				for light_node in child:children() do
					if light_node:has_parameter( "projection" ) then
						if light_node:parameter( "projection" ) == "true" then
							if light:name() == Idstring( light_node:parameter( "name" ) ) then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

function intensity_value()
	local t = {}
	for _,intensity in ipairs( LightIntensityDB:list() ) do
		table.insert( t, LightIntensityDB:lookup( intensity ) )
	end
	table.sort( t )
	return t
end

INTENSITY_VALUES = intensity_value()

-- Returns closest preset based on any multiplier value
function get_intensity_preset( multiplier )
	local intensity = LightIntensityDB:reverse_lookup( multiplier )
	
	if intensity:s() ~= "undefined" then 						-- A direct hit
		return intensity
	end
	
	local intensity_values = INTENSITY_VALUES
	for i = 1, #intensity_values do 							-- Go through all preset values to find a close match
		local next = intensity_values[ i + 1 ]
		local this = intensity_values[ i ]
		if not next then 										-- This is the last preset value
			return LightIntensityDB:reverse_lookup( this )
		end
		
		if this < multiplier and next > multiplier then 		-- Multiplier is somewhere between this and next preset value
			if multiplier - this < next - multiplier then 		-- Multiplier is closer to this then next preset value
				return LightIntensityDB:reverse_lookup( this )
			else 												-- Multiplier was closer to next then this preset value
				return LightIntensityDB:reverse_lookup( next )
			end
		elseif this > multiplier then 							-- Multiplier is smaller then the lowest preset value
			return LightIntensityDB:reverse_lookup( this )
		end
	end
	
end

function get_sequence_files_by_unit( unit, sequence_files )
	_get_sequence_file( CoreEngineAccess._editor_unit_data( unit:name() ), sequence_files )
end

function get_sequence_files_by_unit_name( unit_name, sequence_files )
	_get_sequence_file( CoreEngineAccess._editor_unit_data( unit_name ), sequence_files )
end

function _get_sequence_file( unit_data, sequence_files )
	for _,unit_name in ipairs( unit_data:unit_dependencies() ) do
		_get_sequence_file( CoreEngineAccess._editor_unit_data( unit_name ), sequence_files )
	end
	table.insert( sequence_files, unit_data:sequence_manager_filename() )
end

GrabInfo = GrabInfo or CoreClass.class()

function GrabInfo:init( o )
	self._pos = o:position()
	self._rot = o:rotation()
end

function GrabInfo:rotation()
	return self._rot
end
function GrabInfo:position()
	return self._pos
end

layer_types = layer_types or {}
function parse_layer_types()
	assert(DB:has('xml', "core/settings/editor_types"), "Editor type settings are missing from core settings.")
	
	local node = DB:load_node("xml", "core/settings/editor_types")
	for layer in node:children() do
		layer_types[ layer:name() ] = {}
		for type in layer:children() do
			table.insert( layer_types[ layer:name() ], type:parameter( "value" ) )
		end
	end 
	
	if DB:has('xml', "settings/editor_types") then 
		local node = DB:load_node("xml", "settings/editor_types")
		for layer in node:children() do
			layer_types[ layer:name() ] = {}
			for type in layer:children() do
				table.insert( layer_types[ layer:name() ], type:parameter( "value" ) )
			end
		end 
	end
end

function layer_type( layer )
	return layer_types[ layer ]
end

function get_layer_types()
	return layer_types
end

-- A global function introduced to use as callback function for check tools in toolbars to toggle a bool value.
-- data is a table and contains
-- class (required)					- the class where the value is
-- toolbar (required)(as string)	- the toolbar containing the check tool
-- value (required)(as string		- the value in the class to set
-- menu (optional)					- if there is a corresponding setting in the menu it to can be changed
function toolbar_toggle( data, event )
	local c = data.class
	local toolbar = c[ data.toolbar ]
	c[ data.value ] = toolbar:tool_state( event:get_id() )
	if c[ data.menu ] then
		c[ data.menu ]:set_checked( event:get_id(), c[ data.value ] )
	end
end

-- Ann event called by a shortkey to affect a value and set a check tool state in the toolbar and set a menu check item's checked state.
-- The id of the item and tool must be the same
-- data is a table and contains
-- class (required)					- the class where the value is
-- toolbar (required)(as string)	- the toolbar containing the check tool
-- value (required)(as string		- the value in the class to set
-- id (required)(as string)
-- menu (optional)					- if there is a corresponding setting in the menu it to can be changed

function toolbar_toggle_trg( data )
	local c = data.class
	local toolbar = c[ data.toolbar ]
	toolbar:set_tool_state( data.id, not toolbar:tool_state( data.id ) )
	c[ data.value ] = toolbar:tool_state( data.id )
	if c[ data.menu ] then
		c[ data.menu ]:set_checked( data.id, c[ data.value ] )
	end
end

----------------------
-- Dump mesh functions
----------------------

function dump_mesh( units, name, get_objects_string )
	name = name or "dump_mesh"
	get_objects_string = get_objects_string or "g_*"
	units = units or World:find_units_quick( "all", managers.slot:get_mask( "dump_mesh" ) )
	local objects = {}
	local lods = { 'e', '_e', 'd', '_d', 'c', '_c', 'b', '_b', 'a', '_a' }
	cat_print( "editor", 'Starting dump mesh' )
	cat_print( "editor", '  Dumping from '..#units..' units' )
	for _,u in ipairs(units) do
		-- if string.match( u:name(), 'ground' ) or string.match( u:name(), 'build' ) then
			local i = 1
			local objs = {}
			--[[local all_objs = u:get_objects( 'g_*' )
			local found = false
			while i <= #lods and not found do
				local s = lods[ i ]
				for _,o in ipairs( all_objs ) do
						if string.match( o:name(), 'lod'..s ) then
							cat_print( "editor", 'insert obj', o:name() )
							table.insert( objs, o )
							cat_print( "editor", 'found' )
							found = true
						end
				end
				
				--cat_print( "editor", 'check for', 'lod'..s..'. Found '..#objs )
				--if #objs > 0 then
				--	cat_print( "editor", 'objects', #objs )
				--	cat_print( "editor", 'break' )
				--	break
				--end
				
				i = i + 1
			end]]
			if #objs == 0 then
				cat_print( "editor", 'getting gfx instead of lod for unit '..u:name():s() )
				objs = u:get_objects( get_objects_string )
			end
			cat_print( "editor", 'insert objs', #objs )
			for _,o in ipairs(objs) do 
				cat_print( "editor", '    '..o:name():s() )
				table.insert(objects,o) 
			end 
			objs = u:get_objects( "gfx_*" )
			cat_print( "editor", 'insert objs', #objs )
			for _,o in ipairs(objs) do 
				cat_print( "editor", '    '..o:name():s() )
				table.insert(objects,o) 
			end 
--			table.insert( objects,u:orientation_object() ) 
		-- end
	end
	cat_print( "editor", '  Dumped '..#objects..' objects' )
	MeshDumper:dump_meshes( managers.database:root_path()..name, objects, Rotation(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))) -- transform to MB coordinates
end

-- Dumps all units in slotmask dump_all in a level to file
function dump_all( units, name, get_objects_string )
	name = name or "all_dumped"
	get_objects_string = get_objects_string or "g_*"
	units = units or World:find_units_quick( "all", managers.slot:get_mask( "dump_all" ) )
	local objects = {}
	cat_print( "editor", 'Starting dump mesh' )
	cat_print( "editor", '  Dumping from '..#units..' units' )
	for _,u in ipairs(units) do
			
		local objs = {}
		local all_objs = u:get_objects( 'g_*' )
		
		-- Find a lod object
		for i = 5, 0, -1 do
			for _,o in ipairs( all_objs ) do
				if string.match( o:name():s(), 'lod'..i ) then
					cat_print( "editor", 'insert obj', o:name():s() )
					table.insert( objs, o )
					break
				end
			end
			if #objs > 0 then
				cat_print( "editor", 'enough lods, time to break' )
				break
			end
		end

		-- If no lod objects found, use graphic objects named g_* or gfx_*
		if #objs == 0 then
			cat_print( "editor", 'getting gfx instead of lod for unit '..u:name():s() )
			objs = u:get_objects( get_objects_string )
			if #objs == 0 then
				objs = u:get_objects( "gfx_*" )
			end
		end
		
		-- Insert the found objects
		cat_print( "editor", 'insert objs', #objs, 'from unit', u:name():s() )
		for _,o in ipairs(objs) do 
			cat_print( "editor", '    '..o:name():s() )
			table.insert( objects,o ) 
		end 
			
	end
	cat_print( "editor", '  Starting dump of '..#objects..' objects...' )
	MeshDumper:dump_meshes( managers.database:root_path()..name, objects, Rotation(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))) -- transform to MB coordinates
	cat_print( "editor", '  .. dumping done.' )
end