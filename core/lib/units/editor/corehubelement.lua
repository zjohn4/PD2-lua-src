CoreHubElement = CoreHubElement or class()

-- This is the prepared class for a project heritance
-- This is what all hubelements must inherit.
HubElement = HubElement or class( CoreHubElement )
function HubElement:init( ... )
	CoreHubElement.init( self, ... )
end

-- Save values table contains what data should be saved for world and mission. It is
-- specified in the inheritance
function CoreHubElement:init( unit )
	self._unit = unit 							-- Init recieves the unit and saves it
	self._hed = self._unit:hub_element_data() 	-- the hubelement data extension is set in a variable
	self._ud = self._unit:unit_data() 			-- the unitdata extension is set in a variable
	self._unit:anim_play( 1 ) 					-- start playing animation if it has any
	self._save_values = {} 						-- create the save values table
	self._mission_trigger_values = {}			-- create the trigger save values 
	
	self._update_selected_on = false			-- Specifies if the update_selected function should be called even when not selected
	
	-- Get the panel and sizer from editor hub element layer that the unit can use for its own gui
	self._parent_panel = managers.editor:hub_element_panel()
	self._parent_sizer = managers.editor:hub_element_sizer()
	
	-- Contains gui panels belonging to different parents
	self._panels = {}
		
	self._arrow_brush = Draw:brush()

	self:_createicon()	-- Create the icon for this huelement
end

-- Values that can be set from unit xml
-- _icon = The icon to use, a string with a single character. Ex "G" 
-- _iconcolor = Color of icon, if not set it will be white. Ex "ff0" for yellow.
function CoreHubElement:_createicon()
	local iconsize = 128
	if Global.iconsize then 
		iconsize = Global.iconsize
	end

	if self._icon == nil then
		return
	end

	local root = self._unit:get_object( Idstring( "c_hub_element_sphere" ) )
	if root == nil then
		-- Show error that unit is missing a icon object. 
		return
	end

	if self._iconcolor == nil then
		self._iconcolor = "fff"
	end
	
	self._icon_gui = World:newgui()
	self._icon_gui:preload("core/guis/core_edit_icon")

	--self._icon_ws = self._icon_gui:create_object_workspace(64, 64, root)
	local pos = self._unit:position() - Vector3(iconsize / 2, iconsize / 2,0)
	self._icon_ws = self._icon_gui:create_linked_workspace(64, 64, root, pos,Vector3(iconsize,0,0),Vector3(0,iconsize,0))
	self._icon_ws:set_billboard(self._icon_ws.BILLBOARD_BOTH)

	self._icon_ws:panel():gui("core/guis/core_edit_icon")
	self._icon_script = self._icon_ws:panel():gui( "core/guis/core_edit_icon" ):script()
	self._icon_script:seticon( self._icon, tostring(self._iconcolor) )
end

-- Should be called first in _build_panel. It creates a standard panel which extra data to be able to know if its alive or not.
function CoreHubElement:_create_panel()
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
function CoreHubElement:_build_panel()
	self._panel = nil
end

-- Returns the panel, will try to build the panel if there isn't one. The _panel object will still be nil if _build_panel isn't inherited
-- Can't call _build_panel at init since loaded hub elements will not be able to set their saved data to the gui at that time.
function CoreHubElement:panel( id, parent, parent_sizer )
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

