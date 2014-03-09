core:import( "CoreEngineAccess" )
core:import( "CoreEditorUtils" )

EditGui = EditGui or class()

function EditGui:init( parent, toolbar, btn, name )
	self._panel = EWS:Panel( parent, "", "TAB_TRAVERSAL")
	self._main_sizer = EWS:StaticBoxSizer( self._panel, "HORIZONTAL", name )
	self._panel:set_sizer( self._main_sizer )
	self._toolbar = toolbar
	
	self._btn = btn
	
	self._ctrls = {}
	
	self._ctrls.unit = nil
		
	self:set_visible( false )
end

function EditGui:has( unit )
	if alive( unit ) then
		
	else
		self:disable()
		return false
	end
end

function EditGui:disable()
	self._ctrls.unit = nil
	self._toolbar:set_tool_enabled( self._btn, false )
	self._toolbar:set_tool_state( self._btn, false )
	self:set_visible( false )
end

function EditGui:set_visible( vis )
	self._visible = vis
	self._panel:set_visible( vis )
	self._panel:layout()
end

function EditGui:visible()
	return self._visible
end

function EditGui:get_panel()
	return self._panel
end

--[[EditLight = EditLight or class( EditGui )

function EditLight:init( parent, toolbar, btn )
	EditGui.init( self, parent, toolbar, btn, "Edit Light" )
	
	local v_sizer = EWS:BoxSizer( "VERTICAL" )
	
		local h_sizer = EWS:BoxSizer( "HORIZONTAL" )
		
			local lights_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Lights")
				local lights = EWS:ComboBox( self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
				lights:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "change_light" ), lights )
				lights_sizer:add( lights, 1, 0, "EXPAND")
				
				local enabled = EWS:CheckBox( self._panel, "Enabled", "" )
				enabled:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "update_light_ctrl" ), enabled )
				lights_sizer:add( enabled, 0, 5, "EXPAND,TOP" )
				
			h_sizer:add( lights_sizer, 0, 0, "ALIGN_LEFT")
				
			local ctrl_sizer = EWS:BoxSizer( "VERTICAL" )
				
				local color_button = EWS:Button( self._panel, "Color", "", "BU_EXACTFIT,NO_BORDER" )
					color_button:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "show_color_dialog" ), "" )
				ctrl_sizer:add( color_button, 0, 0, "EXPAND")
				
				local range_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Range [cm]")
					local far_range = EWS:SpinCtrl( self._panel, 0, "", "" )
					far_range:set_range( 0, 50000 )
					far_range:connect( "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_light_ctrl" ), far_range )
					far_range:connect( "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "update_light_ctrl" ), far_range )
					range_sizer:add( far_range, 0, 0, "EXPAND" )
				ctrl_sizer:add( range_sizer, 0, 0, "EXPAND" )
											
			h_sizer:add( ctrl_sizer, 0, 5, "ALIGN_LEFT,LEFT" )
			
		v_sizer:add( h_sizer, 0, 5, "ALIGN_LEFT,LEFT" )

		local intensity_sizer = EWS:BoxSizer( "HORIZONTAL" )
		
			intensity_sizer:add( EWS:StaticText( self._panel, "Intensity:", 0, "" ), 1, 0, "ALIGN_CENTER_VERTICAL" )
					
			local intensities = EWS:ComboBox( self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
				for _,intensity in ipairs( LightIntensityDB:list() ) do
					intensities:append( intensity:s() )
				end
				intensities:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "update_light_ctrl" ), intensities )
			intensity_sizer:add( intensities, 2, 0, "EXPAND" )
							
		v_sizer:add( intensity_sizer, 0, 0, "EXPAND" )
		
		self._falloff_params = {
			name 				= "Falloff:",
			panel 				= self._panel,
			sizer 				= v_sizer,
			value 				= 1,
			floats 				= 1,
			tooltip 			= "Controls the light falloff exponent",
			min 				= 1,
			max					= 10,
			name_proportions 	= 1,
			ctrlr_proportions 	= 0
		}
		CoreEWS.slider_and_number_controller( self._falloff_params )
		
		self._falloff_params.slider_ctrlr:connect( "EVT_SCROLL_CHANGED", callback( self, self, "update_light_ctrl" ), self._falloff_params )
		self._falloff_params.slider_ctrlr:connect( "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_light_ctrl" ), self._falloff_params )
		
		self._falloff_params.number_ctrlr:connect( "EVT_COMMAND_TEXT_ENTER", callback( self, self, "update_light_ctrl" ), self._falloff_params )
		self._falloff_params.number_ctrlr:connect( "EVT_KILL_FOCUS", callback( self, self, "update_light_ctrl" ), self._falloff_params )
				
	self._main_sizer:add( v_sizer, 0, 5, "ALIGN_LEFT,LEFT" )
	
	local angles_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Start/End Angle")
		
		local start_angle = EWS:Slider( self._panel, 1, 1, 179, "", "SL_LABELS")
			start_angle:connect( "EVT_SCROLL_CHANGED", callback( self, self, "update_light_ctrl" ), start_angle )
			start_angle:connect( "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_light_ctrl" ), start_angle )
		angles_sizer:add( start_angle, 0, 0, "EXPAND" )
		
		local end_angle = EWS:Slider( self._panel, 1, 1, 179, "", "SL_LABELS")
			end_angle:connect( "EVT_SCROLL_CHANGED", callback( self, self, "update_light_ctrl" ), end_angle )
			end_angle:connect( "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_light_ctrl" ), end_angle )
		angles_sizer:add( end_angle, 0, 0, "EXPAND" )
	
	self._main_sizer:add( angles_sizer, 0, 5, "ALIGN_LEFT,LEFT" )
		
	self._ctrls.lights = lights
	self._ctrls.enabled = enabled
	self._ctrls.color_button = color_button
	self._ctrls.far_range = far_range
	self._ctrls.intensities = intensities
	self._ctrls.start_angle = start_angle
	self._ctrls.end_angle = end_angle
		
	return self._panel
