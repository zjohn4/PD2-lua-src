UnhideByName = UnhideByName or class( CoreEditorEwsDialog )

function UnhideByName:init( ... )
	CoreEditorEwsDialog.init( self, nil, "Unhide by name", "", Vector3( 300, 150, 0), Vector3( 350, 500, 0), "DEFAULT_DIALOG_STYLE,RESIZE_BORDER,STAY_ON_TOP", ... )
	self:create_panel( "VERTICAL" )
		
		local horizontal_ctrlr_sizer = EWS:BoxSizer( "HORIZONTAL" )
		
		local list_sizer = EWS:BoxSizer( "VERTICAL" )
		
			list_sizer:add( EWS:StaticText( self._panel, "Filter", 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL" )
			self._filter = EWS:TextCtrl( self._panel, "", "", "TE_CENTRE" )
			list_sizer:add( self._filter, 0, 0, "EXPAND" )		
			self._filter:connect( "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "update_filter" ), nil )
		
			-- self._list = EWS:ListBox( self._panel, "", "LB_SINGLE,LB_HSCROLL,LB_NEEDED_SB,LB_SORT" )
			self._list = EWS:ListCtrl( self._panel, "", "LC_REPORT,LC_NO_HEADER,LC_SORT_ASCENDING" )
			self._list:clear_all()
			self._list:append_column( "Name" )		
						
		list_sizer:add( self._list, 1, 0, "EXPAND" )
		
		horizontal_ctrlr_sizer:add( list_sizer, 3, 0, "EXPAND" )
		
		local list_ctrlrs = EWS:BoxSizer( "VERTICAL" )
						
			self._layer_cbs = {}
			local layers_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "List Layers" )
				local layers = managers.editor:layers()
				local names_layers = {}
				for name, layer in pairs( layers ) do
					table.insert( names_layers, name )
				end
				table.sort( names_layers )
				for _,name in ipairs( names_layers ) do
					local cb = EWS:CheckBox( self._panel, name, "" )
					cb:set_value( true )
					self._layer_cbs[ name ] = cb
					cb:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "on_layer_cb" ), { cb = cb, name = name } )
					cb:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					layers_sizer:add( cb, 0, 2, "EXPAND,TOP" )
				end
				
				local layer_buttons_sizer = EWS:BoxSizer( "HORIZONTAL" )
					local all_btn = EWS:Button( self._panel, "All", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( all_btn, 0, 2, "TOP,BOTTOM" )
					all_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_all_layers" ), "" )
					all_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					
					local none_btn = EWS:Button( self._panel, "None", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( none_btn, 0, 2, "TOP,BOTTOM" )
					none_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_none_layers" ), "" )
					none_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
					
					local invert_btn = EWS:Button( self._panel, "Invert", "", "BU_EXACTFIT,NO_BORDER" )
					layer_buttons_sizer:add( invert_btn, 0, 2, "TOP,BOTTOM" )
					invert_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_invert_layers" ), "" )
					invert_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )

				layers_sizer:add( layer_buttons_sizer, 0, 2, "TOP,BOTTOM" )
						
			list_ctrlrs:add( layers_sizer, 0, 30, "EXPAND,TOP" )
			
			local continents_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Continents" )
				
				self._continents_sizer = EWS:BoxSizer( "VERTICAL" )
				self:build_continent_cbs()
			
				continents_sizer:add( self._continents_sizer, 0, 2, "TOP,BOTTOM" )

			list_ctrlrs:add( continents_sizer, 0, 5, "EXPAND,TOP" )
			
			local continent_buttons_sizer = EWS:BoxSizer( "HORIZONTAL" )
				local continent_all_btn = EWS:Button( self._panel, "All", "", "BU_EXACTFIT,NO_BORDER" )
				continent_buttons_sizer:add( continent_all_btn, 0, 2, "TOP,BOTTOM" )
				continent_all_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_all_continents" ), "" )
				continent_all_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
				
				local continent_none_btn = EWS:Button( self._panel, "None", "", "BU_EXACTFIT,NO_BORDER" )
				continent_buttons_sizer:add( continent_none_btn, 0, 2, "TOP,BOTTOM" )
				continent_none_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_none_continents" ), "" )
				continent_none_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
				
				local continent_invert_btn = EWS:Button( self._panel, "Invert", "", "BU_EXACTFIT,NO_BORDER" )
				continent_buttons_sizer:add( continent_invert_btn, 0, 2, "TOP,BOTTOM" )
				continent_invert_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_invert_continents" ), "" )
				continent_invert_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
		
			continents_sizer:add( continent_buttons_sizer, 0, 2, "TOP,BOTTOM" )
		
		horizontal_ctrlr_sizer:add( list_ctrlrs, 2, 0, "EXPAND" )
		
		-- self._panel_sizer:add( list_sizer, 1, 0, "EXPAND" )
		
		self._panel_sizer:add( horizontal_ctrlr_sizer, 1, 0, "EXPAND" )
		
		
		self._list:connect( "EVT_COMMAND_LIST_ITEM_SELECTED", callback( self, self, "on_mark_unit" ), nil )
		-- self._list:connect( "EVT_COMMAND_LIST_ITEM_ACTIVATED", callback( self, self, "on_select_unit" ), nil )
		self._list:connect( "EVT_COMMAND_LIST_ITEM_ACTIVATED", callback( self, self, "on_unhide" ), nil )
		-- self._list:connect( "EVT_KEY_DOWN", callback( self, self, "key_delete" ), "" )
		self._list:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
		
		local button_sizer = EWS:BoxSizer("HORIZONTAL")
			
			--[[
			local find_btn = EWS:Button( self._panel, "Find", "", "BU_BOTTOM" )
			button_sizer:add( find_btn, 0, 2, "RIGHT,LEFT" )
			find_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_find_unit" ), "" )
			find_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
			
			local select_btn = EWS:Button( self._panel, "Select", "", "BU_BOTTOM" )
			button_sizer:add( select_btn, 0, 2, "RIGHT,LEFT" )
			select_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_select_unit" ), "" )
			select_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
			]]
			
			local unhide_btn = EWS:Button( self._panel, "Unhide", "", "BU_BOTTOM" )
			button_sizer:add( unhide_btn, 0, 2, "RIGHT,LEFT" )
			unhide_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_unhide" ), "" )
			unhide_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
								
			local cancel_btn = EWS:Button( self._panel, "Cancel", "", "" )
			button_sizer:add( cancel_btn, 0, 2, "RIGHT,LEFT" )
			cancel_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_cancel" ), "" )
			cancel_btn:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
						
		self._panel_sizer:add( button_sizer, 0, 0, "ALIGN_RIGHT" )
				
	self._dialog_sizer:add( self._panel, 1, 0, "EXPAND" )
	
	self:fill_unit_list()
	self._dialog:set_visible( true )
end

function UnhideByName:build_continent_cbs()
	self._continents_cbs = {}
		
	local continents = managers.editor:continents()
	self._continent_names = {}
	for name, continent in pairs( continents ) do
		table.insert( self._continent_names, name )
	end
	table.sort( self._continent_names )
	for _,name in ipairs( self._continent_names ) do
		local cb = EWS:CheckBox( self._panel, name, "" )
		cb:set_value( true )
		self._continents_cbs[ name ] = cb
		cb:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "on_continent_cb" ), { cb = cb, name = name } )
		cb:connect( "EVT_KEY_DOWN", callback( self, self, "key_cancel" ), "" )
		self._continents_sizer:add( cb, 0, 2, "EXPAND,TOP" )
	end
