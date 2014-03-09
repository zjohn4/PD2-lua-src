core:module("CoreMenuNodeGui")
core:import( "CoreUnit" ) 
-----------------------------------------------------------
-- A gui class representing a menu node. Used by Renderer
NodeGui = NodeGui or class()

function NodeGui:init( node, layer, parameters )
	self.node				= node
	self.name				= node:parameters().name
	self.font				= "core/fonts/diesel"	
	self.font_size			= 28
	self.topic_font_size	= 48
	self.spacing			= 0

	-- Global.render_debug.menu_debug = false
		
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self.ws = managers.gui_data:create_saferect_workspace() -- Overlay:gui():create_scaled_screen_workspace( 1280, 720, safe_rect_pixels.x, safe_rect_pixels.y, safe_rect_pixels.width )
	
	self._item_panel_parent = self.ws:panel():panel( { name = "item_panel_parent" } )
	self.item_panel = self._item_panel_parent:panel( { name = "item_panel" } )
	self.safe_rect_panel = self.ws:panel():panel( { name = "safe_rect_panel" } ) -- , w = safe_rect_pixels.width, h = safe_rect_pixels.height } )
		
	self.ws:show()
	
	-- self._item_panel_parent:set_debug( true )
	-- self.item_panel:set_debug( true )
		
	self.layers = {}
	self.layers.first		= layer
	self.layers.background	= layer
	self.layers.marker		= layer + 1
	self.layers.items		= layer + 2
	self.layers.last		= self.layers.items
	
	self.localize_strings = true
		
	self.row_item_color			= self.row_item_color or Color( 1, 141/255, 176/255, 211/255 )
	self.row_item_hightlight_color		= self.row_item_hightlight_color or Color( 1, 141/255, 176/255, 211/255 )
	self.row_item_disabled_text_color	= self.row_item_disabled_text_color or Color( 1, 0.5, 0.5, 0.5 )

	-- Set parameters
	if parameters then
		for param_name, param_value in pairs( parameters ) do
			self[ param_name ] = param_value
		end
	end

	-- Set background
	if self.texture then
		self.texture.layer = self.layers.background
		self.texture = self.ws:panel():bitmap( self.texture )
		self.texture:set_visible( true )
	end

	self:_setup_panels( node )

	-- Setup menu row items
	self.row_items = {}
	
	-- Setup item rows
	self:_setup_item_rows( node )
end

function NodeGui:item_panel_parent()
	return self._item_panel_parent
end

function NodeGui:_setup_panels( node )
end

function NodeGui:_setup_item_rows( node )
	local items = node:items()
	local i = 0
	for _,item in pairs( items ) do
		if( item:visible() ) then
			item:parameters().gui_node = self -- IS THIS REALLY GOOD? !!!
			local item_name = item:parameters().name
			local item_text = "menu item missing 'text_id'"
			if item:parameters().no_text then
				item_text = nil
			end
			local help_text
			local params = item:parameters()
			if params.text_id then
				if self.localize_strings and params.localize ~= "false" then
					item_text = managers.localization:text( params.text_id )
				else
					item_text = params.text_id
				end
			end
			if params.help_id then
				help_text = managers.localization:text( params.help_id )
			end

			local row_item		= {}
			table.insert( self.row_items, row_item )
			
			row_item.item		= item
			row_item.node		= node
			row_item.node_gui	= self
			row_item.type		= item._type
			row_item.name		= item_name
			row_item.position	= { x = 0, y = self.font_size * i + self.spacing * ( i - 1 ) }
			row_item.color		= params.color or self.row_item_color
			row_item.disabled_color	= params.disabled_color or self.row_item_disabled_text_color
			row_item.font		= self.font
			row_item.font_size	= self.font_size
			row_item.text		= item_text
			row_item.help_text	= help_text
			row_item.align		= params.align or self.align or "left"
			row_item.halign		= params.halign or self.halign or "left"
			row_item.vertical	= params.vertical or self.vertical or "center"
			-- row_item.to_upper = params.to_upper or self.to_upper or false
			row_item.to_upper = params.to_upper == nil and self.to_upper or params.to_upper or false 
			row_item.color_ranges = params.color_ranges or self.color_ranges or nil

			self:_create_menu_item( row_item )

			self:reload_item( item )

			i = i + 1
		end
	end

	self:_setup_size()
	self:scroll_setup()
	
	self:_set_item_positions()
	
	self._highlighted_item = nil
