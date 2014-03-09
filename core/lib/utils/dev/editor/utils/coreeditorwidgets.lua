core:module( "CoreEditorWidgets" )
core:import( "CoreClass" )
core:import( "CoreTable" )

----------------------------------------------------------------
-- Core base class for widgets
Widget = Widget or CoreClass.class()

function Widget:init( layer, name )
	self._layer = layer
	-- World:preload_unit( Idstring("core/units/" .. name .. "/"  .. name) )
	self._widget = World:spawn_unit( Idstring("core/units/" .. name .. "/" .. name), Vector3() )
	
	self._widget:set_enabled( false )
	self._use = false
	self._x_pen = Draw:pen( "no_z", "red" )
	self._y_pen = Draw:pen( "no_z", "green" )
	self._z_pen = Draw:pen( "no_z", "blue" )
	self._yellow_pen = Draw:pen( "no_z", "yellow" )
end

function Widget:widget()
	return self._widget
end

function Widget:set_enabled( enabled )
	self._widget:set_enabled( self._use and enabled )
end

function Widget:set_use( use )
	self._use = use
end

function Widget:enabled()
	return self._widget:enabled()
end

function Widget:set_position( pos )
	self._widget:set_position( pos )
end

function Widget:set_rotation( rot )
	self._widget:set_rotation( rot )
end

function Widget:update()
end

function Widget:calculate()
end

function Widget:reset_values()
end

----------------------------------------------------------------

MoveWidget = MoveWidget or CoreClass.class( Widget )

function MoveWidget:init( layer )
	MoveWidget.super.init( self, layer, "move_widget" )
	
	self._draw_axis = {}
	self._move_widget_axis = {}
	self._move_widget_offset = Vector3()
	self._widget:set_visible( false )
end

function MoveWidget:reset_values()
	self._move_widget_axis = {}
	self._draw_axis = {}
	self._move_widget_offset = Vector3()
end

function MoveWidget:update( t, dt )
	local u_pos = self._widget:position()
	local u_rot = self._widget:rotation()
	self._x_pen:arrow( u_pos+u_rot:x()*10, u_pos+u_rot:x()*100, 0.25 )
	self._y_pen:arrow( u_pos+u_rot:y()*10, u_pos+u_rot:y()*100, 0.25 )
	self._z_pen:arrow( u_pos+u_rot:z()*10, u_pos+u_rot:z()*100, 0.25 )

	local ps = 40
	local pr = 1
	Application:draw_cylinder( u_pos+u_rot:z()*ps, u_pos+(u_rot:z()+u_rot:y())*ps, pr, 0, 0, 1 )
	Application:draw_cylinder( u_pos+u_rot:y()*ps, u_pos+(u_rot:z()+u_rot:y())*ps, pr, 0, 1, 0 )
	
	Application:draw_cylinder( u_pos+u_rot:z()*ps, u_pos+(u_rot:z()+u_rot:x())*ps, pr, 0, 0, 1 )
	Application:draw_cylinder( u_pos+u_rot:x()*ps, u_pos+(u_rot:z()+u_rot:x())*ps, pr, 1, 0, 0 )
	
	Application:draw_cylinder( u_pos+u_rot:y()*ps, u_pos+(u_rot:y()+u_rot:x())*ps, pr, 0, 1, 0 )
	Application:draw_cylinder( u_pos+u_rot:x()*ps, u_pos+(u_rot:y()+u_rot:x())*ps, pr, 1, 0, 0 )
	
	-- Use current selected axises when drawing
	local draw_axis = CoreTable.clone( self._draw_axis )
	
	-- If there are no current axises then check what we are raying at
	if #draw_axis == 0 then
		local from = managers.editor:get_cursor_look_point(0)
		local to = managers.editor:get_cursor_look_point(100000)
		local ray = World:raycast( "ray", from, to, "ray_type", "widget", "target_unit", self._widget )	
		if ray and ray.body then
			local axis = ray.body:name():s()
			
			table.insert( draw_axis, axis )
			if axis == "xy" or axis == "xz" then
				table.insert( draw_axis, "x" )
			end
			if axis == "xy" or axis == "yz" then
				table.insert( draw_axis, "y" )
			end
			if axis == "xz" or axis == "yz" then
				table.insert( draw_axis, "z" )
			end
		end
	end
	
	-- Draw all selected or mouse over axis yellow
	for _,axis in ipairs( draw_axis ) do
		if axis == "xy" then
			self._yellow_pen:cylinder( u_pos+u_rot:y()*ps, u_pos+(u_rot:y()+u_rot:x())*ps, pr )
			self._yellow_pen:cylinder( u_pos+u_rot:x()*ps, u_pos+(u_rot:y()+u_rot:x())*ps, pr )
		elseif axis == "xz" then
			self._yellow_pen:cylinder( u_pos+u_rot:z()*ps, u_pos+(u_rot:z()+u_rot:x())*ps, pr )
			self._yellow_pen:cylinder( u_pos+u_rot:x()*ps, u_pos+(u_rot:z()+u_rot:x())*ps, pr )
		elseif axis == "yz" then
			self._yellow_pen:cylinder( u_pos+u_rot:z()*ps, u_pos+(u_rot:z()+u_rot:y())*ps, pr )
			self._yellow_pen:cylinder( u_pos+u_rot:y()*ps, u_pos+(u_rot:z()+u_rot:y())*ps, pr )
		else
			self._yellow_pen:arrow( u_pos+u_rot[ axis ]( u_rot )*10, u_pos+u_rot[ axis ]( u_rot )*100, 0.25 )
		end
	end

