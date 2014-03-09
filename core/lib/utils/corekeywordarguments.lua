
core:module( "CoreKeywordArguments" )

core:import( "CoreClass" )

--[[

The CoreKeywordArguments provides some functionality for
using tables when passing arguments to functions. The advantage
is that: a) we get a type-check of the data, and b) the order
that the arguments are passed becomes irrelevant (nice for
long argument lists).

This module supports two different variants to do this:

1. parse_kwargs
---------------
parse_kwargs is intended as a helper function to be used in
normal functions (or methods).

Example without parse_kwargs:

	function foo( alfa, beta )
		local c = beta * 2
		cat_print( "spam", alfa .. ":" .. tostring( c ) )
	end

	foo( "double", 3 )


And with parse_kwargs:

	core:import( "CoreKeywordArguments" )           -- put this at the top of the file ...
	local parse_kwargs = CoreKeywordArguments.parse_kwargs  -- just for convenience if used in many functions ...
	
	function foo( ... )
		local alfa, beta = parse_kwargs( {...}, 'string:alfa', 'number:beta' )
		local c = beta * 2
		cat_print( "spam", alfa .. ":" .. tostring( c ) )
	end

	foo{ alfa = "double", beta = 3 }


2. KeywordArguments
-------------------
KeywordArguments is intended to be used in the init method of a class,
when the attributes of an instance is populated.

Example:

	MyClass = CoreClass.class()
	
	MyClass:init( ... )
		local args = CoreKeywordArguments.KeywordArguments:new( ... )
		self._name = args:mandatory_string( "name" )
		self._cb   = args:mandatory_function( "my_class_modified_cb"
		self._col  = args:optional_string( "color" )		
		args:assert_all_consumed()
		
	end
	
	local my_instance = MyClass:new{ name                 = "SUNE",
	                                 my_class_modified_cb = foo,
	                                 color                = "red" }

]]--


-----------------------------------------------------------------------
--  function: p a r s e _ k w a r g s
--
-----------------------------------------------------------------------

function parse_kwargs ( args, ... )
	assert( #args == 1 )
	assert( type(args[1]) == "table" )
	local kwargs = args[1]
	local result = {}
	for _,arg_def in ipairs{...} do
		local j     = string.find( arg_def, ":" )
		local typ   = string.sub( arg_def, 1, j-1 )
		local name  = string.sub( arg_def, j+1 )
		local value = kwargs[ name ]
		assert( type( value ) == typ, 
		        string.format( "For value='%s' wanted type is '%s', received '%s'", 
		                        name, typ, type(value) ) )
		table.insert( result, value )
		kwargs[ name ] = nil
	end
	for n,v in pairs( kwargs ) do
		assert( n )
	end
	return unpack( result )
end



-----------------------------------------------------------------------
--  class: K e y w o r d A r g u m e n t s 
--
-----------------------------------------------------------------------
KeywordArguments = KeywordArguments or CoreClass.class()

function KeywordArguments:init(...)
	local args = {...}
	assert( #args == 1, "must be called with one argument only (a table with keyword arguments)" )
	assert( type(args[1]) == "table", "must be called with table as first argument" )
	self._kwargs = args[1]
	self._unconsumed_kwargs = {}
	for k,_ in pairs( self._kwargs ) do
		self._unconsumed_kwargs[k] = k
	end
end

function KeywordArguments:assert_all_consumed()
	assert( table.size( self._unconsumed_kwargs ) == 0, "unknown keyword argument(s): " .. string.join( ", ", self._unconsumed_kwargs ) )
end


function KeywordArguments:mandatory( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:mandatory_string( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		assert( type( v ) == "string", "keyword argument is not a string (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:mandatory_number( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		assert( type( v ) == "number", "keyword argument is not a number (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:mandatory_table( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		assert( type( v ) == "table", "keyword argument is not a table (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:mandatory_function( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		assert( ( type( v ) == "function" ), 
		        "keyword argument is not a function (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:mandatory_object( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( v ~= nil, "a mandatory keyword argument (" .. n .. ") is missing" )
		assert( ( type( v ) == "table" ) or ( type( v ) == "userdata" ), 
		        "keyword argument is not a table or userdata (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end


function KeywordArguments:optional( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		table.insert( ret_list, self._kwargs[n] )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:optional_string( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( ( v == nil ) or ( type( v ) == "string" ), 
		        "keyword argument is not a string (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:optional_number( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( ( v == nil ) or ( type( v ) == "number" ), 
		        "keyword argument is not a number (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:optional_table( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( ( v == nil ) or ( type( v ) == "table" ), 
		        "keyword argument is not a table or userdata (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:optional_function( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( ( v == nil ) or ( type( v ) == "function" ), "keyword argument is not a function (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

function KeywordArguments:optional_object( ... )
	local ret_list = {}
	for _,n in ipairs{...} do
		local v = self._kwargs[n]
		assert( ( v == nil ) or ( type( v ) == "table" ) or ( type( v ) == "userdata" ), 
		        "keyword argument is not a table or userdata (" .. n .. "=" .. tostring( v ) .. ")" )
		table.insert( ret_list, v )
		self._unconsumed_kwargs[n] = nil
	end
	return unpack( ret_list )
end

