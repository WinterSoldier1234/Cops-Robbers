
--[[
  Cops and Robbers: Robberies & Heists
  Created by RhapidFyre

  These files contain all of the scripts for robberies, heists, and anything
  that requires the players to steal from NPCs. Personal robberies, jewelry
  missions, etc. This does not include any jobs, such as armored transport.

  Contributors:
    -

  Created 07/19/2019
--]]


fx_version 'cerulean'
game 'gta5'

ui_page "nui/ui.html"
dependencies  {'cnrobbers'}

files {
	"nui/ui.html",
  "nui/ui.js",
  "nui/ui.css"
}

client_scripts {
  "config.lua",
  "cl_robberies.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "config.lua",
  "sv_robberies.lua"
}

server_exports {

}

exports {

}