end

function EditLight:change_light()
	if alive( self._ctrls.unit ) then
		local light = self._ctrls.unit:get_object( Idstring( self._ctrls.lights:get_value() ) )
		self:update_light_ctrls_from_light( light )
	end
end

function EditLight:update_light_ctrls_from_light( light )
	self._ctrls.lights:set_value( light:name():s() )
	self._ctrls.enabled:set_value( light:enable() )
	self._ctrls.color_button:set_background_colour( light:color().x*255, light:color().y*255, light:color().z*255 )
	local intensity = CoreEditorUtils.get_intensity_preset( light:multiplier() )
	light:set_multiplier( LightIntensityDB:lookup( intensity ) )
	light:set_specular_multiplier( LightIntensityDB:lookup_specular_multiplier( intensity ) )
	self._ctrls.intensities:set_value( intensity:s() )
	CoreEWS.change_slider_and_number_value( self._falloff_params, light:falloff_exponent() )
	
	self._ctrls.start_angle:set_value( light:spot_angle_start() )
	self._ctrls.end_angle:set_value( light:spot_angle_end() )
	if string.match( light:properties(), "omni" ) then
		self._ctrls.start_angle:set_enabled( false )
		self._ctrls.end_angle:set_enabled( false )
	else
		self._ctrls.start_angle:set_enabled( true )
		self._ctrls.end_angle:set_enabled( true )
	end
	self._ctrls.far_range:set_value( light:far_range() ) -- This will cause an event, needs to be last!
end

