core:import("CoreEngineAccess")

function CoreEditor:build_lower_panel( parent )
	self._lower_panel = EWS:Panel( Global.frame_panel, "", "TAB_TRAVERSAL" )
	local lower_sizer = EWS:BoxSizer( "HORIZONTAL" )
	self._lower_panel:set_sizer( lower_sizer )
	
	lower_sizer:add( self:build_info_frame( self._lower_panel ), 1, 0, "EXPAND" )
	lower_sizer:add( self:build_edit_frame( self._lower_panel ), 1, 0, "EXPAND" )
		
	self._edit_panel:set_visible( false )
	return self._lower_panel
end

-- Called from file CoreEditorLeftToolbars.lua
function CoreEditor:add_edit_buttons( edit_btn_sizer )
	cat_print( "editor", ' CoreEditor:add_edit_buttons( edit_btn_sizer )' )
	self._edit_buttons = {}
	
	-- self._left_toolbar:add_check_tool( "LTB_EDIT_LIGHT", "Edit light", CoreEWS.image_path( "world_editor\\edit_light_16x16.png" ), "Edit Light" )
	-- self._left_toolbar:add_check_tool( "LTB_EDIT_VARIATION", "Edit variation", CoreEWS.image_path( "world_editor\\edit_variation_16x16.png" ), "Edit variation" )
	-- self._left_toolbar:add_check_tool( "LTB_EDIT_TRIGGABLE", "Edit triggable", CoreEWS.image_path( "world_editor\\edit_triggable_16x16.png" ), "Edit triggable" )
	-- self._left_toolbar:add_check_tool( "LTB_EDIT_GUI", "Edit gui", CoreEWS.image_path( "world_editor\\edit_gui_16x16.png" ), "Edit gui" )
	-- self._left_toolbar:add_check_tool( "LTB_EDIT_SETTINGS", "Edit settings", CoreEWS.image_path( "world_editor\\edit_settings_16x16.png" ), "Edit settings" )
	
	-- self._left_toolbar:add_separator()
		
	-- self._edit_buttons.edit_light_btn = "LTB_EDIT_LIGHT"
	-- self._edit_buttons.edit_variation_btn = "LTB_EDIT_VARIATION"
	-- self._edit_buttons.edit_triggable_btn = "LTB_EDIT_TRIGGABLE"
	-- self._edit_buttons.edit_gui_btn = "LTB_EDIT_GUI"
	-- self._edit_buttons.edit_settings_btn = "LTB_EDIT_SETTINGS"

	for _,btn in pairs( self._edit_buttons ) do
		self._left_toolbar:set_tool_enabled( btn, false )
	end
	
	--[[if self._use_edit_light_dialog then
		self._left_toolbar:connect( "LTB_EDIT_LIGHT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_light_dialog" ), { btn = self._edit_buttons.edit_light_btn } )
	else
		self._left_toolbar:connect( "LTB_EDIT_LIGHT", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_edit" ), { btn = self._edit_buttons.edit_light_btn, panel = "_edit_light" } )
	end]]
	
	-- self._left_toolbar:connect( "LTB_EDIT_VARIATION", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_edit" ), { btn = self._edit_buttons.edit_variation_btn, panel = "_edit_variation" } )
	-- self._left_toolbar:connect( "LTB_EDIT_TRIGGABLE", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_edit" ), { btn = self._edit_buttons.edit_triggable_btn, panel = "_edit_triggable" } )
	-- self._left_toolbar:connect( "LTB_EDIT_GUI", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_edit" ), { btn = self._edit_buttons.edit_gui_btn, panel = "_edit_text_gui" } )
	-- self._left_toolbar:connect( "LTB_EDIT_SETTINGS", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "show_edit" ), { btn = self._edit_buttons.edit_settings_btn, panel = "_edit_settings" } )
end
		
function CoreEditor:build_info_frame( parent )
	self._info_frame = EWS:Panel( parent, "Info Frame", "TAB_TRAVERSAL")
	-- self._info_sizer = EWS:StaticBoxSizer(self._info_frame, "HORIZONTAL", "Info")
	self._info_sizer = EWS:BoxSizer( "HORIZONTAL" )
	self._info_frame:set_sizer(self._info_sizer)
	
	self._outputctrl = EWS:TextCtrl( self._info_frame, "- What would you like to build today? -\n\n", "", "TE_MULTILINE,TE_NOHIDESEL,TE_RICH2,TE_DONTWRAP,TE_READONLY" )
	self._outputctrl:set_font_face( "Courier New" )
	self._info_sizer:add( self._outputctrl, 1, 0, "EXPAND" )
	self._outputctrl:set_tool_tip( "Editor console output" )
		
	self._unit_info_notebook = EWS:Notebook( self._info_frame, "_unit_info_notebook", "NB_RIGHT,NB_MULTILINE" )
	self._ews_editor_frame:connect( "_unit_info_notebook", "EVT_COMMAND_NOTEBOOK_PAGE_CHANGED", callback( self, self, "_change_unit_info" ), self._unit_info_notebook )
	self._info_sizer:add( self._unit_info_notebook, 1, 0, "EXPAND" )
	
	self._unit_info = EWS:TextCtrl( self._unit_info_notebook, "Generic unit info", "", "TE_MULTILINE,TE_RICH2,TE_DONTWRAP,TE_READONLY" )
	self._unit_info:set_font_face( "Courier New" )
	-- self._info_sizer:add( self._unit_info, 1, 0, "EXPAND" )
	self._unit_info:set_tool_tip( "Generic unit information" )
	
	self._gfx_unit_info = EWS:TextCtrl( self._unit_info_notebook, "Gfx unit info", "", "TE_MULTILINE,TE_RICH2,TE_DONTWRAP,TE_READONLY" )
	self._gfx_unit_info:set_font_face( "Courier New" )
	self._gfx_unit_info:set_tool_tip( "Gfx unit information" )
	
	self._unit_info_notebook:add_page( self._unit_info, "Generic", true )
	self._unit_info_notebook:add_page( self._gfx_unit_info, "Gfx", false )
	
	local unit_info_panel = EWS:Panel( self._info_frame, "", "" )
	local unit_info_sizer = EWS:BoxSizer( "HORIZONTAL" )
	unit_info_panel:set_sizer( unit_info_sizer )
	
	self._info_sizer:add( unit_info_panel, 0, 0, "EXPAND" )
	
	self._unit_info_toolbar = EWS:ToolBar( unit_info_panel, "", "TB_FLAT,TB_VERTICAL,TB_NODIVIDER" )

	self:add_open_unit_file_buttons()
		
	self._unit_info_toolbar:realize()
	
	unit_info_sizer:add( self._unit_info_toolbar, 0, 0, "EXPAND" )
	
	return self._info_frame
end

function CoreEditor:add_open_unit_file_buttons()
	self._open_unit_file_buttons = {}
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_UNIT_XML", "Open unit file", CoreEWS.image_path( "world_editor\\unit_file_unit_16x16.png" ), "Open unit file" )
	self._unit_info_toolbar:connect( "LTB_OPEN_UNIT_XML", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "unit" } )
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_OBJECT_XML", "Open object file", CoreEWS.image_path( "world_editor\\unit_file_object_16x16.png" ), "Open unit file" )
	self._unit_info_toolbar:connect( "LTB_OPEN_OBJECT_XML", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "object" } )
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_MATERIAL_XML", "Open material file", CoreEWS.image_path( "world_editor\\unit_file_material_16x16.png" ), "Open material file" )
	self._unit_info_toolbar:connect( "LTB_OPEN_MATERIAL_XML", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "material_config" } )
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_SEQUECNCE_XML", "Open sequence file", CoreEWS.image_path( "world_editor\\unit_file_sequence_16x16.png" ), "Open sequence file" )
	self._unit_info_toolbar:connect( "LTB_OPEN_SEQUECNCE_XML", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "sequence_manager" } )
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_LAST_EXPORTED", "Open source file", CoreEWS.image_path( "world_editor\\unit_file_max_16x16.png" ), "Open source 3Dsmax file" )
	self._unit_info_toolbar:connect( "LTB_OPEN_LAST_EXPORTED", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "max" } )
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_FOLDER_EXPORTED", "Open content folder", CoreEWS.image_path( "folder_open_16x16.png" ), "Open content folder" )
	self._unit_info_toolbar:connect( "LTB_OPEN_FOLDER_EXPORTED", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "folder" } )	
	
	self._unit_info_toolbar:add_tool( "LTB_OPEN_FOLDER_SOURCE", "Open source folder", CoreEWS.image_path( "folder_open_source_16x16.png" ), "Open source folder" )
	self._unit_info_toolbar:connect( "LTB_OPEN_FOLDER_SOURCE", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "on_open_unit_file" ), { type = "folder_source" } )
	
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_UNIT_XML" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_OBJECT_XML" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_MATERIAL_XML" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_SEQUECNCE_XML" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_LAST_EXPORTED" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_FOLDER_EXPORTED" )
	table.insert( self._open_unit_file_buttons, "LTB_OPEN_FOLDER_SOURCE" )
		
	for _,btn in ipairs( self._open_unit_file_buttons ) do
		self._unit_info_toolbar:set_tool_enabled( btn, false )
	end
