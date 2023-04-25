
--[[
  Cops and Robbers: Vehicle Resource
  Created by RhapidFyre

  Contributors:
    -

  Created 12/29/2019
--]]

fx_version 'cerulean'
game 'gta5'

ui_page "nui/ui.html"
dependency 'cnrobbers'

files {
	"nui/ui.html",
  "nui/ui.js",
  "nui/ui.css"
}

client_scripts {
  "cl_config.lua",
  "cl_vehicles.lua"
}

server_scripts {
  "sv_config.lua",
  "sv_vehicles.lua"
}

server_exports {
  '',
}

exports {
  ''
}