end

function MoveWidget:calculate( unit, widget_rot )
	local result_pos = self:calc_move_widget_pos( unit, widget_rot )
	-- Application:draw_sphere( result_pos, 90, 1, 1, 0 )
	result_pos = result_pos + self._move_widget_offset
	-- Application:draw_sphere( result_pos, 100, 0, 1, 0 )
	return result_pos
end

function MoveWidget:calc_move_widget_pos( unit, widget_rot )
	local result_pos = Vector3()
	if #self._move_widget_axis == 2 then
		local p1 = managers.editor:get_cursor_look_point(0)
		local p2 = managers.editor:get_cursor_look_point(100)
		local axis1 = widget_rot[self._move_widget_axis[ 1 ]](widget_rot)
		local axis2 = widget_rot[self._move_widget_axis[ 2 ]](widget_rot)
		
		-- plane normal
		local normal = axis1:cross( axis2 )
		
		-- define the plane
		local d = self._unit_start_pos:dot( normal )
		
		-- line plane intersection http://en.wikipedia.org/wiki/Line-plane_intersection
		-- distance to plane instersection
		-- local t = (d -p1:dot(normal))/((p2-p1):dot(normal))
		if ((p2-p1):dot(normal)) ~= 0 then -- A crash has been reported where divide by zero occured
			local t = (d -p1:dot(normal))/((p2-p1):dot(normal))
			result_pos = (p2-p1)*t
		end
		-- result_pos = (p2-p1)*t
	else
		local axis1 = self._move_widget_axis[ 1 ]
		local from = managers.editor:get_cursor_look_point(0)
		local to = managers.editor:get_cursor_look_point(100)
		local w_s_pos = self._unit_start_pos+widget_rot[axis1](widget_rot) * -100
		local w_e_pos = self._unit_start_pos+widget_rot[axis1](widget_rot) * 100
		local mid_line_pos = math.line_intersection( w_s_pos, w_e_pos, from, to )
		-- Application:draw_sphere( mid_line_pos, 50, 1, 1, 1 )
		local dot1_v = mid_line_pos - w_s_pos
		-- Application:draw_line( mid_line_pos, w_s_pos, 1, 0, 1 )
		local dot2_v = w_e_pos - w_s_pos
		-- Application:draw_line( w_e_pos, w_s_pos, 0, 1, 1 )
		local dot = (dot2_v:normalized()):dot( dot1_v )
		local line_pos = w_s_pos + dot2_v:normalized() * dot
		-- Application:draw_sphere( line_pos, 50, 0, 0, 1 )
		result_pos = line_pos - self._unit_start_pos
	end
	
	result_pos = result_pos:rotate_with( widget_rot:inverse() )
		
	local grid_size = self._layer:grid_size()	
		
	result_pos = result_pos:with_x( math.round((result_pos.x)/grid_size) * grid_size )
	result_pos = result_pos:with_y( math.round((result_pos.y)/grid_size) * grid_size )
	result_pos = result_pos:with_z( math.round((result_pos.z)/grid_size) * grid_size )
	
	result_pos = result_pos:rotate_with( widget_rot )
	
	return result_pos + self._unit_start_pos
