core:module( "CoreApp" )

--[[

The CoreApp module contains functions for retaining information about the main application.

]]--

---------------------------------------------------------------------- 
--  Functions for retaining application information.
---------------------------------------------------------------------- 

function arg_supplied(key)
	for _,arg in ipairs(Application:argv()) do
		if arg == key then
			return true
		end
	end
	return false
end

function arg_value(key)
	local found
	for _,arg in ipairs(Application:argv()) do
		if found then
			return arg
		elseif arg == key then
			found = true
		end
	end
end

function min_exe_version(version, system_name)
--[[
	local current_version = {}
	local required_version = {}
	
	for n in string.gmatch(Application:version(), "%d+") do
		table.insert(current_version, tonumber(n))
	end
	
	for n in string.gmatch(version, "%d+") do
		table.insert(required_version, tonumber(n))
	end
	
	current_version = {select(3, unpack(current_version))} -- We are only interested in the exe version.
	if #current_version < #required_version then
		local diff = #required_version - #current_version
		required_version = {select(diff + 1, unpack(required_version))}
	end
	
	assert(#current_version == #required_version, "Bad version number!")
	
	for i, n in ipairs(current_version) do
		if n > required_version[i] then
			break
		elseif n < required_version[i] then
			Application:throw_exception("Exe version " .. version .. " is required by " .. (system_name or "UNKNOWN") .. ". Current version is " .. Application:version())
		end
	end
	]]
end
