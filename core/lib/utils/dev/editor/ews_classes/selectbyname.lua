SelectByName = SelectByName or class( UnitByName )

function SelectByName:init( ... )
	UnitByName.init( self, "Select by name", nil, ... )
	--[[
	CoreEditorEwsDialog.init( self, nil, self._dialog_name, "", Vector3( 300, 150, 0), Vector3( 350, 500, 0), "DEFAULT_DIALOG_STYLE,RESIZE_BORDER,STAY_ON_TOP", ... )
	self:create_panel( "VERTICAL" )	
	
	local panel = self._panel
	local panel_sizer = self._panel_sizer
	panel:set_sizer( panel_sizer )
		
		local horizontal_ctrlr_sizer = EWS:BoxSizer( "HORIZONTAL" )
		
		local list_sizer = EWS:BoxSizer( "VERTICAL" )
		
			list_sizer:add( EWS:StaticText( panel, "Filter", 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL" )
			self._filter = EWS:TextCtrl( panel, "", "", "TE_CENTRE" )
			list_sizer:add( self._filter, 0, 0, "EXPAND" )		
			self._filter:connect( "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "update_filter" ), nil )
		
			-- self._list = EWS:ListBox( panel, "", "LB_SINGLE,LB_HSCROLL,LB_NEEDED_SB,LB_SORT" )
			self._list = EWS:ListCtrl( panel, "", "LC_REPORT,LC_NO_HEADER,LC_SORT_ASCENDING" )
			self._list:clear_all()
			self._list:append_column( "Name" )		
						
		list_sizer:add( self._list, 1, 0, "EXPAND" )
		
		horizontal_ctrlr_sizer:add( list_sizer, 3, 0, "EXPAND" )
		
		local list_ctrlrs = EWS:BoxSizer( "VERTICAL" )
						
			self._layer_cbs = {}
			local layers_sizer = EWS:StaticBoxSizer( panel, "VERTICAL", "List Layers" )
				local layers = managers.editor:layers()
				local names_layers = {}
				for name, layer in pairs( layers ) do
					table.insert( names_layers, name )
				end
				table.sort( names_layers )
				for _,name in ipairs( names_layers ) do
					local cb = EWS:CheckBox( panel, name, "" )
					cb:set_value( true )
					self._layer_cbs[ name ] = cb
					cb:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "on_layer_cb" ), { cb = cb, name = name } )
					cb:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					layers_sizer:add( cb, 0, 2, "EXPAND,TOP" )
				end
				
				local layer_buttons_sizer = EWS:BoxSizer( "HORIZONTAL" )
					local all_btn = EWS:Button( panel, "All", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( all_btn, 0, 2, "TOP,BOTTOM" )
					all_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_all_layers" ), "" )
					all_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					
					local none_btn = EWS:Button( panel, "None", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( none_btn, 0, 2, "TOP,BOTTOM" )
					none_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_none_layers" ), "" )
					none_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					
					local invert_btn = EWS:Button( panel, "Invert", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( invert_btn, 0, 2, "TOP,BOTTOM" )
					invert_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_invert_layers" ), "" )
					invert_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )

				layers_sizer:add( layer_buttons_sizer, 0, 2, "TOP,BOTTOM" )
						
			list_ctrlrs:add( layers_sizer, 0, 30, "EXPAND,TOP" )
		
		horizontal_ctrlr_sizer:add( list_ctrlrs, 2, 0, "EXPAND" )
		
		-- panel_sizer:add( list_sizer, 1, 0, "EXPAND" )
		
		panel_sizer:add( horizontal_ctrlr_sizer, 1, 0, "EXPAND" )
		]]

		-- self._list:connect( "EVT_KEY_DOWN", callback( self, self, "key_delete" ), "" )
		-- self._list:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
						
	-- self._dialog_sizer:add( self._panel, 1, 0, "EXPAND" )
	
	-- self:fill_unit_list()
	-- self._dialog:set_visible( true )
end

function SelectByName:_build_buttons( panel, sizer )
	local find_btn = EWS:Button( panel, "Find", "", "BU_BOTTOM" )
	sizer:add( find_btn, 0, 2, "RIGHT,LEFT" )
	find_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "_on_find_unit" ), "" )
	find_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
			
	local select_btn = EWS:Button( panel, "Select", "", "BU_BOTTOM" )
	sizer:add( select_btn, 0, 2, "RIGHT,LEFT" )
	select_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "_on_select_unit" ), "" )
	select_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
			
	local delete_btn = EWS:Button( panel, "Delete", "", "BU_BOTTOM" )
	sizer:add( delete_btn, 0, 2, "RIGHT,LEFT" )
	delete_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "_on_delete" ), "" )
	delete_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
	
	UnitByName._build_buttons( self, panel, sizer )
end

--[[
function SelectByName:on_all_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( true )
	end
	self:fill_unit_list()
end

function SelectByName:on_none_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( false )
	end
	self:fill_unit_list()
end

function SelectByName:on_invert_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( not cb:get_value() )
	end
	self:fill_unit_list()
end
]]

--[[
function SelectByName:key_cancel( ctrlr, event )
	event:skip()
	if EWS:name_to_key_code( "K_ESCAPE" ) == event:key_code() then
		self:on_cancel()
	end
end
]]
--[[
function SelectByName:on_layer_cb( data )
	self:fill_unit_list()
end
]]
--[[
function SelectByName:on_cancel()
	self._dialog:set_visible( false )
end
]]