end

function CoreEditor:_change_unit_info( notebook )
end

function CoreEditor:on_open_unit_file( data )
	if alive( self:selected_unit() ) then
		local unit = self:selected_unit()
		local u_name = self:selected_unit():name()
		local lookup
		if data.type == "unit" then
			lookup = unit:name():s()
		elseif data.type == "object" then
			lookup = unit:model_filename()
		elseif data.type == "material_config" then
			lookup = unit:material_config():s()
		elseif data.type == "sequence_manager" then
			lookup = self:sequence_file( unit )
		elseif data.type == "max" then
			lookup = unit:last_export_source()
			os.execute( "start ".. lookup)
			return
		elseif data.type == "folder" then
			lookup = unit:name():s()
			local fullPath = managers.database:entry_expanded_directory( lookup )
			lookup = string.gsub(fullPath, "/", "\\")
			os.execute( "explorer /select, ".. lookup.. ".unit")
			return
		elseif data.type == "folder_source" then
			lookup = unit:last_export_source():s()
			lookup = string.gsub(lookup, "/", "\\")
			os.execute ( "explorer /select, ".. lookup )
			return
		end

		if not lookup then
			return
		end
		
		local full_path = managers.database:entry_expanded_path(data.type, lookup)
		if managers.database:has(full_path) then
			os.execute( "start ".. full_path)
		else
			self:output_warning( "Unit "..u_name:s().." didn't have a "..data.type.." file." )
		end

	end
