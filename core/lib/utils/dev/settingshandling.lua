-- The EWSControlSettingSync class is created to bridge EWS controls with different kinds of settings like Skies and Posteffects
EWSControlSettingSync = EWSControlSettingSync or class()

function EWSControlSettingSync:init( ews_frame )
	if ews_frame == nil then
        Application:error( "EWSControlSettingSync:init(): No ews_frame given as argument. Check so you use : to call new." )
	end

	self._controls_map = {}
	self._ews_frame = ews_frame
	self._ending_mark = "-"
	self._unique_id_counter = 0
	self._col = EWS:ColourDialog(self._ews_frame, true, Vector3(1,1,1))
end


function EWSControlSettingSync:get_control( id )
	local control_info = self._controls_map[id]
	if(not control_info) then
		Application:throw_exception('EWSControlSettingSync::get_control_info() control info does not exist for "'..id..'"')
	end
	return control_info["main_control"]
end


function EWSControlSettingSync:set_control_updated_callback( cb ) -- should be in the form self:func(id, value)
	self._control_updated_callback = cb
end

function EWSControlSettingSync:get_unique_id()
	self._unique_id_counter = self._unique_id_counter + 1
	return "_unique_id"..self._unique_id_counter
end


function EWSControlSettingSync:update_setting_box(custom_data, event_object)
	local id = event_object:get_id()
	local res = self._col:show_modal ()

	local control_info = self:get_control_info(id)
	local main_data = control_info[ "main_control" ]

	if res == true then
	    local val = self._col:get_colour()
	    main_data:set_background_colour(val.x*255, val.y*255, val.z*255)

		if(self._control_updated_callback) then
			self._control_updated_callback(id, val)
		end
	end
end




function EWSControlSettingSync:update_setting(custom_data, event_object)
	local id = event_object:get_id()
	local control_info = self:get_control_info(id)
	local value = self:get_ews_control_value(custom_data, control_info)
	-- main control controls the type and data of the setting, therefore we must first let the main control set itself and fix any bad values
	local main_data = control_info[ "main_control" ]
	if(custom_data ~= main_data) then
		-- need to set the main control with the value and see if there are som limits or issues
		self:set_ews_control_value(value, main_data, control_info)
		value = self:get_ews_control_value(main_data, control_info)
	end
	-- when the main control has tuched the value all the others will handle it as good as they can			
	local controls = control_info[ "controls" ]
	if(controls) then
		for _,data in ipairs( controls ) do
			if(data ~= main_data) then
				self:set_ews_control_value(value, data, control_info)
			end
		end
	end
	if(self._control_updated_callback) then
		self._control_updated_callback(id, value)
	end

	-- fix links			
	local links = control_info[ "links" ]
	if(links) then
		for _,link_id in ipairs( links ) do
			if(id ~= link_id) then
				self:set_ews_value(link_id, value)
			end
		end
	end
	
	-- fix syncs
	-- The control is master and all the syncs will be self:slaves(the master will make the slaves obey)
	-- - To avoid getting locked in sync loops, it is better to only sync once and not in set_ews_value...
	local sync_slaves = control_info["sync_less"] -- the self:control(master) should be LESS than the slaves
	if(sync_slaves) then
		for _,slave_id in ipairs( sync_slaves ) do
			if(id ~= slave_id) then
				local slave_value = self:get_ews_value(slave_id)
				if(slave_value <= value) then
					local control_info = self:get_control_info(slave_id)
					if(control_info["sync_step"]) then
						value = value + control_info["sync_step"]
					end
					self:set_ews_value(slave_id, value)
				end
			end
		end
	end
	sync_slaves = control_info["sync_more"] -- the self:control(master) should be MORE than the slaves
	if(sync_slaves) then
		for _,slave_id in ipairs( sync_slaves ) do
			if(id ~= slave_id) then
				local slave_value = self:get_ews_value(slave_id)
				if(slave_value >= value) then
					local control_info = self:get_control_info(slave_id)
					if(control_info["sync_step"]) then
						value = value - control_info["sync_step"]
					end
					self:set_ews_value(slave_id, value)
				end
			end
		end
	end
end

function EWSControlSettingSync:set_ews_vector( id, value )
	self:set_ews_value(id .. "-r", value.x)
	self:set_ews_value(id .. "-g", value.y)
	self:set_ews_value(id .. "-b", value.z)
end

