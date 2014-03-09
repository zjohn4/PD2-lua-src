local tmp_vec3 = Vector3()

GrenadeBase = GrenadeBase or class( UnitBase )
GrenadeBase.types = { "frag" }
GrenadeBase.EVENT_IDS = { detonate = 1 }

function GrenadeBase.server_throw_grenade( grenade_type, pos, dir, owner_peer_id )
	local grenade_entry = GrenadeBase.types[ grenade_type ]
	local unit_name = Idstring( tweak_data.blackmarket.grenades[ grenade_entry ].unit )
	local unit = World:spawn_unit( unit_name, pos, Rotation() )
	if owner_peer_id and managers.network:game() then
		local member = managers.network:game():member( owner_peer_id )
		local thrower_unit = member and member:unit()
		if alive( thrower_unit ) then
			unit:base():set_thrower_unit( thrower_unit )
		end
	end
	unit:base():throw( { dir = dir, grenade_entry = grenade_entry } )
	
	managers.network:session():send_to_peers_synched( "sync_throw_grenade", unit, dir, grenade_type )
end

function GrenadeBase.spawn( unit_name, pos, rot ) -- Only called from server
	--[[local brush = Draw:brush( Color.red:with_alpha( 0.5 ) )
	brush:set_persistance( 2 ) 
	brush:sphere( pos, 2 )
	brush:set_color( Color.blue:with_alpha( 0.5 ) )
	brush:cylinder( pos, pos + rot:z() * 50, 1 )
	brush:set_color( Color.green:with_alpha( 0.5 ) )
	brush:cylinder( pos, pos + rot:y() * 50, 1 )]]
	
	local unit = World:spawn_unit( Idstring( unit_name ), pos, rot )
	return unit
end

-----------------------------------------------------------------------------------

function GrenadeBase:init( unit )
	UnitBase.init( self, unit, true )
	self._unit = unit
	
	if not Network:is_server() then
		return 
	end
	self:_setup()
end


function GrenadeBase:set_thrower_unit( unit )
	self._thrower_unit = unit
end

function GrenadeBase:thrower_unit()
	return alive( self._thrower_unit ) and self._thrower_unit or nil
end

-----------------------------------------------------------------------------------

function GrenadeBase:_setup()
	self._slotmask = managers.slot:get_mask( "trip_mine_targets" )
	self._timer = self._init_timer or 3
end

-----------------------------------------------------------------------------------

function GrenadeBase:set_active( active )
	self._active = active
	self._unit:set_extension_update_enabled( Idstring( "base" ), self._active )
	
end

-----------------------------------------------------------------------------------

function GrenadeBase:active()
	return self._active
end

-----------------------------------------------------------------------------------













function GrenadeBase:_detect_and_give_dmg( hit_pos )
	local params = {}
	params.hit_pos = hit_pos
	params.collision_slotmask = self._collision_slotmask
	params.user = self._user
	params.damage = self._damage
	params.player_damage = self._player_damage or self._damage
	params.range = self._range
	params.ignore_unit = self._ignore_unit
	params.curve_pow = self._curve_pow
	params.col_ray = self._col_ray
	params.alert_filter = self._alert_filter
	params.owner = self._owner
	
	local hit_units, splinters = managers.explosion:detect_and_give_dmg(params)
	return hit_units, splinters
end

--[[function GrenadeBase._units_to_push( units_to_push, hit_pos, range )
	for u_key, unit in pairs( units_to_push ) do
		if alive( unit ) then
			local is_character = unit:character_damage() and unit:character_damage().damage_explosion
			if not is_character or unit:character_damage():dead() then
				if is_character then
					if unit:movement()._active_actions[1] and unit:movement()._active_actions[1]:type() == "hurt" then
						unit:movement()._active_actions[1]:force_ragdoll()
					end
				end
				local nr_u_bodies = unit:num_bodies()
				local i_u_body = 0
				while i_u_body < nr_u_bodies do
					local u_body = unit:body( i_u_body )
					if u_body:enabled() and u_body:dynamic() then
						local body_mass = u_body:mass()
						local len = mvector3.direction( tmp_vec3, hit_pos, u_body:center_of_mass() )
						local body_vel = u_body:velocity()
						local vel_dot = mvector3.dot( body_vel, tmp_vec3 )
						local max_vel = 800
						if vel_dot < max_vel then
							local push_vel = ( 1 - len / range ) * ( max_vel - math.max( vel_dot, 0 ) )
							mvector3.multiply( tmp_vec3, push_vel )
							u_body:push_at( body_mass/math.random(2), tmp_vec3, u_body:position() ) -- Create some rotation on the bodies
							-- u_body:push( body_mass, tmp_vec3 )
						end
					end
					i_u_body = i_u_body + 1
				end
			end
		end
	end
end]]