end

function NodeGui:_insert_row_item( item, node, i )
	-- print( "function NodeGui:_insert_row_item" )
	if( item:visible() ) then
		item:parameters().gui_node = self -- IS THIS REALLY GOOD? !!!
		local item_name = item:parameters().name
		local item_text = "menu item missing 'text_id'"
		local help_text
		local params = item:parameters()
		if params.text_id then
			if self.localize_strings and params.localize ~= "false" then
				item_text = managers.localization:text( params.text_id )
			else
				item_text = params.text_id
			end
		end
		if params.help_id then
			help_text = managers.localization:text( params.help_id )
		end

		local row_item		= {}
		table.insert( self.row_items, i, row_item )
		
		row_item.item		= item
		row_item.node		= node
		row_item.type		= item._type
		row_item.name		= item_name
		row_item.position	= { x = 0, y = self.font_size * i + self.spacing * ( i - 1 ) }
		row_item.color		= params.color or self.row_item_color
		row_item.disabled_color	= params.disabled_color or self.row_item_disabled_text_color
		row_item.font		= self.font
		row_item.text		= item_text
		row_item.help_text	= help_text
		row_item.align		= params.align or self.align or "left"
		row_item.halign		= params.halign or self.halign or "left"
		row_item.vertical	= params.vertical or self.vertical or "center"
		row_item.to_upper = params.to_upper or false
		row_item.color_ranges = params.color_ranges or self.color_ranges or nil
		
		self:_create_menu_item( row_item )

		self:reload_item( item )
	end
	
--[[
	self:_setup_size()
	self:scroll_setup()
	
	self:_set_item_positions()
	
	self._highlighted_item = nil
	]]
end

function NodeGui:_delete_row_item( item )
	for i,row_item in ipairs( self.row_items ) do
		if row_item.item == item then
			-- print( "REMOVE ITEM", i )
			local delete_row_item = table.remove( self.row_items, i )
			-- print( "delete_row_item", delete_row_item )
			if alive( row_item.gui_panel ) then
				item:on_delete_row_item( row_item )
				self.item_panel:remove( row_item.gui_panel )
				self.item_panel:remove( row_item.menu_unselected )
			end
			return
		end
	end
end

function NodeGui:refresh_gui( node )
	self:_clear_gui()
	self:_setup_item_rows( node )
end

function NodeGui:_clear_gui()
	-- for _,row_item in ipairs( self.row_items ) do
	local to = #self.row_items
	for i = 1, to do
		local row_item = self.row_items[ i ]
		if alive( row_item.gui_panel ) then
			row_item.gui_panel:parent():remove( row_item.gui_panel )
			row_item.gui_panel = nil
			if alive( row_item.menu_unselected ) then
				row_item.menu_unselected:parent():remove( row_item.menu_unselected )
				row_item.menu_unselected = nil
			end
		end
		-- self.item_panel:clear()
		if alive( row_item.gui_info_panel ) then
			self.safe_rect_panel:remove( row_item.gui_info_panel )
		end
		
		if alive( row_item.icon ) then
			row_item.icon:parent():remove( row_item.icon )
		end
		self.row_items[ i ] = nil
	end
	-- self.item_panel:clear()
	self.row_items = {}
end

function NodeGui:close()
	Overlay:gui():destroy_workspace( self.ws )
	self.ws		= nil
end

function NodeGui:layer()
	return self.layers.last
end

function NodeGui:set_visible( visible )
	-- print( "set_visible", visible, self.name )
	-- Application:stack_dump()
	if visible then
		self.ws:show()
	else
		self.ws:hide()
	end
end

function NodeGui:reload_item( item )
	local type = item:type()
	
	-- Is standard item
	if type == "" then
		self:_reload_item( item )
	end
	
	-- If toggle item, change toggle text
	if type == "toggle" then -- Moved to CoreMenuItemToggle
		-- self:_reload_toggle_item( item )
	end
	
	-- If slider item, change slider text
	if type == "slider" then -- Moved to CoreMenuItemSlider
		-- self:_reload_slider_item( item )
	end
end

function NodeGui:_reload_item( item )
	local row_item = self:row_item( item )
	local params = item:parameters()
	if params.text_id then
		if self.localize_strings and params.localize ~= "false" then
			item_text = managers.localization:text( params.text_id )
		else
			item_text = params.text_id
		end
	end
	if row_item then
		row_item.text = item_text
		if row_item.gui_panel.set_text then
			row_item.gui_panel:set_text( row_item.to_upper and utf8.to_upper( row_item.text ) or row_item.text )
			row_item.gui_panel:set_color(row_item.color)
		end
	end