function EWSControlSettingSync:set_ews_vector2( id, value )
	self:set_ews_value(id .. "-r", value.x)
	self:set_ews_value(id .. "-g", value.y)
end

function EWSControlSettingSync:set_ews_box( id, value )
	local control_info = self:get_control_info(id .. "-rgb")
	local main_data = control_info[ "main_control" ]

  	main_data:set_background_colour(value.x*255, value.y*255, value.z*255)
end

function EWSControlSettingSync:do_set_ews_value( id, value ) -- I needed to be able to set a value without getting the callback /Martin
	local control_info = self:get_control_info(id)
	local main_data = control_info["main_control"]

	self:set_ews_control_value(value, main_data, control_info)
	local main_value = self:get_ews_control_value(main_data, control_info)

	local controls = control_info["controls"]
	if(controls) then
		for _,data in ipairs( controls ) do
			if(data ~= main_data) then
				self:set_ews_control_value(main_value, data, control_info)
			end
		end
	end
	return main_value
end

function EWSControlSettingSync:set_ews_value( id, value )
	local main_value = self:do_set_ews_value( id, value )
	
	if(self._control_updated_callback) then
		self._control_updated_callback(id, main_value)
	end
end
function EWSControlSettingSync:get_ews_value( id )
	local control_info = self:get_control_info(id)
	local data = control_info["main_control"]
	return self:get_ews_control_value(data, control_info)
end

function EWSControlSettingSync:set_ews_control_value( value, data, control_info )
	local controls_type = control_info["controls_type"]
	if(controls_type) then
		local scales = control_info["controls_scale"]
		if(value and scales and scales[data]) then
			value = tonumber( value ) * scales[data]
		end
		local type = controls_type[data]
		if(type == "list") then
			-- no supported set func in a listbox
		elseif(type == "listctrl") then
			local index = data:get_next_item(index, "LIST_NEXT_ALL", "LIST_STATE_SELECTED")
			local data_map = control_info["listctrl_data"]
			while(index ~= -1) do
				data:set_item(index, 1, value)
				data_map[index]:set(1, value)
				index = data:get_next_item(index, "LIST_NEXT_ALL", "LIST_STATE_SELECTED")
			end
		else
			data:set_value(value)
		end
	else
		Application:throw_exception('EWSControlSettingSync::set_ews_control_value() controls_type was not specified for control_info map')
	end
end
function EWSControlSettingSync:get_ews_control_value( data, control_info )
	local controls_type = control_info["controls_type"]
	local value
	if(controls_type) then
		local type = controls_type[data]
		if(type == "list") then
			local index = data:selected_index()
			if( index > -1 ) then
				value = data:get_string(index)
			end
		elseif(type == "listctrl") then
			local index = data:get_next_item(-1, "LIST_NEXT_ALL", "LIST_STATE_SELECTED")
			if(index ~= -1) then
-- 					value = data:get_item(index, 1) This function does not exist yet... if it will it should be used instead of get and set item data
				local data_map = control_info["listctrl_data"]
				value = data_map[index][1]
			end
		else
			value = data:get_value()
		end
		local scales = control_info["controls_scale"]
		if(value and scales and scales[data]) then
			value = tonumber( value ) / scales[data]
		end
	else
		Application:throw_exception('EWSControlSettingSync::get_ews_control_value() controls_type was not specified for control_info map')
	end
	return value
end
function EWSControlSettingSync:get_ews_control_value_from_id( data, id )
	return self:get_ews_control_value(data, self:get_control_info(id))
end

function EWSControlSettingSync:get_control_info( id )
	local control_info = self._controls_map[id]
	if(not control_info) then
		Application:throw_exception('EWSControlSettingSync::get_control_info() control info does not exist for "'..id..'"')
	end
	return control_info
end

function EWSControlSettingSync:update_link(custom_data, event_object)
	local control_info = self:get_control_info(event_object:get_id())
	local value = self:get_ews_control_value(custom_data, control_info)
	local links = control_info["links"]
	if(links) then
		for link_id in links do
			if(event_object:get_id() ~= link_id) then
				local link_info = self:get_control_info(link_id)
				if(value) then
					link_info["links"] = links
				else
					link_info["links"] = nil
				end
			end
		end
	end
end

function EWSControlSettingSync:show_texture_dialog(custom_data, event_object)
	local control_info = self:get_control_info(event_object:get_id())
