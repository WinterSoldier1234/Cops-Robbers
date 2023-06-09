
-- sv admin
RegisterServerEvent('cnr:client_loaded')
RegisterServerEvent('cnr:admin_check')

RegisterServerEvent('cnr:admin_cmd_release')
RegisterServerEvent('cnr:admin_cmd_kick')
RegisterServerEvent('cnr:admin_cmd_ban')
RegisterServerEvent('cnr:admin_cmd_warn')
RegisterServerEvent('cnr:admin_cmd_freeze')
RegisterServerEvent('cnr:admin_cmd_teleport')
RegisterServerEvent('cnr:admin_cmd_tp_sendback')
RegisterServerEvent('cnr:admin_cmd_unfreeze')
RegisterServerEvent('cnr:admin_cmd_tphere')
RegisterServerEvent('cnr:admin_cmd_tpto')
RegisterServerEvent('cnr:admin_cmd_tpsend')
RegisterServerEvent('cnr:admin_cmd_tpmark')
RegisterServerEvent('cnr:admin_cmd_announce')
RegisterServerEvent('cnr:admin_cmd_mole')
RegisterServerEvent('cnr:admin_cmd_asay')
RegisterServerEvent('cnr:admin_cmd_csay')
RegisterServerEvent('cnr:admin_cmd_plyinfo')
RegisterServerEvent('cnr:admin_cmd_vehinfo')
RegisterServerEvent('cnr:admin_cmd_svinfo')
RegisterServerEvent('cnr:admin_cmd_spawncar')
RegisterServerEvent('cnr:admin_cmd_delveh')
RegisterServerEvent('cnr:admin_cmd_spawnped')
RegisterServerEvent('cnr:admin_cmd_setcash')
RegisterServerEvent('cnr:admin_cmd_setbank')
RegisterServerEvent('cnr:admin_cmd_setweather')
RegisterServerEvent('cnr:admin_cmd_settime')
RegisterServerEvent('cnr:admin_cmd_giveweapon')
RegisterServerEvent('cnr:admin_cmd_takeweapon')
RegisterServerEvent('cnr:admin_cmd_stripweapons')
RegisterServerEvent('cnr:admin_cmd_togglelock')
RegisterServerEvent('cnr:admin_cmd_inmates')
RegisterServerEvent('cnr:admin_cmd_setwanted')

local admins = {}
local warns  = {}
local cprint = function(msg) exports['cnrobbers']:ConsolePrint(msg) end

--- EXPORT: AdminLevel()
-- Checks if the player is an admin
-- @param client The server ID
-- @return table 1:Admin Level, 2:Admin ID Number
function AdminLevel(client)

  if not client then          return {[1] = 0, [2] = 0}  end
  if not admins[client] then  return {[1] = 0, [2] = 0}  end

  if admins[client] > 9999 then
    return {[1] = 4, [2] = admins[client]}
  elseif admins[client] > 999 then
    return {[1] = 3, [2] = admins[client]}
  end

  return {[1] = 2, [2] = admins[client]}
end

local function AssignAdministrator(client, aLevel)
  if not type(aLevel) == "number" then aLevel = tonumber(aLevel) end
  if aLevel > 1 then
    repeat

      local gen = math.random(1000,9999)
      if aLevel == 2 then gen = math.random(100,999)
      elseif aLevel == 4 then gen = math.random(10000, 99999)
      end

      local exists = false
      for k,v in pairs(admins) do
        if v == gen then exists = true end
      end

      if not exists then
        admins[client] = gen
        print("[CNR ADMIN] Assigned Admin ID "..admins[client].." to "..GetPlayerName(client))
        TriggerClientEvent('cnr:admin_assigned', client, admins[client])

      end
      Citizen.Wait(10)

    until admins[client]
  end
  return ( admins[client] )
end


--- BlockAction()
-- Blocks the action attempt if affected admin is equal or greater rank
-- @return True if the action should be blocked/stopped
local function BlockAction(offense, defense)
  if admins[offense] > 9999 then return false
  elseif admins[offense] > 999 then
    if admins[defense] > 999 then return true end
  elseif admins[offense] > 99 then
    if admins[defense] > 99 then return true end
  end
  return true
