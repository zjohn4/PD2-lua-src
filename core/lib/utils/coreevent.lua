if core then
	core:module( "CoreEvent" )

	core:import( "CoreDebug" )
end

--[[

The module CoreEvent has various functions/classes for
supporting callbacks, events, etc...

]]--


----------------------------------------------------------------------
-- function: callback
----------------------------------------------------------------------
function callback( o, base_callback_class, base_callback_func_name, base_callback_param )
	if( base_callback_class and base_callback_func_name and base_callback_class[ base_callback_func_name ] ) then
		if( base_callback_param ~= nil ) then
			if( o ) then
				return function( ... ) return base_callback_class[ base_callback_func_name ]( o, base_callback_param, ... ) end
			else
				return function( ... ) return base_callback_class[ base_callback_func_name ]( base_callback_param, ... ) end
			end
		else
			if( o ) then
				return function( ... ) return base_callback_class[ base_callback_func_name ]( o, ... ) end
			else
				return function( ... ) return base_callback_class[ base_callback_func_name ]( ... ) end
			end
		end
	elseif( base_callback_class ) then
		local class_name = base_callback_class and CoreDebug.class_name( getmetatable( base_callback_class ) or base_callback_class )
		error( "Callback on class \"" .. tostring( class_name ) .. "\" refers to a non-existing function \"" .. tostring( base_callback_func_name ) .. "\"." )
	elseif( base_callback_func_name ) then
		error( "Callback to function \"" .. tostring( base_callback_func_name ) .. "\" is on a nil class." )
	else
		error( "Callback class and function was nil." )
	end
end


----------------------------------------------------------------------
-- Ticket system, for optimization
----------------------------------------------------------------------
local tc = 0

function get_ticket(delay)
	return {delay,math.random(delay-1)}
end

function valid_ticket(ticket)
	return tc%ticket[1]==ticket[2]
end

function update_tickets()
	tc = tc + 1
	if tc > 30 then
		tc = 0
	end
end


----------------------------------------------------------------------
-- class: B a s i c E v e n t H a n d l i n g
--
-- usage: MyClass = MyClass or class()
--        mixin(MyClass, BasicEventHandling)
----------------------------------------------------------------------
BasicEventHandling = {}

BasicEventHandling.connect = function(self, event_name, callback_func, data)
	self._event_callbacks = self._event_callbacks or {}
	self._event_callbacks[event_name] = self._event_callbacks[event_name] or {}
	local wrapped_func = function(...) callback_func(data, ...) end
	table.insert(self._event_callbacks[event_name], wrapped_func)
	return wrapped_func
end

BasicEventHandling.disconnect = function(self, event_name, wrapped_func)
	if self._event_callbacks and self._event_callbacks[event_name] then
		table.delete(self._event_callbacks[event_name], wrapped_func)
		if table.empty(self._event_callbacks[event_name]) then
			self._event_callbacks[event_name] = nil
			if table.empty(self._event_callbacks) then
				self._event_callbacks = nil
			end
		end
	end
end

BasicEventHandling._has_callbacks_for_event = function(self, event_name)
	return self._event_callbacks ~= nil and self._event_callbacks[event_name] ~= nil
end

BasicEventHandling._send_event = function(self, event_name, ...)
	if self._event_callbacks then
		for _, wrapped_func in ipairs(self._event_callbacks[event_name] or {}) do
			wrapped_func(...)
		end
	end
end


----------------------------------------------------------------------
-- class: C a l l b a c k H a n d l e r
--
-- Basic CallbackHandler.
----------------------------------------------------------------------
CallbackHandler = CallbackHandler or class()

function CallbackHandler:init()
    self:clear()
end

function CallbackHandler:clear()
    self._t = 0
    self._sorted = {}
end

function CallbackHandler:__insert_sorted(cb)
    local i = 1
    while self._sorted[i] and (self._sorted[i].next == nil or cb.next > self._sorted[i].next) do
        i = i + 1
    end
    table.insert(self._sorted, i, cb)
end

function CallbackHandler:add(f, interval, times)
	if not times then
		times = -1
	end
    local cb = {f = f, interval = interval, times = times, next = self._t + interval}
    self:__insert_sorted(cb)
    return cb
end

function CallbackHandler:remove(cb)
	if cb then
    	cb.next = nil
    end
end

function CallbackHandler:update(dt)
    self._t = self._t + dt
    while true do
        local cb = self._sorted[1]
        
        if cb == nil then
            return
        elseif cb.next == nil then
            table.remove(self._sorted, 1)
        elseif cb.next > self._t then
            return
        else
            table.remove(self._sorted, 1)
            cb.f(cb, self._t)
            if cb.times >= 0 then
                cb.times = cb.times - 1
                if cb.times <= 0 then cb.next = nil end
            end
            if cb.next then
                cb.next = cb.next + cb.interval
                self:__insert_sorted(cb)
            end
        end
    end
end


-- Handler for callbacks. You can safely add and remove functions while calling the callback functions.

CallbackEventHandler = CallbackEventHandler or class()

function CallbackEventHandler:init()
	--[[ Used variables:
	self._callback_map = nil
	self._next_callback = nil
	]]
end

function CallbackEventHandler:clear()
	self._callback_map = nil
end

function CallbackEventHandler:add( func )
	self._callback_map = self._callback_map or {}
	self._callback_map[ func ] = true
end

function CallbackEventHandler:remove( func )
	if( not self._callback_map or not self._callback_map[ func ] ) then
		return
	end

	if( self._next_callback == func ) then
		self._next_callback = next( self._callback_map, self._next_callback )
	end

	self._callback_map[ func ] = nil

	if( not next( self._callback_map ) ) then
		self._callback_map = nil
	end
end

function CallbackEventHandler:dispatch( ... )
	if( self._callback_map ) then
		self._next_callback = next( self._callback_map )
		self._next_callback( ... )

		while( self._next_callback ) do
			self._next_callback = next( self._callback_map, self._next_callback )

			if( self._next_callback ) then
				self._next_callback( ... )
			end
		end
	end
end



----------------------------------------------------------------------
-- Helper functions for new gui animation coroutines
--
-- In the new gui, animation is done with coroutines. These are some
-- helper functions for writing such functions.
----------------------------------------------------------------------

-- Calls the function f over the specified number of seconds. Each time
-- f is called it is called as f(p, t). p is the fraction of total time
-- that has elapsed (ranges from 0-1), while t is the total time elapsed
-- in seconds.
function over(seconds, f, fixed_dt)
    local t = 0
    while true do
    	local dt = coroutine.yield()
        t = t + (fixed_dt and 1/30 or dt)
        if t >= seconds then break end
        f(t/seconds, t)
    end
    f(1, seconds)
end

-- Used to loop in for loops:
--      for t,p,dt in seconds(10) do
--      end
-- If no number is given, loops forever and p = t
function seconds(s, t)
    if not t then return seconds,s,0 end
    if s and t>=s then return nil end
    local dt = coroutine.yield()
    t = t + dt
    if s and t>s then t=s end
    if s then
        return t, t/s, dt
    else
        return t, t, dt
    end
end

-- Waits until the specified number of seconds have elapsed.
function wait(seconds,fixed_dt)
    local t = 0
    while t < seconds do
    	local dt = coroutine.yield()
        t = t + (fixed_dt and 1/30 or dt)
    end
end

