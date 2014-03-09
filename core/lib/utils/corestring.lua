
core:module( "CoreString" )

--[[

Module CoreString adds several function to the standard
Lua string library. 

]]--

----------------------------------------------------------------------
-- additions to utf8:
----------------------------------------------------------------------

function utf8.find_char( text, char )
	for i,c in ipairs( utf8.characters( text ) ) do
		if c == char then
			return i
		end
	end
end

----------------------------------------------------------------------
-- additions to string:
----------------------------------------------------------------------

function string.begins( s, beginning )
	if( s and beginning ) then
		return s:sub( 1, #beginning ) == beginning
	end

	return false
end

function string.ends( s, ending )
	if( s and ending ) then
		return ( #ending == 0 ) or ( s:sub( -#ending ) == ending )
	end

	return false
end

--- Compare two strings in a case-insensitive fasion.
-- Mainly useful as a comparator function for sorting, e.g.
-- table.sort(names, string.case_insensitive_compare)
function string.case_insensitive_compare(a, b)
	return string.lower(a) < string.lower(b)
end

--- Split a string into a list of component parts.
-- Based on the code "Split a string with a pattern, Take Three" at http://lua-users.org/wiki/StringRecipes
-- @param s				The string to split.
-- @separator_pattern	String pattern to split the string at. Verbatim strings work too. See the docs for Lua string patterns at http://www.lua.org/manual/5.1/manual.html#5.4.1
-- @keep_empty			Optional. If true, keeps empty string matches in the result. "a//bad/path" => { "a", "", "bad", "path" }
-- @max_splits			Optional. The number of times to split the string. The final element in the result will be the remaining string. "first/and/a/bit" => { "first", "and/a/bit" }
-- @return				A list of string component parts, or a list with the input string as its sole entry if no matches were found.
function string.split(s, separator_pattern, keep_empty, max_splits)
    local result = {}
    local pattern = "(.-)" .. separator_pattern .. "()"
    local count = 0
    local final_match_end_index = 0
    
    for part, end_index in string.gmatch(s, pattern) do
    	final_match_end_index = end_index
    	if keep_empty or part ~= "" then
	        count = count + 1
	        result[count] = part
	        if count == max_splits then break end
        end
    end
    
    -- We need to add the remainder of the string explicitly, as our pattern won't catch it.
    local remainder = string.sub(s, final_match_end_index)
    result[count + 1] = (keep_empty or remainder ~= "") and remainder or nil
    return result
end

function string.join(separator, elements, keep_empty)
	local strings = table.collect(elements, function(element)
		local as_string = tostring(element)
		if as_string ~= "" or keep_empty then
			return as_string
		end
	end)
	
	return table.concat(strings, separator)
end

function string.trim(s, pattern)
	pattern = pattern or "%s*"
	return string.match(s, "^" .. pattern .. "(.-)" .. pattern .. "$")
end

function string.capitalize(s)
	return string.gsub(s, "(%w)(%w*)", function(first_letter, remaining_letters) return string.upper(first_letter) .. string.lower(remaining_letters) end)
end

function string.pretty(s, capitalize)
	local pretty = string.gsub(s, "%W", " ")
	return capitalize and string.capitalize(pretty) or pretty
end

function string:rep(n)
    local out = ""
    for i=1,n do out = out .. self end
    return out
end

function string:left(n)
    return self .. (" "):rep(n - self:len())
end
