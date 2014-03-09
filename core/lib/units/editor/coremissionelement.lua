CoreMissionElement = CoreMissionElement or class()

-- This is the prepared class for a project heritance
-- This is what all hubelements must inherit.
MissionElement = MissionElement or class( CoreMissionElement )
MissionElement.SAVE_UNIT_POSITION = true
MissionElement.SAVE_UNIT_ROTATION = true

function MissionElement:init( ... )
	CoreMissionElement.init( self, ... )
end

-- Save values table contains what data should be saved for world and mission. It is
-- specified in the inheritance
function CoreMissionElement:init( unit )
	if not CoreMissionElement.editor_link_brush then -- Only create one brush
		local brush = Draw:brush()
		brush:set_font( Idstring("core/fonts/nice_editor_font"), 10 )
		brush:set_render_template( Idstring("OverlayVertexColorTextured") )
			
		CoreMissionElement.editor_link_brush = brush
	end

	self._unit = unit 							-- Init recieves the unit and saves it
	self._hed = self._unit:mission_element_data() 	-- the hubelement data extension is set in a variable
	self._ud = self._unit:unit_data() 			-- the unitdata extension is set in a variable
	self._unit:anim_play( 1 ) 					-- start playing animation if it has any
	self._save_values = {} 						-- create the save values table
	
	self._update_selected_on = false			-- Specifies if the update_selected function should be called even when not selected
	
	self:_add_default_saves()
	
	if self.USES_POINT_ORIENTATION then
		self.base_update_editing = callback( self, self, "__update_editing" )
	end
	
	-- Get the panel and sizer from editor hub element layer that the unit can use for its own gui
	self._parent_panel = managers.editor:mission_element_panel()
	self._parent_sizer = managers.editor:mission_element_sizer()
		
	-- Contains gui panels belonging to different parents
	self._panels = {}
	
	self._on_executed_units = {}
		
	self._arrow_brush = Draw:brush()
	
	self:_createicon()	-- Create the icon for this huelement
end

function CoreMissionElement:post_init()
end

-- Values that can be set from unit xml
-- _icon = The icon to use, a string with a single character. Ex "G"
-- _icon_x, _icon_y, _icon_w, _icon_h, specifies a texture rect to use instead of character
-- _iconcolor = Color of icon, if not set it will be white. Ex "ff0" for yellow.
function CoreMissionElement:_createicon()
	local iconsize = 32
	if Global.iconsize then 
		iconsize = Global.iconsize
	end

	if self._icon == nil and self._icon_x == nil then
		return
	end

	local root = self._unit:orientation_object() -- get_object( Idstring( "c_hub_element_sphere" ) )
	if root == nil then
		-- Show error that unit is missing a icon object. 
		return
	end

	if self._iconcolor_type then
		if self._iconcolor_type == "trigger" then
			-- self._iconcolor = "ffbbdbff"
			self._iconcolor = "ff81bffc"
			-- self._iconcolor = "bbffbb"
		elseif self._iconcolor_type == "logic" then
			self._iconcolor = "ffffffd9"
		elseif self._iconcolor_type == "operator" then
			self._iconcolor = "fffcbc7c"
		elseif self._iconcolor_type == "filter" then
			self._iconcolor = "ff65ad67"
		end
	end
	
	if self._iconcolor == nil then
		self._iconcolor = "fff"
	end
	
	self._iconcolor_c = Color( self._iconcolor )
	
	self._icon_gui = World:newgui()

	--self._icon_ws = self._icon_gui:create_object_workspace(64, 64, root)
	local pos = self._unit:position() - Vector3(iconsize / 2, iconsize / 2,0)
	self._icon_ws = self._icon_gui:create_linked_workspace(64, 64, root, pos,Vector3(iconsize,0,0),Vector3(0,iconsize,0))
	self._icon_ws:set_billboard(self._icon_ws.BILLBOARD_BOTH)

	self._icon_ws:panel():gui( Idstring( "core/guis/core_edit_icon" ) )
	self._icon_script = self._icon_ws:panel():gui( Idstring( "core/guis/core_edit_icon" ) ):script()
	if self._icon then
		self._icon_script:seticon( self._icon, tostring(self._iconcolor) )
	elseif self._icon_x then
		self._icon_script:seticon_texture_rect( self._icon_x, self._icon_y, self._icon_w, self._icon_h, tostring(self._iconcolor) )
	end
	-- self._icon_script:seticon_texture_rect()
end

function CoreMissionElement:set_iconsize( size )
	if not self._icon_ws then
		return
	end
	local root = self._unit:orientation_object()
	local pos = self._unit:position() - Vector3( size/2, size/2,0)
	self._icon_ws:set_linked( 64, 64, root, pos, Vector3(size,0,0), Vector3(0,size,0) )
end