end

local function CheckAdmin(client)
  local uid    = exports['cnrobbers']:UniqueId(client)
  local aLevel = MySQL.query.await(
    "SELECT perms FROM players WHERE idUnique = @uid",
    {['uid'] = uid}
  )
  print(GetPlayerName(client).." (ID #"..client..") [UID "..uid.."] has permission level "..aLevel[1].perms)
  if aLevel and aLevel[1] and aLevel[1].perms then
    AssignAdministrator(client, aLevel[1].perms)
  else
    print("[CNR ADMIN] - No idUnique found for player #"..client)
  end
end
AddEventHandler('cnr:client_loaded', function() CheckAdmin(source) end)
AddEventHandler('cnr:admin_check',   function() CheckAdmin(source) end)


function ShutdownServer(src, a)
  if not src then src = 1 end
  if not a then a = 61 end
	if src < 1 then
    if a < 60 then a = 60 end -- Give people a minimum of 60 seconds
    local mins = math.floor(a/60)
    
    local tempMessage = "The server is shutting down in "..mins.." minute(s)!"
    cprint("^3"..tempMessage, true)
    
    exports['cnrobbers']:DiscordFeed(
      9807270, "Game Server",
      "The server is shutting down in **"..mins.." minute(s)**!",
      "Safe-Shutdown process was invoked at the Server Terminal."
    )
    
    TriggerClientEvent('chatMessage', (-1), 
      "^3The server is shutting down in "..mins.." minutes.\n"..
      "^3Wrap up what you're doing, the world's about to end."
    )
    
    -- Loop until time is up
    while a > 0 do
      if a % 15 then
      
        a = a - 1
        local secs = math.floor(a%60)
        local mins = math.floor(a/60)
        local pl = {s = "", m = ""} -- plural
        
        if mins > 1 then pl.m = "s" end
        if secs > 1 then pl.s = "s" end
        
        -- Prep message. If no time remains, nil it and disregard
        local msg = "^3The server is shutting down in "
        if a < 1 then msg = nil end
        
        -- If a minute or more remain, add "# minute(s)" to message
        if mins > 0 then msg = msg..mins.." minute"..(pl.m) end
        
        -- If time remains, and seconds are > 0, add "# second(s)" to message
        if msg and secs > 0 then
          msg = msg..secs.." second"..(pl.s)
        end
        
        if msg then 
          -- Broadcast every 15 seconds
          if (a % 15 == 0) or (a <= 10) then 
            TriggerClientEvent('chatMessage', (-1), msg)
          end
        end
        
      end
      Citizen.Wait(1001)
    end
    
    TriggerClientEvent('chatMessage', (-1),
      "^1The server is now shutting down.\n"..
      "^7All players will be disconnected to preserve character information."
    )
    
		Citizen.Wait(1000)
		while (#GetPlayers() > 0) do
			DropPlayer(GetPlayers()[1], "The server is shutting down. Please come again soon!")
			Citizen.Wait(10)
		end
    
		Citizen.Wait(100)
    cprint("^2Safe Shutdown Complete. ^7Terminating the program.", true)
    
    
    Citizen.Wait(3000)
    os.execute('screen -S "fivem" -X quit') -- Terminate the window
    
	else
		TriggerClientEvent('chat:addMessage', {templateId = 'errMsg', args = {
      "Improper Usage", "Command must be used at the terminal window."
    }})
	end
end
RegisterCommand('shutdown', function(src,sec)
  if not sec then sec = {} end       -- If not given, empty table (stops nil error)
  if not sec[1] then sec[1] = 60 end -- If not given, shutdown in 60 seconds
  ShutdownServer(tonumber(src), tonumber(sec[1]))
end, true)

AddEventHandler('playerDropped', function(reason)
  local client = source
  if admins[client] then admins[client] = nil end
end)


AddEventHandler('cnr:admin_cmd_release', function(target, bailReason)
  local client = source
  if admins[client] then
    exports['cnr_police']:ReleaseFugitive(target, false)
    cprint(
      "^3[ADMIN] ^7"..GetPlayerName(client).." released "..GetPlayerName(target)..
      " from custody. Reason Given: "..bailReason
    )
    Citizen.Wait(1000)
    TriggerClientEvent('chat:addMessage', (-1), {templateId = 'sysMsg', args = {
      "Admin #"..(admins[client]).." ^2set^7 "..GetPlayerName(target)..
      " free. Reason: ^3"..bailReason.."^7"
    }})
    Citizen.Wait(1200)
  else
    TriggerClientEvent('chat:addMessage', client, {templateId = 'errMsg', args = {
      "Command Failure", "You're not an admin, fuck off."
    }})
  end
end)


AddEventHandler('cnr:admin_cmd_imprison', function(target, jailReason)
  local client = source
  if admins[client] then
    exports['cnr_police']:ImprisonClient(target, client, true)
    cprint(
      "^3[ADMIN] ^7"..GetPlayerName(client).." threw "..GetPlayerName(target)..
      " in jail. Reason Given: "..jailReason
    )
    Citizen.Wait(1000)
    TriggerClientEvent('chat:addMessage', (-1), {templateId = 'sysMsg', args = {
      "Admin #"..(admins[client]).." threw ^7 "..GetPlayerName(target)..
      " in jail. Reason: ^3"..jailReason.."^7"
    }})
    Citizen.Wait(1200)
  end
end)


AddEventHandler('cnr:admin_cmd_kick', function(target, kickReason)
  local client = source
  if admins[client] then
    if admins[target] then
      if BlockAction(client, target) then
        TriggerEvent('cnr:admin_message',
          "Admin "..GetPlayerName(client).." (ID #"..client..") attempted to kick "..
          "Admin "..GetPlayerName(target).." (ID #"..target.."), but was blocked."
        )
        return 0
      end
    end
    TriggerClientEvent('chat:addMessage', (-1), {
      multiline = true, args = {
        "^1Admin #"..(admins[client])..
        " kicked "..GetPlayerName(target)..
        "\nReason: ^7"..tostring(kickReason)
      }
    })
    Citizen.Wait(1200)
    DropPlayer(target, "Kicked by Admin: "..kickReason)
  end
end)


AddEventHandler('cnr:admin_cmd_ban', function(target, banReason, minutes)
  local client = source
  if admins[client] then

    if admins[client] > 99 then

      if BlockAction(client, target) then
        cprint("Admin Action was blocked (equal or greater rank)")
        TriggerEvent('cnr:admin_message',
          "Admin "..GetPlayerName(client).." (ID #"..client..") attempted to BAN "..
          "Admin "..GetPlayerName(target).." (ID #"..target.."), but was blocked."
        )
        return 0
      end

      local banType = " permabanned "
      if minutes then banType = " tempbanned " end
      TriggerClientEvent('chat:addMessage', (-1), {
        multiline = true, args = {
          "^1Admin #"..(admins[client])..
          banType..GetPlayerName(target)..
          "\nReason: ^7"..tostring(banReason)
        }
      })

      local uid = exports['cnrobbers']:UniqueId(target)
      if minutes then
        local bTime = os.time() + (minutes * 1000)
        banReason = banReason.." (Ban lifts: "..(os.date("%I:%M%p", bTime))..")"
        local bTimeModified = os.date("%Y-%m-%d %I:%M:%S", bTime)
        MySQL.execute(
          "UPDATE players SET perms = 0, bantime = @bt, "..
          "reason = @br WHERE id = @uid",
          {
            ['br'] = banReason, ['uid'] = uid,
            ['bt'] = bTimeModified
          }
        )

      else
        MySQL.execute(
          "UPDATE players SET perms = 0, bantime = NULL, "..
          "reason = @br WHERE id = @uid",
          {['br'] = banReason, ['uid'] = uid}
        )

      end

      Citizen.Wait(1200)
      DropPlayer(target, "Banned by Admin: "..banReason)

    else
      local msg = "Insufficient Permissions"
      TriggerEvent('cnr:admin_message', msg)

    end
  else
  end
end)


AddEventHandler('cnr:admin_cmd_warn', function(target, reason)
  local client = source
  if admins[client] then

    if admins[client] > 99 then

      if BlockAction(client, target) then
        cprint("Admin Action was blocked (equal or greater rank)")
        TriggerEvent('cnr:admin_message',
          "Admin "..GetPlayerName(client).." (ID #"..client..") attempted to warn "..
          "Admin "..GetPlayerName(target).." (ID #"..target.."), but was blocked."
        )
        return 0
      end

      if not warns[target] then warns[target] = 0 end
      warns[target] = warns[target] + 1

      if warns[target] > 2 then
        TriggerClientEvent('chat:addMessage', (-1), {
          multiline = true, args = {
            "^1Server auto-kicked "..GetPlayerName(target)..": Too many warnings. "..
            "\nLatest Warning For: "..reason
          }
        })
        Citizen.Wait(1200)
        DropPlayer(target, "Auto-Kicked: Received 3 Warnings in One Session.")
      else
        TriggerClientEvent('chat:addMessage', (-1), {
          multiline = true, args = {
            "^1Admin #"..(admins[client])..
            " warned "..GetPlayerName(target).." ("..warns[target].."/3)"..
            "\nReason: ^7"..reason
          }
        })
      end

    else
      local msg = "Insufficient Permissions"
      TriggerEvent('cnr:admin_message', msg)

    end
  else
  end
end)


AddEventHandler('cnr:admin_cmd_setwanted', function(target, setLevel)
  local client = source
  if admins[client] then

    if admins[client] > 99 then

      if BlockAction(client, target) then
        cprint("Admin Action was blocked (equal or greater rank)")
        TriggerEvent('cnr:admin_message',
          "Admin "..GetPlayerName(client).." (ID #"..client..") attempted to freeze "..
          "Admin "..GetPlayerName(target).." (ID #"..target.."), but was blocked."
        )
        return 0
      end
  
      local offen = "ticketable"
      if setLevel < 1 then 
        exports['cnr_wanted']:WantedPoints(target, "jailed")
        TriggerClientEvent('chat:addMessage', (-1), {
          multiline = true, args = {
            GetPlayerName(target).." had their wanted levels ^2cleared^7 by ^1Admin #"..
            (admins[client]).."^7. They're now innocent."
          }
        })
        return 0
      elseif setLevel == 1 then
        exports['cnr_wanted']:WantedPoints(target, "vandalism")
        offen = "ticketable"
      elseif setLevel == 2 then
        exports['cnr_wanted']:WantedPoints(target, "gta-npc")
        offen = "a criminal"
      elseif setLevel == 3 then 
        exports['cnr_wanted']:WantedPoints(target, "murder")
        offen = "a felon"
      else
        exports['cnr_wanted']:WantedPoints(target, "murder-leo")
        exports['cnr_wanted']:WantedPoints(target, "murder-leo")
        offen = "Most Wanted"
      end
      TriggerClientEvent('chat:addMessage', (-1), {
        multiline = true, args = {
          GetPlayerName(target).." had their wanted level set by ^1Admin #"..
          (admins[client]).."^7. They're now ^1"..offen..".^7"
        }
      })
        

    else
      local msg = "Insufficient Permissions"
      TriggerEvent('cnr:admin_message', msg)

    end
  end
end)


AddEventHandler('cnr:admin_cmd_freeze', function(target, doFreeze)
  local client = source
  if admins[client] then

    if admins[client] > 99 then

      if BlockAction(client, target) then
        cprint("Admin Action was blocked (equal or greater rank)")
        TriggerEvent('cnr:admin_message',
          "Admin "..GetPlayerName(client).." (ID #"..client..") attempted to freeze "..
          "Admin "..GetPlayerName(target).." (ID #"..target.."), but was blocked."
        )
        return 0
      end

      TriggerClientEvent('cnr:admin_do_freeze', target, doFreeze, admins[client])

    else
      local msg = "Insufficient Permissions"
      TriggerEvent('cnr:admin_message', msg)

    end
  else
  end
end)


-- DEBUG - Come back and finish this after asay works
local function TeleportAlert(toPlayer, fromPlayer, admin, aid)

  -- CASE 1: Player to Player
  if toPlayer and fromPlayer then
    -- CASE 1A: Player to Player
    if toPlayer ~= admin and fromPlayer ~= admin then

    -- CASE 1B: Player to Admin
    elseif toPlayer == admin then

    -- CASE 1C: Admin to Player
    elseif fromPlayer == admin then

    -- CASE 1D: Admin to Admin
    else

    end

  -- CASE 2: Player to Nobody (TP to coords)
  elseif fromPlayer then

  -- CASE 3: Nobody to Player (Should never happen?)
  else

  end


end

AddEventHandler('cnr:admin_cmd_teleport', function(toPlayer, fromPlayer, coords)
  local client = source
  print("DEBUG", toPlayer, fromPlayer, coords)
  if admins[client] then
    -- Sending one player to another
    if toPlayer > 0 and fromPlayer > 0 then
      TriggerClientEvent('cnr:admin_tp_coords', fromPlayer, toPlayer, nil, admins[client])
      TeleportAlert(toPlayer, fromPlayer, client, admins[client])
      ActionLog("Admin #"..admins[client].." ("..GetPlayerName(client)..") sent "..GetPlayerName(fromPlayer).." (ID #"..fromPlayer..") to "..GetPlayerName(toPlayer).." (ID #"..toPlayer..")")

    -- Sending Admin to player
    elseif toPlayer > 0 then
      TriggerClientEvent('cnr:admin_tp_coords', client, toPlayer, nil, admins[client])
      TeleportAlert(toPlayer, client, client, admins[client])
      ActionLog("Admin #"..admins[client].." ("..GetPlayerName(client)..") teleported to "..GetPlayerName(toPlayer).." (ID #"..toPlayer..")")

    -- Bringing another player to Admin
    elseif fromPlayer > 0 then
      TriggerClientEvent('cnr:admin_tp_coords', fromPlayer, client, nil, admins[client])
      TeleportAlert(client, fromPlayer, client, admins[client])
      ActionLog("Admin #"..admins[client].." ("..GetPlayerName(client)..") brought "..GetPlayerName(fromPlayer).." (ID #"..fromPlayer..") to them.")

    -- Going to a specific location
    else
      TriggerClientEvent('cnr:admin_tp_coords', client, client, coords, admins[client])
      TeleportAlert(nil, nil, client, admins[client])
      ActionLog("Admin #"..admins[client].." ("..GetPlayerName(client)..") teleported to "..tostring(coords))
    end
  else
  end
end)


AddEventHandler('cnr:admin_cmd_teleport', function(teleportee)
  local client = source
  if admins[client] then
    TriggerClientEvent('cnr:admin_do_sendback', teleportee, admins[client])
  end
end)

AddEventHandler('cnr:admin_cmd_announce', function(message)
  local client = source
  if admins[client] then
    if admins[client] > 999 then
      TriggerClientEvent('chat:addMessage', (-1), {templateId = 'sysMsg',
        args = { "Admin #"..admins[client]..": "..message }
      })
    else
      TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
        args = { "Insufficient Permissions." }
      })
    end
  end