end

function CoreEditor:sequence_file( unit )
	if alive( unit ) then
		local object_file = CoreEngineAccess._editor_unit_data( unit:name():id() ):model()
		
		local node
		if DB:has( "object", object_file ) then
			node = DB:load_node( "object", object_file )
		else
			node = SystemFS:parse_xml( 'data/objects'..object_file:s() )
		end
	
		for child in node:children() do
			if child:name() == "sequence_manager" then
				return child:parameter( "file" )
			end
		end
		managers.editor:output_warning( unit:name():s().." didn't have a sequence xml." )
	end
	return false
end

function CoreEditor:build_edit_frame( parent )
	self._edit_panel = EWS:Panel( parent, "Edit Panel", "TAB_TRAVERSAL")
	local main_sizer = EWS:BoxSizer( "HORIZONTAL" )
	self._edit_panel:set_sizer( main_sizer )
	
	-- self._edit_light = EditLight:new( self._edit_panel, self._left_toolbar, self._edit_buttons.edit_light_btn )
	-- main_sizer:add( self._edit_light:get_panel(), 0, 0, "EXPAND" )
	
	-- self._edit_variation = EditVariation:new( self._edit_panel, self._left_toolbar, self._edit_buttons.edit_variation_btn )
	-- main_sizer:add( self._edit_variation:get_panel(), 0, 0, "EXPAND" )
	
	-- self._edit_triggable = EditTriggable:new( self._edit_panel, self._left_toolbar, self._edit_buttons.edit_triggable_btn )
	-- main_sizer:add( self._edit_triggable:get_panel(), 0, 0, "EXPAND" )
	
	-- self._edit_text_gui = EditTextGui:new( self._edit_panel, self._left_toolbar, self._edit_buttons.edit_gui_btn )
	-- main_sizer:add( self._edit_text_gui:get_panel(), 0, 0, "EXPAND" )
	
	-- local edit_settings = rawget( _G, "EditSettings" ) or rawget( _G, "CoreEditSettings" )
	-- self._edit_settings = edit_settings:new( self._edit_panel, self._left_toolbar, self._edit_buttons.edit_settings_btn )
	-- main_sizer:add( self._edit_settings:get_panel(), 0, 0, "EXPAND" )
	
	self._edit_panel:set_visible( false )
	
	return self._edit_panel, main_sizer