-- 		local file = self:get_ews_control_value(custom_data, control_info)
	local dialog = EWS:FileDialog(self._ews_frame, "Choose file", managers.database:base_path(), "", "DDS self:files(*.dds)|*.dds|TGA self:files(*.tga)|*.tga", "OPEN,FILE_MUST_EXIST")
	if(dialog:show_modal()) then
		local path = dialog:get_path()
		path = path:substring(managers.database:base_path().size) -- cut away the base path, it in not useful
		path = path:substring(0, path.size-4) -- also the ending filename
		self:set_ews_control_value(path, custom_data, control_info)
		self:update_setting(custom_data, event_object) -- force update of the setting
	end
end

function EWSControlSettingSync:create_small_label(text)
	local label = EWS:StaticText(self._ews_frame, text, 0, "")
	label:set_font_size(7)
	return label
end

function EWSControlSettingSync:create_linker( id, link_ids )
	local check = EWS:CheckBox(self._ews_frame, "Link", id, "")
	check:set_font_size(6)

	self._ews_frame:connect(id, "EVT_COMMAND_CHECKBOX_CLICKED", callback( self, self, "update_link" ), check)
	
	local info_map = {}
	local types_map = {}
	types_map[check] = "check"
	info_map["controls_type"] = types_map
	info_map["main_control"] = check
	info_map["links"] = link_ids

	self._controls_map[id] = info_map
	
	return check
end

function EWSControlSettingSync:create_slider( id, min, max, num_decimals, labeltext )
	if(not min) then
		min = 0
	end
	if(not max) then
		max = 0
	end
	local scale = math.pow(10, math.abs(num_decimals))
	min = min * scale
	max = max * scale
	if((min > max) or (min == max)) then
		Application:throw_exception("EWSControlSettingSync::create_slider("..id..","..min..","..max..","..num_decimals..") Arguments are confusing")
	end
	local sizer = EWS:BoxSizer("HORIZONTAL")

	if labeltext ~= nil then
	    local label = self:create_small_label( labeltext )
		sizer:add(label, 0, 0, "FIXED_MINSIZE")
	end

	local slider = EWS:Slider(self._ews_frame, min, min, max, id, "")
	local text = EWS:TextCtrl(self._ews_frame, "", id, "")
	sizer:add(slider, 1, 0, "EXPAND")
	sizer:add(text, 0, 2, "LEFT")

	self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", callback( self, self, "update_setting" ), text)

	self._ews_frame:connect(id, "EVT_SCROLL_THUMBTRACK", callback( self, self, "update_setting" ), slider)
	self._ews_frame:connect(id, "EVT_SCROLL_CHANGED", callback( self, self, "update_setting" ), slider)

	local info_map = {}
	local types_map = {}
	types_map[text] = "text"
	types_map[slider] = "slider"
	info_map["controls_type"] = types_map
	local scales_map = {}
	scales_map[slider] = scale
	info_map["controls_scale"] = scales_map
	info_map["controls"] = {slider, text}
	info_map["main_control"] = slider
	info_map["sync_step"] = math.pow(10, -math.abs(num_decimals))

	self._controls_map[id] = info_map

	return sizer
end

function EWSControlSettingSync:create_double_slider( id_min, id_max, min, max, num_decimals)
	local sizer = EWS:BoxSizer("VERTICAL")
	sizer:add(self:create_slider(id_min, min, max, num_decimals), 1, 0, "EXPAND")
	sizer:add(self:create_slider(id_max, min, max, num_decimals), 1, 0, "EXPAND")

	self:get_control_info(id_min)["sync_less"] = {id_max}
	self:get_control_info(id_max)["sync_more"] = {id_min}

	return sizer
end

function EWSControlSettingSync:create_double_slider2( id_min, id_max, min, max, num_decimals)
	local sizer = EWS:BoxSizer("VERTICAL")
	sizer:add(self:create_slider(id_min, min, max, num_decimals), 1, 0, "EXPAND")
	sizer:add(self:create_slider(id_max, min, max, num_decimals), 1, 0, "EXPAND")
	return sizer
end

function EWSControlSettingSync:create_rgb_slider( base_id, min, max, num_decimals, labeltext )
	local sizer = EWS:BoxSizer("VERTICAL")

	if labeltext ~= nil then
	    local label = self:create_small_label( labeltext )
		sizer:add(label, 0, 0, "FIXED_MINSIZE")
	end

	local id_r = base_id .. self._ending_mark.."r"
	local id_g = base_id .. self._ending_mark.."g"
	local id_b = base_id .. self._ending_mark.."b"
	sizer:add(self:create_slider(id_r, min, max, num_decimals), 0, 0, "EXPAND")
	sizer:add(self:create_slider(id_g, min, max, num_decimals), 0, 0, "EXPAND")
	sizer:add(self:create_slider(id_b, min, max, num_decimals), 0, 0, "EXPAND")
	sizer:add(self:create_linker("link_"..base_id, {id_r,id_g,id_b}), 1, 0, "ALIGN_CENTER_HORIZONTAL")

	return sizer