end

--[[function NodeGui:_reload_toggle_item( item )
	local row_item = self:row_item( item )
	if self.localize_strings and item:selected_option():parameters().localize ~= "false" then 
		row_item.option_text = managers.localization:text( item:selected_option():parameters().text_id )
	else
		row_item.option_text = item:selected_option():parameters().text_id
	end
	row_item.gui_panel:set_text( row_item.text .. ": " .. row_item.option_text )
end]]

--[[function NodeGui:_reload_slider_item( item )
	local row_item = self:row_item( item )
	local value = string.format( "%.0f", item:percentage() )
	row_item.gui_panel:set_text( row_item.text .. ": " .. value .. "%" )
end]]

function NodeGui:_create_menu_item( row_item )
	--[[if row_item.gui_panel then
		self.item_panel:remove( row_item.gui_panel )
	end
	row_item.gui_panel = self.item_panel:text( {
												font_size = self.font_size,
												x = row_item.position.x, y = 0,
												align="left", halign="left", vertical="center",
												font = row_item.font,
												color = row_item.color,
												layer = self.layers.items,
												text = row_item.text,
												render_template = Idstring("VertexColorTextured")
											} )
	row_item.gui_panel:set_render_template( Idstring("VertexColorTextured") )
	row_item.gui_panel:set_text( row_item.text )
	local x,y,w,h = row_item.gui_panel:text_rect()
	row_item.gui_panel:set_height( h )
	
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_panel:set_width( safe_rect.width/2 )
		
	self:_align_normal( row_item )]]
end

--[[function NodeGui:_current_offset( safe_rect )
	return self.item_panel:world_y() - safe_rect.y
end]]

