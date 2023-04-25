
--[[
  Cops and Robbers: Score Tracking
  Created by RhapidFyre

  Handles all scoreboard related displays, scorekeeping, as well as
  player floating names (above head), and any other tracking features that
  does not belong in the Radar or other more applicable script(s).

  Contributors:
    -

  Created 07/13/2019
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
  "cl_score.lua"
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "sv_score.lua"
}

server_exports {
  "CalculateRanks",
  "CopRankFormula"
}

exports {
  "GetClientScore"
}