end

function EWSControlSettingSync:create_rgb_box( base_id, labeltext)
	local sizer = EWS:BoxSizer("HORIZONTAL")

	local newid = base_id .. "-rgb"

	local label
	if labeltext == nil then
	 	label = base_id	-- string.sub(base_id, 1, -5)
	else
		label = labeltext
	end
	
	sizer:add(self:create_small_label( label ), 2, 0, "")
	local slider = EWS:Button(self._ews_frame, label, newid, "")
	sizer:add(slider, 2,1, "")
	slider:connect("", "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "update_setting_box" ), slider)

	local info_map = {}
	local types_map = {}
	types_map[slider] = "box"
	info_map["controls_type"] = types_map
	info_map["main_control"] = slider
	self._controls_map[newid] = info_map


	return sizer
end

function EWSControlSettingSync:create_string( id, label_text )
	local sizer = EWS:BoxSizer("HORIZONTAL")
	local text = EWS:TextCtrl(self._ews_frame, "", id, "")
	if(label_text) then
		local label = EWS:StaticText(self._ews_frame, label_text, 0, "")
		sizer:add(label, 0, 2, "ALIGN_CENTER_VERTICAL,RIGHT")
	end
	sizer:add(text, 1, 0, "EXPAND")

	self._ews_frame:connect(id, "EVT_COMMAND_TEXT_UPDATED", callback( self, self, "update_setting" ), text)
	self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", callback( self, self, "update_setting" ), text)

	local info_map = {}
	local types_map = {}
	types_map[text] = "text"
	info_map["controls_type"] = types_map
	info_map["main_control"] = text

	self._controls_map[id] = info_map

	return sizer
end

function EWSControlSettingSync:create_texture_path( id )
	local sizer = EWS:BoxSizer("HORIZONTAL")
	local text = EWS:TextCtrl(self._ews_frame, "", id, "TE_PROCESS_ENTER")
	sizer:add(text, 1, 0, "EXPAND")
	sizer:add(EWS:Button(self._ews_frame, "Browse", id, "BU_EXACTFIT,NO_BORDER"), 0, 2, "LEFT,EXPAND")

	self._ews_frame:connect(id, "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "show_texture_dialog" ), text)
	self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", callback( self, self, "update_setting" ), text)

	local info_map = {}
	local types_map = {}
	types_map[text] = "text"
	info_map["controls_type"] = types_map
	info_map["main_control"] = text

	self._controls_map[id] = info_map

	return sizer
end

function EWSControlSettingSync:create_list_config( id, rename_event_func, add_event_func )
	local sizer = EWS:BoxSizer("VERTICAL")
	local text = EWS:TextCtrl(self._ews_frame, "", id, "")
	local list = EWS:ListBox(self._ews_frame, id, "LB_SINGLE,LB_HSCROLL")
	local text_sizer = EWS:BoxSizer("HORIZONTAL")
	text_sizer:add(text, 1, 0, "EXPAND")
	sizer:add(text_sizer, 0, 0, "EXPAND")
	sizer:add(list, 1, 0, "EXPAND")

	if(add_event_func) then
		local add_btn = EWS:Button(self._ews_frame, "Add", id, "BU_EXACTFIT,NO_BORDER")
		text_sizer:add(add_btn, 0, 2, "LEFT,EXPAND")

		self._ews_frame:connect(id, "EVT_COMMAND_BUTTON_CLICKED", add_event_func, text)
	end
	
	self._ews_frame:connect(id, "EVT_COMMAND_LISTBOX_SELECTED", callback( self, self, "update_setting" ), list)
	if(rename_event_func) then
		self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", rename_event_func, text)
	end

	local info_map = {}
	local types_map = {}
	types_map[list] = "list"
	types_map[text] = "text"
	info_map["controls_type"] = types_map
	info_map["controls"] = {list, text}
	info_map["main_control"] = list
	
	self._controls_map[id] = info_map
	
	return sizer
end

function EWSControlSettingSync:create_combo_config( id, label_text, rename_event_func )
	local sizer = EWS:BoxSizer("HORIZONTAL")
	local combo = EWS:ComboBox(self._ews_frame, "", id, "CB_SORT,CB_DROPDOWN")
	if(label_text) then
		local label = EWS:StaticText(self._ews_frame, label_text, 0, "")
		sizer:add(label, 0, 2, "ALIGN_CENTER_VERTICAL,RIGHT")
	end
	sizer:add(combo, 1, 0, "")
	if(rename_event_func) then
		self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", rename_event_func, combo)
	end
	self._ews_frame:connect(id, "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "update_setting" ), combo)

	local info_map = {}
	local types_map = {}
	types_map[combo] = "combo"
	info_map["controls_type"] = types_map
	info_map["main_control"] = combo

	self._controls_map[id] = info_map

	return sizer
end
function EWSControlSettingSync:create_name_popup( id, label_text, init_text )
	if not init_text then
		init_text = "none"
	end
	local pop_up = EWS:Dialog( nil, label_text, "", Vector3( 525, 400, 0), Vector3( 230, 150, 0), "CAPTION,CLOSE_BOX" )
	pop_up:set_background_colour( "LIGHT GREY"  )
	local pop_up_main_sizer = EWS:StaticBoxSizer( pop_up, "VERTICAL" )
	pop_up:set_sizer( pop_up_main_sizer )
	
	local popup_name = EWS:TextCtrl( pop_up, init_text, id, "TE_CENTRE" )
	pop_up_main_sizer:add( popup_name, 0, 0, "EXPAND" )
	
		local button_sizer = EWS:BoxSizer("HORIZONTAL")
		-- Create new button
			local ok_btn = EWS:Button(pop_up, "Ok", id, "BU_EXACTFIT,NO_BORDER")
			button_sizer:add( ok_btn, 0, 5, "RIGHT" )
			ok_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "update_setting" ), popup_name )
			
			local cancel_btn = EWS:Button(pop_up, "Cancel", "_pop_up_cancel", "BU_EXACTFIT,NO_BORDER")
			button_sizer:add( cancel_btn, 0, 5, "RIGHT" )
			cancel_btn:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "close_name_popup" ), pop_up )
			
		pop_up_main_sizer:add( button_sizer, 0, 0, "EXPAND" )
	
	local info_map = {}
	local types_map = {}
	types_map[popup_name] = "popup_name"
	info_map["controls_type"] = types_map
	info_map["main_control"] = popup_name

	self._controls_map[id] = info_map
	
	return pop_up