end)


AddEventHandler('cnr:admin_cmd_mole', function(message)
  local client = source
  if admins[client] then
    if admins[client] > 999 then
      TriggerClientEvent('cnr:chat_notification', (-1), "CHAR_LESTER",
        "MOLE", "555-1234", message
      )
    else
      TriggerClientEvent('cnr:chat_notification', (-1), "CHAR_LESTER",
        "5M CNR", "Server Notice", "Insufficient Permissions"
      )
    end
  end
end)


--- EXPORT: AdminMessage()
-- Sends an admin message to all admins on the server
-- @param message A message sent to all admins
-- @param client  Player Server ID; If nil, comes from "server"
function AdminMessage(message, client)

  local aid  = 0
  local ply  = "SERVER"
  local name = "SERVER CONSOLE"
  if client then
    ply  = client
    aid  = admins[client]
    name = GetPlayerName(client)
  end
  PerformHttpRequest(
    "https://discordapp.com/api/webhooks/667800489534160925/ws7iwSoeIBjRrcX5vV7nJoyDFoAEXXAXoJx6onGgZyKqa3fLWBAJzf12fGzWUuA5gTqT",
    function(err, text, headers) end, 'POST',
    json.encode({
      username = "5M:CNR Monitor",
      content  = "**"..name.." (# "..aid..")**: "..message
    }),
    { ['Content-Type'] = 'application/json' }
  )
  for k,_ in pairs (admins) do
    TriggerClientEvent('chat:addMessage', k, {templateId = 'asay',
      args = {name.." ("..aid..")", message}
    })
  end