end

--[[function CoreEditor:show_light_dialog( data )
	self._edit_light_dialog:set_visible( self._left_toolbar:tool_state( data.btn ) )
end]]

function CoreEditor:show_edit( data )
	self[ data.panel ]:set_visible( self._left_toolbar:tool_state( data.btn ) )
	self._info_frame:set_visible( not self:check_edit_buttons() )
	self._edit_panel:set_visible( self:check_edit_buttons() )
	self._edit_panel:layout()
	self._lower_panel:layout()
end

function CoreEditor:check_edit_buttons()
	local value = false
	for _, btn in pairs( self._edit_buttons ) do
		value = value or self._left_toolbar:tool_state( btn )
	end
	return value
end

-- The edit classes might need to call this to get a complete layout for its units ( EditTriggable )
function CoreEditor:layout_edit_panel()
	self._edit_panel:layout()
	self._lower_panel:layout()
end

-- Called from layer function update_unit_settings
function CoreEditor:unit_output( unit )
	if alive( unit ) then
		local n = '\n'
		local t = '\t'
		local text = 'ID / Name:' .. t .. tostring( unit:unit_data().unit_id ) .. ' / ' .. unit:name():s().. n
   		text = text .. 'NameID:' .. t .. unit:unit_data().name_id .. n
		text = text .. 'Type / Slot:' .. t .. unit:type():s() .. ' / ' .. unit:slot() .. n
		text = text .. 'Mass:' .. t .. t .. unit:mass() .. n
		text = text .. 'Author:' .. t .. t .. unit:author():s() .. n
		text = text .. 'Damage types:' .. t .. t .. managers.sequence:editor_info( unit:name() ) .. n
--		text = text .. 'Snappoints:' .. t .. t .. #unit:get_objects( "snap*" ) .. n
		text = text .. 'Geometry memory:' .. t .. unit:geometry_memory_use() .. n
		text = text .. 'Unit filename:' .. t .. unit:unit_filename() .. n
		text = text .. 'Object filename:' .. t .. unit:model_filename() .. n
		text = text .. 'Diesel filename:' .. t .. unit:diesel_filename() .. n
		text = text .. 'Material filename:' .. t .. unit:material_config():s() .. n
		text = text .. 'Materials:' .. n
		for _,name in ipairs( self:_unit_materials( unit ) ) do
			text = text .. t .. name .. n
		end
		text = text .. 'Last export from:' .. t .. unit:last_export_source() .. n
		
		local models_text = ""
						
		models_text = models_text .. 'Models:' .. t .. unit:nr_models() .. n	
		
		models_text = models_text .. 'Name' .. t .. t .. t .. t .. t .. 'Instanced'..t..'Vertecies'..t..'Triangles'..t..'Atoms' .. n
		for i = 0, unit:nr_models() - 1 do
			 if unit:is_visible( i ) then
				local len = string.len( unit:model_name( i ):s() )
				local tabs = 5 - math.floor( len / 7 )
				local tab = ''
				for j = 1, tabs do
					tab = tab .. t
				end
				models_text = models_text .. unit:model_name( i ):s() .. tab .. tostring(unit:is_model_instance( i )) .. t .. t .. unit:vertex_count( i ) .. t .. t .. unit:triangle_count( i ) .. t .. t .. unit:atom_count( i ) .. n
			 end
		end
		
		models_text = models_text .. n.. 'Used texture names:' .. n
		for _,name in ipairs( unit:used_texture_names() ) do
			models_text = models_text .. t .. name .. n	
		end
		
		self._unit_info:set_value( text )
		self._gfx_unit_info:set_value( models_text )
		for _,btn in ipairs( self._open_unit_file_buttons ) do
			self._unit_info_toolbar:set_tool_enabled( btn, true )
		end
	else
 		self._unit_info:set_value( "" )
 		self._gfx_unit_info:set_value( "" )
 		for _,btn in ipairs( self._open_unit_file_buttons ) do
			self._unit_info_toolbar:set_tool_enabled( btn, false )
		end
	end
end

-- Returns names of all materials in the unit, only unique once though
function CoreEditor:_unit_materials( unit )
	local names = {}
	for _,material in ipairs( unit:get_objects_by_type( Idstring("material") ) ) do
		if not table.contains( names, material:name():s() ) then
			table.insert( names, material:name():s() )
		end
	end
	return names
end
