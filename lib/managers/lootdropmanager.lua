LootDropManager = LootDropManager or class()

function LootDropManager:init()
	self:_setup()
end

function LootDropManager:_setup()
	self:add_qlvl_to_weapon_mods()

	if not Global.lootdrop_manager then
		Global.lootdrop_manager = {}
		self:_setup_items()
	end
	self._global = Global.lootdrop_manager
end

function LootDropManager:add_qlvl_to_weapon_mods( override_tweak_data )
	local weapon_mods_tweak_data = override_tweak_data or tweak_data.blackmarket.weapon_mods
	--[[
	local weapon_level_data = {}
	for level, data in pairs( tweak_data.upgrades.level_tree ) do
		if data.upgrades then
			for _, upgrade in ipairs( data.upgrades ) do
				local def = tweak_data.upgrades.definitions[ upgrade ]
				if def.weapon_id then
					local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id( def.weapon_id )
					weapon_level_data[ factory_id ] = level
				end
			end
		end

	end
	
	for part_id, data in pairs( tweak_data.weapon.factory.parts ) do
		local weapon_uses_part = managers.weapon_factory:get_weapons_uses_part( part_id ) or {}
		local min_level = managers.experience:level_cap()

		for _, factory_id in ipairs( weapon_uses_part ) do
			if not table.contains( tweak_data.weapon.factory[ factory_id ].default_blueprint, part_id ) then
				min_level = math.min( min_level, weapon_level_data[ factory_id ] or 0 )
			end
		end



		weapon_mods_tweak_data[ part_id ].qlvl = min_level
	end
	]]
	
	local weapons_data = {}
	for weapon_id, data in pairs( Global.blackmarket_manager.weapons ) do
		weapons_data[ data.factory_id ] = data.level
	end
	
	for part_id, data in pairs( tweak_data.weapon.factory.parts ) do
		local weapon_uses_part = managers.weapon_factory:get_weapons_uses_part( part_id ) or {}
		local min_level = managers.experience:level_cap()

		for _, factory_id in ipairs( weapon_uses_part ) do
			if not table.contains( tweak_data.weapon.factory[ factory_id ].default_blueprint, part_id ) then
				min_level = math.min( min_level, weapons_data[ factory_id ] or 0 )
			end
		end

		weapon_mods_tweak_data[ part_id ].qlvl = min_level
	end
end

function LootDropManager:_setup_items()
	local pc_items = {}
	
	Global.lootdrop_manager.pc_items = pc_items
	
	local sort_pc = function( type, data )
		for id,item_data in pairs( data ) do
			local dlcs = item_data.dlcs or {}
			local dlc = item_data.dlc

			if dlc then
				table.insert( dlcs, dlc )
			end
			local has_dlc = #dlcs == 0
			for _, dlc in pairs( dlcs ) do
				has_dlc = has_dlc or managers.dlc:has_dlc( dlc )
			end

			if has_dlc then
				if item_data.pc then
					pc_items[ item_data.pc ] = pc_items[ item_data.pc ] or {}
					pc_items[ item_data.pc ][ type ] = pc_items[ item_data.pc ][ type ] or {}
					table.insert( pc_items[ item_data.pc ][ type ], id )
				end
				if item_data.pcs then
					for _,pc in ipairs( item_data.pcs ) do
						pc_items[ pc ] = pc_items[ pc ] or {}
						pc_items[ pc ][ type ] = pc_items[ pc ][ type ] or {}
						table.insert( pc_items[ pc ][ type ], id )
					end
				end
			end
		end
	end
	
	for type, data in pairs( tweak_data.blackmarket ) do
		-- print( type, inspect( data ) )
		
		sort_pc( type, data )
		
		--[[for id,item_data in pairs( data ) do
			if item_data.pc then
				pc_items[ item_data.pc ] = pc_items[ item_data.pc ] or {}
				pc_items[ item_data.pc ][ type ] = pc_items[ item_data.pc ][ type ] or {}
				table.insert( pc_items[ item_data.pc ][ type ], id )
			end
			if item_data.pcs then
				for _,pc in ipairs( item_data.pcs ) do
					pc_items[ pc ] = pc_items[ pc ] or {}
					pc_items[ pc ][ type ] = pc_items[ pc ][ type ] or {}
					table.insert( pc_items[ pc ][ type ], id )
				end
			end
		end]]
	end
	
	-- for type, data in pairs( tweak_data.weapon.factory.parts ) do
	-- sort_pc( "weapon_mods", tweak_data.weapon.factory.parts )
		
	-- print( inspect( pc_items ) )