end

RegisterCommand('players', function(s,a,r)
  local plys = GetPlayers()
  if #plys > 0 then
    if not a[1] then 
      cprint("^3[ADMIN] ~~ Listing current players ~~^7")
      for _,i in ipairs (plys) do
        local isCop = exports['cnr_police']:DutyStatus(i)
        local msg   = "Civilian"
        local wLevel = exports['cnr_wanted']:WantedLevel(i)
        if not isCop then
          if wLevel > 0 then msg = "^1WANTED LEVEL ^7("..(wLevel)..")"
          else msg = "^7INNOCENT" end
        else              msg = "^5POLICE^7"
        end
        cprint("~ ^2"..GetPlayerName(i).." ^7(ID #^3"..(i).."^7) - "..msg) 
      end
      cprint("^3[ADMIN] ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~")
    else
      if a[1] == "cops" or a[1] == "police" or a[1] == "law" then
        cprint("^3[ADMIN] ~~ Listing ^5law enforcement ^3players only ~~^7")
        for _,i in ipairs (plys) do
          local isCop = exports['cnr_police']:DutyStatus(i)
          if isCop then
            cprint("^2"..GetPlayerName(i).." ^7(ID #^5"..(i).."^7)") 
          end
        end
      
      elseif a[1] == "civs" or a[1] == "civilian" or a[1] == "civilians" or a[1] == "innocent" or a[1] == "innocents" then
        cprint("^3[ADMIN] ~~ Listing ^7innocent ^3players only ~~^7")
        for _,i in ipairs (plys) do
          local wLevel = exports['cnr_wanted']:WantedLevel(i)
          if wLevel < 1 then
            cprint("^2"..GetPlayerName(i).." ^7(ID #^3"..(i).."^7)")
          end
        end
      
      elseif a[1] == "wanteds" or a[1] == "wanted" or a[1] == "robbers" then 
        cprint("^3[ADMIN] ~~ Listing ^2wanted ^3players only ~~^7")
        for _,i in ipairs (plys) do
          local wLevel = exports['cnr_wanted']:WantedLevel(i)
          if wLevel > 0 then
            cprint("^2"..GetPlayerName(i).." ^7(ID #^1"..(i).."^7) - Wanted Level "..wLevel)
          end
        end
      else
        cprint("^1[ADMIN] ^7Failed. Usage: /players <[opt]cops/civs/wanteds>")
      end
      cprint("^3[ADMIN] ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~")
    end
  else
    cprint("^3[ADMIN] ^7There are currently ^30 ^7players on the server.")
  end
end, true)