end

function MoveWidget:add_move_widget_axis( axis )
	if axis == "x" then
		table.insert( self._move_widget_axis, "x" )
		table.insert( self._draw_axis, "x" )
	elseif axis == "y" then
		table.insert( self._move_widget_axis, "y" )
		table.insert( self._draw_axis, "y" )
	elseif axis == "z" then
		table.insert( self._move_widget_axis, "z" )
		table.insert( self._draw_axis, "z" )
	elseif axis == "xy" then
		table.insert( self._move_widget_axis, "x" )
		table.insert( self._move_widget_axis, "y" )
		table.insert( self._draw_axis, "x" )
		table.insert( self._draw_axis, "y" )
		table.insert( self._draw_axis, "xy" )
	elseif axis == "xz" then
		table.insert( self._move_widget_axis, "x" )
		table.insert( self._move_widget_axis, "z" )
		table.insert( self._draw_axis, "x" )
		table.insert( self._draw_axis, "z" )
		table.insert( self._draw_axis, "xz" )
	elseif axis == "yz" then
		table.insert( self._move_widget_axis, "y" )
		table.insert( self._move_widget_axis, "z" )
		table.insert( self._draw_axis, "y" )
		table.insert( self._draw_axis, "z" )
		table.insert( self._draw_axis, "yz" )
	end
	return table
end

function MoveWidget:set_move_widget_offset( unit, widget_rot )
	self._unit_start_pos = unit:position()
	self._move_widget_offset = unit:position() - self:calc_move_widget_pos( unit, widget_rot )
end

----------------------------------------------------------------

RotationWidget = RotationWidget or CoreClass.class( Widget )

function RotationWidget:init( layer )
	RotationWidget.super.init( self, layer, "rotation_widget" )
	self._rotate_widget_axis = nil
end

function RotationWidget:reset_values()
	self._rotate_widget_axis = nil
end

function RotationWidget:set_rotate_widget_axis( axis )
	self._rotate_widget_axis = axis
end

function RotationWidget:set_rotate_widget_start_screen_position( pos )
	self._rotate_widget_start_screen_position = pos
end

function RotationWidget:set_rotate_widget_unit_rot( rot )
	self._rotate_widget_unit_rot = rot
end

function RotationWidget:set_world_dir( ray_pos )
	self._world_dir = ray_pos - self._widget:position()
end

function RotationWidget:update( t, dt )
	local u_pos = self._widget:position()
	local u_rot = self._widget:rotation()
	self._x_pen:torus( u_pos, 75, 2.5, u_rot:x() )
	self._y_pen:torus( u_pos, 75, 2.5, u_rot:y() )
	self._z_pen:torus( u_pos, 75, 2.5, u_rot:z() )
	local axis = self._rotate_widget_axis
	if not axis then
		local from = managers.editor:get_cursor_look_point(0)
		local to = managers.editor:get_cursor_look_point(100000)
		local ray = World:raycast( "ray", from, to, "ray_type", "widget", "target_unit", self._widget )
		if ray and ray.body then
			axis = ray.body:name():s()
		end
	end
	if axis then
		self._yellow_pen:torus( u_pos, 75, 2.5, u_rot[ axis ]( u_rot ) )
	end
end