function EditLight:update_light_ctrl( ctrlr )
	if self._no_event then
		return
	end
	
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) then
			local light = unit:get_object( Idstring( self._ctrls.lights:get_value() ) )
			if light then
				if ctrlr == self._ctrls.far_range then
					light:set_far_range( self._ctrls.far_range:get_value() )
				elseif ctrlr == self._ctrls.enabled then
					light:set_enable( self._ctrls.enabled:get_value() )
				elseif ctrlr == self._ctrls.color_button then
					light:set_color( self._ctrls.color_button:background_colour() / 255 )
				elseif ctrlr == self._ctrls.intensities then
					light:set_multiplier( LightIntensityDB:lookup( Idstring( self._ctrls.intensities:get_value() ) ) )
					light:set_specular_multiplier( LightIntensityDB:lookup_specular_multiplier( Idstring( self._ctrls.intensities:get_value() ) ) )
				elseif ctrlr == self._falloff_params then
					light:set_falloff_exponent( self._falloff_params.value )
				elseif ctrlr == self._ctrls.start_angle then
					light:set_spot_angle_start( self._ctrls.start_angle:get_value() )
				elseif ctrlr == self._ctrls.end_angle then
					light:set_spot_angle_end( self._ctrls.end_angle:get_value() )
				end
			end
		end
	end
end

function EditLight:show_color_dialog()
	local colordlg = EWS:ColourDialog( Global.frame, true, self._ctrls.color_button:background_colour() / 255 )
	if colordlg:show_modal() then
		self._ctrls.color_button:set_background_colour( colordlg:get_colour().x*255, colordlg:get_colour().y*255, colordlg:get_colour().z*255 )
		self:update_light_ctrl( self._ctrls.color_button )
	end
end

function EditLight:has_lights( unit, units )
	if alive( unit ) then
		local lights = CoreEditorUtils.get_editable_lights( unit )
		
		self._ctrls.lights:clear()
		for _,light in ipairs( lights ) do
			self._ctrls.lights:append( light:name():s() )
		end
		if lights[ 1 ] then
			self._ctrls.unit = unit
			self._ctrls.units = units
			self._no_event = true
			self:update_light_ctrls_from_light( lights[ 1 ] )
			self._no_event = false
			self._toolbar:set_tool_enabled( self._btn, true )
			return true
		else
			self:disable()
			return false
		end
	else
		self:disable()
		return false
	end
end]]

--[[
EditVariation = EditVariation or class( EditGui )

function EditVariation:init( parent, toolbar, btn )
	EditGui.init( self, parent, toolbar, btn, "Edit Variation" )
		
	local all_variations_sizer = EWS:BoxSizer( "VERTICAL" )
		
		local variations_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Mesh" )
			local variations = EWS:ComboBox( self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
			variations:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "change_variation" ), variations )
			variations_sizer:add( variations, 1, 0, "EXPAND")
		all_variations_sizer:add( variations_sizer, 0, 0, "EXPAND")
		
		local materials_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Material" )
			local materials = EWS:ComboBox( self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
			materials:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "change_material" ), materials )
			materials_sizer:add( materials, 1, 0, "EXPAND")
		all_variations_sizer:add( materials_sizer, 0, 0, "EXPAND")
	
	self._main_sizer:add( all_variations_sizer, 0, 0, "ALIGN_LEFT")
	
	self._ctrls.variations = variations
	self._ctrls.materials = materials
	
	self._avalible_material_groups = {}
		
	return self._panel
end

function EditVariation:change_variation()
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) then
			local variation = self._ctrls.variations:get_value()
			local reset = managers.sequence:get_reset_editable_state_sequence_list( unit:name() )[ 1 ]
			if reset then
				managers.sequence:run_sequence_simple2( reset, "change_state", unit )
			end
			
			local variations = managers.sequence:get_editable_state_sequence_list( unit:name() )
			if #variations > 0 then -- Skip units without any variations
				if variation == "default" then -- If variation is default, we only need to set the unit data.
					unit:unit_data().mesh_variation = "default"
				else
					-- Check if the unit actually has that variation we want to set, skip if not.
					if table.contains( variations, variation ) then
						managers.sequence:run_sequence_simple2( variation, "change_state", unit )
						unit:unit_data().mesh_variation = variation
					end
				end
			end
		end
	end
