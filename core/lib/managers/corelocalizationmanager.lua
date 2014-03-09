core:module( "CoreLocalizationManager" )

core:import( "CoreClass" )
core:import( "CoreEvent" )

--[[

 Localization manager

 The purpose of the localizationmanager is to simplify working
 with strings on different SKU's and in different languages.

 The 2 main features:
  * Platform-specific strings
  * Macros in strings


 --- PLATFORM-SPECIFIC STRINGS ---
	Sometimes we have the same features on the different platforms and they
 have to be presented differentely. Like online multiplayer for instance.
 On Xbox360 it is required to call this menu "Xbox LIVE" but on the PC the
 menu would read simply "Online". That is solved by overriding string ID's.

 Example:
	<string id="mnm_multiplayer_X360" value="Xbox LIVE"/>
	<string id="mnm_multiplayer_WIN32" value="Online"/>
	<string id="mnm_multiplayer" value="Fallback"/>

 So if you refer to the string mnm_multiplayer and the game runs on x360 you will
 get "Xbox LIVE" back. If the game runs on Win32 you will get "Online". If the game
 runs on any other platform (for example PS3) you will get "Fallback"


 --- MACROS IN STRINGS ---
	When you have to replace bits in strings with runtime generated content, such as
 player names or a counter showing progress then you can use macros.

 Example:
	<string id="ig_welcome" value="Hello $PLAYER_NAME;, and welcome to the game!"/>

 It is easy to replace the macro PLAYER_NAME with any runtime generated data and it
 will be possible for the localization team to handle proper grammar in all different
 languages. To access the string and replace the macro you simply do:
	LocalizationManager:text("ig_welcome", {PLAYER_NAME="Bosse})


 LocalizationManager
 -----------------
 public methods:
	load(path)
	string_map(xml_name)
	set_default_macro(macro, value)
	exists(string_id)
	text(string_id, macros)


]]

LocalizationManager = LocalizationManager or CoreClass.class()


------------------------------------------------------------------------------------------------------------------
--
--
--
function LocalizationManager:init()
	Localizer:set_post_processor( CoreEvent.callback( self, self, "_localizer_post_process" ) )

	-- Default macros
	self._default_macros = {}
	self:set_default_macro( "NL", "\n" )
	self:set_default_macro( "EMPTY", "" )

	local platform_id = SystemInfo:platform()
	if( platform_id == Idstring( "X360" ) ) then
		self._platform = "X360"
	elseif( platform_id == Idstring( "PS3" ) ) then
		self._platform = "PS3"
	else
		self._platform = "WIN32"
	end
end

------------------------------------------------------------------------------------------------------------------
--
-- LocalizationManager:add_default_macro( macro, value )
--
-- Deprecated. Use set_default_macro
--
function LocalizationManager:add_default_macro( macro, value )
	self:set_default_macro(macro, value)
end


------------------------------------------------------------------------------------------------------------------
--
-- LocalizationManager:set_default_macro( macro, value )
--
-- Will set a macro that is always used regardless what macros are passed to the text function
-- These macros should be images for controller buttons etc..
--
-- Input:
--	macro		- String, the name of the macro. BTN_BACK for instance. Keep macros UPPERCASE for simplicity
--	value		- Any object, what the macro should be replaced with
--
function LocalizationManager:set_default_macro( macro, value )
	if( not self._default_macros ) then
		self._default_macros = {}
	end
	--table.insert( self._default_macros, { macro, value } )
	self._default_macros["$"..macro..";"] = tostring( value )
end

function LocalizationManager:get_default_macro( macro )
	return self._default_macros["$"..macro..";"]
end

------------------------------------------------------------------------------------------------------------------
--
-- LocalizationManager:exists(string_id)
--
-- Check if the is available
--
-- Input:
--	string_id		- String, the name of the string you need to check
--
-- Output:
--	boolean			- If the string exists or not
--
function LocalizationManager:exists(string_id)
	return Localizer:exists( Idstring( string_id ) )
end


------------------------------------------------------------------------------------------------------------------
--
-- LocalizationManager:text( string_id, macros )
--
-- Translates string_id to a string that can be displayed to the end user
-- Replace macros in the string with either default macros or macros provided
-- to this function.
--
-- Input:
--	string_id		- String, the name of the string you need translated
--	macros			- Table, a table or macros. Can be nil
--
-- Output:
--	String			- The translated and processed string
--
-- The macro table:
--	A simple table where the key is the name of the macro and the value is what should be instead of the macro
--
-- Usage:
--	managers.localization:text("ig_welcome", {PLAYER_NAME="Player 1"} )
--
function LocalizationManager:text( string_id, macros )
	local return_string = "ERROR: " .. string_id
	local str_id = nil

	if( not string_id or string_id == "" ) then
		return_string = ""
	elseif( self:exists( string_id .. "_" .. self._platform ) ) then
		str_id = string_id .. "_" .. self._platform
	elseif( self:exists( string_id ) ) then
		str_id = string_id
	end

	if( str_id ) then
		self._macro_context = macros
		return_string = Localizer:lookup( Idstring( str_id ) )
		self._macro_context = nil
	end

	return return_string
end




------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
--
--  Private functions
--
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

function LocalizationManager:_localizer_post_process( string )
	local localized_string = string
	local macros = {}

	--
	if( type(self._macro_context) ~= "table" ) then
		self._macro_context = {}
	end
	
	--
	for k, v in pairs( self._default_macros ) do
		macros[k] = v
	end
	
	-- Build a table of all the macros we want to replace
	for k, v in pairs( self._macro_context ) do
		macros["$"..k..";"] = tostring(v)
	end

	-- Is this usefull
	if self._pre_process_func then
		self._pre_process_func( macros )
	end
	
	localized_string = string.gsub( localized_string, "%b$;", macros )		--search for words that start with $ and ends with ; matching macros(table) key and replace with macros value for that key

	return localized_string
end
