-- The EnvironmentEffectsManager holds different kinds of environment effects. The can be started by calling 
-- the use function with desired effect. They can be stopped using the stop function or all can be stopped with stop_all
-- All effects should inherit EnvironmentEffect

-- It will also play and keep track of effects played from mission script (hubelement play_effect)

core:module('CoreEnvironmentEffectsManager')

core:import( "CoreTable" )

EnvironmentEffectsManager = EnvironmentEffectsManager or class()

function EnvironmentEffectsManager:init()
	self._effects = {}
	self._current_effects = {}
	self._mission_effects = {}
	self._repeat_mission_effects = {}
end

-- Add an effect with name and class instance
-- Then check if it should be on as default
function EnvironmentEffectsManager:add_effect( name, effect )
	self._effects[ name ] = effect
	if effect:default() then
		self:use( name )
	end
end

-- Returns an effect
function EnvironmentEffectsManager:effect( name )
	return self._effects[ name ]
end

-- Returns the effect table
function EnvironmentEffectsManager:effects()
	return self._effects
end

-- Returns a sorted table containing names of effects
function EnvironmentEffectsManager:effects_names()
	local t = {}
	for name,effect in pairs( self._effects ) do
		if not effect:default() then
			table.insert( t, name )
		end
	end
	table.sort( t )
	return t
end

-- Called to use an effect
function EnvironmentEffectsManager:use( effect )
	if self._effects[ effect ] then
		if not table.contains( self._current_effects, self._effects[ effect ] ) then
			self._effects[ effect ]:load_effects()
			self._effects[ effect ]:start()
			table.insert( self._current_effects, self._effects[ effect ] )
		end
	else
		Application:error( 'No effect named, '..effect..' availible to use' )
	end
end

-- Called to preload effects (used from CoreActionManager when starting effect from script)
function EnvironmentEffectsManager:load_effects( effect )
	if self._effects[ effect ] then
		self._effects[ effect ]:load_effects()
	end
end

-- Called to stop an effect
function EnvironmentEffectsManager:stop( effect )
	if self._effects[ effect ] then
		self._effects[ effect ]:stop()
		table.delete( self._current_effects, self._effects[ effect ] )
	end
end

-- Called to stop all effects
function EnvironmentEffectsManager:stop_all()
	for _,effect in ipairs( self._current_effects ) do
		effect:stop()
	end
	self._current_effects = {}
end

-- Update all effects
function EnvironmentEffectsManager:update( t, dt )
	for _,effect in ipairs( self._current_effects ) do
		effect:update( t, dt )
	end
	
	-- Check if it is time to spawn or remove repeat effects
	for name,params in pairs( self._repeat_mission_effects ) do
		params.next_time = params.next_time - dt
		if params.next_time <= 0 then
			params.next_time = params.base_time + math.rand( params.random_time )
			params.effect_id = World:effect_manager():spawn( params )
			if params.max_amount then
				params.max_amount = params.max_amount - 1
				if params.max_amount <= 0 then
					self._repeat_mission_effects[ name ] = nil
				end
			end
		end
	end
	
end

function EnvironmentEffectsManager:gravity_and_wind_dir()
	local wind_importance = 0.5
	return ( Vector3( 0,0,-982 ) + Wind:wind_at( Vector3() )*wind_importance )
end

-- Spawn an mission effect and add it to a table for that id
function EnvironmentEffectsManager:spawn_mission_effect( name, params )

	-- Check if it should be handled as a repeating effect
	if params.base_time > 0 or params.random_time > 0 then
		if self._repeat_mission_effects[ name ] then
			self:kill_mission_effect( name )
		end
		params.next_time = 0
		params.effect_id = nil
		self._repeat_mission_effects[ name ] = params
		return
	end
	
	-- Standard, once, effect
	params.effect_id = World:effect_manager():spawn( params )
	self._mission_effects[ name ] = self._mission_effects[ name ] or {}
	table.insert( self._mission_effects[ name ], params )
end

-- Stops all mission effects (stop simulation from editor)
function EnvironmentEffectsManager:kill_all_mission_effects()
	for _,params in pairs( self._repeat_mission_effects ) do
		if params.effect_id then
			World:effect_manager():kill( params.effect_id )
		end
	end
	self._repeat_mission_effects = {}
	
	for _,effects in pairs( self._mission_effects ) do
		for _,params in ipairs( effects ) do
			World:effect_manager():kill( params.effect_id )
		end
	end
	self._mission_effects = {}
end

-- Kills all mission effects in the table name
function EnvironmentEffectsManager:kill_mission_effect( name )
	self:_kill_mission_effect( name, "kill" )
end

-- Fade kills all mission effects in the table name
function EnvironmentEffectsManager:fade_kill_mission_effect( name )
	self:_kill_mission_effect( name, "fade_kill" )
end

-- Kills all mission effects in the table name
function EnvironmentEffectsManager:_kill_mission_effect( name, type )
	local kill = callback( World:effect_manager(), World:effect_manager(), type )
	
	-- If it is an repeating effect, kill that one	
	local params = self._repeat_mission_effects[ name ]
	if params then
		if params.effect_id then
			kill( params.effect_id )
		end
		self._repeat_mission_effects[ name ] = nil
		return
	end

	-- If it is a once effect, kill that one
	local effects = self._mission_effects[ name ]
	if not effects then
		return
	end
	for _,params in ipairs( effects ) do
		kill( params.effect_id )
	end
	self._mission_effects[ name ] = nil
end

function EnvironmentEffectsManager:save( data )
	-- Saves mission played effects, checks if they are still alive (we really only want to start looping effects on load)
	local state = { mission_effects = {} }
	for name,effects in pairs( self._mission_effects ) do
		state.mission_effects[ name ] = {}
		for _,params in pairs( effects ) do
			if World:effect_manager():alive( params.effect_id ) then -- Use this to know if the effect is still playing
				table.insert( state.mission_effects[ name ], params )
			end
		end
	end
	data.EnvironmentEffectsManager = state
end

function EnvironmentEffectsManager:load( data )
	local state = data.EnvironmentEffectsManager
	for name,effects in pairs( state.mission_effects ) do
		for _,params in ipairs( effects ) do
			self:spawn_mission_effect( name, params )
		end
	end
end

---------------------------------------------------------------

EnvironmentEffect = EnvironmentEffect or class()

function EnvironmentEffect:init( default )
	self._default = default
	
end

-- Load effects are called before start of the effect
-- Don't want the effects to be loaded if we are not going to use them
function EnvironmentEffect:load_effects()
	
end

function EnvironmentEffect:update( t, dt )

end

-- Called when starting the effect
function EnvironmentEffect:start()

end

-- Called when stopping the effect
function EnvironmentEffect:stop()

end

function EnvironmentEffect:default()
	return self._default
end

