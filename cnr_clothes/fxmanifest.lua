
--[[
  Cops and Robbers: Clothing Resource
  Created by RhapidFyre

  Contributors:
    -

  Created 12/22/2019
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
  "cl_clothes.lua"
}

server_scripts {
  "sv_config.lua",
  "sv_clothes.lua"
}

server_exports {
  '',
}

exports {
  ''
}