-- This is test for new mission script
function CoreMissionElement:_add_default_saves()
	self._hed.enabled = true
	self._hed.debug = nil
	self._hed.execute_on_startup = false
	self._hed.execute_on_restart = nil
	self._hed.base_delay = 0
	self._hed.trigger_times = 0
	self._hed.on_executed = {}
	
	if self.USES_POINT_ORIENTATION then
		self._hed.orientation_elements = nil
		self._hed.use_orientation_sequenced = nil
		self._hed.disable_orientation_on_use = nil
	end
	
	if self.USES_INSTIGATOR_RULES then
		self._hed.rules_elements = nil
	end
	
	table.insert( self._save_values, "unit:position" )
	table.insert( self._save_values, "unit:rotation" )
	table.insert( self._save_values, "enabled" )
	-- table.insert( self._save_values, "debug" )
	table.insert( self._save_values, "execute_on_startup" )
	-- table.insert( self._save_values, "execute_on_restart" )
	table.insert( self._save_values, "base_delay" )
	table.insert( self._save_values, "trigger_times" )
	table.insert( self._save_values, "on_executed" )
	table.insert( self._save_values, "orientation_elements" )
	table.insert( self._save_values, "use_orientation_sequenced" )
	table.insert( self._save_values, "disable_orientation_on_use" )
	table.insert( self._save_values, "rules_elements" )
end

function CoreMissionElement:build_default_gui( panel, sizer )
	local enabled = EWS:CheckBox( panel, "Enabled", "" )
		enabled:set_value( self._hed.enabled )
		enabled:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = enabled, value = "enabled" } )
	sizer:add( enabled, 0, 0, "EXPAND" )
	
	--[[local debug = EWS:CheckBox( panel, "Debug", "" )
		debug:set_value( self._hed.debug )
		debug:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = debug, value = "debug" } )
	sizer:add( debug, 0, 0, "EXPAND" )]]
	
	local execute_on_startup = EWS:CheckBox( panel, "Execute on startup", "" )
		execute_on_startup:set_value( self._hed.execute_on_startup )
		execute_on_startup:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = execute_on_startup, value = "execute_on_startup" } )
	sizer:add( execute_on_startup, 0, 0, "EXPAND" )
	
	--[[local execute_on_restart = EWS:CheckBox( panel, "Execute on restart", "" )
		execute_on_restart:set_value( self._hed.execute_on_restart )
		execute_on_restart:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = execute_on_restart, value = "execute_on_restart" } )
	sizer:add( execute_on_restart, 0, 0, "EXPAND" )]]
	
	-- Trigger Times
	local trigger_times_params = {
		name 				= "Trigger times:",
		panel 				= panel,
		sizer 				= sizer,
		value 				= self._hed.trigger_times,
		floats 				= 0,
		tooltip 			= "Specifies how many time this element can be executed (0 mean unlimited times)",
		min 				= 0,
		name_proportions 	= 1,
		ctrlr_proportions 	= 2
	}
	local trigger_times = CoreEWS.number_controller( trigger_times_params )
	
	trigger_times:connect( "EVT_COMMAND_TEXT_ENTER", callback( self, self, "set_element_data" ), { ctrlr = trigger_times, value = "trigger_times" } )
	trigger_times:connect( "EVT_KILL_FOCUS", callback( self, self, "set_element_data" ), { ctrlr = trigger_times, value = "trigger_times" } )
	
	-- End Delay
	local base_delay_params = {
		name 				= "Base Delay:",
		panel 				= panel,
		sizer 				= sizer,
		value 				= self._hed.base_delay,
		floats 				= 2,
		tooltip 			= "Specifies a base delay that is added to each on executed delay",
		min 				= 0,
		name_proportions 	= 1,
		ctrlr_proportions 	= 2
	}
	local base_delay = CoreEWS.number_controller( base_delay_params )
	
	base_delay:connect( "EVT_COMMAND_TEXT_ENTER", callback( self, self, "set_element_data" ), { ctrlr = base_delay, value = "base_delay" } )
	base_delay:connect( "EVT_KILL_FOCUS", callback( self, self, "set_element_data" ), { ctrlr = base_delay, value = "base_delay" } )
		
	local on_executed_sizer = EWS:StaticBoxSizer( panel, "VERTICAL", "On Executed")
			
		local element_sizer = EWS:BoxSizer( "HORIZONTAL" )
		on_executed_sizer:add( element_sizer, 0, 1, "EXPAND,LEFT" )
			
		-- Elements
		self._elements_params = {
			name 				= "Element:",
			panel 				= panel,
			sizer 				= element_sizer,
			options				= {},
			value 				= nil,
			tooltip 			= "Select an element from the combobox",
			name_proportions 	= 1,
			ctrlr_proportions 	= 2,
			sizer_proportions	= 1,
			sorted				= true
		}
		local elements = CoreEWS.combobox( self._elements_params )
				
		elements:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "on_executed_element_selected" ), nil )
		
		self._add_elements_toolbar = EWS:ToolBar( panel, "", "TB_FLAT,TB_NODIVIDER" )
			self._add_elements_toolbar:add_tool( "ADD_ELEMENT", "Add an element", CoreEws.image_path( "world_editor\\unit_by_name_list.png" ), nil )
			self._add_elements_toolbar:connect( "ADD_ELEMENT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "_on_toolbar_add_element" ), nil )
			self._add_elements_toolbar:realize()
		element_sizer:add( self._add_elements_toolbar, 0, 1, "EXPAND,LEFT" )
		
		self._elements_toolbar = EWS:ToolBar( panel, "", "TB_FLAT,TB_NODIVIDER" )
			self._elements_toolbar:add_tool( "DELETE_SELECTED", "Remove selected element", CoreEws.image_path( "toolbar\\delete_16x16.png" ), nil )
			self._elements_toolbar:connect( "DELETE_SELECTED", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "_on_toolbar_remove" ), nil )
			self._elements_toolbar:realize()
		element_sizer:add( self._elements_toolbar, 0, 1, "EXPAND,LEFT" )
		
		if self.ON_EXECUTED_ALTERNATIVES then
			local on_executed_alternatives_params = {
				name							= "Alternative:",
				panel							= panel,
				sizer							= on_executed_sizer,
				options						= self.ON_EXECUTED_ALTERNATIVES,
				value							= self.ON_EXECUTED_ALTERNATIVES[1],
				tooltip						= "Select am alternative on executed from the combobox",
				name_proportions	=	1,
				ctrlr_proportions	= 2,
				sorted						= false
			}
			local on_executed_alternatives_types = CoreEWS.combobox( on_executed_alternatives_params )
			on_executed_alternatives_types:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "on_executed_alternatives_types" ), nil )
			
			self._on_executed_alternatives_params = on_executed_alternatives_params
		end
		
		-- Delay Time
		self._element_delay_params = {
			name 				= "Delay:",
			panel 				= panel,
			sizer 				= on_executed_sizer,
			value 				= 0,
			floats 				= 2,
			tooltip 			= "Sets the delay time for the selected on executed element",
			min 				= 0,
			name_proportions 	= 1,
			ctrlr_proportions 	= 2
		}
		local element_delay = CoreEWS.number_controller( self._element_delay_params )
		
		element_delay:connect( "EVT_COMMAND_TEXT_ENTER", callback( self, self, "on_executed_element_delay" ), nil )
		element_delay:connect( "EVT_KILL_FOCUS", callback( self, self, "on_executed_element_delay" ), nil )
			
	sizer:add( on_executed_sizer, 0, 0, "EXPAND" )
	
	if self.USES_POINT_ORIENTATION then
		sizer:add( self:_build_point_orientation( panel ), 0, 0, "EXPAND" )
	end
	
	sizer:add( EWS:StaticLine( panel, "", "LI_HORIZONTAL" ), 0, 5, "EXPAND,TOP,BOTTOM" )
	
	self:append_elements_sorted()
	self:set_on_executed_element()