end
function EWSControlSettingSync:close_name_popup( popup )
	popup:end_modal()
end

function EWSControlSettingSync:attach_function_button( to_id, sizer, text, event_func ) -- will attach a function button to a sizer and a id
	local id = self:get_unique_id()
	local btn = EWS:Button(self._ews_frame, text, id, "BU_EXACTFIT,NO_BORDER")
	sizer:add(btn, 0, 2, "LEFT,EXPAND")
	self._ews_frame:connect(id, "EVT_COMMAND_BUTTON_CLICKED", event_func, to_id)
end

function EWSControlSettingSync:append_to_control( id, map )
	local control_info = self:get_control_info(id)
	local list_data = control_info["main_control"] -- the list/combo is the main control
	list_data:clear()
	if map[ 1 ] then
		for _, name in ipairs( map ) do
		list_data:append(name)
		end
	else
		for name, data in pairs( map ) do
			list_data:append(name)
		end
	end
end

function EWSControlSettingSync:create_properties_list( id, add_vector, read_only )
	local sizer = EWS:BoxSizer("VERTICAL")
	local list = EWS:ListCtrl(self._ews_frame, id, "LC_REPORT,LC_HRULES,LC_VRULES,LC_SINGLE_SEL")
	list:insert_column(0, "Property", "")
	list:insert_column(1, "Value", "")
	sizer:add(list, 1, 0, "EXPAND")

	local text
	if(not read_only) then
		local value_sizer = EWS:BoxSizer("HORIZONTAL")
		text = EWS:TextCtrl(self._ews_frame, "", id, "")
		local remove_id = self:get_unique_id()
		local remove_btn = EWS:Button(self._ews_frame, "Remove", remove_id, "BU_EXACTFIT,NO_BORDER")
		value_sizer:add(text, 1, 0, "EXPAND")
		value_sizer:add(remove_btn, 0, 2, "LEFT,EXPAND")
		sizer:add(value_sizer, 0, 0, "EXPAND")

		self._ews_frame:connect(remove_id, "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "remove_selected_property_from_list" ), id)
	end
	
	-- dropdown with possible properties and a add button that can add them
	if(add_vector and (#add_vector > 0)) then
		local add_sizer = EWS:BoxSizer("HORIZONTAL")
		local combo = EWS:ComboBox(self._ews_frame, "", id, "CB_SORT,CB_DROPDOWN")
		local add_btn = EWS:Button(self._ews_frame, "Add", id, "BU_EXACTFIT,NO_BORDER")

		-- fill the combo with available default add properties
		for _,name in ipairs( add_vector ) do
			combo:append(name)
		end
		add_sizer:add(combo, 1, 0, "EXPAND")
		add_sizer:add(add_btn, 0, 2, "LEFT,EXPAND")
		sizer:add(add_sizer, 0, 4, "TOP,EXPAND")

		self._ews_frame:connect(id, "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "add_property_to_list" ), combo)
	end

	self._ews_frame:connect(id, "EVT_COMMAND_LIST_ITEM_SELECTED", callback( self, self, "update_setting" ), list)
	self._ews_frame:connect(id, "EVT_COMMAND_TEXT_ENTER", callback( self, self, "update_setting" ), text)

	local info_map = {}
	info_map["listctrl_data"] = {}
	local types_map = {}
	types_map[list] = "listctrl"
	if(not read_only) then
		types_map[text] = "text"
		info_map["controls"] = {list, text}
	end
	info_map["controls_type"] = types_map
	info_map["main_control"] = list
	
	self._controls_map[id] = info_map
	
	return sizer		
end
function EWSControlSettingSync:load_properties_list( id, properties_map )
	local control_info = self:get_control_info(id)
	local list_data = control_info["main_control"]
	list_data:delete_all_items()
	local data_map = control_info["listctrl_data"]
	data_map = {}
	if(properties_map) then
		for name, value in pairs( properties_map ) do
			local index = list_data:append_item(name)
			list_data:set_item(index, 1, value)
			data_map[index] = {name, value}
		end
	end
	local controls_type = control_info["controls_type"]
	for data, type in pairs( controls_type ) do
		if(type == "text") then
			data:set_value("") -- clear all text fields, but silently not with set_ews_value stuff
		end
	end
end
function EWSControlSettingSync:save_properties_list( id )
	local saved_map = {}
	local control_info = self:get_control_info(id)
	local data_map = control_info["listctrl_data"]
	for index, data in pairs( data_map ) do
		saved_map[data[0]] = data[1]
	end
	return saved_map
end

function EWSControlSettingSync:add_property_to_list(custom_data, event_object)
	-- custom data contains the name of the property and event_objects main local the list where it should be added
	local control_info = self:get_control_info(event_object:get_id())
	local name = self:get_ews_control_value(custom_data, control_info)
	local list_data = control_info["main_control"]
	
	local index = list_data:append_item(name)
	local data_map = control_info["listctrl_data"]
	data_map[index] = {name, ""}
end
function EWSControlSettingSync:remove_selected_property_from_list(custom_data, event_object)
	local control_info = self:get_control_info(custom_data)
	local list_data = control_info["main_control"]
	local index = list_data:get_next_item(index, "LIST_NEXT_ALL", "LIST_STATE_SELECTED")
	local data_map = control_info["listctrl_data"]
	while(index ~= -1) do
		list_data:delete_item(index)
		data_map[index] = nil
		index = list_data:get_next_item(index, "LIST_NEXT_ALL", "LIST_STATE_SELECTED")
	end
end

function EWSControlSettingSync:create_about_dialog( about_text )
	local text = about_text or "This about was created by\nHåkan\nThe all and mighty."

	local num_lines = 0
	local longest_line = 0
	local at, at_end = 0, 0
	local _ = nil
	
	while true do
	
		num_lines = num_lines + 1
		_, at_end = text:find( "\n", at, true )	
		
		if _ and at_end then
			local length = text:sub( at, at_end):len()
			
			if length > longest_line then
				longest_line = length
			end

			at = at_end + 1
		else
			break
		end
		
	end
	
	if longest_line == 0 then
		longest_line = text:len()
	end

	local text_box_size = num_lines * 15 
	
	local frame_size_height = text_box_size + 50
	local frame_size_width = longest_line * 8
	
	local about_dialog = EWS:Dialog ( nil, "About", "hoho", Vector3( -1, -1, 0), Vector3( frame_size_width, frame_size_height ) , "")

	-- local static_text = EWS:StaticText( about_dialog, text, "", "ALIGN_CENTRE")
	local static_text = EWS:TextCtrl( about_dialog, text, "", "TE_CENTRE,TE_READONLY,TE_MULTILINE,TE_NO_VSCROLL,TE_RICH,TE_AUTO_URL" )
	static_text:set_background_colour( 212, 208, 200 )
	static_text:set_position( Vector3( 0, 0, 0 ) )
	static_text:set_size( Vector3( frame_size_width, text_box_size, 0) )
	
	local ok_button = EWS:Button( about_dialog, "OK", "", "" )
	ok_button:set_position( Vector3( 0, text_box_size, 0 ) )
	ok_button:set_size( Vector3( frame_size_width - 5, -1, 0 ) )
	ok_button:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_about_dialog_button_ok" ), about_dialog )
		
	return about_dialog
end

function EWSControlSettingSync:on_about_dialog_button_ok( data, event )
	data:end_modal( "" )
end


AboutDialog = AboutDialog or class()

function AboutDialog:init( parent, text )

	local text = text or "This about was created by\nHåkan\nThe all and mighty."

	local num_lines = 0
	local longest_line = 0
	local at, at_end = 0, 0
	local _ = nil
	
	while true do
	
		num_lines = num_lines + 1
		_, at_end = text:find( "\n", at, true )	
		
		if _ and at_end then
			local length = text:sub( at, at_end):len()
			
			if length > longest_line then
				longest_line = length
			end

			at = at_end + 1
		else
			break
		end
		
	end
	
	if longest_line == 0 then
		longest_line = text:len()
	end

	local text_box_size = num_lines * 15 
	
	local frame_size_height = text_box_size + 50
	local frame_size_width = longest_line * 6

	self._frame = EWS:Dialog ( parent, "About", "hoho", Vector3( -1, -1, 0), Vector3( frame_size_width, frame_size_height ) , "")
	

	self._static_text = EWS:StaticText( self._frame, text, "", "ALIGN_CENTRE")
	self._static_text:set_position( Vector3( 0, 0, 0 ) )
	self._static_text:set_size( Vector3( frame_size_width, text_box_size, 0) )
	
	self._ok_button = EWS:Button( self._frame, "OK", "", "" )
	self._ok_button:set_position( Vector3( 0, text_box_size, 0 ) )
	self._ok_button:set_size( Vector3( frame_size_width - 5, -1, 0 ) )
	self._ok_button:connect( "EVT_COMMAND_BUTTON_CLICKED", callback( self, self, "on_button_ok" ), "" )

end

function AboutDialog:on_button_ok( data, event )
	self._frame:end_modal ( "" )
end

function AboutDialog:show()

	self._frame:show_modal()

end


-- The SettingsBase class is created to be a base for Skies and Posteffects
--[[
SettingsBase = SettingsBase or class()

function init( name, node )
	self._name = name
	self._path_map = {}
	self._settings = {}
	self._ending_mark = "-"
	
	self:parse_node( node )
end
function parse_node( node )
	if(node) then
		local valid_vector_value_endings = {"x","y","z","r","g","b","min","max"}
		local settings = node:children()
		for setting in settings do
			if(setting:name() == "path") then
				self._path_map[setting:parameter("name").string] = setting:parameter("value").string
			else
				local params = setting:parameter_map()
				for param, value in pairs( params ) do
					if(valid_vector_value_endings:contains(param)) then
						self:set_setting(setting:name()+_ending_mark+param, value)
					end
				end
				if(params:has("value")) then
					self:set_setting(setting:name(), params["value"])
				end
			end
		end
	end
end

function copy( from )
	self._name = from._name
	self._path_map = from._path_map:copy()
	self._settings = from._settings:copy()
end

function override( with, scale )
	scale = math.clamp(scale, 0, 1)
	for id, data in with._settings do
		self:override_setting(id, with, scale)
	end
end
function override_setting( id, with, scale )
	local inv_scale = 1 - scale
	if(self._settings:has(id)) then
		self._settings:insert(id, self._settings[id]*inv_scale + with._settings[id]*scale)
	else
		self._settings:insert(id, with._settings[id]*scale)
	end
end
	
function add( with, scale )
	scale = math.clamp(scale, 0, 1)
	for id, data in with._settings do
		self:add_setting(id, with, scale)
	end
end
function add_setting( id, with, scale )
	if(self._settings:has(id)) then
		self._settings:insert(id, self._settings[id] + with._settings[id]*scale)
	else
		self:override_setting( id, with, scale )
	end
end

function multiply( with, scale )
	scale = math.clamp(scale, 0, 1)
	for id, data in with._settings do
		self:multiply_setting(id, with, scale)
	end
end
function multiply_setting( id, with, scale )
	if(self._settings:has(id)) then
		self._settings:insert(id, self._settings[id] * (with._settings[id]*scale))
	else
		self:override_setting( id, with, scale )
	end
end

function set_setting(id, value)
	if(id == "name") then
		self._name = value
	elseif(id:beginswith("path_")) then
		self._path_map:insert(id:substring(5), value)
	else
		-- see if there is a ending that can be converted into a vector3 self:index(x, y, or z)
		local ending = self:extract_ending(id, self._ending_mark)
		local vec_pos = self:convert_ending_to_vector3_pos(ending)
		if( vec_pos ~= -1 ) then
			local vec_id = id:substring(0, id.size-(ending.size+_ending_mark.size))
			local setting = self._settings[vec_id]
			if(not setting) then
				setting = Vector3(0,0,0)
			end
			if(vec_pos == 1) then
				setting = Vector3(value, setting.y, setting.z)
			elseif(vec_pos == 2) then
				setting = Vector3(setting.x, value, setting.z)
			elseif(vec_pos == 3) then
				setting = Vector3(setting.x, setting.y, value)
			else
				setting = Vector3(value, value, value)
			end
			self._settings:insert(vec_id, setting)
		else
			self._settings:insert(id, value)
		end
	end
end

function get_setting(id)
	if(id == "name") then
		return self._name
	elseif(id:beginswith("path_")) then
		return self._path_map[id:substring(5)]
	else
		-- see if there is a ending that can be converted into a vector3 self:index(x, y, or z)
		local ending = self:extract_ending(id, self._ending_mark)
		local vec_pos = self:convert_ending_to_vector3_pos(ending)
		if( vec_pos ~= -1 ) then
			local vec_id = id:substring(0, id.size-(ending.size+_ending_mark.size))
			local setting = self._settings[vec_id]
			if(setting) then
				if(vec_pos == 1) then
					return setting.x
				elseif(vec_pos == 2) then
					return setting.y
				elseif(vec_pos == 3) then
					return setting.z
				else
					return setting.x+setting.y+setting.z -- ? dont know really what to expect here, but I guess it should be a value and not a Vector3
				end
			else
				Application:throw_exception('SettingsBase::get_setting() setting not found "'..vec_id..'"')
			end
		else
			return self._settings[id]
		end
	end
	return nil
end

function extract_ending( all, delimiter )
	local ending = all
	local i = ending:index(delimiter)
	while( i ~= -1 ) do
		ending = ending:substring(i+delimiter.size)
		i = ending:index(delimiter)
	end
	return ending
end
			
function convert_ending_to_vector3_pos( ending )
	if(ending == "x" or ending == "r" or ending == "min" ) then
		return 1
	elseif(ending == "y" or ending == "g" or ending == "max" ) then
		return 2
	elseif(ending == "z" or ending == "b" ) then
		return 3
	elseif(ending == "all") then
		return 0
	else
		return -1
	end
end

function create_xml_tag_vector(id)
	local vec = self._settings[id]
	if(vec) then
		return ''..id..' x="'..vec.x..'" y="'..vec.y..'" z="'..vec.z..'"'
	else
		Application:throw_exception('SettingsBase::create_xml_tag_vector() Unable to find setting "'..id..'"')
	end
	return nil
end
function create_xml_tag_color(id)
	local vec = self._settings[id]
	if(vec) then
		return ''..id..' r="'..vec.x..'" g="'..vec.y..'" b="'..vec.z..'"'
	else
		Application:throw_exception('SettingsBase::create_xml_tag_color() Unable to find setting "'..id..'"')
	end
end
function create_xml_tag_minmax(id)
	local vec = self._settings[id]
	if(vec) then
		return ''..id..' min="'..vec.x..'" max="'..vec.y..'"'
	else
		Application:throw_exception('SettingsBase::create_xml_tag_color() Unable to find setting "'..id..'"')
	end
end
function create_xml_tag_value(id)
	return ''..id..' value="'.._settings[id]..'"'
end
]]