end


function LootDropManager:new_debug_drop( amount, add_to_inventory, stars )
	amount = amount or 10
	add_to_inventory = add_to_inventory or false

	local debug_infamous = 0
	local debug_max_pc = 0

	if stars == "random" then
	else
		stars = stars or 5
	end
	self._debug_drop_result = {}
	for i = 1, amount do
		local s = stars == "random" and math.random( 10 ) or stars
		local global_value, category, id, pc = self:_new_make_drop( true, add_to_inventory, s )
		self._debug_drop_result[ global_value ] = self._debug_drop_result[ global_value ] or {}
		self._debug_drop_result[ global_value ][ category ] = self._debug_drop_result[ global_value ][ category ] or {}
		self._debug_drop_result[ global_value ][ category ][ id ] = (self._debug_drop_result[ global_value ][ category ][ id ] or 0 ) + 1

		if global_value == "infamous" then
			debug_infamous = debug_infamous + 1
		end

		if pc == tweak_data.lootdrop.STARS[ s ].pcs[ 1 ] then
			debug_max_pc = debug_max_pc + 1
		end
	end

	if stars ~= "random" then
		Application:debug( debug_max_pc .. " dropped at PC " .. stars, "infamous items dropped: " .. debug_infamous )
	end
	Global.debug_drop_result = self._debug_drop_result
end