function NodeGui:_reposition_items( highlighted_row_item )
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local dy = 0

	if highlighted_row_item then
		if highlighted_row_item.item:parameters().back or highlighted_row_item.item:parameters().pd2_corner then
			return
		end
			
		-- local current_offset = self:_current_offset( safe_rect, highlighted_row_item )
		-- local current_offset = self.item_panel:world_y() - safe_rect.y - highlighted_row_item.gui_panel:h()
		-- local current_offset = self.item_panel:y() - safe_rect.y
		-- local item_y = current_offset + highlighted_row_item.position.y
		
		-- if item_y < 0 then
		local first = self.row_items[1].gui_panel == highlighted_row_item.gui_panel
				
		local last = (self.row_items[ #self.row_items ].item:parameters().back or self.row_items[ #self.row_items ].item:parameters().pd2_corner) and self.row_items[ #self.row_items-1 ] or self.row_items[ #self.row_items ]
		last = last.gui_panel == highlighted_row_item.gui_panel
		
		local h = highlighted_row_item.item:get_h( highlighted_row_item, self ) or highlighted_row_item.gui_panel:h()
		local offset = (first or last )and 0 or h
		
		if self._item_panel_parent:world_y() > highlighted_row_item.gui_panel:world_y() - offset then
			-- dy = -item_y
			dy = -( highlighted_row_item.gui_panel:world_y() - self._item_panel_parent:world_y() - offset )
		-- elseif item_y + self.font_size > self.height then
		elseif self._item_panel_parent:world_y() + self._item_panel_parent:h() < highlighted_row_item.gui_panel:world_y() + highlighted_row_item.gui_panel:h() + offset then
			-- dy = -( item_y + self.font_size - self.height )
			dy = -( highlighted_row_item.gui_panel:world_y() + highlighted_row_item.gui_panel:h()  - (self._item_panel_parent:world_y() + self._item_panel_parent:h()) + offset )
		end
		
		-- More intuitive scrolling by using old scroll value if same direction and still within view:
		local old_dy = self._scroll_data.dy_left
		local is_same_dir = ( math.abs( old_dy ) > 0 ) and ( ( math.sign( dy ) == math.sign( old_dy ) ) or ( dy == 0 ) )

		if( is_same_dir ) then
			-- local within_view = math.within( highlighted_row_item.position.y, -current_offset - old_dy, -current_offset - old_dy + self.height - self.font_size )
			local within_view = math.within( highlighted_row_item.gui_panel:world_y(), self._item_panel_parent:world_y(), self._item_panel_parent:world_y() + self._item_panel_parent:h() )

			if( within_view ) then
				dy = math.max( math.abs( old_dy ), math.abs( dy ) ) * math.sign( old_dy )
			end
		end
	end

	self:scroll_start( dy )
end

function NodeGui:scroll_setup()
	self._scroll_data = {}
	self._scroll_data.max_scroll_duration = 0.5	-- Seconds
	self._scroll_data.scroll_speed = ( self.font_size + self.spacing * 2 ) / 0.1		-- Pixels / second
	self._scroll_data.dy_total = 0
	self._scroll_data.dy_left  = 0
end

function NodeGui:scroll_start( dy )
	local speed = self._scroll_data.scroll_speed

	if( ( speed > 0 ) and ( math.abs( dy / speed ) > self._scroll_data.max_scroll_duration ) ) then
		speed = math.abs( dy ) / self._scroll_data.max_scroll_duration
	end

	self._scroll_data.speed = speed
	self._scroll_data.dy_total = dy
	self._scroll_data.dy_left = dy
	
	self:scroll_update( TimerManager:main():delta_time() )
end

function NodeGui:scroll_update( dt )
	local dy_left = self._scroll_data.dy_left
	if( dy_left ~= 0 ) then
		local speed = self._scroll_data.speed
		local dy

		if( speed <= 0 ) then
			dy = dy_left
		else
			dy = math.lerp( 0, dy_left, math.clamp( math.sign( dy_left ) * speed * dt / dy_left, 0, 1 ) )
		end
		self._scroll_data.dy_left = self._scroll_data.dy_left - dy

		if self._item_panel_y and self._item_panel_y.target then
			self._item_panel_y.target = self._item_panel_y.target + dy
			self.item_panel:move( 0, dy )
		else
			self.item_panel:move( 0, dy )
		end
		return true
	end
end

function NodeGui:wheel_scroll_start( dy )
	local speed = 30
	-- if self._item_panel_parent:world_y() < self.item_panel:world_y() then
	-- if dy < 0 and math.round( self.item_panel:world_y() ) - self._item_panel_parent:world_y() >= 0 then
	if dy > 0 then
		local dist = self.item_panel:world_y() - self._item_panel_parent:world_y()
		if not ( math.round( self.item_panel:world_y() ) - self._item_panel_parent:world_y() < 0 ) then
			return
		end
		speed = math.min( speed, math.abs(dist) ) 
	else
		local dist = self.item_panel:world_bottom() - self._item_panel_parent:world_bottom()
		if ( math.round( self.item_panel:world_bottom() ) - self._item_panel_parent:world_bottom() < 4 ) then
			return
		end
		speed = math.min( speed, math.abs(dist) )
	end
	-- print( speed )
	self:scroll_start( speed * dy )
end

function NodeGui:highlight_item( item, mouse_over )
	if not item then
		return
	end
	local item_name = item:parameters().name
	local row_item	= self:row_item( item )
	self:_highlight_row_item( row_item, mouse_over )
	self:_reposition_items( row_item )
	self._highlighted_item = item
end

function NodeGui:_highlight_row_item( row_item, mouse_over )
	if row_item then		
		row_item.highlighted = true
		row_item.color = row_item.item:enabled() and (row_item.hightlight_color or self.row_item_hightlight_color) or row_item.disabled_color -- Color( 1, 1, 1, 1 )
		row_item.gui_panel:set_color( row_item.color )
	end
end

function NodeGui:fade_item( item )
	local item_name = item:parameters().name
	local row_item	= self:row_item( item )
	self:_fade_row_item( row_item )
end

function NodeGui:_fade_row_item( row_item )
	if row_item then
		row_item.highlighted = false
		row_item.color	= row_item.item:enabled() and (row_item.row_item_color or self.row_item_color) or row_item.disabled_color
		row_item.gui_panel:set_color( row_item.color )
	end
end

function NodeGui:row_item( item )
	local item_name = item:parameters().name
	for _,row_item in ipairs( self.row_items ) do
		if row_item.name == item_name then
			return row_item
		end
	end
	return nil
end

function NodeGui:row_item_by_name( item_name )
	for _,row_item in ipairs( self.row_items ) do
		if row_item.name == item_name then
			return row_item
		end
	end
	return nil
end

function NodeGui:update( t, dt )
	local scrolled = self:scroll_update( dt )
	-- print( "scrolled", scrolled )
	if self._item_panel_y and not scrolled then
		if self._item_panel_y.target and self.item_panel:center_y() ~= self._item_panel_y.target then 
			-- print( self.item_panel:center_y(), self._item_panel_y.current )
			-- set_center_y( self._item_panel_y.current )
			self._item_panel_y.current = math.lerp( self.item_panel:center_y(), self._item_panel_y.target, dt * 10 )
			-- if self.item_panel:h() < self._item_panel_parent:h() then
				self.item_panel:set_center_y( self._item_panel_y.current )
				-- print( "set_center_y" )
			-- end
			
			self:_set_topic_position()
		end
	elseif scrolled and self._item_panel_y then
		if self._item_panel_y.target and self.item_panel:center_y() ~= self._item_panel_y.target then
			self._item_panel_y.current = math.lerp( self.item_panel:center_y(), self._item_panel_y.target, dt * 10 )
		end
		self:_set_topic_position()
	end
end

function NodeGui:_item_panel_height()
	local height = 0 -- 24 -- HERE and HERE
	for _,row_item in pairs( self.row_items ) do
		if not row_item.item:parameters().back and not row_item.item:parameters().pd2_corner then
			local x,y,w,h = row_item.gui_panel:shape()
			height = height + h + self.spacing
		end
	end
	return height
end

function NodeGui:_set_item_positions()
	local total_height = self:_item_panel_height()
	local current_y = 0 -- 24 -- HERE and HERE
	local current_item_height = 0
	local scaled_size = managers.gui_data:scaled_size()
	
	for _,row_item in pairs( self.row_items ) do
		if not row_item.item:parameters().back then
			row_item.position.y = current_y
			row_item.gui_panel:set_y( row_item.position.y )
			
			row_item.menu_unselected:set_left( self:_mid_align() + (row_item.item:parameters().expand_value or 0) )
			row_item.menu_unselected:set_h( 64 * row_item.gui_panel:h()/32 )
			row_item.menu_unselected:set_center_y( row_item.gui_panel:center_y() )
			row_item.menu_unselected:set_w( scaled_size.width - row_item.menu_unselected:x() )
			
			if row_item.current_of_total then
				row_item.current_of_total:set_w( 200 )
				row_item.current_of_total:set_center_y( row_item.menu_unselected:center_y() )
				row_item.current_of_total:set_right( row_item.menu_unselected:right() - self._align_line_padding )
			end
			
			row_item.item:on_item_position( row_item, self )
					

			if alive( row_item.icon ) then
				row_item.icon:set_left( row_item.gui_panel:right() )
				row_item.icon:set_center_y( row_item.gui_panel:center_y() )
				row_item.icon:set_color( row_item.gui_panel:color() )
			end
			local x,y,w,h = row_item.gui_panel:shape()
			current_item_height = h + self.spacing
			current_y = current_y + current_item_height
		end
	end
	
	for _,row_item in pairs( self.row_items ) do
		if not row_item.item:parameters().back and not row_item.item:parameters().pd2_corner then
			row_item.item:on_item_positions_done( row_item, self )
		end
	end
end

function NodeGui:resolution_changed()
	self:_setup_size()
	
	self:_set_item_positions()

	self:highlight_item( self._highlighted_item )
end

function NodeGui:_setup_item_panel_parent( safe_rect )
	self._item_panel_parent:set_shape( safe_rect.x, safe_rect.y, safe_rect.width, safe_rect.height )
end

function NodeGui:_set_width_and_height( safe_rect )
	self.width = safe_rect.width
	self.height = safe_rect.height
end

function NodeGui:_setup_item_panel( safe_rect, res )
	local item_panel_offset = safe_rect.height * 0.5 - #self.row_items * 0.5 * ( self.font_size + self.spacing )

	if( item_panel_offset < 0 ) then
		item_panel_offset = 0
	end
	
	-- self._item_panel_y = self._item_panel_y or { current = item_panel_offset }
	-- self._item_panel_y.target = item_panel_offset
	-- self._item_panel_y = self._item_panel_y or {}
	
	-- self.item_panel:set_shape( safe_rect.x, safe_rect.y + item_panel_offset, safe_rect.width, self:_item_panel_height() )
	self.item_panel:set_shape( 0, 0 + item_panel_offset, safe_rect.width, self:_item_panel_height() )
	-- self.item_panel:set_shape( 0, 0 + self._item_panel_y.current, safe_rect.width, self:_item_panel_height() )
-- 	self.item_panel:set_center_y( self._item_panel_parent:h()/2 )
	self.item_panel:set_w( safe_rect.width )
end

function NodeGui:_scaled_size()
	return managers.gui_data:scaled_size()
end

function NodeGui:_setup_size()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local scaled_size = managers.gui_data:scaled_size() -- self:_scaled_size()
	local res = RenderSettings.resolution
	
	managers.gui_data:layout_workspace( self.ws )

	self:_setup_item_panel_parent( scaled_size )
	self:_set_width_and_height( scaled_size )
	self:_setup_item_panel( scaled_size, res )
	--[[local item_panel_offset = safe_rect.height * 0.5 - #self.row_items * 0.5 * ( self.font_size + self.spacing )

	if( item_panel_offset < 0 ) then
		item_panel_offset = 0
	end
		
	-- self.item_panel:set_shape( safe_rect.x, safe_rect.y + item_panel_offset, safe_rect.width, self:_item_panel_height() )
	self.item_panel:set_shape( 0, 0 + item_panel_offset, safe_rect.width, self:_item_panel_height() )
	self.item_panel:set_w( safe_rect.width )]]
	
	if self.texture then
		self.texture:set_width( res.x )
		self.texture:set_height( res.x / 2 )
		self.texture:set_center_x( safe_rect.x + safe_rect.width/2 )
		self.texture:set_center_y( safe_rect.y + safe_rect.height/2 )
	end
		
	self.safe_rect_panel:set_shape( scaled_size.x, scaled_size.y, scaled_size.width, scaled_size.height ) -- self:_item_panel_height() )
	for _,row_item in pairs( self.row_items ) do
		if row_item.item:parameters().back then
			-- TEST FOR BUTTON BACK
			-- row_item.gui_panel:set_w( 16 )
			-- row_item.gui_panel:set_h( math.min( self.item_panel:h(), self._item_panel_parent:h() ) )
			row_item.gui_panel:set_w( 24 )
			row_item.gui_panel:set_h( 24 )
			row_item.gui_panel:set_right( self:_mid_align() )
			row_item.unselected:set_h( 64 * row_item.gui_panel:h()/32 )
			row_item.unselected:set_center_y( row_item.gui_panel:h()/2 )
			row_item.selected:set_shape( row_item.unselected:shape() )
			row_item.shadow:set_w( row_item.gui_panel:w() )
			row_item.shadow_bottom:set_bottom( row_item.gui_panel:h() )
			row_item.shadow_bottom:set_w( row_item.gui_panel:w() )
			
			row_item.arrow_selected:set_size( row_item.gui_panel:w(), row_item.gui_panel:h() ) 
			row_item.arrow_unselected:set_size( row_item.gui_panel:w(), row_item.gui_panel:h() )
			
			--[[row_item.gui_panel:set_font_size( self.font_size )
			local x,y,w,h = row_item.gui_panel:text_rect()
			local pad = 32
			row_item.gui_panel:set_h( h )
			row_item.gui_panel:set_w( 150 )
			row_item.gui_panel:set_rightbottom( self.safe_rect_panel:w() - 10 * _G[ "tweak_data" ].scale.align_line_padding_multiplier, self.safe_rect_panel:h() )
			row_item.gui_panel:set_top( self.safe_rect_panel:h() - _G[ "tweak_data" ].load_level.upper_saferect_border + _G[ "tweak_data" ].load_level.border_pad - pad )
			]]
			
			-- row_item.gui_panel:set_top( self.safe_rect_panel:h() - _G[ "tweak_data" ].load_level.upper_saferect_border + _G[ "tweak_data" ].load_level.border_pad - pad )
			-- row_item.gui_panel:set_top( self.safe_rect_panel:h() - CoreMenuRenderer.Renderer.border_height )
			break
		end
		self:_setup_item_size( row_item ) 
	end
end

function NodeGui:_setup_item_size( row_item )
end

function NodeGui:mouse_pressed( button, x, y )
	if self.item_panel:inside( x, y ) and self._item_panel_parent:inside( x, y ) and x > self:_mid_align() then
		if button == Idstring( "mouse wheel down" ) then
			self:wheel_scroll_start( -1 )
			return true
		elseif button == Idstring( "mouse wheel up" ) then
			self:wheel_scroll_start( 1 )
			return true
		end
	end
end
