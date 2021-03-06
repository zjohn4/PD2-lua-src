FragGrenade = FragGrenade or class( GrenadeBase )

-----------------------------------------------------------------------------------

function FragGrenade:init( unit )
	self._init_timer = 2.5
	
	FragGrenade.super.init( self, unit )
	
	
	self._range = tweak_data.grenades.frag.range
	self._effect_name = "effects/payday2/particles/explosions/grenade_explosion"
	self._curve_pow = 3
	self._damage = tweak_data.grenades.frag.damage
	self._player_damage = tweak_data.grenades.frag.player_damage
	
	self._custom_params = { effect = self._effect_name, sound_event = "grenade_explode", feedback_range = self._range * 2, camera_shake_max_mul = 4, sound_muffle_effect = true }
end

-----------------------------------------------------------------------------------

function FragGrenade:_detonate()
	local pos = self._unit:position()
	local normal = math.UP
	local range = self._range
	local slot_mask = managers.slot:get_mask( "bullet_impact_targets" )
	
	managers.explosion:give_local_player_dmg( pos, range, self._player_damage )
	
	managers.explosion:play_sound_and_effects( pos, normal, range, self._custom_params )
	
	local hit_units, splinters = managers.explosion:detect_and_give_dmg( {
		hit_pos = pos,
		range = range,
		collision_slotmask = slot_mask,
		curve_pow = self._curve_pow,
		damage = self._damage,
		player_damage = 0,
		ignore_unit = self._unit,
		user = self:thrower_unit()
	} )
	managers.network:session():send_to_peers_synched( "sync_unit_event_id_8", self._unit, "base", GrenadeBase.EVENT_IDS.detonate )
	
	self._unit:set_slot( 0 )
end

function FragGrenade:_detonate_on_client()
	local pos = self._unit:position()
	local range = self._range
	managers.explosion:give_local_player_dmg( pos, range, self._player_damage )
	managers.explosion:explode_on_client( pos, math.UP, nil, self._damage, range, self._curve_pow, self._custom_params )
end

function FragGrenade:bullet_hit()
	if not Network:is_server() then
		return 
	end
	print("FragGrenade:bullet_hit()")
	self._timer = nil
	self:_detonate()
end

function FragGrenade:OLD_detonate()
	local units = World:find_units( "sphere", self._unit:position(), 400, self._slotmask )
	
	--[[local brush = Draw:brush( Color.green:with_alpha( 0.5 ) )
	brush:set_persistance( 2 ) 
	brush:sphere( self._unit:position(), 500 )]]
		
	for _,unit in ipairs( units ) do
		local col_ray = {}
		col_ray.ray = (unit:position()-self._unit:position()):normalized()
		col_ray.position = self._unit:position()
		if unit:character_damage() and unit:character_damage().damage_explosion then
			-- return self:_give_explosion_damage( col_ray, unit, 10 )
			self:_give_explosion_damage( col_ray, unit, 10 )
		end
	end
		
	-- managers.network:session():send_to_peers_synched( "sync_trip_mine_explode", self._unit )
	self._unit:set_slot( 0 )
end

--[[function FragGrenade:sync_trip_mine_explode()
	self:_play_sound_and_effects()
	self._unit:set_slot( 0 )
end]]

function FragGrenade:OLD_play_sound_and_effects()
	World:effect_manager():spawn( { effect = Idstring( "effects/particles/explosions/explosion_grenade" ), position = self._unit:position(), normal = self._unit:rotation():y() } )
	self._unit:sound_source():post_event( "trip_mine_explode" )
end

function FragGrenade:OLD_give_explosion_damage( col_ray, unit, damage )
	local action_data = {}
	action_data.variant = "explosion"
	action_data.damage = damage
	action_data.attacker_unit = self._unit
	-- action_data.attacker_unit = self._owner
	action_data.col_ray = col_ray
	
	local defense_data = unit:character_damage():damage_explosion( action_data )
	return defense_data
end

-----------------------------------------------------------------------------------