end

function EditVariation:change_material()
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) then
			local material = self._ctrls.materials:get_value()
			
			local materials = self:get_material_configs_from_meta( unit:name() )
			if table.contains( materials, material ) then			
				if material ~= "default" then
					-- self._ctrls.unit:set_material_config( material, true )
					unit:set_material_config( Idstring( material ), true )
				else
					-- put on default material
				end
				-- self._ctrls.unit:unit_data().material = material
				unit:unit_data().material = material
			end
		end
	end
end

function EditVariation:has_variation( unit, units )
	if alive( unit ) then
		local variations = managers.sequence:get_editable_state_sequence_list( unit:name() )
		local materials = self:get_material_configs_from_meta( unit:name() )
				
		if #variations > 0 or #materials > 0 then
			self._ctrls.unit = unit
			self._ctrls.units = units
			
			self._ctrls.variations:clear()
			self._ctrls.variations:append( "default" )
			for _,variation in ipairs( variations ) do
				self._ctrls.variations:append( variation )
			end
			self._ctrls.variations:set_value( self._ctrls.unit:unit_data().mesh_variation )
			self._ctrls.variations:set_enabled( #variations > 0 )
						
			self._ctrls.materials:clear()
			self._ctrls.materials:append( "default" )
			for _,material in ipairs( materials ) do
				self._ctrls.materials:append( material )
			end
			self._ctrls.materials:set_value( self._ctrls.unit:unit_data().material )
			self._ctrls.materials:set_enabled( #materials > 0 )

			self._toolbar:set_tool_enabled( self._btn, true )
			return true		
		else
			self:disable()
			return false
		end
	else
		self:disable()
		return false
	end
end

function EditVariation:get_material_configs_from_meta( unit_name )
	self._avalible_material_groups = self._avalible_material_groups or {}
	if self._avalible_material_groups[ unit_name:key() ] then
		return self._avalible_material_groups[ unit_name:key() ]
	end
	
	local node = CoreEngineAccess._editor_unit_data( unit_name:id() ):model_script_data()
	local available_groups = {}
	local groups = {}
	
	for child in node:children() do
		if child:name() == "metadata" and child:parameter("material_config_group") ~= "" then
			table.insert(groups, child:parameter("material_config_group"))
		end
	end
	
	if #groups > 0 then
		for _,entry in ipairs( managers.database:list_entries_of_type("material_config") ) do -- Expensive if done on several units over one frame
			local node = DB:load_node("material_config", entry)
			for _,group in ipairs(groups) do
				local group_name = node:has_parameter("group") and node:parameter("group")
				if group_name == group and not table.contains( available_groups, entry ) then
					table.insert( available_groups, entry )
				end
			end
		end
	end
		
	self._avalible_material_groups[ unit_name:key() ] = available_groups
	return available_groups
end]]

