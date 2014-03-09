core:module( "CoreElementDebug" )
core:import( "CoreMissionScriptElement" )

ElementDebug = ElementDebug or class( CoreMissionScriptElement.MissionScriptElement )

function ElementDebug:init( ... )
	ElementDebug.super.init( self, ... )
end

function ElementDebug:client_on_executed( ... )
	self:on_executed( ... )
end

function ElementDebug:on_executed( instigator )
	if not self._values.enabled then
		return
	end

	-- self:_print_debug( "[ElementDebug]: ".. self._values.debug_string )
	local prefix = "<debug>    "
	local text = prefix .. self._values.debug_string
	if not self._values.as_subtitle then
		if self._values.show_instigator then
			text = text .. " - " .. tostring( instigator )
		end
	end
	local color = self._values.color or self._values.as_subtitle and Color.yellow
	managers.mission:add_fading_debug_output(text, color, self._values.as_subtitle)
	-- managers.mission:add_fading_debug_output( prefix..self._values.debug_string.." "..(instigator and instigator:name():s() or "") )
	ElementDebug.super.on_executed( self, instigator )
end