end

function CoreMissionElement:_build_point_orientation( panel )
	local sizer = EWS:StaticBoxSizer( panel, "HORIZONTAL", "Point orientation" )
	
	local toolbar = EWS:ToolBar( panel, "", "TB_FLAT,TB_NODIVIDER" )
	toolbar:add_tool( "ADD_ELEMENT", "Add an element", CoreEws.image_path( "world_editor\\unit_by_name_list.png" ), nil )
	toolbar:connect( "ADD_ELEMENT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "_add_unit_to_orientation_elements" ), nil )
	
	toolbar:add_tool( "DELETE_ELEMENT", "Remove selected element", CoreEws.image_path( "toolbar\\delete_16x16.png" ), nil )
	toolbar:connect( "DELETE_ELEMENT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "_remove_unit_from_orientation_elements" ), nil )
	
	toolbar:realize()
	
	sizer:add( toolbar, 0, 1, "EXPAND,LEFT" )
	
	local use_orientation_sequenced = EWS:CheckBox( panel, "Use sequenced", "" )
	use_orientation_sequenced:set_value( self._hed.use_orientation_sequenced )
	use_orientation_sequenced:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = use_orientation_sequenced, value = "use_orientation_sequenced" } )
	sizer:add( use_orientation_sequenced, 0, 4, "EXPAND,LEFT" )
	
	local disable_orientation_on_use = EWS:CheckBox( panel, "Disable on use", "" )
	disable_orientation_on_use:set_value( self._hed.disable_orientation_on_use )
	disable_orientation_on_use:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_element_data" ), { ctrlr = disable_orientation_on_use, value = "disable_orientation_on_use" } )
	sizer:add( disable_orientation_on_use, 0, 4, "EXPAND,LEFT" )
	
	return sizer
end

function CoreMissionElement:_add_unit_to_orientation_elements()
	local script = self._unit:mission_element_data().script
	local f = function( unit )
		if not string.find( unit:name():s(), "point_orientation", 1, true ) then
			return 
		end
		if not unit:mission_element_data() or unit:mission_element_data().script ~= script then
			return 
		end
		local id = unit:unit_data().unit_id
		if self._hed.orientation_elements and table.contains( self._hed.orientation_elements, id ) then
			return false
		end
		return managers.editor:layer( "Mission" ):category_map()[ unit:type():s() ]
	end
	
	local dialog = SelectUnitByNameModal:new( "Add Unit", f ) 
	for _, unit in ipairs( dialog:selected_units() ) do
		self:_add_orientation_unit_id( unit:unit_data().unit_id )
	end