function LootDropManager:droppable_items( item_pc, infamous_success, skip_types )
	local plvl = managers.experience:current_level()
	local xp_no_next_lv = managers.experience:next_level_data_points() - managers.experience:next_level_data_current_points()
	
	local pc_items = self._global.pc_items[ item_pc ]
	
	local droppable_items = {}
	local maxed_inventory_items = {}
	
	for type, items in pairs( pc_items ) do
		local type_tweak = tweak_data.blackmarket[ type ]
		droppable_items[ type ] = {}
		maxed_inventory_items[ type ] = {}
		
		if not skip_types or not skip_types[ type ] then
			for i, item in ipairs( items ) do
				local item_tweak = type_tweak[ item ]
				
				local is_infamous = item_tweak.infamous or false
				local is_dlc = item_tweak.dlcs or item_tweak.dlc or false
				local got_qlvl = item_tweak.qlvl or false
				local fixed_global_value = item_tweak.global_value or false
				
				local pass_infamous = not is_infamous or infamous_success
				local pass_dlc = true
				local pass_qlvl = not got_qlvl or plvl >= got_qlvl
				local pass_xp_card = ( type ~= "xp" ) or ( ( tweak_data:get_value( "experience_manager", "loot_drop_value", item_tweak.value_id ) or 0 ) < xp_no_next_lv )
				
				local global_value = fixed_global_value or "normal"
				if is_infamous then
					global_value = "infamous"
				elseif is_dlc then
					local dlcs = item_tweak.dlcs or {}
					if item_tweak.dlc then
						table.insert( dlcs, item_tweak.dlc )
					end
					
					local dlc_global_values = {}
					for _, dlc in ipairs( dlcs ) do
						if managers.dlc:has_dlc( dlc ) then
							table.insert( dlc_global_values, dlc )
						end
					end
					
					if #dlc_global_values > 0 then
						global_value = fixed_global_value or dlc_global_values[ math.random( #dlc_global_values ) ]
					else
						pass_dlc = false
					end
				end
				local amount_in_inventory = managers.blackmarket:get_item_amount( global_value, type, item, true )
				
				if pass_infamous and pass_dlc and pass_qlvl and pass_xp_card then
					local weight = item_tweak.weight or tweak_data.lootdrop.DEFAULT_WEIGHT
					
					local type_weight_mod_func = tweak_data.lootdrop.type_weight_mod_funcs[ type ]
					if type_weight_mod_func then
						weight = weight * type_weight_mod_func( global_value, type, item )
					end
					
					if amount_in_inventory > 0 then
						weight = weight * ( item_tweak.got_item_weight_mod or tweak_data.lootdrop.got_item_weight_mod or 0.5 )
					end
					
					if not item_tweak.max_in_inventory or amount_in_inventory < item_tweak.max_in_inventory then
						table.insert( droppable_items[ type ], { entry = item, global_value = global_value, weight = weight } )
					else
						table.insert( maxed_inventory_items[ type ], { entry = item, global_value = global_value, weight = weight } )
					end
				end
			end
		end
		
		if #droppable_items[ type ] == 0 then
			droppable_items[ type ] = nil
		end
	end
	
	return droppable_items, maxed_inventory_items
end

function LootDropManager:infamous_chance( setup_data )
	local infamous_diff = 1
	if not setup_data or not setup_data.disable_difficulty then
		local difficulty_stars = managers.job:current_difficulty_stars() or 0
		infamous_diff = tweak_data.lootdrop.risk_infamous_multiplier[difficulty_stars] or 1
	end
	
	local chance = tweak_data.lootdrop.global_values.infamous.chance
	local multiplier = managers.player:upgrade_value( "player", "passive_loot_drop_multiplier", 1 ) * managers.player:upgrade_value( "player", "loot_drop_multiplier", 1 ) * infamous_diff * ( setup_data and setup_data.increase_infamous or 1 )
	
	if managers.experience:current_rank() > 0 then
		for infamy, item in pairs( tweak_data.infamy.items ) do
			if managers.infamy:owned( infamy ) and item.upgrades and item.upgrades.infamous_lootdrop then
				multiplier = multiplier * item.upgrades.infamous_lootdrop
			end
		end
	end
	
	return chance * multiplier, chance, multiplier
end

function LootDropManager:new_make_drop( return_data, setup_data )
	return_data = type( return_data ) == "table" and return_data or {}
	self:_new_make_drop( false, true, nil, return_data, setup_data )
end

function LootDropManager:_new_make_drop( debug, add_to_inventory, debug_stars, return_data, setup_data )
	local plvl = managers.experience:current_level()
	local pstars = managers.experience:level_to_stars()
	--local difficulty_stars = managers.job:current_difficulty_stars() or 0
	--local xp_no_next_lv = managers.experience:next_level_data_points() - managers.experience:next_level_data_current_points()
	local stars = debug_stars or pstars
	local pc = stars * 10
	
	if not debug then
		print("Player level", plvl)
		print("Player stars", pstars)
		print("Stars", stars)
		print("Pay class", pc)
		print("Difficulty stars", managers.job:current_difficulty_stars() or 0)
	end
	
	return_data = return_data or {}
	return_data.job_stars = stars
	return_data.total_stars = stars
	return_data.player_level = plvl
	return_data.player_stars = pstars
	return_data.payclass = pc
	
	
	local pcs = tweak_data.lootdrop.STARS[ stars ].pcs
	local chance_curve = tweak_data.lootdrop.STARS_CURVES[ stars ]
	local start_chance = tweak_data.lootdrop.PC_CHANCE[ stars ]
	
	local no_pcs = nil
	local item_pc = nil
	
	if setup_data and setup_data.max_pcs then
		no_pcs = setup_data.max_pcs
	else
		no_pcs = #pcs
	end
	
	for i = 1, no_pcs do
		local chance = no_pcs > 1 and math.lerp( start_chance, 1, math.pow( ( i - 1 ) / ( no_pcs - 1 ), chance_curve ) ) or 1
		if not debug then print("chance for", i, pcs[ i ], "is", chance) end
		local roll = math.rand( 1 )
		if not debug then print(" roll,", roll) end
		if roll <= chance then
			if not debug then print(" got it at", i, pcs[ i ]) end
			item_pc = pcs[ i ]
			return_data.item_payclass = item_pc
			break
		end
	end
	
	local infamous_chance, infamous_base_chance, infamous_base_multiplier = self:infamous_chance( setup_data )
	-- local pc_items = self._global.pc_items[ item_pc ]
	local infamous_roll = math.rand( 1 )
	local infamous_success = infamous_roll < infamous_chance
	if not debug then print( "infamous_success", infamous_success, "infamous_roll", infamous_roll, "infamous_chance", infamous_chance, "infamous_base_chance", infamous_base_chance, "infamous_base_multiplier", infamous_base_multiplier ) end
	
	local droppable_items, maxed_inventory_items = self:droppable_items( item_pc, infamous_success, setup_data and setup_data.skip_types )
	
	local weighted_type_chance = {}
	local sum = 0

	for type, items in pairs( droppable_items ) do
		weighted_type_chance[ type ] = tweak_data.lootdrop.WEIGHTED_TYPE_CHANCE[ pc ][ type ]
		sum = sum + weighted_type_chance[ type ]
		if not debug then print( "added", type, weighted_type_chance[ type ], "to sum", sum ) end
	end

	if setup_data and setup_data.preferred_type and setup_data.preferred_chance then
		local increase = setup_data.preferred_chance * sum
		weighted_type_chance[ setup_data.preferred_type ] = ( weighted_type_chance[ setup_data.preferred_type ] or 0 ) + increase
		sum = sum + increase
	end
	
	if not debug then print( "sum", sum ) end
	
	local normalized_chance = {}
	for type, items in pairs( droppable_items ) do
		normalized_chance[ type ] = weighted_type_chance[ type ]>0 and weighted_type_chance[ type ] / sum or 0
	end
	if not debug then print( "normalized_chance: pc", inspect( normalized_chance ) ) end
	
	
	local pc_type = setup_data and setup_data.preferred_type_drop or self:_get_type_items( normalized_chance, debug )
	local drop_table = droppable_items[ pc_type ] or maxed_inventory_items[ pc_type ]
	
	local global_value, entry
	
	
	if drop_table then
		sum = 0
		for index, item_data in ipairs( drop_table ) do
			sum = sum + item_data.weight
		end
		
		normalized_chance = {}
		for index, item_data in ipairs( drop_table ) do
			normalized_chance[ index ] = item_data.weight / sum
		end
		if not debug then print( "normalized_chance: item", inspect( normalized_chance ) ) end
		
		local dropped_index = self:_get_type_items( normalized_chance, debug )
		local dropped_item = drop_table[ dropped_index ]
		
		if not debug then print( "GOT: ", dropped_index, dropped_item.global_value, pc_type, dropped_item.entry ) end
		
		if add_to_inventory then
			managers.blackmarket:add_to_inventory( dropped_item.global_value, pc_type, dropped_item.entry )
		end
		
		global_value = dropped_item.global_value
		entry = dropped_item.entry
	end
	
	return_data.global_value = global_value
	return_data.type_items = pc_type
	return_data.item_entry = entry
	
	return global_value, pc_type, entry, pc
end


function LootDropManager:debug_drop( amount, add_to_inventory, stars )
	amount = amount or 10
	add_to_inventory = add_to_inventory or false
	
	local debug_infamous = 0
	local debug_max_pc = 0
	
	if stars == "random" then
	else
		stars = stars or 5
	end
	self._debug_drop_result = {}
	for i = 1, amount do
		local s = stars == "random" and math.random( 10 ) or stars
		local global_value, category, id, pc = self:_make_drop( true, add_to_inventory, s )
		self._debug_drop_result[ global_value ] = self._debug_drop_result[ global_value ] or {}
		self._debug_drop_result[ global_value ][ category ] = self._debug_drop_result[ global_value ][ category ] or {}
		self._debug_drop_result[ global_value ][ category ][ id ] = (self._debug_drop_result[ global_value ][ category ][ id ] or 0) + 1
		
		if global_value == "infamous" then
			debug_infamous = debug_infamous + 1
		end
		
		if pc == tweak_data.lootdrop.STARS[ s ].pcs[1] then
			debug_max_pc = debug_max_pc + 1
		end
	end
	
	if stars ~= "random" then
		Application:debug( debug_max_pc .. " dropped at PC " .. stars, "infamous items dropped: " .. debug_infamous )
	end
	Global.debug_drop_result = self._debug_drop_result
	-- print( inspect( self._debug_drop_result ) )
end

function LootDropManager:make_drop( return_data )
	return_data = (type(return_data) == "table") and return_data or {}
	self:_make_drop( false, true, nil, return_data )
end

function LootDropManager:_make_drop( debug, add_to_inventory, debug_stars, return_data )
	-- Get stars from job
	-- Get PC from amount of stars
	-- Add one PC if all players are human
	local human_players = managers.network:game() and managers.network:game():amount_of_alive_players() or 1
	local all_humans = human_players == 4
	local plvl = managers.experience:current_level()
	
	local stars = debug_stars or managers.job:current_job_stars() -- Get it from the JOB
		return_data = return_data or {}
		return_data.job_stars = stars
		return_data.player_level = plvl
	
	local difficulty = Global.game_settings.difficulty or "easy"
	local difficulty_id = math.max( 0, ( tweak_data:difficulty_to_index( difficulty ) or 0 ) - 2 )
	
	stars = stars + difficulty_id
	
	local player_stars = math.max( math.ceil( plvl / 10 ), 1 )
	-- stars = math.min( stars, player_stars + tweak_data.lootdrop.level_limit )				-- Limit stars from job based on plvl
	-- stars = math.min( stars, player_stars )				-- Limit stars from job based on plvl
	
	difficulty_id = math.min( difficulty_id, stars - return_data.job_stars )
	
	if all_humans then
		-- stars = stars + 1
		-- 	return_data.human_stars = 1
	end
	
	if not debug then
		print( "Total stars", stars )
	end
	
	-- stars = math.clamp( debug_stars or stars, 1, #tweak_data.lootdrop.STARS )
	stars = player_stars -- Use player level raw as input instead of narrative's star count
	
		return_data.player_stars = player_stars
		return_data.difficulty_stars = difficulty_id
		return_data.total_stars = stars
	
	local pc = math.lerp( 0, 100, stars/10 )
		return_data.payclass = pc
	-- if all_humans then
		-- pc = pc + tweak_data.lootdrop.PC_STEP
	-- end
	
	if not debug then	
		print( "Pay class", pc )
	end
	
	-- Chance of no drop	
	--[[local no_drop_chance = tweak_data.lootdrop.no_drop.BASE
	no_drop_chance = no_drop_chance - tweak_data.lootdrop.no_drop.HUMAN_STEP_MODIFIER * (human_players-1)
	no_drop_chance = math.max( no_drop_chance, 0 )
	
	if not debug then
		print( "No drop chance", no_drop_chance )
	end
	
	local no_drop = math.rand( 1 ) < (no_drop_chance/100)
	if not debug then
		print( "No drop", no_drop )
	end
	if no_drop then
		if not debug then
			print( "Got nothing" )
		end
		return "normal", "no_drop", "amount"
	end]]
	
	local drop_pc = stars * 10
	local pcs = tweak_data.lootdrop.STARS[ stars ].pcs
	
	if math.rand(1) <= tweak_data.lootdrop.joker_chance then
		pcs = deep_clone(pcs)
		
		for i=1, #pcs do
			local new_value = pcs[i] + math.random(5)*10 - 30
			if new_value >= 5 and new_value <= 100 then
				pcs[i] = new_value
			end
		end
		
			return_data.joker = true
		if not debug then
			Application:debug( "JOKER" )
		end
	end
	
	if not debug then
		print( "num of pcs", #pcs )
	end
	
	-- CHANGE AMOUNT OF PC DEPENDING ON HEIST COMPLETED IN JOB (IF IT ISN'T RAGING)
-- Go through PCs
	local chance_risk_mod = tweak_data.lootdrop.risk_pc_multiplier[ difficulty_id ] or 0
	local chance_curve = tweak_data.lootdrop.STARS_CURVES[ stars ] -- - chance_risk_mod
	local start_chance = tweak_data.lootdrop.PC_CHANCE[ stars ] -- * ( tweak_data.lootdrop.risk_pc_multiplier[difficulty_id] or 1 )
	
	if not debug then
		print( "start_chance before skills: ", start_chance )
	end
	
	--[[start_chance = start_chance * managers.player:upgrade_value( "player", "passive_loot_drop_multiplier", 1 ) * managers.player:upgrade_value( "player", "loot_drop_multiplier", 1 )
	if not debug then
		print( "start_chance after skills: ", start_chance )
	end]]
	
	local no_pcs = #pcs
	local pc
	for i = 1, no_pcs do
		local chance = math.lerp( start_chance, 1, math.pow((i-1)/(no_pcs-1), chance_curve) )
		if not debug then print( "chance for", i, pcs[i], "is", chance ) end
		local roll = math.rand(1)
		if not debug then print( " roll,", roll ) end
		if roll <= chance then
			if not debug then print( " got it at", i, pcs[i] ) end
			pc = pcs[i]
				return_data.item_payclass = pc
			break
		end
	end
	
	if not debug then
		print( "Select from pc", pc )
	end
	local pc_items = self._global.pc_items[ pc ]
	
	local i_pc_items = {}
	if not debug then
		print( " Random from type:" )
	end
	--[[for type,items in pairs( pc_items ) do
		if not debug then
			print( "   ", type )
		end
		table.insert( i_pc_items, type )
	end]]
	
	-- local i_pc_items = {}
	local weighted_type_chance = tweak_data.lootdrop.WEIGHTED_TYPE_CHANCE[ drop_pc ]
	local sum = 0
	
	for type,items in pairs( pc_items ) do
		sum = sum + weighted_type_chance[ type ]
		if not debug then  print( "added", type, weighted_type_chance[ type ], "to sum", sum ) end 
				
		--[[if not debug then
			print( "   ", type )
		end
		for i = 1, weighted_type_chance[ type ] or 1 do
			table.insert( i_pc_items, type )
		end]]
	end
	
	if not debug then print( "sum", sum ) end
	
	local normalized_chance = {}
	for type,items in pairs( pc_items ) do
		normalized_chance[ type ] = weighted_type_chance[ type ]/sum
	end
	if not debug then print( "normalized_chance", inspect( normalized_chance ) ) end
	
	
	-- print( inspect( i_pc_items ) )
	-- i_pc_items = { "cash" }
	
	local has_result
	while not has_result do
			-- local new_item = {}
			-- table.insert( return_data, new_item )








































		local type_items = self:_get_type_items( normalized_chance, debug )
				
		-- local type_items = i_pc_items[ math.random( #i_pc_items ) ]
		if not debug then
			print( " Type result", type_items )
		end
		
		local items = pc_items[ type_items ]
		local item_entry = items[ math.random( #items ) ]
		
		local global_value = "normal"
		local block_item = false
		-- print( "qlvl infamous", type_items, item_entry, tweak_data.blackmarket[ type_items ][ item_entry ].qlvl, tweak_data.blackmarket[ type_items ][ item_entry ].infamous )
		if not tweak_data.blackmarket[ type_items ][ item_entry ].qlvl or
			tweak_data.blackmarket[ type_items ][ item_entry ].qlvl <= plvl then
						
			-- if type_items == "masks" then
				local global_value_chance = math.rand( 1 )
				local quality_mul = managers.player:upgrade_value( "player", "passive_loot_drop_multiplier", 1 ) * managers.player:upgrade_value( "player", "loot_drop_multiplier", 1 )
				-- print( "Global value chance is", global_value_chance )
				if tweak_data.blackmarket[ type_items ][ item_entry ].infamous and 
					global_value_chance < tweak_data.lootdrop.global_values.infamous.chance * quality_mul then
					
					global_value = "infamous"
				--[[elseif global_value_chance < tweak_data.lootdrop.global_values.exceptional.chance then
					-- global_value = "exceptional"
				elseif global_value_chance < tweak_data.lootdrop.global_values.superior.chance then
					-- global_value = "superior"]]
				else
					local dlcs = tweak_data.blackmarket[ type_items ][ item_entry ].dlcs or {}

					if true then
					local dlc = tweak_data.blackmarket[ type_items ][ item_entry ].dlc
					if dlc then
						table.insert( dlcs, dlc )
					end
					end

					local dlc_global_values = {}
					for _, dlc in pairs( dlcs ) do
						if managers.dlc:has_dlc( dlc ) then
							table.insert( dlc_global_values, dlc )
						else
							block_item = true
						end
					end

					if #dlc_global_values > 0 then
						global_value = dlc_global_values[ math.random( #dlc_global_values ) ]
						block_item = false
					end
				end
			-- end

			if block_item then
				if not debug then
					print( "Item drop got blocked!", "type_items", type_items, "item_entry", item_entry, "global_value", global_value )
				end
			elseif tweak_data.blackmarket[ type_items ][ item_entry ].max_in_inventory and managers.blackmarket:get_item_amount( global_value, type_items, item_entry ) >= tweak_data.blackmarket[ type_items ][ item_entry ].max_in_inventory then
				if not debug then
					print( "Already got max of this item", item_entry )
				end
			else
				if not tweak_data.blackmarket[ type_items ][ item_entry ].infamous or global_value == "infamous" then
					-- Either not infamous, which is ok, or we need to have rolled an infamous chance
					-- Is an ok thing
					has_result = true
					if not debug then
						print( "You got", item_entry, "of type", type_items, "with global value", global_value )
					end
			
					-- SO THE RESULT SHOULD BE ADDED TO BLACKMARKET INVENTORY
					if add_to_inventory then
						if type_items == "cash" then
							--[[	-- adding this into managers.blackmarket:add_to_inventory, so dlc can access it
								local value_id = tweak_data.blackmarket[ type_items ][ item_entry ].value_id
								local money = tweak_data.money_manager.loot_drop_cash[ value_id ] or 100
								print( "Cash value_id", value_id )
								print( " - cash:", money )
								managers.money:on_loot_drop_cash( value_id )
							]]
				
							managers.blackmarket:add_to_inventory( global_value, type_items, item_entry )
							-- print( "You got cash, multiplier", tweak_data.blackmarket[ type_items ][ item_entry ].multiplier ,"!" )
						else
							managers.blackmarket:add_to_inventory( global_value, type_items, item_entry )
						end
							return_data.global_value = global_value
							return_data.type_items = type_items
							return_data.item_entry = item_entry
							-- return_data[#return_data].global_value = global_value
							-- return_data[#return_data].type_items = type_items
							-- return_data[#return_data].item_entry = item_entry
					end
			
					if not debug then
						print( inspect( tweak_data.blackmarket[ type_items ][ item_entry ] ) )
					end
					if global_value == "infamous" then
						--- print( "GOT AN INFAMOUS", global_value, type_items, item_entry )
					end
					return global_value, type_items, item_entry, pc
				end
			end
		end
		-- print( "-- REROLL", type_items, item_entry, tweak_data.blackmarket[ type_items ][ item_entry ].qlvl, tweak_data.blackmarket[ type_items ][ item_entry ].infamous, "global_value", global_value )
	end
	
	--[[local type_items = i_pc_items[ math.random( #i_pc_items ) ]
	if not debug then
		print( " Type result", type_items )
	end
	
	local global_value = "normal"
	if type_items == "masks" then
		local global_value_chance = math.rand( 1 )
		print( "Global value chance is", global_value_chance )
		if global_value_chance < tweak_data.lootdrop.global_values.infamous.chance then
			global_value = "infamous"
		elseif global_value_chance < tweak_data.lootdrop.global_values.exceptional.chance then
			global_value = "exceptional"
		elseif global_value_chance < tweak_data.lootdrop.global_values.superior.chance then
			global_value = "superior"
		end
	end
	
	local items = pc_items[ type_items ]
	
	local item_entry = items[ math.random( #items ) ]
	if not debug then
		print( "You got", item_entry, "of type", type_items, "with global value", global_value )
	end
		
	-- SO THE RESULT SHOULD BE ADDED TO BLACKMARKET INVENTORY
	if add_to_inventory then
		if type_items == "cash" then
			print( "You got cash, multiplier", tweak_data.blackmarket[ type_items ][ item_entry ].multiplier ,"!" )
		else
			managers.blackmarket:add_to_inventory( global_value, type_items, item_entry )
		end
	end
	
	if not debug then
		print( inspect( tweak_data.blackmarket[ type_items ][ item_entry ] ) )
	end
	return global_value, type_items, item_entry ]]
end

function LootDropManager:_get_type_items( normalized_chance, debug )
	local seed = math.rand( 1 )
	if not debug then print( "seed", seed ) end
	for type,weight in pairs( normalized_chance ) do
		seed = seed - weight
		if not debug then print( "   sub seed", type, weight, seed ) end
		if seed <= 0 then
			if not debug then print( "RETURN TYPE", type ) end
			return type		
		end
	end
	return next( normalized_chance ) -- Safety
end

function LootDropManager:reset()
	Global.lootdrop_manager = nil
	self:_setup()
end

function LootDropManager:can_drop_weapon_mods()
	local plvl = managers.experience:current_level()
	local dropable_items = {}

	for item, item_tweak in pairs( tweak_data.blackmarket.weapon_mods ) do
		if item_tweak.pc or item_tweak.pcs then
			local is_infamous = item_tweak.infamous or false
			local is_dlc = item_tweak.dlcs or item_tweak.dlc or false
			local got_qlvl = item_tweak.qlvl or false

			local pass_infamous = not is_infamous or infamous_success
			local pass_dlc = true
			local pass_qlvl = not got_qlvl or (plvl >= got_qlvl)
			local pass_max_in_inventory

			local global_value = "normal"
			if is_infamous then
				global_value = "infamous"
			elseif is_dlc then
				local dlcs = item_tweak.dlcs or {}
				if item_tweak.dlc then
					table.insert( dlcs, item_tweak.dlc )
				end

				local dlc_global_values = {}
				for _, dlc in pairs( dlcs ) do
					if managers.dlc:has_dlc( dlc ) then
						table.insert( dlc_global_values, dlc )
					end
				end

				if #dlc_global_values > 0 then
					global_value = dlc_global_values[ math.random( #dlc_global_values ) ]
				else
					pass_dlc = false
				end
			end
			local amount_in_inventory = managers.blackmarket:get_item_amount( global_value, "weapon_mods", item, true )
			pass_max_in_inventory = not item_tweak.max_in_inventory or ( amount_in_inventory < item_tweak.max_in_inventory )

			if pass_infamous and pass_dlc and pass_qlvl and pass_max_in_inventory then
				table.insert( dropable_items, true)
			end
		end
	end

	return #dropable_items > 0
end

function LootDropManager:specific_fake_loot_pc( preferred )
	local to_drop = {masks = 1, weapon_mods = 2, cash = 3, xp = 4, materials = 5, colors = 6, textures = 7}
	return to_drop[ preferred ] or 1
end

function LootDropManager:new_fake_loot_pc( debug_pc, skip_mods )
	local sum = 0
	local to_drop = {masks = 1, weapon_mods = 2, cash = 3, xp = 4, materials = 5, colors = 6, textures = 7}
	
	for skip, value in pairs( skip_mods ) do
		if value then
			to_drop[ skip ] = nil
		end
	end
	
	local WEIGHTS = tweak_data.lootdrop.WEIGHTED_TYPE_CHANCE[ (debug_pc or managers.experience:level_to_stars() ) * 10]
	
	for type in pairs( to_drop ) do
		sum = sum + WEIGHTS[ type ]
	end
	
	local variant = math.random( sum )
	for type, card in pairs( to_drop ) do
		variant = variant - WEIGHTS[ type ]
		
		if variant <= 0 then
			return card
		end
	end
	return 1
end

--[[
function LootDropManager:fake_loot_pc( debug_pc )
	local max_pc = debug_pc or math.ceil( math.min( managers.experience:current_level() / 10, managers.job:current_job_and_difficulty_stars() ) )
	local chance = 0.85 / math.max ( 2^(#tweak_data.lootdrop.STARS[max_pc].pcs-1), 1)
	chance = chance * managers.player:upgrade_value( "player", "passive_loot_drop_multiplier", 1 ) -- * managers.player:upgrade_value( "player", "loot_drop_multiplier", 1 )

	
	-- chance = chance / math.max( #tweak_data.lootdrop.STARS[max_pc].pcs, 1 )
	for i=1, 5 do
		if math.rand(1) < 0.20 then
			chance = chance + chance
		end
	end
	
	-- Application:debug( "START CHANCE FOR OTHER LOOTDROPS" , chance , "max_pc" , max_pc )
	
	for i = 1, #tweak_data.lootdrop.STARS[max_pc].pcs do
		if math.rand(1) < chance then
			return math.ceil( tweak_data.lootdrop.STARS[max_pc].pcs[i] / 10 )
		end
		chance = chance + chance
	end
	return 0
end
]]

function LootDropManager:debug_check_items( check_type )	
	for type, data in pairs( tweak_data.blackmarket ) do
		if not check_type or type == check_type then
			for id,item_data in pairs( data ) do
				if not item_data.pc and not item_data.pcs then
					print( "Item", id, "of type", type, "hasn't been assigned a pay class" )
				end
			end
		end
	end
end

function LootDropManager:debug_print_pc_items( check_type )	
	for type, data in pairs( tweak_data.blackmarket ) do
		if not check_type or type == check_type then
			for id,item_data in pairs( data ) do
				if check_type ~= "weapon_mods" or item_data.pc or item_data.pcs then
					local name = item_data.name_id and managers.localization:text( item_data.name_id ) or "NO NAME"
					local pcs = ""..(item_data.pc or "")
					if item_data.pcs then
						for _,pc in ipairs( item_data.pcs ) do
							pcs = pcs.." "..pc
						end
					end
					
					-- print( name, id, inspect( item_data.pcs or item_data.pc ) )
					local infamous = item_data.infamous and "infamous" or ""
					print( name, id, pcs, infamous )
				end
			end
		end
	end
end

-- Not called yet
function LootDropManager:save( data )
	data.LootDropManager = self._global
end

-- Not called yet
function LootDropManager:load( data )
	self._global = data.LootDropManager 
end