RegisterCommand('asay', function(s,a,r)
  AdminMessage(table.concat(a, " "))
end, true)

AddEventHandler('cnr:admin_cmd_asay', function(message)
  local client = source
  if admins[client] then AdminMessage(message, client)
  end
end)


AddEventHandler('cnr:admin_cmd_csay', function(message)
  local client = source
  TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
    args = { "( Not Implemented )" }
  })
end)


AddEventHandler('cnr:admin_cmd_plyinfo', function()
  local client = source
  TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
    args = { "( Not Implemented )" }
  })
end)


AddEventHandler('cnr:admin_cmd_vehinfo', function()
  local client = source
  TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
    args = { "( Not Implemented )" }
  })
end)

AddEventHandler('cnr:admin_cmd_svinfo', function()
  local client = source
  TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
    args = { "( Not Implemented )" }
  })
end)


AddEventHandler('cnr:admin_cmd_spawncar', function(vModel)
  local client = source
  if admins[client] then
    if admins[client] > 999 then
      TriggerClientEvent('cnr:admin_do_spawncar', client, vModel)
    else
      TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
        args = { "Insufficient Permissions" }
      })
    end
  end
end)


AddEventHandler('cnr:admin_cmd_delveh', function()
  local client = source
  if admins[client] then
    TriggerClientEvent('cnr:admin_do_delveh', client)
  end
end)