--[[EditTriggable = EditTriggable or class( EditGui )

function EditTriggable:init( parent, toolbar, btn )
	EditGui.init( self, parent, toolbar, btn, "Edit Trigger Sequences" )
	
	self._element_guis = {}
	
	local triggers_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Triggers" )
		local triggers = EWS:ComboBox( self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
		triggers:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "change_triggers" ), triggers )
		triggers_sizer:add( triggers, 1, 0, "EXPAND")
		
		self._btn_toolbar = EWS:ToolBar( self._panel, "", "TB_FLAT,TB_NODIVIDER" )
		
			self._btn_toolbar:add_check_tool( "ADD_UNIT", "Add unit by selecting in world", CoreEWS.image_path( "world_editor\\add_unit.png" ), nil )
			self._btn_toolbar:connect( "ADD_UNIT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "add_unit_btn" ), nil )

			self._btn_toolbar:add_tool( "ADD_UNIT_LIST", "Add unit from unit list", CoreEWS.image_path( "world_editor\\unit_by_name_list.png" ), nil )
			self._btn_toolbar:connect( "ADD_UNIT_LIST", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "add_unit_list_btn" ), nil )
				
		self._btn_toolbar:realize()
		
		triggers_sizer:add( self._btn_toolbar, 0, 1, "ALIGN_RIGHT,BOTTOM" )
				
	self._main_sizer:add( triggers_sizer, 0, 0, "ALIGN_RIGHT")
			
	self._main_sizer:add( self:build_scrolled_window(), 1, 0, "EXPAND")
		
	self._ctrls.triggers = triggers
	
	self:set_visible( false )
	
	return self._panel
end

function EditTriggable:build_scrolled_window()
	self._scrolled_window = EWS:ScrolledWindow( self._panel, "", "VSCROLL")
	self._scrolled_window:set_scroll_rate( Vector3( 0, 1, 0 ) )
	self._scrolled_window:set_virtual_size_hints( Vector3( 0, 0, 0 ), Vector3( 1, -1, -1 ) )
	
	self._scrolled_main_sizer = EWS:StaticBoxSizer( self._scrolled_window, "VERTICAL", "Trigger Sequences" )
	self._scrolled_window:set_sizer( self._scrolled_main_sizer )
		
	return self._scrolled_window
end

function EditTriggable:build_element_gui( data )
	local panel = EWS:Panel( self._scrolled_window, "", "TAB_TRAVERSAL")
	local sizer = EWS:BoxSizer( "HORIZONTAL" )
	local id = data.id or 0
	local trigger_name = data.trigger_name or "none"
	local name = Idstring( "none" )
	if data.notify_unit then
		name = data.notify_unit:name()
	end
	local sequences = { "none" }
	if #managers.sequence:get_triggable_sequence_list( name ) > 0 then
		sequences = managers.sequence:get_triggable_sequence_list( name )
	end
	local sequence = data.notify_unit_sequence or "none"
	local t = data.time or "-"
	
	panel:set_sizer( sizer )
		local remove_btn = EWS:Button( panel, "Remove", "", "BU_EXACTFIT,NO_BORDER" )
		sizer:add( remove_btn, 0, 0, "EXPAND")
		
		local name = EWS:TextCtrl( panel, name:s(), "", "TE_CENTRE,TE_READONLY" )
		sizer:add( name, 0, 0, "EXPAND")
		
		local trigger = EWS:ComboBox( panel, "", "", "CB_DROPDOWN,CB_READONLY" )
		for _,name in ipairs( sequences ) do
			trigger:append( name )
		end
		trigger:set_value( sequence )
		sizer:add( trigger, 0, 0, "EXPAND")
		
		local time = EWS:TextCtrl( panel, t, "", "TE_CENTRE" )
		sizer:add( time, 0, 0, "EXPAND")
		
		local ctrls = { id = id, trigger_name = trigger_name, trigger = trigger, time = time }
		remove_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "remove_element" ), ctrls )
		
		trigger:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "change_sequence" ), ctrls )
				
		time:connect( "EVT_CHAR", callback( nil, _G, "verify_number" ), time )
		time:connect( "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "change_time" ), ctrls )
		
		self._scrolled_main_sizer:add( panel, 0, 0, "EXPAND")
		table.insert( self._element_guis, panel )
	return panel
end

function EditTriggable:change_sequence( ctrls )
	self._ctrls.unit:damage():set_trigger_sequence_name( ctrls.id, ctrls.trigger_name, ctrls.trigger:get_value() )
end

function EditTriggable:change_time( ctrls )
	self._ctrls.unit:damage():set_trigger_sequence_time( ctrls.id, ctrls.trigger_name, ctrls.time:get_value() )
end

function EditTriggable:remove_element( ctrls )
	self._ctrls.unit:damage():remove_trigger_func( ctrls.trigger_name, ctrls.id, true )
	self:update_element_gui()
end

function EditTriggable:clear_element_gui()
	self._scrolled_main_sizer:clear()	
	for _,gui in ipairs( self._element_guis ) do
		gui:destroy()
	end
	self._element_guis = {}
end

function EditTriggable:add_unit_btn()
	managers.editor:set_trigger_add_unit( self._btn_toolbar:tool_state( "ADD_UNIT" ) )
end

function EditTriggable:add_unit_list_btn()
	local f = function( unit ) return #managers.sequence:get_triggable_sequence_list( unit:name() ) > 0 end
	local dialog = SelectUnitByNameModal:new( "Add Trigger Unit", f )
	for _,unit in ipairs( dialog:selected_units() ) do
		self:add_unit( unit )
	end
end

function EditTriggable:update_element_gui()
	self:clear_element_gui()
	local trigger_data = self._ctrls.unit:damage():get_editor_trigger_data()
	if trigger_data and #trigger_data > 0 then
		for _,data in ipairs( trigger_data ) do
			if data.trigger_name == self._ctrls.triggers:get_value() then
				self:build_element_gui( data )
			end
		end
	end
	if #self._element_guis == 0 then
		local panel = self:build_element_gui( {} )
		panel:set_enabled( false )
	end
		
	self._scrolled_window:fit_inside()
	managers.editor:layout_edit_panel()
end

function EditTriggable:add_unit( unit )
	local triggable_sequences = managers.sequence:get_triggable_sequence_list( unit:name() )
	if #triggable_sequences > 0 then
		self._ctrls.unit:damage():add_trigger_sequence( self._ctrls.triggers:get_value(), triggable_sequences[ 1 ], unit, 0, nil, nil, true )
		self:update_element_gui()
	end
end

function EditTriggable:change_triggers()
	if alive( self._ctrls.unit ) then
		self:update_element_gui()
	end
end

function EditTriggable:has_triggable( unit )
	if alive( unit ) and unit:damage() then
		local triggers = managers.sequence:get_trigger_list( unit:name() )
		if #triggers > 0 then
			self._ctrls.unit = unit
			self._ctrls.triggers:clear()
			for _,trigger in ipairs( triggers ) do
				self._ctrls.triggers:append( trigger )
			end
			self._ctrls.triggers:set_value( triggers[ 1 ] )
			
			self:update_element_gui()
			self._toolbar:set_tool_enabled( self._btn, true )
			return true
		else
			self:disable()
			return false
		end
	else
		self:disable()
		return false
	end
end

function EditTriggable:set_visible( vis )
	if not vis and self._btn_toolbar then
		self._btn_toolbar:set_tool_state( "ADD_UNIT", false )
		self:add_unit_btn()
	end
	if self._scrolled_window then
		self._scrolled_window:fit_inside()
	end
	EditGui.set_visible( self, vis )
	managers.editor:layout_edit_panel()
end]]

