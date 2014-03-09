CoreScriptUnitData = CoreScriptUnitData or class()

CoreScriptUnitData.world_pos = Vector3( 0, 0, 0 )
CoreScriptUnitData.local_pos = Vector3( 0, 0, 0 )
CoreScriptUnitData.local_rot = Rotation( 0, 0, 0 )
CoreScriptUnitData.unit_id = 0
CoreScriptUnitData.name_id = "none"
-- CoreScriptUnitData.group_name = "none" -- To remember which group in the GroupHandler the unit belongs to
CoreScriptUnitData.mesh_variation = nil -- "default" -- Which varitaion sequence the unit uses
CoreScriptUnitData.material = nil -- "default" -- Which material variation the unit uses
CoreScriptUnitData.unique_item = false
CoreScriptUnitData.only_exists_in_editor = false -- Set true and the unit will be removed when not in the editor (good for helper units)
CoreScriptUnitData.only_visible_in_editor = false -- Set true and it will only be visible in the editor and not in game
CoreScriptUnitData.editable_gui = false -- Set this to true if a unit has editable gui text
CoreScriptUnitData.editable_gui_text = "Default" -- This is the default text for a unit with editable gui text
CoreScriptUnitData.portal_visible_inverse = false -- Set true if a unit should be visible when other units in the portal are hidden and viceverse
CoreScriptUnitData.exists_in_stages = { true, true, true, true, true, true }
CoreScriptUnitData.helper_type = "none"
CoreScriptUnitData.disable_shadows = nil
CoreScriptUnitData.hide_on_projection_light = nil -- If true, the unit will be hidden when projection lights are generated
CoreScriptUnitData.disable_on_ai_graph = nil -- If true, the unit will be hidden when ai graph is calculated
  
function CoreScriptUnitData:init()
	if Application:editor() then
		self.unit_groups = {} -- Which unit group the unit belongs to
	end
end