function SelectByName:_on_delete()
	local confirm = EWS:message_box( self._dialog, "Delete selected unit(s)?", self._dialog_name, "YES_NO,ICON_QUESTION", Vector3( -1, -1, 0 ) )
	if confirm == "NO" then
		return
	end

	managers.editor:freeze_gui_lists()
	for _,unit in ipairs( self:_selected_item_units() ) do
		managers.editor:delete_unit( unit )
	end
	managers.editor:thaw_gui_lists()
--[[
	if self._list:selected_item() ~= -1 then
		self:_on_select_unit()
		managers.editor:delete_selected_unit()
	end
]]
end

function SelectByName:_on_find_unit()
	self:_on_select_unit()
	managers.editor:center_view_on_unit( self:_selected_item_unit() )
end

function SelectByName:_on_select_unit()
	managers.editor:change_layer_based_on_unit( self:_selected_item_unit() )
	managers.editor:freeze_gui_lists()
	self._blocked = true
	managers.editor:select_units( self:_selected_item_units() )
	managers.editor:thaw_gui_lists()
	self._blocked = false
		
	--[[
	for _,unit in ipairs( self:_selected_item_units() ) do
		self:select_unit( unit )
	end
	]]

	--[[
	local index = self._list:selected_item()
	if index ~= -1 then
		local unit = self._units[ self._list:get_item_data( index ) ]
		self:select_unit( unit )
	end
	]]
end

-- Returns all selected units
--[[
function SelectByName:_selected_item_units()
	local units = {}
	for _,i in ipairs( self._list:selected_items() ) do
		local unit = self._units[ self._list:get_item_data( i ) ]
		table.insert( units, unit )
	end
	return units
end
]]

-- Return the first selected unit
--[[
function SelectByName:_selected_item_unit()
	local index = self._list:selected_item()
	if index ~= -1 then
		return self._units[ self._list:get_item_data( index ) ]
	end
end
]]
--[[
function SelectByName:select_unit( unit )
	managers.editor:select_unit( unit )
end
]]

-- Called from editor when a unit is about to be deleted
--[[
function SelectByName:deleted_unit( unit )
	for i = 0, self._list:item_count()-1 do
		if self._units[ self._list:get_item_data( i ) ] == unit then
			self._list:delete_item( i )
			return
		end
	end
end
]]

-- Called from editor when a unit has been spawned
--[[
function SelectByName:spawned_unit( unit )
	local i = self._list:append_item( unit:unit_data().name_id )
	local j = #self._units+1
	self._units[ j ] = unit
	self._list:set_item_data( i, j )
end
]]

-- Called from editor when a unit has been selected
--[[
function SelectByName:selected_unit( unit )
	for _,i in ipairs( self._list:selected_items() ) do
		self._list:set_item_selected( i, false )
	end
	
	for i = 0, self._list:item_count()-1 do
		if self._units[ self._list:get_item_data( i ) ] == unit then
			self._list:set_item_selected( i, true )
			self._list:ensure_visible( i )
			return
		end
	end
end
]]

-- Called from the editor to set which units are currently selected
--[[
function SelectByName:selected_units( units )
	if self._blocked then
		return
	end
	for _,i in ipairs( self._list:selected_items() ) do
		self._list:set_item_selected( i, false )
	end
	
	for _,unit in ipairs( units ) do
		for i = 0, self._list:item_count()-1 do
			if self._units[ self._list:get_item_data( i ) ] == unit then
				self._list:set_item_selected( i, true )
				self._list:ensure_visible( i )
				break
			end
		end
	end
end
]]

-- Called from the editor when a unit has changeds its name id
--[[
function SelectByName:unit_name_changed( unit )
	for i = 0, self._list:item_count()-1 do
		if self._units[ self._list:get_item_data( i ) ] == unit then
			self._list:set_item( i, 0, unit:unit_data().name_id )
			
			local sort = false
			if i - 1 >= 0 then
				local over = self._units[ self._list:get_item_data( i - 1 ) ]:unit_data().name_id
				sort = sort or over > unit:unit_data().name_id
			end
			if i + 1 < self._list:item_count() then
				local under = self._units[ self._list:get_item_data( i + 1 ) ]:unit_data().name_id
				sort = sort or under < unit:unit_data().name_id
			end
			if sort then
				self:fill_unit_list()
				for i = 0, self._list:item_count()-1 do
					if self._units[ self._list:get_item_data( i ) ] == unit then
						self._list:set_item_selected( i, true )
						self._list:ensure_visible( i )
						break
					end
				end
			end
			
			break
		end
	end
end
]]

--[[
function SelectByName:update_filter()
	self:fill_unit_list()
end
]]

-- Goes through all layers all created units and append them to the list. The unit is also stored in a table which then can be accessed 
-- through the item data.
--[[
function SelectByName:fill_unit_list()
	self._list:delete_all_items()
	local layers = managers.editor:layers()
	local j = 1
	local filter = self._filter:get_value()
	self._units = {}
	self._list:freeze()
	for name,layer in pairs( layers ) do
		if self._layer_cbs[ name ]:get_value() then
			for _,unit in ipairs( layer:created_units() ) do
				if string.find( unit:unit_data().name_id, filter, 1 ,true ) then
					local i = self._list:append_item( unit:unit_data().name_id )
					self._units[ j ] = unit
					self._list:set_item_data( i, j )
					j = j + 1
				end
			end
		end
	end
	self._list:thaw()
	self._list:autosize_column( 0 )
end 

function SelectByName:reset()
	self:fill_unit_list()
end

function SelectByName:freeze()
	self._list:freeze()
end

function SelectByName:thaw()
	self._list:thaw()
end
]]
