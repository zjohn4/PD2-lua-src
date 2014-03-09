--[[

C o r e P a t c h E n g i n e
-----------------------------

The CorePatchEngine modifies and/or adds functions to engine classes.
This functionality should - eventually - be moved to the Engine where
it belongs.
  
]]--

-- For transparent compatability with Idstrings, we patch the class associated
-- with all Lua strings with the same interface as Idstring instances. We also
-- add the id() mehtod to Idstrings, which return self, but in the case of strings
-- return an Idstring constructed from the string.

function Idstring:id()
	return self
end

function string:id()
	return Idstring(self)
end

function string:t()
	return Idstring(self):t()
end

function string:s()
	return self
end

function string:key()
	return Idstring(self):key()
end

function string:raw()
	return Idstring(self):raw()
end

if Vector3 then
	Vector3.__concat = function( o1, o2 ) return tostring( o1 ) .. tostring( o2 ) end

	function Vector3:flat( v )
		return math.cross( math.cross( v, self ), v )
	end

	function Vector3:orthogonal( ratio )
		return self:orthogonal_func()( ratio )
	end

	function Vector3:orthogonal_func( start_dir )
		local rot = Rotation( self, start_dir or Vector3( 0, 0, -1 ) )
		return function( ratio ) return ( -rot:z() * math.cos( 180 + 360 * ratio ) + rot:x() * math.cos( 90 + 360 * ratio ) ):normalized() end
	end

	function Vector3:unpack()
		return self.x, self.y, self.z
	end
end

if Color then
	function Color:unpack()
		return self.r, self.g, self.b
	end
end