-- Used by grenade launcher explosion to sync what happens on clients
function GrenadeBase._explode_on_client( position, normal, user_unit, dmg, range, curve_pow, custom_params )
	managers.explosion:play_sound_and_effects( position, normal, range, custom_params )
	managers.explosion:client_damage_and_push( position, normal, user_unit, dmg, range, curve_pow )
end

--[[function GrenadeBase._client_damage_and_push( position, normal, user_unit, dmg, range, curve_pow )
	local bodies = World:find_bodies( "intersect", "sphere", position, range, managers.slot:get_mask( "bullet_impact_targets" ) )

	local units_to_push = {}
	for _, hit_body in ipairs( bodies ) do
		units_to_push[ hit_body:unit():key() ] = hit_body:unit()
		
		-- Only apply damage do units that are not network synced
		local apply_dmg = hit_body:extension() and hit_body:extension().damage and (hit_body:unit():id() == -1)
		local dir, len, damage
		if apply_dmg then
			dir = hit_body:center_of_mass()
			len = mvector3.direction( dir, position, dir )
			damage = dmg * math.pow( math.clamp( 1 - len / range, 0, 1 ), curve_pow )
			damage = math.max( damage, 1 ) -- under 1 damage is generally not allowed
			
			local normal = dir

			hit_body:extension().damage:damage_explosion( user_unit, normal, hit_body:position(), dir, damage )
			hit_body:extension().damage:damage_damage( user_unit, normal, hit_body:position(), dir, damage )
		end
	end
	
	GrenadeBase._units_to_push( units_to_push, position, range )
end]]

function GrenadeBase._play_sound_and_effects( position, normal, range, custom_params )
	managers.explosion:play_sound_and_effects( position, normal, range, custom_params )
end

--[[
function GrenadeBase._player_feedback( position, normal, range )
	local player = managers.player:player_unit()
	
	if player then
		local feedback = managers.feedback:create( "mission_triggered" )
		local distance = mvector3.distance_sq( position, player:position() )
		local mul = math.clamp( 1 - distance / (range * range), 0, 1 )

		feedback:set_unit( player )
		feedback:set_enabled( "camera_shake", true )
		feedback:set_enabled( "rumble", true )
		feedback:set_enabled( "above_camera_effect", false )
		
		local params = {
			"camera_shake", "multiplier", 	mul,
			"camera_shake", "amplitude", 	0.50,
			"camera_shake", "attack", 		0.05,
			"camera_shake", "sustain", 		0.15,
			"camera_shake", "decay", 		0.50,
			
			"rumble", "multiplier_data", 	mul,
			"rumble", "peak", 				0.50,
			"rumble", "attack", 			0.05,
			"rumble", "sustain", 			0.15,
			"rumble", "release", 			0.50,
		}
		
		feedback:play( unpack( params ) )
	end
end
]]

--[[
function GrenadeBase._spawn_sound_and_effects( position, normal, range, effect_name )
	effect_name = effect_name or "effects/particles/explosions/explosion_grenade_launcher"
	if effect_name ~= "none" then
		World:effect_manager():spawn( { effect = Idstring( effect_name ), position = position, normal = normal } )
	end
	
	local sound_source = SoundDevice:create_source( "M79GrenadeBase" )
	sound_source:set_position( position )
	sound_source:post_event( "trip_mine_explode" )
	managers.enemy:add_delayed_clbk( "M79expl", callback( GrenadeBase, GrenadeBase, "_dispose_of_sound", { sound_source = sound_source } ), TimerManager:game():time() + 2 )
end
]]