end

function CoreMissionElement:_remove_unit_from_orientation_elements()
	if not self._hed.orientation_elements then
		return
	end
	local f = function( unit ) return table.contains( self._hed.orientation_elements, unit:unit_data().unit_id ) end
	local dialog = SelectUnitByNameModal:new( "Remove Unit", f )
	if dialog:cancelled() then return end
	for _, unit in ipairs( dialog:selected_units() ) do
		self:_remove_orientation_unit_id( unit:unit_data().unit_id )
	end
end


-- Should be called first in _build_panel. It creates a standard panel which extra data to be able to know if its alive or not.
function CoreMissionElement:_create_panel()
	if self._panel then
		return
	end
	self._panel, self._panel_sizer = self:_add_panel( self._parent_panel, self._parent_sizer )
	--[[
	self._panel = EWS:Panel( self._parent_panel, "", "TAB_TRAVERSAL" )
	self._panel_sizer = EWS:BoxSizer("VERTICAL")
	self._panel:set_sizer( self._panel_sizer )
	
		self._panel_sizer:add( EWS:StaticText( self._panel, managers.editor:category_name( self._unit:name() ), 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL" )
		self._panel_sizer:add( EWS:StaticLine( self._panel, "", "LI_HORIZONTAL" ), 0, 0, "EXPAND" )
		
	self._parent_sizer:add( self._panel, 1, 0, "EXPAND")
	self._panel:set_visible( false )
	self._panel:set_extension( { alive = true } )
	]]
end

-- Inherit this function and build the gui. First thing is do call _create_panel to create the panel with standard settings, which
-- is needed to be able to check if the panel is alive or not. Can't call _build_panel at init since loaded hub elements will not be
-- able to set their saved data to the gui at that time.
function CoreMissionElement:_build_panel()
	self:_create_panel()
--	self._panel = nil
end

-- Returns the panel, will try to build the panel if there isn't one. The _panel object will still be nil if _build_panel isn't inherited
-- Can't call _build_panel at init since loaded hub elements will not be able to set their saved data to the gui at that time.
function CoreMissionElement:panel( id, parent, parent_sizer )
	if id then
		if self._panels[ id ] then
			return self._panels[ id ]
		end
		local panel, panel_sizer = self:_add_panel( parent, parent_sizer )
		self:_build_panel( panel, panel_sizer )
		self._panels[ id ] = panel
		return self._panels[ id ]
	end
	if not self._panel then
		self:_build_panel()
	end
	return self._panel
end

function CoreMissionElement:_add_panel( parent, parent_sizer )
	local panel = EWS:Panel( parent, "", "TAB_TRAVERSAL" )
	local panel_sizer = EWS:BoxSizer("VERTICAL")
	panel:set_sizer( panel_sizer )
	
	-- 	panel_sizer:add( EWS:StaticText( panel, managers.editor:category_name( self._unit:name() ), 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL" )
		panel_sizer:add( EWS:StaticLine( panel, "", "LI_HORIZONTAL" ), 0, 0, "EXPAND" )
		
	parent_sizer:add( panel, 1, 0, "EXPAND")
	panel:set_visible( false )
	panel:set_extension( { alive = true } )
	
	self:build_default_gui( panel, panel_sizer )
	
	return panel, panel_sizer
end

-- This function can be used to add a help text to a hub element
-- data is a table containing:
-- text		-- help to be displayed
-- panel	-- the parent panel
-- sizer	-- the sizer the controller should be added to
function CoreMissionElement:add_help_text( data )
	if data.panel and data.sizer then
		data.sizer:add( EWS:TextCtrl( data.panel, data.text, 0, "TE_MULTILINE,TE_READONLY,TE_WORDWRAP,TE_CENTRE" ), 0, 5, "EXPAND,TOP,BOTTOM" )
	end
end

-- Shows a list of units and add/removes selected ones
function CoreMissionElement:_on_toolbar_add_element()
	local f = function( unit ) return unit:type() == Idstring( "mission_element" ) and unit ~= self._unit end
	local dialog = SelectUnitByNameModal:new( "Add/Remove element", f )
	for _,unit in ipairs( dialog:selected_units() ) do
		self:add_on_executed( unit )
	end
end

-- Removed current selected on exexuted element
function CoreMissionElement:_on_toolbar_remove()
	self:remove_on_execute( self:_current_element_unit() )
end

-- Is called when a event from a ews ctrlr is made
-- Makes callback for special events or sets the data value from the ctrlr
function CoreMissionElement:set_element_data( data )
	if data.callback then
		local he = self._unit:mission_element()
		he[ data.callback ]( he, data.ctrlr, data.params )
	end
	if data.value then
		self._hed[ data.value ] = data.ctrlr:get_value()
		self._hed[ data.value ] = tonumber( self._hed[ data.value ] ) or self._hed[ data.value ] -- Convert string back to number
		
		
		if EWS:get_key_state("K_CONTROL") then
			local value = data.ctrlr:get_value()
			value = tonumber( self._hed[ data.value ] ) or self._hed[ data.value ]
			
			for _, unit in ipairs( managers.editor:layer( "Mission" ):selected_units() ) do
				if unit ~= self._unit then
					if unit:mission_element_data() then
						unit:mission_element_data()[ data.value ] = value
						unit:mission_element():set_panel_dirty()
					end
				end
			end
		end
	end
end

function CoreMissionElement:set_panel_dirty()
	if not alive( self._panel ) then
		return 
	end
	
	self._panel:destroy()
	self._panel = nil
end

-- Called from the editor layer when a hubelement unit is selected
function CoreMissionElement:selected()
	self:append_elements_sorted() -- Will update the on executed element combox with new names if any unit has changed name id.
end

-- An update function that is called while a hubelement unit is selected
function CoreMissionElement:update_selected()
end

-- An update function that is called while a hubelement unit is not selected
function CoreMissionElement:update_unselected()
end

function CoreMissionElement:can_edit()
	return self.update_editing or self.base_update_editing
end

function CoreMissionElement:begin_editing() 

end

function CoreMissionElement:end_editing() 

end

-- Called after cloning is done to make whatever might be needed. Spawn help units or simular
function CoreMissionElement:clone_data( all_units )
	for _,data in ipairs( self._hed.on_executed ) do
		table.insert( self._on_executed_units, all_units[ data.id ] )
	end
end

-- Hubelements layer uses this function to check if it should enable Edit Element button or not
-- function CoreMissionElement:update_editing() 
-- end

-- Hubelements layer uses this function to check if it should enable Test Element button or not
-- function CoreMissionElement:test_element()
-- end

-- Hubelements layer uses this function to check if it should enable Stop Test Element button or not
-- function CoreMissionElement:stop_test_element()
-- end

-- Called when the entire layer has been loaded
-- For example used by Hub to set up all its units associations
function CoreMissionElement:layer_finished()
	for _,data in ipairs( self._hed.on_executed ) do
		local unit = managers.worlddefinition:get_mission_element_unit( data.id )
		table.insert( self._on_executed_units, unit )
	end
end

-- Saves all the data for a unit. It is done automaticly at its simpliest but can be overridden by the inheritance
-- if you want to handle the data sava/load and use by yourself (normaly not)
function CoreMissionElement:save_data( file, t )
	self:save_values( file, t )
end

-- Saves to world file
function CoreMissionElement:save_values( file, t )
	t = t..'\t'
	file:puts( t..'<values>' )
	for _,name in ipairs( self._save_values ) do
		self:save_value( file, t, name )
	end
	file:puts( t..'</values>' )
end

-- A Save value function that saves values according to a standard format
function CoreMissionElement:save_value( file, t, name )
	t = t..'\t'
	file:puts( save_value_string( self._hed, name, t, self._unit ) )
end

function CoreMissionElement:new_save_values()
	local t = {
				position = self.SAVE_UNIT_POSITION and self._unit:position() or nil,
				rotation = self.SAVE_UNIT_ROTATION and self._unit:rotation() or nil
			}
	for _,value in ipairs( self._save_values ) do
		t[ value ] = self._hed[ value ]
	end
	return t
end

function CoreMissionElement:name()
	return self._unit:name()..self._ud.unit_id
end

-- In this function it is possible to add content to the mission package. Play effect does this.
function CoreMissionElement:add_to_mission_package()
end

-- Get color returns a color value to be used for drawing action arrows in different colors pending on the action type
function CoreMissionElement:get_color( type )
	if type then
		if type == "activate" or type == "enable" then
			return 0, 1, 0
		elseif type == "deactivate" or type == "disable"  then
			return 1, 0, 0
		end
	end
	return 0, 1, 0
end

-- Draws links to/from this element when selected
function CoreMissionElement:draw_links_selected( t, dt, selected_unit )
	local unit = self:_current_element_unit()
	if alive( unit ) then
		local r, g, b = 1, 1, 1
		if self._iconcolor and managers.editor:layer( "Mission" ):use_colored_links() then
			r = self._iconcolor_c.r
			g = self._iconcolor_c.g
			b = self._iconcolor_c.b
		end
		self:_draw_link( { from_unit = self._unit, to_unit = unit,  r = r, g = g, b = b, thick = true } )
	end
end

function CoreMissionElement:_draw_link( params )
	params.draw_flow = managers.editor:layer( "Mission" ):visualize_flow()
	Application:draw_link( params )
end

-- Draws connection to/from this element when not selected
function CoreMissionElement:draw_links_unselected()

end


-- clear is called before a unit is removed. It can then clear out whatever data it needs to.
-- ImperialEnemy for example deletes all its patrol point units
function CoreMissionElement:clear()
end

-- Returns a table with availible action for the hubelement unit.
-- Hub uses this to display it as availible options in the Actions/Types dropdown
function CoreMissionElement:action_types()
	return self._action_types
end

function CoreMissionElement:timeline_color()
	return self._timeline_color
end

-- Called from the layer to add keyboard and mouse triggers to be used when editing an element
function CoreMissionElement:add_triggers( vc )
end


function CoreMissionElement:base_add_triggers( vc )
	if self.USES_POINT_ORIENTATION then
		vc:add_trigger( Idstring( "lmb" ), callback( self, self, "_on_use_point_orientation" ) )
	end
	if self.USES_INSTIGATOR_RULES then
		vc:add_trigger( Idstring( "lmb" ), callback( self, self, "_on_use_instigator_rule" ) )
	end
end


function CoreMissionElement:_on_use_point_orientation()
	local ray = managers.editor:unit_by_raycast( { mask = 10, ray_type = "editor" } )
	
	if ray and ray.unit then
		if string.find( ray.unit:name():s(), "point_orientation", 1, true ) then
			local id = ray.unit:unit_data().unit_id
			if self._hed.orientation_elements and table.contains( self._hed.orientation_elements, id ) then
				self:_remove_orientation_unit_id( id )
			else
				self:_add_orientation_unit_id( id )
			end
		end
	end
end

function CoreMissionElement:_add_orientation_unit_id( id )
	self._hed.orientation_elements = self._hed.orientation_elements or {}
	table.insert( self._hed.orientation_elements, id )
end

function CoreMissionElement:_remove_orientation_unit_id( id )
	table.delete( self._hed.orientation_elements, id )
	self._hed.orientation_elements = #self._hed.orientation_elements > 0 and self._hed.orientation_elements or nil
end


function CoreMissionElement:_on_use_instigator_rule()
	local ray = managers.editor:unit_by_raycast( { mask = 10, ray_type = "editor" } )
	
	if ray and ray.unit then
		if string.find( ray.unit:name():s(), "data_instigator_rule", 1, true ) then
			local id = ray.unit:unit_data().unit_id
			if self._hed.rules_elements and table.contains( self._hed.rules_elements, id ) then
				self:_remove_instigator_rule_unit_id( id )
			else
				self:_add_instigator_rule_unit_id( id )
			end
		end
	end
end

function CoreMissionElement:_add_instigator_rule_unit_id( id )
	self._hed.rules_elements = self._hed.rules_elements or {}
	table.insert( self._hed.rules_elements, id )
end

function CoreMissionElement:_remove_instigator_rule_unit_id( id )
	table.delete( self._hed.rules_elements, id )
	self._hed.rules_elements = #self._hed.rules_elements > 0 and self._hed.rules_elements or nil
end

function CoreMissionElement:__update_editing( _, t, dt, current_pos )


end

-- Removes the added keyboard and mouse triggers
function CoreMissionElement:clear_triggers()
end

-- Possible to return a unit used by the element
function CoreMissionElement:widget_affect_object()
	return nil
end

-- Possible to use the information from the move widget (need to return true if using)
function CoreMissionElement:use_widget_position()
	return nil
end

-- When a hubelement unit is enabled through the layer function set_enabled a call goes to the hubelement as well
-- Here a hubelement can enable units that it has created.
-- Minefield in BC uses this to enable its mine units
function CoreMissionElement:set_enabled()
	if self._icon_ws then
		self._icon_ws:show()
	end
end

-- When a hubelement unit is disabled through the layer function set_disabled a call goes to the hubelement as well
-- Here a hubelement can enable units that it has created.
-- Minefield in BC uses this to disabled its mine units
function CoreMissionElement:set_disabled()
	if self._icon_ws then
		self._icon_ws:hide()
	end
end

-- Makes sure that the gui is hidden when the unit is hidden
function CoreMissionElement:on_set_visible( visible )
	if self._icon_ws then
		if visible then
			self._icon_ws:show()
		else
			self._icon_ws:hide()
		end
	end
end

-- Sets _update_selected_on status
function CoreMissionElement:set_update_selected_on( value )
	self._update_selected_on = value
end

-- Returns _update_selected_on status
function CoreMissionElement:update_selected_on()
	return self._update_selected_on
end

-- Might be dangerous to call if it is not recreated afterwardf
function CoreMissionElement:destroy_panel()
	if self._panel then
		self._panel:extension().alive = false
		self._panel:destroy()
		self._panel = nil 
	end
end

-- As for all extensions destroyed is called when a unit is deletet
function CoreMissionElement:destroy()
	if self._timeline then
		self._timeline:destroy()
	end
	if self._panel then
		self._panel:extension().alive = false
		self._panel:destroy() 
	end
	
	if self._icon_ws then
		self._icon_gui:destroy_workspace( self._icon_ws )
		self._icon_ws = nil
	end
end

-- Draws on executed links. If selected_unit is used, only links from and to that unit will
-- be drawn.
function CoreMissionElement:draw_links( t, dt, selected_unit, all_units )
	self:_base_check_removed_units( all_units )
	self:draw_link_on_executed( t, dt, selected_unit )
	
	self:_draw_elements( t, dt, self._hed.orientation_elements, selected_unit, all_units )
	self:_draw_elements( t, dt, self._hed.rules_elements, selected_unit, all_units )
end

function CoreMissionElement:_base_check_removed_units( all_units )
	if self._hed.orientation_elements then
		for _, id in ipairs( clone( self._hed.orientation_elements ) ) do
			local unit = all_units[ id ]
			if not alive( unit ) then
				self:_remove_orientation_unit_id( id )
			end
		end
	end
	
	if self._hed.rules_elements then
		for _, id in ipairs( clone( self._hed.rules_elements ) ) do
			local unit = all_units[ id ]
			if not alive( unit ) then
				self:_remove_instigator_rule_unit_id( id )
			end
		end
	end
end

function CoreMissionElement:_draw_elements( t, dt, elements, selected_unit, all_units )
	if not elements then
		return 
	end
	
	for _, id in ipairs( elements ) do
			local unit = all_units[ id ]
			
			if self:_should_draw_link( selected_unit, unit ) then
				local r, g, b = unit:mission_element():get_link_color()
				self:_draw_link( { from_unit = unit, to_unit = self._unit, r = r, g = g, b = b } )
			end
	end
end


















function CoreMissionElement:_should_draw_link( selected_unit, unit )
	return not selected_unit or unit == selected_unit or self._unit == selected_unit
end

function CoreMissionElement:get_link_color( unit )
	local r, g, b = 1, 1, 1
	if self._iconcolor and managers.editor:layer( "Mission" ):use_colored_links() then
		r = self._iconcolor_c.r
		g = self._iconcolor_c.g
		b = self._iconcolor_c.b
	end
	return r, g, b
end

function CoreMissionElement:draw_link_on_executed( t, dt, selected_unit )
	local unit_sel = self._unit == selected_unit
	CoreMissionElement.editor_link_brush:set_color( unit_sel and Color.green or Color.white ) -- Color( 1.0, 1, 1, 1 ) )

	for _,unit in ipairs( self._on_executed_units ) do
		if not selected_unit or unit_sel or ( unit == selected_unit ) then
			local dir = mvector3.copy( unit:position() )
			mvector3.subtract( dir, self._unit:position() )
			
			local vec_len = mvector3.normalize( dir )
			local offset = math.min( 50, vec_len )
			mvector3.multiply( dir, offset )
			
			-- self._distance_to_camera is set from mission layer
			if self._distance_to_camera < 1000 * 1000 then
				local text = string.format( "%.2f", self:_get_on_executed( unit:unit_data().unit_id ).delay )
				local alternative = self:_get_on_executed( unit:unit_data().unit_id ).alternative
				if alternative then
					text = text .. " - " .. alternative .. ""
				end
				CoreMissionElement.editor_link_brush:center_text( self._unit:position() + dir, text, managers.editor:camera_rotation():x(), -managers.editor:camera_rotation():z() )
			end

			local r, g, b = self:get_link_color()
			self:_draw_link( { from_unit = self._unit, to_unit = unit,  r = r*0.75, g = g*0.75, b = b*0.75 } )
		end
	end
end

-- Called from the mission layer to add or remove a unit as an on executed element
-- If it is allready added, it will be removed instead.
function CoreMissionElement:add_on_executed( unit )
	if self:remove_on_execute( unit ) then
		return
	end
	
	local params = { id = unit:unit_data().unit_id, delay = 0 }
	params.alternative = self.ON_EXECUTED_ALTERNATIVES and self.ON_EXECUTED_ALTERNATIVES[1] or nil
	table.insert( self._on_executed_units, unit )
	table.insert( self._hed.on_executed, params )
	
	if self._timeline then
		self._timeline:add_element( unit, params )
	end
	
	self:append_elements_sorted()
	self:set_on_executed_element( unit )
end

function CoreMissionElement:remove_links( unit )

end

-- This function is called from either add_on_execute function (to add/remove toggle) or from
-- a deleted unit to check if it is used and therefor should be removed. 
-- Returns true if the unit was removed.
function CoreMissionElement:remove_on_execute( unit )
	for _,on_executed in ipairs( self._hed.on_executed ) do
		if on_executed.id == unit:unit_data().unit_id then
			if self._timeline then
				self._timeline:remove_element( on_executed )
			end
			table.delete( self._hed.on_executed, on_executed )
			table.delete( self._on_executed_units, unit )
			self:append_elements_sorted()
			return true
		end
	end
	return false
end

-- Called from hub element layer then the unit is deleted. The units parameter is
-- all created units in the layer, it will call them to see if they want to remove this unit
-- from any connections.
function CoreMissionElement:delete_unit( units )
	local id = self._unit:unit_data().unit_id
	for _,unit in ipairs( units ) do
		unit:mission_element():remove_on_execute( self._unit )
		unit:mission_element():remove_links( self._unit )
	end
end

-- Set which on executed element data that should be displayed in the on executed ctrlrs
-- Can be called either with a unit or an id.
-- If no unit can be found, the ctrlrs are disabled and then calls to try to set the first on executed element
-- Otherwise it will enable the ctrlrs and then change the combobox value accordingly and then update the data.
function CoreMissionElement:set_on_executed_element( unit, id )
	unit = unit or self:on_execute_unit_by_id( id )
	if not alive( unit ) then
		self:_set_on_execute_ctrlrs_enabled( false )
		self:_set_first_executed_element()
		return
	end
	
	self:_set_on_execute_ctrlrs_enabled( true )
	if self._elements_params then
		local name = self:combobox_name( unit )
		CoreEWS.change_combobox_value( self._elements_params, name )
		self:set_on_executed_data()
	end
end

-- Sets the on executed data based on the currently selected element in the combobox
function CoreMissionElement:set_on_executed_data()
	local id = self:combobox_id( self._elements_params.value )
	local params = self:_get_on_executed( id )
	CoreEWS.change_entered_number( self._element_delay_params, params.delay )
	if self._on_executed_alternatives_params then
		CoreEWS.change_combobox_value( self._on_executed_alternatives_params, params.alternative )
	end
	if self._timeline then
		self._timeline:select_element( params )
	end
end

-- Picks the first on executed element (if availible) and calls to the data to that
function CoreMissionElement:_set_first_executed_element()
	if #self._hed.on_executed > 0 then
		self:set_on_executed_element( nil, self._hed.on_executed[ 1 ].id )
	end
end

-- Enabled or disables the on executed ctrlrs
function CoreMissionElement:_set_on_execute_ctrlrs_enabled( enabled )
	if not self._elements_params then
		return
	end
	
	self._elements_params.ctrlr:set_enabled( enabled )
	self._element_delay_params.number_ctrlr:set_enabled( enabled )
	self._elements_toolbar:set_enabled( enabled )
	if self._on_executed_alternatives_params then
		self._on_executed_alternatives_params.ctrlr:set_enabled( enabled )
	end
end

-- Callback from the on executed elements combobox ctrlr
function CoreMissionElement:on_executed_element_selected()
	self:set_on_executed_data()
end

-- Returns a on executed params base on an id
function CoreMissionElement:_get_on_executed( id )
	for _,params in ipairs( self._hed.on_executed ) do
		if params.id == id then
			return params
		end
	end
end

-- Returns current selected element id
function CoreMissionElement:_current_element_id()
	if not self._elements_params or not self._elements_params.value then
		return nil
	end
	return self:combobox_id( self._elements_params.value )
end

-- Returns current selected on executed unit
function CoreMissionElement:_current_element_unit()
	local id = self:_current_element_id()
	if not id then
		return nil
	end
	local unit = self:on_execute_unit_by_id( id )
	if not alive( unit ) then
		return nil
	end
	return unit
end

-- Callback from the delay ctrlr to set the delay to the currently selected on_executed element
function CoreMissionElement:on_executed_element_delay()
	local id = self:combobox_id( self._elements_params.value )
	local params = self:_get_on_executed( id )
	params.delay = self._element_delay_params.value
	if self._timeline then
		self._timeline:delay_updated( params )
	end
end


function CoreMissionElement:on_executed_alternatives_types()
	local id = self:combobox_id( self._elements_params.value )
	local params = self:_get_on_executed( id )
	print( "self._on_executed_alternatives_params.value", self._on_executed_alternatives_params.value )
	params.alternative = self._on_executed_alternatives_params.value
end

-- Appends all on executed element names and if a element is selected in the combobox, it will reselect it.
function CoreMissionElement:append_elements_sorted()
	if not self._elements_params then
		return
	end

	local id = self:_current_element_id()
	CoreEWS.update_combobox_options( self._elements_params, self:_combobox_names_names( self._on_executed_units ) )
	self:set_on_executed_element( nil, id )
end

-- Creates a name for comboboxes which uses name id and the unique unit id
function CoreMissionElement:combobox_name( unit )
	return unit:unit_data().name_id..' ('..unit:unit_data().unit_id..')'
end

-- Returns a correct number unit id based on a combobox name
function CoreMissionElement:combobox_id( name )
	local s
	local e = string.len( name ) - 1
	for i = string.len( name ), 0, -1 do 
		local t = string.sub( name, i, i  )
	 	if t == '(' then
	 		s = i+1
	 		break
	 	end
	 end
	 return tonumber( string.sub( name, s, e ) )
end

-- Returns a on executed unit base on a id
function CoreMissionElement:on_execute_unit_by_id( id )
	for _,unit in ipairs( self._on_executed_units ) do
		if unit:unit_data().unit_id == id then
			return unit
		end
	end
	return nil
end

-- Returns a  table with names for comboboxes
function CoreMissionElement:_combobox_names_names( units )
	local names = {}
	for _,unit in ipairs( units ) do
		table.insert( names, self:combobox_name( unit ) )
	end
	return names
end

-- Called from mission layer
function CoreMissionElement:on_timeline()
	if not self._timeline then
		self._timeline = MissionElementTimeline:new( self._unit:unit_data().name_id )
		self._timeline:set_mission_unit( self._unit )
	else
		self._timeline:set_visible( true )
	end
end

