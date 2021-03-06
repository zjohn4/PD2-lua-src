DLCTweakData = DLCTweakData or class()

function DLCTweakData:init( tweak_data )
	self.starter_kit = {}
	self.starter_kit.free = true
	self.starter_kit.content = {}
	self.starter_kit.content.loot_global_value = "normal"
	self.starter_kit.content.loot_drops = {
					{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_ns_pis_medium", amount = 1 },
					{ type_items = "weapon_mods", item_entry = "wpn_fps_m4_uupg_m_std", amount = 1 },
	}
	self.starter_kit.content.upgrades = {
		"fists"
	}
	self.pd2_clan = {}
	self.pd2_clan.content = {}
	self.pd2_clan.dlc = "has_pd2_clan"
	self.pd2_clan.content.loot_drops = {
					{ type_items = "masks", item_entry = "bear", amount = 1 },
	}
	self.pd2_clan2 = {}
	self.pd2_clan2.content = {}
	self.pd2_clan2.dlc = "has_pd2_clan"
	self.pd2_clan2.content.loot_global_value = "pd2_clan"
	self.pd2_clan2.content.loot_drops = {
					{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_fl_pis_tlr1", amount = 1 },
	}
	self.pd2_clan2.content.upgrades = {
					"usp"
	}
	self.pd2_clan3 = {}
	self.pd2_clan3.content = {}
	self.pd2_clan3.dlc = "has_pd2_clan"
	self.pd2_clan3.content.loot_global_value = "pd2_clan"
	self.pd2_clan3.content.loot_drops = {
					{ type_items = "masks", item_entry = "heat", amount = 1 },
	}
	
	self.preorder = {}
	self.preorder.dlc = "has_preorder"
	self.preorder.content = {}
	self.preorder.content.loot_drops = {
					{ type_items = "colors", item_entry = "red_black", amount = 1 },
					{ type_items = "textures", item_entry = "fan", amount = 1 },
					{ type_items = "masks", item_entry = "skull", amount = 1 },
					{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_o_aimpoint_2", amount = 1 },
					{ type_items = "cash", item_entry = "cash_preorder", amount = 1 },
					
					--[[{ type_items = "materials", item_entry = "whiterock", amount = 1 },
					{ type_items = "materials", item_entry = "fish_skin", amount = 1 },
					{ type_items = "colors", item_entry = "brown_black", amount = 1 },]]
	}
	self.preorder.content.upgrades = {
		"player_crime_net_deal"
	}

	self.cce = {}
	self.cce.dlc = "has_cce"
	self.cce.content = {}
	self.cce.content.loot_drops = {

	}
	self.cce.content.upgrades = {
		"player_crime_net_deal_2"
	}
	
	
	
	--[[ self.halloween = {}
	self.halloween.free = true
	self.halloween.content = {}
	self.halloween.content.loot_drops = {
					{
						{ type_items = "masks", item_entry = "pumpkin_king", amount = 1 },
						{ type_items = "masks", item_entry = "witch", amount = 1 },
						{ type_items = "masks", item_entry = "venomorph", amount = 1 },
						{ type_items = "masks", item_entry = "frank", amount = 1 },
					}
	}]]
	self.halloween_nightmare_1 = {}
	self.halloween_nightmare_1.dlc = "has_achievement"
	self.halloween_nightmare_1.achievement_id = "halloween_nightmare_1"
	self.halloween_nightmare_1.content = {}
	self.halloween_nightmare_1.content.loot_global_value = "halloween"
	self.halloween_nightmare_1.content.loot_drops = {
					{ type_items = "masks", item_entry = "baby_happy", amount = 1 }
	}
	self.halloween_nightmare_2 = {}
	self.halloween_nightmare_2.dlc = "has_achievement"
	self.halloween_nightmare_2.achievement_id = "halloween_nightmare_2"
	self.halloween_nightmare_2.content = {}
	self.halloween_nightmare_2.content.loot_global_value = "halloween"
	self.halloween_nightmare_2.content.loot_drops = {
					{ type_items = "masks", item_entry = "brazil_baby", amount = 1 }
	}
	self.halloween_nightmare_3 = {}
	self.halloween_nightmare_3.dlc = "has_achievement"
	self.halloween_nightmare_3.achievement_id = "halloween_nightmare_3"
	self.halloween_nightmare_3.content = {}
	self.halloween_nightmare_3.content.loot_global_value = "halloween"
	self.halloween_nightmare_3.content.loot_drops = {
					{ type_items = "masks", item_entry = "baby_angry", amount = 1 }
	}
	self.halloween_nightmare_4 = {}
	self.halloween_nightmare_4.dlc = "has_achievement"
	self.halloween_nightmare_4.achievement_id = "halloween_nightmare_4"
	self.halloween_nightmare_4.content = {}
	self.halloween_nightmare_4.content.loot_global_value = "halloween"
	self.halloween_nightmare_4.content.loot_drops = {
					{ type_items = "masks", item_entry = "baby_cry", amount = 1 }
	}
	
	
	
	self.armored_transport = {}
	self.armored_transport.content = {}
	self.armored_transport.dlc = "has_armored_transport"
	self.armored_transport.content.loot_drops = {
					{
						{ type_items = "masks", item_entry = "clinton", amount = 1 },
						{ type_items = "masks", item_entry = "bush", amount = 1 },
						{ type_items = "masks", item_entry = "obama", amount = 1 },
						{ type_items = "masks", item_entry = "nixon", amount = 1 }
					},
					{
						{ type_items = "materials", item_entry = "cash", amount = 1 },
						{ type_items = "materials", item_entry = "jade", amount = 1 },
						{ type_items = "materials", item_entry = "redwhiteblue", amount = 1 },
						{ type_items = "materials", item_entry = "marble", amount = 1 }
					},
					{
						{ type_items = "textures", item_entry = "racestripes", amount = 1 },
						{ type_items = "textures", item_entry = "americaneagle", amount = 1 },
						{ type_items = "textures", item_entry = "stars", amount = 1 },
						{ type_items = "textures", item_entry = "forestcamo", amount = 1 }
					}
	}
	self.armored_transport.content.upgrades = {
		"m45",
		"s552", "ppk"
		
	}
	
	
	self.gage_pack = {}
	self.gage_pack.content = {}
	self.gage_pack.dlc = "has_gage_pack"
	self.gage_pack.content.loot_drops = {
					{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_i_singlefire", amount = 5 },
					{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_i_autofire", amount = 5 },
					{
						{ type_items = "masks", item_entry = "goat", amount = 1 },
						{ type_items = "masks", item_entry = "panda", amount = 1 },
						{ type_items = "masks", item_entry = "pitbull", amount = 1 },
						{ type_items = "masks", item_entry = "eagle", amount = 1 }
					},
					{
						{ type_items = "materials", item_entry = "fur", amount = 1 },
						{ type_items = "materials", item_entry = "galvanized", amount = 1 },
						{ type_items = "materials", item_entry = "heavymetal", amount = 1 },
						{ type_items = "materials", item_entry = "oilmetal", amount = 1 }
					},
					{
						{ type_items = "textures", item_entry = "army", amount = 1 },
						{ type_items = "textures", item_entry = "commando", amount = 1 },
						{ type_items = "textures", item_entry = "hunter", amount = 1 },
						{ type_items = "textures", item_entry = "digitalcamo", amount = 1 }
					}
	}
	self.gage_pack.content.upgrades = {
		"mp7",
		"scar",
		"p226"
	}
	
	
	
	self.gage_pack_lmg = {}
	self.gage_pack_lmg.content = {}
	self.gage_pack_lmg.dlc = "has_gage_pack_lmg"
	self.gage_pack_lmg.content.loot_drops = {
					{
						{ type_items = "masks", item_entry = "cloth_commander", amount = 1 },
						{ type_items = "masks", item_entry = "gage_blade", amount = 1 },
						{ type_items = "masks", item_entry = "gage_rambo", amount = 1 },
						{ type_items = "masks", item_entry = "gage_deltaforce", amount = 1 }
					},
					{
						{ type_items = "materials", item_entry = "gunmetal", amount = 1 },
						{ type_items = "materials", item_entry = "mud", amount = 1 },
						{ type_items = "materials", item_entry = "splinter", amount = 1 },
						{ type_items = "materials", item_entry = "erdl", amount = 1 }
					},
					{
						{ type_items = "textures", item_entry = "styx", amount = 1 },
						{ type_items = "textures", item_entry = "fingerpaint", amount = 1 },
						{ type_items = "textures", item_entry = "fighter", amount = 1 },
						{ type_items = "textures", item_entry = "warrior", amount = 1 }
					}
	}
	self.gage_pack_lmg.content.upgrades = {
		
		
		"rpk",
		"kabar"
	}
	
	
	self.charliesierra = {}
	self.charliesierra.content = {}
	self.charliesierra.free = true
	
	self.charliesierra.content.loot_global_value = "normal"
	self.charliesierra.content.loot_drops = {
						{ type_items = "weapon_mods", item_entry = "wpn_fps_upg_o_acog", amount = 1 }
					}
	self.pd2_clan4 = {}
	self.pd2_clan4.content = {}
	self.pd2_clan4.dlc = "has_pd2_clan"
	self.pd2_clan4.content.loot_global_value = "pd2_clan"
	self.pd2_clan4.content.loot_drops = {
						{ type_items = "masks", item_entry = "santa_happy", amount = 1 }
					}
	
	
	
	self.xmas_soundtrack = {}
	self.xmas_soundtrack.content = {}
	self.xmas_soundtrack.dlc = "has_xmas_soundtrack"
	
	self.xmas_soundtrack.content.loot_drops = {
					{
						{ type_items = "masks", item_entry = "santa_mad", amount = 1 },
						{ type_items = "masks", item_entry = "santa_drunk", amount = 1 },
						{ type_items = "masks", item_entry = "santa_surprise", amount = 1 }
					}
	}
	
	
	self.sweettooth = {}
	self.sweettooth.content = {}
	self.sweettooth.dlc = "has_sweettooth"
	self.sweettooth.content.loot_drops = {
					{ type_items = "masks", item_entry = "sweettooth", amount = 1 }
	}
	
	--[[self.japan = {}
	self.japan.dlc = "has_japan"
	self.japan.content = {}
	self.japan.content.loot_drops = {
					{ type_items = "colors", item_entry = "red_black", amount = 1 },
					{ type_items = "textures", item_entry = "japan", amount = 1 },
					{ type_items = "masks", item_entry = "shogun", amount = 1 },
	}]]
	--[[
	self.overkill = {}
	self.overkill.dlc = "has_overkill"
	self.overkill.free = false
	self.overkill.content = {}
	self.overkill.content.loot_drops = {
	
					{ type_items = "textures", item_entry = "compass", amount = 34 },
					{ type_items = "textures", item_entry = "pd2", amount = 123 },
					{ type_items = "materials", item_entry = "deep_bronze", amount = 11 },
					{ type_items = "materials", item_entry = "rock3", amount = 21 },
					{ type_items = "colors", item_entry = "magenta_solid", amount = 1 },
					{ type_items = "colors", item_entry = "dark_gray_solid", amount = 18 },
					{ type_items = "masks", item_entry = "dallas_clean", amount = 1 },
					{ type_items = "masks", item_entry = "chains_clean", amount = 1 },
					{ type_items = "masks", item_entry = "hoxton_clean", amount = 1 },
					{ type_items = "masks", item_entry = "wolf_clean", amount = 1 },
	}]]
end