--[[ EditTextGui = EditTextGui or class( EditGui )

function EditTextGui:init( parent, toolbar, btn )
	EditGui.init( self, parent, toolbar, btn, "Edit Text Gui" )
	
	local ctrlrs_sizer = EWS:BoxSizer( "VERTICAL" )
	
		local horizontal_sizer = EWS:BoxSizer( "HORIZONTAL" )
	
			local gui_text_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Gui Text" )
				local gui_text = EWS:TextCtrl( self._panel, "none", "", "TE_RIGHT" )
				gui_text:connect( "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "update_gui_text" ), gui_text )
			gui_text_sizer:add( gui_text, 1, 0, "EXPAND")
		
		horizontal_sizer:add( gui_text_sizer, 0, 0, "ALIGN_LEFT" )
	
			local color_button = EWS:Button( self._panel, "Color", "", "BU_EXACTFIT,NO_BORDER" )
				color_button:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "show_color_dialog" ), "" )
		
		horizontal_sizer:add( color_button, 0, 2, "EXPAND,LEFT")
		
		ctrlrs_sizer:add( horizontal_sizer, 0, 0, "EXPAND")
		
		ctrlrs_sizer:add( EWS:StaticText( self._panel, "Font Size", 0, ""), 0, 2, "ALIGN_CENTER_HORIZONTAL,TOP" )
		
		local font_size = EWS:Slider( self._panel, 1, 1, 100, "", "SL_LABELS")
			font_size:connect( "EVT_SCROLL_CHANGED", callback( self, self, "update_font_size" ), font_size )
			font_size:connect( "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_font_size" ), font_size )
		ctrlrs_sizer:add( font_size, 1, 0, "EXPAND" )
	
	self._main_sizer:add( ctrlrs_sizer, 0, 0, "EXPAND")
		
	self._ctrls.gui_text = gui_text
	self._ctrls.color_button = color_button
	self._ctrls.font_size = font_size
	
	return self._panel
