CoreExecuteInOtherMissionUnitElement = CoreExecuteInOtherMissionUnitElement or class( MissionElement )

ExecuteInOtherMissionUnitElement = ExecuteInOtherMissionUnitElement or class( CoreExecuteInOtherMissionUnitElement )

function ExecuteInOtherMissionUnitElement:init( ... )
	CoreExecuteInOtherMissionUnitElement.init( self, ... )
end

function CoreExecuteInOtherMissionUnitElement:init( unit )
	MissionElement.init( self, unit )
	
end

function CoreExecuteInOtherMissionUnitElement:selected()
	MissionElement.selected( self )
	
end

function CoreExecuteInOtherMissionUnitElement:add_unit_list_btn()
	local f = function( unit ) return unit:type() == Idstring( "mission_element" ) and unit ~= self._unit end
	local dialog = SelectUnitByNameModal:new( "Add other mission unit", f )
	for _,unit in ipairs( dialog:selected_units() ) do
		-- self:_add_or_remove_graph( unit:unit_data().unit_id )
		self:add_on_executed( unit )
	end
end

function CoreExecuteInOtherMissionUnitElement:_build_panel( panel, panel_sizer )
		
	self:_create_panel()
	
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	
	self._btn_toolbar = EWS:ToolBar( panel, "", "TB_FLAT,TB_NODIVIDER" )
	
	self._btn_toolbar:add_tool( "ADD_UNIT_LIST", "Add unit from unit list", CoreEws.image_path( "world_editor\\unit_by_name_list.png" ), nil )
	self._btn_toolbar:connect( "ADD_UNIT_LIST", "EVT_COMMAND_MENU_SELECTED", callback( self, self, "add_unit_list_btn" ), nil )
				
	self._btn_toolbar:realize()
	
	panel_sizer:add( self._btn_toolbar, 0, 1, "EXPAND,LEFT" )
	--[[
	-- script
	self._script_params = {
		name 				= "Script:",
		panel 				= panel,
		sizer 				= panel_sizer,
		default				= "none",
		options				= self:_scripts(),
		value 				= self._hed.activate_script,
		tooltip 			= "Select a script from the combobox",
		name_proportions 	= 1,
		ctrlr_proportions 	= 2,
		sorted				= true
	}
	local scripts = CoreEWS.combobox( self._script_params )
	
	scripts:connect( "EVT_COMMAND_COMBOBOX_SELECTED", callback( self, self, "set_element_data" ), { ctrlr = scripts, value = "activate_script" } )
	]]
end
