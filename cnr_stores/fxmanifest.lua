
--[[
  Cops and Robbers: Stores Resource
  Created by Michael Harris ( mike@harrisonline.us )
  02/26/2020

  This file contains all store information such as 24/7 convenience stores,
  and any other generic shops that do nothing but provide purchasable items

--]]


fx_version 'cerulean'
game 'gta5'

ui_page "nui/ui.html"
dependencies  {'cnrobbers','oxmysql'}

files {
	"nui/ui.html",  "nui/ui.js",  "nui/ui.css",
  "nui/img/beer_bottle.png",    "nui/img/chip_bag.png",
  "nui/img/fish_bait_poor.png", "nui/img/fish_rod_poor.png",
  "nui/img/hamburger.png",      "nui/img/soda_sprunk.png",
  "nui/img/water_bottle.png",   "nui/img/wbreaker.png",
  "nui/img/scratchers.png",     "nui/img/lotto_ticket.png",
}

client_scripts {
  "sh_config.lua",
  "cl_config.lua",
  "sh_stores.lua",
  "cl_stores.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "sh_config.lua",
  "sv_config.lua",
  "sh_stores.lua",
  "sv_stores.lua"
}

server_exports {
}

exports {
}

--[[

  NOTES
    itemInfo:
      ['id']      = Database ID # of the item (not an option for 'ADD')
      ['name']    = The game name of the item ('drink_beer')
      ['title']   = The proper name of them item ('Beer')
      ['consume'] = True if useable, false if not
      
]]