function RotationWidget:calculate( unit, widget_rot, widget_pos, widget_screen_pos )
	managers.editor:world_to_screen( unit:position() )
	
	local world_click_pos = self._widget:position() + self._world_dir
	
	-- distance from click position to cursor position
	local distance_vector = self._rotate_widget_start_screen_position-managers.editor:cursor_pos()				
	
	-- Screen click position (divided z with 1000 since that is the widget screen deep position )
	local real_click_screen_pos = managers.editor:world_to_screen( world_click_pos )
	real_click_screen_pos = real_click_screen_pos:with_z( real_click_screen_pos.z/1000 )
	
	-- Screen widget position (divided z with 1000 since that is the widget screen deep position )
	local real_widget_screen_pos = managers.editor:world_to_screen( self._widget:position() )
	real_widget_screen_pos = real_widget_screen_pos:with_z( real_widget_screen_pos.z/1000 )

	-- The screen direction between click and widget
	local real_screen_dir = (real_click_screen_pos - real_widget_screen_pos):normalized()
	
	-- Used to calculate the widget rotation axis in screen space( divided z with widget z position )
	local real_widget_axis_pos = managers.editor:world_to_screen( self._widget:position() + widget_rot[ self._rotate_widget_axis ]( widget_rot ) * 100 )
	real_widget_axis_pos = real_widget_axis_pos:with_z( real_widget_axis_pos.z/1000 )
	
	-- Widget axis direction in screen space	
	local real_widget_screen_dir = (real_widget_axis_pos - real_widget_screen_pos):normalized()
	
	-- The axis used to calculate amount of distance to use( use z 0 and normalize to put the direction fully on screen xy )
	local real_cross_dir = real_screen_dir:cross( real_widget_screen_dir )
	real_cross_dir = ( real_cross_dir:with_z( 0 ) ):normalized()
	
	-- Draw tangent
	local world_to_1 = managers.editor:screen_to_world( real_click_screen_pos + real_cross_dir * 3 )
	local world_to_2 = managers.editor:screen_to_world( real_click_screen_pos + real_cross_dir * -3 )
	Application:draw_line( world_click_pos, world_to_1, 1, 1, 0 )
	Application:draw_line( world_click_pos, world_to_2, 1, 1, 0 )
	
	-- Dot the cross direction with distance vector to get the amount of distance vector to use
	local amount = real_cross_dir:dot( distance_vector:normalized() )
	
	-- Calculate distance with amount
	local distance = distance_vector:length() * amount * 360
	
	-- Get snap rotation setting		
	local snap_rot = self._layer:snap_rotation()
	
	-- Calculate the rotation with snap rotation
	local rot = math.round((distance/snap_rot)) * snap_rot
	
	-- Create the rotation for world transformation
	local result_rot = Rotation( Rotation()[ self._rotate_widget_axis ]( Rotation() ), rot )
	
	--lot of data
	-- managers.editor:set_value_info( 'real_click_screen_pos '..real_click_screen_pos..'\nreal_widget_screen_pos '..real_widget_screen_pos..'\nreal_screen_dir '..real_screen_dir..'\n\nreal_widget_axis_pos '..real_widget_axis_pos..'\nreal_widget_screen_dir '..real_widget_screen_dir..'\nreal_cross_dir '..real_cross_dir..'\namount '..amount )
	
	managers.editor:set_value_info( string.format( '('..self._rotate_widget_axis..') (%.2f %.2f %.2f)', result_rot:yaw(),result_rot:pitch(),result_rot:roll() )  )
	
	-- Change the rotation to local transformation
	if self._layer:local_rot() then
		result_rot = Rotation( self._rotate_widget_unit_rot[ self._rotate_widget_axis ]( self._rotate_widget_unit_rot ), rot )
	end	
	
	-- Calculate final rotation
	result_rot = result_rot * self._rotate_widget_unit_rot
	
	Application:draw_rotation( unit:position(), result_rot )
	managers.editor:set_value_info_pos( widget_screen_pos )
	
	return result_rot
end