end

function UnhideByName:on_continent_cb()
	self:fill_unit_list()
end

function UnhideByName:on_all_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( true )
	end
	self:fill_unit_list()
end

function UnhideByName:on_none_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( false )
	end
	self:fill_unit_list()
end

function UnhideByName:on_invert_layers()
	for name,cb in pairs( self._layer_cbs ) do
		cb:set_value( not cb:get_value() )
	end
	self:fill_unit_list()
end

function UnhideByName:on_all_continents()
	for name,cb in pairs( self._continents_cbs ) do
		cb:set_value( true )
	end
	self:fill_unit_list()
end

function UnhideByName:on_none_continents()
	for name,cb in pairs( self._continents_cbs ) do
		cb:set_value( false )
	end
	self:fill_unit_list()
end

function UnhideByName:on_invert_continents()
	for name,cb in pairs( self._continents_cbs ) do
		cb:set_value( not cb:get_value() )
	end
	self:fill_unit_list()
end

--[[
function UnhideByName:key_delete( ctrlr, event )
	event:skip()
	if EWS:name_to_key_code( "K_DELETE" ) == event:key_code() then
		self:on_delete()
	end
end
]]

function UnhideByName:key_cancel( ctrlr, event )
	event:skip()
	if EWS:name_to_key_code( "K_ESCAPE" ) == event:key_code() then
		self:on_cancel()
	end
