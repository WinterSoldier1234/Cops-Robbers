fx_version 'cerulean'
game 'gta5'

dependency 'cnrobbers'

ui_page "nui/ui.html"

files {
	"nui/ui.html",
	"nui/ui.js", 
	"nui/ui.css",
}

client_scripts {
	'config.lua',
	'cl_delivery.lua'
}
server_scripts {
	"@oxmysql/lib/MySQL.lua",
	'config.lua',
	'sv_delivery.lua'
}