end

function EditTextGui:show_color_dialog()
	local colordlg = EWS:ColourDialog( Global.frame, true, self._ctrls.color_button:background_colour() / 255 )
	if colordlg:show_modal() then
		self._ctrls.color_button:set_background_colour( colordlg:get_colour().x*255, colordlg:get_colour().y*255, colordlg:get_colour().z*255 )
		for _,unit in ipairs( self._ctrls.units ) do
			if alive( unit ) and unit:editable_gui() then
				unit:editable_gui():set_font_color( Vector3( colordlg:get_colour().x, colordlg:get_colour().y, colordlg:get_colour().z ) )
			-- self._ctrls.unit:editable_gui():set_font_color( Vector3( colordlg:get_colour().x, colordlg:get_colour().y, colordlg:get_colour().z ) )
			end
		end
	end
end


function EditTextGui:update_gui_text( gui_text )
	if self._no_event then
		return
	end
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) and unit:editable_gui() then
		--if alive( self._ctrls.unit ) then
			--self._ctrls.unit:editable_gui():set_text( gui_text:get_value() )
			unit:editable_gui():set_text( gui_text:get_value() )
		end
	end
end

function EditTextGui:update_font_size( font_size )
	if self._no_event then
		return
	end
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) and unit:editable_gui() then
	--	if alive( self._ctrls.unit ) then
			unit:editable_gui():set_font_size( font_size:get_value()/10 )
		end
	end
end

function EditTextGui:has_text_gui( unit, units )
	if alive( unit ) then
				
		if unit:editable_gui() then
			self._ctrls.unit = unit
			self._ctrls.units = units
			
			self._no_event = true
			self._ctrls.gui_text:set_value( self._ctrls.unit:editable_gui():text() )
			local font_color = self._ctrls.unit:editable_gui():font_color()
			self._ctrls.color_button:set_background_colour( font_color.x*255, font_color.y*255, font_color.z*255 )
			self._ctrls.font_size:set_value( self._ctrls.unit:editable_gui():font_size()*10 )
			self._no_event = false

			self._toolbar:set_tool_enabled( self._btn, true )
			return true		
		else
			self:disable()
			return false
		end
	else
		self:disable()
		return false
	end

end]]

