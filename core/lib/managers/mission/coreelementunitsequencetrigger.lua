core:module( "CoreElementUnitSequenceTrigger" )
core:import( "CoreMissionScriptElement" )
core:import( "CoreCode" )

ElementUnitSequenceTrigger = ElementUnitSequenceTrigger or class( CoreMissionScriptElement.MissionScriptElement )

function ElementUnitSequenceTrigger:init( ... )
	ElementUnitSequenceTrigger.super.init( self, ... )
	if not self._values.sequence_list and self._values.sequence then
		self._values.sequence_list = { { unit_id = self._values.unit_id, sequence = self._values.sequence } }
	end
end

function ElementUnitSequenceTrigger:on_script_activated()
	-- print( "ElementUnitSequenceTrigger:on_script_activated()", self._id, Network:is_client() )
	if Network:is_client() then
		--[[ -- Client no longer register trigger. For interacting, the server uses the client unit as instigator.
		if self._values.trigger_times == 1 then -- This is a hack sollution. The problem is that the trigger will be reported twice, which brakes the system if you
												-- really want it to happen several times. The issue is also that without the client reporting it, there is no way to
												-- know when client interacts with a unit (cop machine) that then gives him a equipment.
			-- managers.mission:add_runned_unit_sequence_trigger( self._values.unit_id, self._values.sequence, callback( self, self, "send_to_host" ) )
			for _,data in pairs( self._values.sequence_list ) do
				managers.mission:add_runned_unit_sequence_trigger( data.unit_id, data.sequence, callback( self, self, "send_to_host" ) )
			end
		end
		]]
	else
		self._mission_script:add_save_state_cb( self._id )
		-- managers.mission:add_runned_unit_sequence_trigger( self._values.unit_id, self._values.sequence, callback( self, self, "on_executed" ) )
		for _,data in pairs( self._values.sequence_list ) do
			managers.mission:add_runned_unit_sequence_trigger( data.unit_id, data.sequence, callback( self, self, "on_executed" ) )
		end
			
	end
	self._has_active_callback = true
end

function ElementUnitSequenceTrigger:send_to_host( instigator )
	-- print( "ElementUnitSequenceTrigger:send_to_host()" )
	-- print( "1 send to host", instigator )
	if alive( instigator ) then
		-- print( "send to HOST", self._id, instigator )
		managers.network:session():send_to_host( "to_server_mission_element_trigger", self._id, instigator ) -- How to send instigator (needed)?
	end
end

function ElementUnitSequenceTrigger:on_executed( instigator )
	if not self._values.enabled then
		return
	end
	
	-- print( " EXECUTE ElementUnitSequenceTrigger", instigator )
	
	-- instigator = managers.mission:default_instigator()
	-- print( "ElementUnitSequenceTrigger:on_executed( instigator )", inspect( instigator ) )
	
	ElementUnitSequenceTrigger.super.on_executed( self, instigator )
end

function ElementUnitSequenceTrigger:save( data )
	data.save_me = true
end

function ElementUnitSequenceTrigger:load( data )
	-- self:set_enabled( data.enabled )
	-- print( "load ElementUnitSequenceTrigger", self._has_active_callback, self._values.unit_id )
	if not self._has_active_callback then
		-- print( " REGISTER TRIGGER" )
		self:on_script_activated()
	end
end