end

function UnhideByName:on_layer_cb( data )
	self:fill_unit_list()
end

function UnhideByName:on_cancel()
	self._dialog:set_visible( false )
end

function UnhideByName:on_unhide()
	managers.editor:freeze_gui_lists()
	for _,unit in ipairs( self:_selected_item_units() ) do
		managers.editor:set_unit_visible( unit, true )
	end
	managers.editor:thaw_gui_lists()
end

function UnhideByName:on_delete()
	managers.editor:freeze_gui_lists()
	for _,unit in ipairs( self:_selected_item_units() ) do
		managers.editor:delete_unit( unit )
	end
	managers.editor:thaw_gui_lists()
end

function UnhideByName:on_mark_unit()
	-- local index = self._list:selected_item()
	-- cat_print( 'editor', 'UnhideByName:on_mark_unit()', index )
	-- local unit = self._list:get_item_data_ref( index )
end

--[[
function UnhideByName:on_select_unit()
	managers.editor:change_layer_based_on_unit( self:_selected_item_unit() )
	managers.editor:freeze_gui_lists()
	managers.editor:select_units( self:_selected_item_units() )
	managers.editor:thaw_gui_lists()
end
]]

-- Returns all selected units
function UnhideByName:_selected_item_units()
	local units = {}
	for _,i in ipairs( self._list:selected_items() ) do
		local unit = self._units[ self._list:get_item_data( i ) ]
		table.insert( units, unit )
	end
	return units
end

-- Return the first selected unit
function UnhideByName:_selected_item_unit()
	local index = self._list:selected_item()
	if index ~= -1 then
		return self._units[ self._list:get_item_data( index ) ]
	end
end

function UnhideByName:select_unit( unit )
	managers.editor:select_unit( unit )
end

-- Called from editor when a unit is hidden
function UnhideByName:hid_unit( unit )
	local i = self._list:append_item( unit:unit_data().name_id )
	local j = #self._units+1
	self._units[ j ] = unit
	self._list:set_item_data( i, j )
--	self._list:autosize_column( 0 )
end

-- Called from editor when a unit is unhidden
function UnhideByName:unhid_unit( unit )
	for i = 0, self._list:item_count()-1 do
	if self._units[ self._list:get_item_data( i ) ] == unit then
			self._list:delete_item( i )
		--	self._list:autosize_column( 0 )
			return
		end
	end
end

-- Called from the editor when a unit has changeds its name id
function UnhideByName:unit_name_changed( unit )
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

function UnhideByName:update_filter()
	self:fill_unit_list()
end

-- Goes through all layers all created units and append them to the list. The unit is also stored in a table which then can be accessed 
-- through the item data.
function UnhideByName:fill_unit_list()
	self._list:delete_all_items()
	local layers = managers.editor:layers()
	local j = 1
	local filter = self._filter:get_value()
	self._units = {}
	self._list:freeze()
	for name,layer in pairs( layers ) do
		if self._layer_cbs[ name ]:get_value() then
			for _,unit in ipairs( layer:created_units() ) do
				if self:_continent_ok( unit ) then
					if table.contains( managers.editor:hidden_units(), unit ) then
						if string.find( unit:unit_data().name_id, filter, 1 ,true ) then
							local i = self._list:append_item( unit:unit_data().name_id )
							self._units[ j ] = unit
							self._list:set_item_data( i, j )
							j = j + 1
						end
					end
				end
			end
		end
	end
	self._list:thaw()
	self._list:autosize_column( 0 )
end

function UnhideByName:_continent_ok( unit )
	local continent = unit:unit_data().continent
	if not continent then
		return true
	end
	return self._continents_cbs[ continent:name() ]:get_value()
end

function UnhideByName:reset()
	self:fill_unit_list()
end

function UnhideByName:freeze()
	self._list:freeze()
end

function UnhideByName:thaw()
	self._list:thaw()
end

function UnhideByName:recreate()
	for name,cb in pairs( self._continents_cbs ) do
		self._continents_sizer:detach( cb )
		cb:destroy()
	end
	self:build_continent_cbs()
	self:fill_unit_list()
	self._panel:layout()
end