function CoreHubElement:_add_panel( parent, parent_sizer )
	local panel = EWS:Panel( parent, "", "TAB_TRAVERSAL" )
	local panel_sizer = EWS:BoxSizer("VERTICAL")
	panel:set_sizer( panel_sizer )
	
		panel_sizer:add( EWS:StaticText( panel, managers.editor:category_name( self._unit:name() ), 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL" )
		panel_sizer:add( EWS:StaticLine( panel, "", "LI_HORIZONTAL" ), 0, 0, "EXPAND" )
		
	parent_sizer:add( panel, 1, 0, "EXPAND")
	panel:set_visible( false )
	panel:set_extension( { alive = true } )
	
	return panel, panel_sizer
end

-- This function can be used to add a help text to a hub element
-- data is a table containing:
-- text		-- help to be displayed
-- panel	-- the parent panel
-- sizer	-- the sizer the controller should be added to
function CoreHubElement:add_help_text( data )
	if data.panel and data.sizer then
		-- panel_sizer:add( EWS:StaticText( panel, text, 0, "" ), 0, 0, "ALIGN_CENTER" )
		data.sizer:add( EWS:TextCtrl( data.panel, data.text, 0, "TE_MULTILINE,TE_READONLY,TE_WORDWRAP,TE_CENTRE" ), 0, 5, "EXPAND,TOP,BOTTOM" )
	end
end

-- Is called when a event from a ews ctrlr is made
-- Makes callback for special events or sets the data value from the ctrlr
function CoreHubElement:set_element_data( data )
	if data.callback then
		local he = self._unit:hub_element()
		he[ data.callback ]( he, data.ctrlr, data.params )
	end
	if data.value then
		self._hed[ data.value ] = data.ctrlr:get_value()
		self._hed[ data.value ] = tonumber( self._hed[ data.value ] ) or self._hed[ data.value ] -- Convert string back to number
	end
end

-- Called from the editor layer when a hubelement unit is selected
function CoreHubElement:selected()
end

-- An update function that is called while a hubelement unit is selected
function CoreHubElement:update_selected()
end

-- An update function that is called while a hubelement unit is not selected
function CoreHubElement:update_unselected()
end

function CoreHubElement:begin_editing() 

end

function CoreHubElement:end_editing() 

end

-- Called after cloning is done to make whatever might be needed. Spawn help units or simular
function CoreHubElement:clone_data()
end

-- Hubelements layer uses this function to check if it should enable Edit Element button or not
-- function CoreHubElement:update_editing() 
-- end

-- Hubelements layer uses this function to check if it should enable Test Element button or not
-- function CoreHubElement:test_element()
-- end

-- Hubelements layer uses this function to check if it should enable Stop Test Element button or not
-- function CoreHubElement:stop_test_element()
-- end

-- Called when the entire layer has been loaded
-- For example used by Hub to set up all its units associations
function CoreHubElement:layer_finished()
end

-- Returns the action type
function CoreHubElement:action_type()
	return self._action_type or self._type
end

-- Returns the trigger type
function CoreHubElement:trigger_type()
	return self._trigger_type or self._type
end

-- Saves to mission file
function CoreHubElement:save_mission_action( file, t, hub, dont_save_values )
	local type = self:action_type()
	if type then
		local ha = hub:hub_element():get_hub_action( self._unit )
		file:puts( t..'<action type="'..type..'" name="'..self:name()..'" mode="'..ha.type..'" start_time="'..ha.action_delay..'">' )
		if not dont_save_values then -- Used when hub is an action
			for _,name in ipairs( self._save_values ) do
				self:save_value( file, t, name )
			end
		end
		file:puts( t..'</action>' )
	end
end

-- Enemy saves in somewhat different format since it would potentially contain a group of enemy entities
function CoreHubElement:save_mission_action_enemy( file, t, hub )
	local ha = hub:hub_element():get_hub_action( self._unit )
	local pos = self._unit:position()
	local rot = self._unit:rotation()
	file:puts( t..'<action type="'..self:action_type()..'" name="'..self:name()..'" mode="'..ha.type..'" start_time="'..ha.action_delay..'">' )
	if ha.type == "" or ha.type == "create" then -- Don't need to save patrolpoints etc, if it isn't the create action
		file:puts( t..'\t<enemy name="'..self._hed.enemy_name..'">' )
		for _,name in ipairs( self._save_values ) do
			self:save_value( file, t..'\t', name )
		end
		file:puts( t..'\t</enemy>' )
	end
	file:puts( t..'</action>' )
end

-- Saves all the data for a unit. It is done automaticly at its simpliest but can be overridden by the inheritance
-- if you want to handle the data sava/load and use by yourself (normaly not)
function CoreHubElement:save_data( file, t )
	self:save_values( file, t )
end

-- Saves to world file
function CoreHubElement:save_values( file, t )
	t = t..'\t'
	file:puts( t..'<values>' )
	for _,name in ipairs( self._save_values ) do
		self:save_value( file, t, name )
	end
	file:puts( t..'</values>' )
end

-- A Save value function that saves values according to a standard format

function CoreHubElement:save_value( file, t, name )
	t = t..'\t'
	file:puts( save_value_string( self._hed, name, t, self._unit ) )
end

-- Saves to mission file
function CoreHubElement:save_mission_trigger( file, t, hub )
	if #self._mission_trigger_values > 0 then
		local type = self:trigger_type()
		if type then
			local ht = hub:hub_element():get_hub_trigger( self._unit )
			file:puts( t..'<trigger type="'..type..'" name="'..self:name()..'" mode="'..ht.type..'">' )
			for _,name in ipairs( self._mission_trigger_values ) do
				self:save_value( file, t, name )
			end
			file:puts( t..'</trigger>' )
		end
	end
end

function CoreHubElement:name()
	return self._unit:name()..self._ud.unit_id
end

-- load_data is called from the worldholder if you have choosed to handle the data loading by you self
-- Area does this for example
function CoreHubElement:load_data( data )
end

-- Get color returns a color value to be used for drawing action arrows in different colors pending on the action type
function CoreHubElement:get_color( type )
	if type then
		if type == "activate" or type == "enable" then
			return 0, 1, 0
		elseif type == "deactivate" or type == "disable"  then
			return 1, 0, 0
		end
	end
	return 0, 1, 0
end

-- Draws connection to/from this element when selected (CoreHub overrides this with own functionality)
function CoreHubElement:draw_connections_selected()
	for _,hub in ipairs( self._hed.hubs ) do
		local r, g, b = 1, 0.6, 0.2
		self:draw_arrow( self._unit, hub, r, g, b, true )
	end
end

-- Draws connection to/from this element when not selected (CoreHub overrides this with own functionality)
function CoreHubElement:draw_connections_unselected()

end

function CoreHubElement:draw_arrow( from, to, r, g, b, thick )
	self._arrow_brush:set_color( Color( r, g, b ) )

	local mul = 1.2
	r = math.clamp( r*mul, 0, 1 )
	g = math.clamp( g*mul, 0, 1 )
	b = math.clamp( b*mul, 0, 1 )
	from = from:position()
	to = to:position()
	local len = ( from - to ):length()
	local dir = (to - from):normalized()
	len = len - 50
	if thick then
		self._arrow_brush:cylinder( from, from + dir*len, 10 )
		Application:draw_cylinder( from, from + dir*len, 10, r, g, b )
	else
		Application:draw_line( from, to, r, g, b )
	end
	self._arrow_brush:cone( to, to + ((from-to):normalized())*150, 48 )
	Application:draw_cone( to, to + ((from-to):normalized())*150, 48, r, g, b )
end

-- clear is called before a unit is removed. It can then clear out whatever data it needs to.
-- ImperialEnemy for example deletes all its patrol point units
function CoreHubElement:clear()
end

-- Returns a table with availible action for the hubelement unit.
-- Hub uses this to display it as availible options in the Actions/Types dropdown
function CoreHubElement:action_types()
	return self._action_types
end

function CoreHubElement:timeline_color()
	return self._timeline_color
end

-- Called from the layer to add keyboard and mouse triggers to be used when editing an element
function CoreHubElement:add_triggers()
end

-- Removes the added keyboard and mouse triggers
function CoreHubElement:clear_triggers()
end

-- Possible to return a unit used by the element
function CoreHubElement:widget_affect_object()
	return nil
end

-- Possible to use the information from the move widget (need to return true if using)
function CoreHubElement:use_widget_position()
	return nil
end

-- When a hubelement unit is enabled through the layer function set_enabled a call goes to the hubelement as well
-- Here a hubelement can enable units that it has created.
-- Minefield in BC uses this to enable its mine units
function CoreHubElement:set_enabled()
end

-- When a hubelement unit is disabled through the layer function set_disabled a call goes to the hubelement as well
-- Here a hubelement can enable units that it has created.
-- Minefield in BC uses this to disabled its mine units
function CoreHubElement:set_disabled()
end

-- Sets _update_selected_on status
function CoreHubElement:set_update_selected_on( value )
	self._update_selected_on = value
end

-- Returns _update_selected_on status
function CoreHubElement:update_selected_on()
	return self._update_selected_on
end

-- As for all extensions destroyed is called when a unit is deletet
function CoreHubElement:destroy()
	if self._panel then
		self._panel:extension().alive = false
		self._panel:destroy() 
	end
	
	if self._icon_ws then
		self._icon_gui:destroy_workspace( self._icon_ws )
		self._icon_ws = nil
	end
end