--[[CoreEditSettings = CoreEditSettings or class( EditGui )

function CoreEditSettings:init( parent, toolbar, btn )
	EditGui.init( self, parent, toolbar, btn, "Edit Settings" )
		
	local horizontal_sizer = EWS:BoxSizer( "HORIZONTAL" )
					
		local settings_sizer = EWS:StaticBoxSizer( self._panel, "VERTICAL", "Core" )
						
			local cutscene_actor_sizer = EWS:BoxSizer( "HORIZONTAL" )
			
				cutscene_actor_sizer:add( EWS:StaticText( self._panel, "Cutscene Actor:", 0, "" ), 1, 0, "ALIGN_CENTER_VERTICAL" )
				
				local cutscene_actor_name = EWS:StaticText( self._panel, "", 0, "ALIGN_CENTRE,ST_NO_AUTORESIZE" )
				cutscene_actor_sizer:add( cutscene_actor_name, 2, 0, "ALIGN_CENTER_VERTICAL" )
			
				local cutscene_toolbar = EWS:ToolBar( self._panel, "", "TB_FLAT,TB_NODIVIDER" )
			
					cutscene_toolbar:add_tool( "US_ADD_CUTSCENE_ACTOR", "Add this unit as an actor.", CoreEWS.image_path( "plus_16x16.png" ), "Add this unit as an actor." )
					cutscene_toolbar:connect( "US_ADD_CUTSCENE_ACTOR", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "add_cutscene_actor" ), nil )
				
					cutscene_toolbar:add_tool( "US_REMOVE_CUTSCENE_ACTOR", "Remove this unit as an actor.", CoreEWS.image_path( "toolbar\\delete_16x16.png" ), "Add this unit as an actor." )
					cutscene_toolbar:connect( "US_REMOVE_CUTSCENE_ACTOR", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "remove_cutscene_actor" ), nil )
				
					cutscene_toolbar:realize()

				cutscene_actor_sizer:add( cutscene_toolbar, 0, 0, "EXPAND" )
			
			settings_sizer:add( cutscene_actor_sizer, 0, 5, "EXPAND,BOTTOM" )
			
			local disable_shadows = EWS:CheckBox( self._panel, "Disable Shadows", "" )
			disable_shadows:connect( "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "set_disable_shadows" ), nil )
			settings_sizer:add( disable_shadows, 1, 5, "EXPAND,BOTTOM" )
							
		horizontal_sizer:add( settings_sizer, 0, 0, "ALIGN_LEFT")
								
	self._main_sizer:add( horizontal_sizer, 1, 0, "ALIGN_LEFT,EXPAND")
		
	self._ctrls.cutscene_actor_name = cutscene_actor_name
	self._ctrls.cutscene_actor_toolbar = cutscene_toolbar
	self._ctrls.disable_shadows = disable_shadows
		
	return self._panel
end

function CoreEditSettings:add_cutscene_actor()
	local name = EWS:get_text_from_user( Global.frame_panel, "Enter name for cutscene actor:", "Add cutscene actor", "", Vector3( -1, -1, 0 ), true )
	if name and name ~= "" then
		self._ctrls.unit:unit_data().cutscene_actor = name
		if managers.cutscene:register_cutscene_actor( self._ctrls.unit ) then -- Add to cutscene manager
		-- if true then
			self._ctrls.cutscene_actor_name:set_value( name )
			self._ctrls.cutscene_actor_toolbar:set_tool_enabled( "US_REMOVE_CUTSCENE_ACTOR", true )
		else
			self._ctrls.unit:unit_data().cutscene_actor = nil
			self:add_cutscene_actor()
		end
	end
end

function CoreEditSettings:remove_cutscene_actor()
	managers.cutscene:unregister_cutscene_actor( self._ctrls.unit )
	self._ctrls.unit:unit_data().cutscene_actor = nil
	self._ctrls.cutscene_actor_name:set_value( "" )
end

function CoreEditSettings:set_disable_shadows()
	for _,unit in ipairs( self._ctrls.units ) do
		if alive( unit ) then
			unit:unit_data().disable_shadows = self._ctrls.disable_shadows:get_value()
			unit:set_shadows_disabled( unit:unit_data().disable_shadows )
		end
	end
end

function CoreEditSettings:has_settings( unit, units )
	if alive( unit ) then
		self._ctrls.unit = unit
		self._ctrls.units = units
		self._toolbar:set_tool_enabled( self._btn, true )
		
		self._ctrls.cutscene_actor_name:set_value( self._ctrls.unit:unit_data().cutscene_actor or "" )
		self._ctrls.cutscene_actor_toolbar:set_tool_enabled( "US_REMOVE_CUTSCENE_ACTOR", self._ctrls.unit:unit_data().cutscene_actor )
		
		self._ctrls.disable_shadows:set_value( self._ctrls.unit:unit_data().disable_shadows )
		
		return true
	else
		self:disable()
		return false
	end
end]]
