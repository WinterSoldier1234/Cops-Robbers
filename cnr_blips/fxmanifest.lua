fx_version 'cerulean'
game 'gta5'

dependencies  {'cnrobbers'}


client_scripts {
  "cl_blips.lua"
}

server_scripts {
  "sv_blips.lua"
}

server_exports {

}

exports {
  'CreateBlipForPlayer',
  'RemoveBlipForPlayer',
  'GetPlayerBlip'
}