local AppClass = getmetatable(Application)
if AppClass then
	function AppClass:draw_box( s_pos, e_pos, r, g, b )
		Application:draw_line( s_pos, Vector3( e_pos.x, s_pos.y, s_pos.z ), r, g, b )
		Application:draw_line( s_pos, Vector3( s_pos.x, e_pos.y, s_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, e_pos.y, s_pos.z ), Vector3( s_pos.x, e_pos.y, s_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, e_pos.y, s_pos.z ), Vector3( e_pos.x, s_pos.y, s_pos.z ), r, g, b )
		
		Application:draw_line( s_pos, Vector3( s_pos.x, s_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( s_pos.x, e_pos.y, s_pos.z ), Vector3( s_pos.x, e_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, s_pos.y, s_pos.z ), Vector3( e_pos.x, s_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, e_pos.y, s_pos.z ), Vector3( e_pos.x, e_pos.y, e_pos.z ), r, g, b )
		
		Application:draw_line( Vector3( s_pos.x, s_pos.y, e_pos.z ), Vector3( e_pos.x, s_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( s_pos.x, s_pos.y, e_pos.z ), Vector3( s_pos.x, e_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, e_pos.y, e_pos.z ), Vector3( s_pos.x, e_pos.y, e_pos.z ), r, g, b )
		Application:draw_line( Vector3( e_pos.x, e_pos.y, e_pos.z ), Vector3( e_pos.x, s_pos.y, e_pos.z ), r, g, b )
	end

	-- Draws a box from one corner (pos) with rotation and length params
	function AppClass:draw_box_rotation( pos, rot, width, depth, height, r, g, b )
		local c1 = pos
		local c2 = pos + rot:x()*width
		local c3 = pos + rot:y()*depth
		local c4 = pos + rot:x()*width + rot:y()*depth
		local c5 = c1 + rot:z()*height
		local c6 = c2 + rot:z()*height
		local c7 = c3 + rot:z()*height
		local c8 = c4 + rot:z()*height

		Application:draw_line( c1, c2, r, g, b )
		Application:draw_line( c1, c3, r, g, b )
		Application:draw_line( c2, c4, r, g, b )
		Application:draw_line( c3, c4, r, g, b )
		
		Application:draw_line( c1, c5, r, g, b )
		Application:draw_line( c2, c6, r, g, b )
		Application:draw_line( c3, c7, r, g, b )
		Application:draw_line( c4, c8, r, g, b )
		
		Application:draw_line( c5, c6, r, g, b )
		Application:draw_line( c5, c7, r, g, b )
		Application:draw_line( c6, c8, r, g, b )
		Application:draw_line( c7, c8, r, g, b )
	end

	function AppClass:draw_rotation_size( pos, rot, size )
		Application:draw_line( pos, pos + rot:x() * size, 1, 0, 0 )
		Application:draw_line( pos, pos + rot:y() * size, 0, 1, 0 )
		Application:draw_line( pos, pos + rot:z() * size, 0, 0, 1 )
	end

	function AppClass:draw_arrow( from, to, r, g, b, scale )
		scale = scale or 1
		local len = (to-from):length()
		local dir = (to-from):normalized()
		local arrow_end_pos = from + dir * (len - 100*scale )
		Application:draw_cylinder( from, arrow_end_pos, 10*scale, r, g, b )
		Application:draw_cone( to, arrow_end_pos , 40*scale, r, g, b )
	end

	function AppClass:stack_dump_error( ... )
		Application:error( ... )
		Application:stack_dump()
	end
	
	
	-- Draws a link between two units (from_unit and to_unit)
	-- Takes a table as params containing:
	--	from_unit						- The unit to draw the link from
	--	to_unit							- The unit to draw the link to
	--	r								- The red color value (0-1)
	--	g								- The green color value (0-1)
	--	b								- The blue color value (0-1)
	--	thick (optional)				- A boolean specifying if the link should be drawn thick
	--  circle_multiplier (optional)	- A number specifying a multiplier for the rings
	--  height_offset (optional)
--[[
	function AppClass:draw_link( params )
		local from_unit = params.from_unit
		local to_unit = params.to_unit
		local r = params.r
		local g = params.g
		local b = params.b
		
	
		local height_offset = params.height_offset or 5
		
		local from = from_unit:position()
		local to = to_unit:position()
		
		mvector3.set_z( from, mvector3.z( from ) + height_offset )
		mvector3.set_z( to, mvector3.z( to ) + height_offset )
	
		
		-- Get the bounding radius from the from unit and draw a circle around it
		local from_bsr = from_unit:bounding_sphere_radius() / 2
		Application:draw_circle( from, from_bsr, r, g, b )
				
		-- Get the bounding radius from the to unit and draw a circle around it
		local to_bsr = to_unit:bounding_sphere_radius() / 2
		Application:draw_circle( to, to_bsr, r, g, b ) 
	
	
		-- Project the coordinates of from and to positions to the xy-plane and calculate lenght and direction of it
		local xy_dir = mvector3.copy( to )
		mvector3.subtract( xy_dir, from )
		mvector3.set_z( xy_dir, 0 )
		mvector3.normalize( xy_dir )
		
	
		-- Calculate the new from and to positions (is now on the circle around the units)
		local tmp_dir = mvector3.copy( xy_dir )
		mvector3.multiply( tmp_dir, from_bsr )
		mvector3.add( from, tmp_dir )
	
		mvector3.set( tmp_dir, xy_dir )
		mvector3.multiply( tmp_dir, to_bsr )
		mvector3.subtract( to, tmp_dir )
		
	
		local dir = mvector3.copy( to )
		mvector3.subtract( dir, from )
		mvector3.normalize( dir )

		if params.draw_flow then
			local dist = mvector3.distance(to, from)
			local dist5 = dist/500
			
			local arrow_len = math.min( 400, dist )
			local p = math.mod( Application:time() * 50, arrow_len )
			
			while p < dist do

				local pos = from + dir * p
				Application:draw_cone( pos, pos + dir * - 10, 4, r, g, b )
			
				p = p + arrow_len
			end			
		end
	
	
		if params.thick then
			Application:draw_cylinder( from, to - dir * 10, 0.5, r, g, b )
			Application:draw_sphere( from, 4, r, g, b )
			
			mvector3.multiply( dir, -20 )
			mvector3.add( dir, to )
			Application:draw_cone( to, dir, 7.5, r, g, b )
		else
			Application:draw_line( from, to, r, g, b )
	
			mvector3.multiply( dir, -16 )
			mvector3.add( dir, to )
			Application:draw_cone( to, dir, 6, r, g, b )
		end
	end
]]
end

if Draw then
	Draw:pen()
	function Pen:arrow( from, to, scale )
		scale = scale or 1
		local len = (to-from):length()
		local dir = (to-from):normalized()
		local arrow_end_pos = from + dir * (len - 100*scale )
		self:cylinder( from, arrow_end_pos, 10*scale )
		self:cone( to, arrow_end_pos, 40*scale )
	end
end