function GrenadeBase._dispose_of_sound( ... ) -- When this callback is called the table parameter is unreferenced and the sound source can be garbage collected
end


-----------------------------------------------------------------------------------

function GrenadeBase:sync_throw_grenade( dir, grenade_type )
	local grenade_entry = GrenadeBase.types[ grenade_type ]
	self:throw( { dir = dir, grenade_entry = grenade_entry } )
end

local mvec1 = Vector3()
function GrenadeBase:throw( params )
	self._owner = params.owner
	local velocity = params.dir * 250
	velocity = Vector3( velocity.x, velocity.y, velocity.z + 50 )
	
	--local mass = math.max( 2 * (1-math.abs( params.dir.z )), 1 ) -- Tweaking the mass used to throw pending on looking angle (throws a bit looser if looking up or down)
	local mass = math.max( 2 * (1+math.min( 0, params.dir.z )), 1 ) -- Tweaking the mass used to throw pending on looking angle (throws a bit looser if looking up or down)
	self._unit:push_at( mass, velocity, self._unit:position() )
	
	if params.grenade_entry then
		local unit_name = tweak_data.blackmarket.grenades[ params.grenade_entry ].sprint_unit
		if unit_name then
			local sprint = World:spawn_unit( Idstring( unit_name ), self._unit:position(), self._unit:rotation() )
			local rot = Rotation( params.dir, math.UP )
			mrotation.x( rot, mvec1 )
			mvector3.multiply( mvec1, 0.25 )
			mvector3.add( mvec1, params.dir )
			mvector3.add( mvec1, math.UP / 2 )
			mvector3.multiply( mvec1, 100 )
			
			sprint:push_at( mass, mvec1, sprint:position() )
		end
	end
	
	--[[self._unit:body( 0 ):set_collision_script_tag( Idstring( "bounce" ) )
	self._unit:body( 0 ):set_collision_script_filter( 1 )
	self._unit:body( 0 ):set_collision_script_quiet_time( 1 )
	self._unit:set_body_collision_callback( callback( self, self, "_bounce" ) )]]
end

function GrenadeBase:_bounce( ... )
	print( "_bounce", ... )
end

-----------------------------------------------------------------------------------

function GrenadeBase:update( unit, t, dt )
	
	if self._timer then
		self._timer = self._timer - dt
		if self._timer <= 0 then
			self._timer = nil
			self:__detonate()
		end
	end
end

-----------------------------------------------------------------------------------

function GrenadeBase:detonate()
	if not self._active then
		return
	end
end

function GrenadeBase:__detonate()
	-- self:_play_sound_and_effects()
	
	if not self._owner then
		-- return
	end
	
	self:_detonate()
end

function GrenadeBase:_detonate()
	print( "no _detonate function for grenade" )
end

function GrenadeBase:_detonate_on_client()
	print( "no _detonate_on_client function for grenade" )
end

function GrenadeBase:sync_net_event( event_id )
	if event_id == GrenadeBase.EVENT_IDS.detonate then
		self:_detonate_on_client()
	end
end

--[[function GrenadeBase:sync_trip_mine_explode()
	self:_play_sound_and_effects()
	self._unit:set_slot( 0 )
end]]

--[[function GrenadeBase:_play_sound_and_effects()
	World:effect_manager():spawn( { effect = Idstring( "effects/particles/explosions/explosion_grenade" ), position = self._unit:position(), normal = self._unit:rotation():y() } )
	self._unit:sound_source():post_event( "trip_mine_explode" )
end]]

-----------------------------------------------------------------------------------

function GrenadeBase:save( data )
	local state = {}
	state.timer = self._timer 
	data.GrenadeBase = state
	
end

function GrenadeBase:load( data )
	local state = data.GrenadeBase
	self._timer = state.timer 
end

-----------------------------------------------------------------------------------

function GrenadeBase:destroy()

end

