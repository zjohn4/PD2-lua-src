core:module( "CoreInternalGameState" )

--[[

Game state

]]--

GameState = GameState or class()

function GameState:init( name, game_state_machine )
	self._name = name
	self._gsm  = game_state_machine
end

function GameState:destroy()
end

function GameState:name()
	return self._name
end

function GameState:gsm()
	return self._gsm
end


-- ------------------------------------------------------
-- General transition methods
-- ------------------------------------------------------

function GameState:at_enter( previous_state )
end

function GameState:at_exit( next_state )
end

function GameState:default_transition( next_state )
	self:at_exit( next_state )
	next_state:at_enter( self )
end


-- ------------------------------------------------------
-- Special handling for editor
-- ------------------------------------------------------

function GameState:force_editor_state()
	-- GP can override this method to specialize the editor state.
	self._gsm:change_state_by_name( "editor" )
end

function GameState:allow_world_camera_sequence()
	-- Override this method allow the editor to start a worldcamera.
	return false
end

function GameState:play_world_camera_sequence( name, sequence )
	-- Override this method to allow the editor to run a world camera sequence
	error('NotImplemented')
end


-- ------------------------------------------------------
-- Special handling for freeflight
-- ------------------------------------------------------

function GameState:allow_freeflight()
	-- Override this method to veto going into freeflight from your state.
	return true
end

function GameState:freeflight_drop_player( pos, rot )
	-- Override this method to support dropping of the player from freeflight.
	Application:error( "[FreeFlight] Drop player not implemented for state '" .. self:name() .. "'" )
end
