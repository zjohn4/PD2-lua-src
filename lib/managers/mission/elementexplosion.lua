core:import( "CoreMissionScriptElement" )

ElementExplosion = ElementExplosion or class( ElementFeedback )

function ElementExplosion:init( ... )
	ElementExplosion.super.init( self, ... )
	
	if Application:editor() then	
		if self._values.explosion_effect ~= "none" then
			CoreEngineAccess._editor_load( self.IDS_EFFECT, self._values.explosion_effect:id() )
		end
	end
end

function ElementExplosion:client_on_executed( ... )
	self:on_executed( ... )
end

function ElementExplosion:on_executed( instigator )
	if not self._values.enabled then
		return
	end
	
	print( "ElementExplosion:on_executed( instigator )" )
	
	local pos, rot = self:get_orientation()
	local player = managers.player:player_unit()
	if player then
		player:character_damage():damage_explosion( { position = pos, range = self._values.range, damage = self._values.player_damage } )
	end
	
	managers.explosion:spawn_sound_and_effects( pos, rot:z(), self._values.range, self._values.explosion_effect )
	
	if Network:is_server() then
		-- First server needs to check what damage is done by the explosion .. 
		managers.explosion:detect_and_give_dmg( {
					hit_pos = pos,
					range = self._values.range, 
					collision_slotmask = managers.slot:get_mask( "bullet_impact_targets" ), 
					curve_pow = 5, 
					damage = self._values.damage,
					player_damage = 0 } )
		
		-- .. then server can tell clients that they can push units
		managers.network:session():send_to_peers_synched( "element_explode_on_client", pos, rot:z(), self._values.damage, self._values.range, 5 )
	end
		 						
	ElementExplosion.super.on_executed( self, instigator ) -- This will trigger the feedback (camera shake/rumble etc)
end
