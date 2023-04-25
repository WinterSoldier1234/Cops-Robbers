
--[[
  Cops and Robbers: World Pickup Events
  Created by RhapidFyre

  These files contain all of the functionality regarding pickups around the map.
  A pickup is an item you can find on the ground in the game world that, if
  interacted with, awards the player with the item specified.

  Contributors:
    -

  Created 12/12/2019
--]]

fx_version 'cerulean'
game 'gta5'

dependency 'cnrobbers'


client_scripts {
  "cl_pickups.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "sv_config.lua",
  "sv_pickups.lua"
}

server_exports {
}

exports {
}