AddEventHandler('cnr:admin_cmd_spawnped', function()

end)


AddEventHandler('cnr:admin_cmd_setcash', function(target, amount)

  local client = source
  if admins[client] then

    -- If amount is positive
    if amount > 0 then
      TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
        args = { "Admin #"..admins[client].." added $"..amount.." to your wallet." }
      })
      exports['cnr_cash']:CashTransaction(target, amount)

    -- If amount is negative
    elseif amount < 0 then
      if admins[target] then
        -- Admin is higher ranking OR a Superadmin
        if admins[client] > admins[target] or admins[client] > 9999 then
          TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
            args = { "Admin #"..admins[client].." took away $"..amount.." from your wallet." }
          })
          exports['cnr_cash']:CashTransaction(target, amount)

        -- Admin isn't a Superadmin, and is equal or lower ranking than target
        else
          TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
            args = { "Can't take money away from a higher/equal ranking admin" }
          })

        end

      else
        TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
          args = { "Admin #"..admins[client].." took away $"..amount.." from your wallet." }
        })
        exports['cnr_cash']:CashTransaction(target, amount)

      end

    else
      TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
        args = { "Enter an amount other than 0. (Negative takes away money)" }
      })

    end
  end
end)


AddEventHandler('cnr:admin_cmd_setbank', function(target, amount)

  local client = source
  if admins[client] then

    -- If amount is positive
    if amount > 0 then
      TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
        args = { "Admin #"..admins[client].." added $"..amount.." to your bank balance." }
      })
      exports['cnr_cash']:BankTransaction(target, amount)

    -- If amount is negative
    elseif amount < 0 then
      if admins[target] then
        -- Admin is higher ranking OR a Superadmin
        if admins[client] > admins[target] or admins[client] > 9999 then
          TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
            args = { "Admin #"..admins[client].." took away $"..amount.." from your bank balance." }
          })
          exports['cnr_cash']:BankTransaction(target, amount)

        -- Admin isn't a Superadmin, and is equal or lower ranking than target
        else
          TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
            args = { "Can't take money away from a higher/equal ranking admin" }
          })

        end

      else
        TriggerClientEvent('chat:addMessage', target, {templateId = 'sysMsg',
          args = { "Admin #"..admins[client].." took away $"..amount.." from your bank balance." }
        })
        exports['cnr_cash']:BankTransaction(target, amount)

      end

    else
      TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
        args = { "Enter an amount other than 0. (Negative takes away money)" }
      })

    end
  end
end)


AddEventHandler('cnr:admin_cmd_setweather', function()

end)


AddEventHandler('cnr:admin_cmd_settime', function()

end)


AddEventHandler('cnr:admin_cmd_giveweapon', function(target, wHash, wAmmo)
  local client = source
  if admins[client] then
    if admins[client] > 999 then
      TriggerClientEvent('cnr:admin_do_giveweapon', target, admins[client], wHash, wAmmo)
    else
      TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
        args = { "Insufficient Permissions" }
      })
    end
  end
end)


AddEventHandler('cnr:admin_cmd_takeweapon', function()

end)


AddEventHandler('cnr:admin_cmd_stripweapons', function()

end)


AddEventHandler('cnr:admin_cmd_togglelock', function(vehNumber)
  local client = source
  if admins[client] then
    TriggerClientEvent('cnr:admin_do_togglelock', client, vehNumber)
  end
end)


AddEventHandler('cnr:admin_cmd_inmates', function()

end)





function ActionLog(logMessage)
  cprint("ADMIN: "..logMessage)
end
