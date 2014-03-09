AmmoBagBase = AmmoBagBase or class( UnitBase )

function AmmoBagBase.spawn( pos, rot, ammo_upgrade_lvl ) -- Only called from server
	local unit_name = "units/payday2/equipment/gen_equipment_ammobag/gen_equipment_ammobag"
	--[[local unit_name = "units/payday2/equipment/gen_equipment_ammobag_small/gen_equipment_ammobag_small"
	if ammo_upgrade_lvl > 0 then
		unit_name = "units/payday2/equipment/gen_equipment_ammobag_large/gen_equipment_ammobag_large"
	end]]
	local unit = World:spawn_unit( Idstring( unit_name ), pos, rot )
	managers.network:session():send_to_peers_synched( "sync_ammo_bag_setup", unit, ammo_upgrade_lvl )
	unit:base():setup( ammo_upgrade_lvl )
	return unit
end

-----------------------------------------------------------------------------------

-- This is only set by server. This way he can find the unit a remove it if the owning peer id leaves 
function AmmoBagBase:set_server_information( peer_id )
	self._server_information = { owner_peer_id = peer_id }
	managers.network:game():member( peer_id ):peer():set_used_deployable( true )
end

-- Called by server when client leaves
function AmmoBagBase:server_information()
	return self._server_information
end

-----------------------------------------------------------------------------------

function AmmoBagBase:init( unit )
	UnitBase.init( self, unit, false )
	self._unit = unit
	
	-- Used to calculate visual state
	self._max_ammo_amount = tweak_data.upgrades.ammo_bag_base + managers.player:upgrade_value_by_level( "ammo_bag", "ammo_increase", 1 )
	
	self._unit:sound_source():post_event( "ammo_bag_drop" )
	
	-- self:_setup()
end

-----------------------------------------------------------------------------------

function AmmoBagBase:sync_setup( ammo_upgrade_lvl )
	self:setup( ammo_upgrade_lvl )
end

-----------------------------------------------------------------------------------

function AmmoBagBase:setup( ammo_upgrade_lvl )
	self._ammo_amount = tweak_data.upgrades.ammo_bag_base + managers.player:upgrade_value_by_level( "ammo_bag", "ammo_increase", ammo_upgrade_lvl )
		
	self:_set_visual_stage()  
	
	if Network:is_server() then
		local from_pos = self._unit:position() + self._unit:rotation():z() * 10
		local to_pos = self._unit:position() + self._unit:rotation():z() * -10
		local ray = self._unit:raycast( "ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask( "world_geometry" ) )
		if ray then
			self._attached_data = {}
			self._attached_data.body = ray.body
			self._attached_data.position = ray.body:position()
			self._attached_data.rotation = ray.body:rotation()
			self._attached_data.index = 1
			self._attached_data.max_index = 3
			
			self._unit:set_extension_update_enabled( Idstring( "base" ), true )
		end
	end
end

function AmmoBagBase:update( unit, t, dt )
	self:_check_body()
end

-- If the body where the bag is placed is disabled, moved or rotated - removed.
function AmmoBagBase:_check_body()
	if self._is_dynamic then
		return
	end

	if not alive( self._attached_data.body ) then
		self:server_set_dynamic()

		return
	end
	
	if self._attached_data.index == 1 then
		if not self._attached_data.body:enabled() then
			self:server_set_dynamic()

		end
	elseif self._attached_data.index == 2 then
		if not mrotation.equal( self._attached_data.rotation, self._attached_data.body:rotation() ) then
			self:server_set_dynamic()

		end
	elseif self._attached_data.index == 3 then
		if mvector3.not_equal( self._attached_data.position, self._attached_data.body:position() ) then
			self:server_set_dynamic()

		end
	end
	self._attached_data.index = (self._attached_data.index < self._attached_data.max_index and self._attached_data.index or 0) + 1 
end

-----------------------------------------------------------------------------------

function AmmoBagBase:server_set_dynamic()
	self:_set_dynamic()
	if managers.network:session() then
		managers.network:session():send_to_peers_synched("sync_unit_event_id_8", self._unit, "base", 1)
	end
end

function AmmoBagBase:sync_net_event( event_id )

	self:_set_dynamic()
end

function AmmoBagBase:_set_dynamic()
	self._is_dynamic = true
	self._unit:body("dynamic"):set_enabled(true)
end

-----------------------------------------------------------------------------------

function AmmoBagBase:take_ammo( unit )
	if self._empty then
		return
	end
	
	local taken = self:_take_ammo( unit )
	if taken > 0 then
		unit:sound():play( "pickup_ammo" )
		managers.network:session():send_to_peers_synched( "sync_ammo_bag_ammo_taken", self._unit, taken )
	end
	
	-- print( "Took " .. taken .. " ammo, " .. self._ammo_amount .. " left" )
	
	if self._ammo_amount <= 0 then
		self:_set_empty()
	else
		self:_set_visual_stage()
	end
	
	return taken > 0
end

function AmmoBagBase:_set_visual_stage()
	local percentage = self._ammo_amount / self._max_ammo_amount
	if self._unit:damage() then
		local state = "state_"..math.ceil( percentage * 6 )
		if self._unit:damage():has_sequence( state ) then 
			self._unit:damage():run_sequence_simple( state )
		end
	end
end

function AmmoBagBase:sync_ammo_taken( amount )
	self._ammo_amount = self._ammo_amount - amount
	if self._ammo_amount <= 0 then
		self:_set_empty()
	else
		self:_set_visual_stage()
	end
end

function AmmoBagBase:_take_ammo( unit )
	local taken = 0
	local inventory = unit:inventory()
	if inventory then
		for _,weapon in pairs( inventory:available_selections() ) do
			local took = weapon.unit:base():add_ammo_from_bag( self._ammo_amount )
			taken = taken + took
			self._ammo_amount = self._ammo_amount - took
			if self._ammo_amount <= 0 then
				self:_set_empty()
				return taken
			end
		end
	end
	return taken
end

function AmmoBagBase:_set_empty()
	self._empty = true
	self._unit:set_slot( 0 )
end

-----------------------------------------------------------------------------------

function AmmoBagBase:save( data )
	local state = {}
	state.ammo_amount = self._ammo_amount
	state.is_dynamic = self._is_dynamic
	data.AmmoBagBase = state
end

function AmmoBagBase:load( data )
	local state = data.AmmoBagBase
	self._ammo_amount = state.ammo_amount
	if state.is_dynamic then
		self:_set_dynamic()
	end

	self:_set_visual_stage()
end

-----------------------------------------------------------------------------------

function AmmoBagBase:destroy()

end

