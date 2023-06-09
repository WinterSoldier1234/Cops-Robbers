
--- ConsolePrint()
-- Nicely formatted console print with timestamp
-- @param msg The message to be displayed
function ConsolePrint(msg)
  if msg then
    local dt = os.date("%H:%M", os.time())
    print("[CNR "..dt.."] ^7"..(msg).."^7")
  end
end
AddEventHandler('cnr:print', ConsolePrint)


--- EXPORT: UniqueId()
-- Assigns / Retrieves player's Unique ID (SQL Database ID Number)
-- @param ply The player (server ID) to get the UID for
-- @param uid If provided, sets player's UID. If nil, returns UID
-- @return Returns the Unique ID, or 0 if not found

function DecompressTable(id)
  local retval = nil
  for k, v in pairs(id[1]) do
    retval = v
  end
  return retval
end

function UniqueId(client, uid)
  local ply = tonumber(client)
  if ply then

    -- If UID is given, assign it.
    if uid then
      CNR.unique[ply] = tonumber(uid)
      print("[CNROBBERS] ^2Unique ID Set ^7("..uid..") for Player #"..ply)
    else
      if not CNR.unique[ply] then
        print("^3[CNROBBERS] ^7- ^1ERROR; ^7Resource '^3"..GetInvokingResource()..
          "^7' requested Player #"..ply.."'s Unique ID, but 'uid' was '"..tostring(uid).."'."
        )
      end
    end

  else
    if GetConvar("showdebugprintings", "false") == "true" then
      print("DEBUG - ERROR; No 'ply' given to 'UniqueId()' (sv_cnrobbers.lua)")
    end
    return 0 -- No 'ply' given, return 0

  end
  return (CNR.unique[ply])
end


--- EXPORT: CurrentZone()
-- Returns the current zone value
-- @return The current zone (always int)
function CurrentZone()
  return (zone.active)
end


--- EXPORT: ZoneNotification()
-- Called when the zone is changing / has changed / will be changed
function ZoneNotification(i, t, s, m)
  TriggerClientEvent('cnr:chat_notify', (-1), i, t, s, m)
end


--- EXPORT: GetUniqueId()
-- Returns the player's Unique ID. If not found, attempts to find it (SQL)
-- DEBUG - OBSOLETE; Use 'UniqueId(ply, uid)' instead
-- @return The player's UID, or 0 if not found (always int)
function GetUniqueId(ply)
	return UniqueId(ply)
end


--- ZoneChange()
-- Handles changing over the zone. No params, no return.
function ZoneChange()
  local newZone = math.random(zone.count)
  while newZone == zone.active do
    newZone = math.random(zone.count); Wait(1)
  end

  local n = 300 -- 5 Minutes, in seconds
  ConsolePrint("^3Zone "..(newZone).." will unlock in 5 minutes.")

  while n > 30 do
    if n % 60 == 0 then
      local mins = (n/60).." minutes"
      if     n/60 == 1 then mins = "1 minute"
      elseif n/60  < 1 then mins = n.." seconds"
      end
      TriggerClientEvent('chat:addMessage', (-1), {args = {"ZONE CHANGE",
        "^3"..mins.."^1 until zone change!"}
      })
      ZoneNotification("CHAR_SOCIAL_CLUB",
        "Zone Change", "~r~"..mins,
        "The active zone is changing soon!"
      )
    end
    n = n - 1
    Wait(1000)
  end

  Citizen.Wait(20000)

  for i = 0, 9 do
    TriggerClientEvent('chat:addMessage', (-1),
      {args = {"^1Zone ^3#"..newZone.." ^1activates in ^3"..(10-i).." Second(s)^1!!"}}
    )
    Citizen.Wait(1000)
  end

  zone.active = newZone
  ConsolePrint("^2Zone "..(newZone).." is now active.")

  TriggerClientEvent('chat:addMessage', (-1),
    {args = {"^2Zone ^7#"..(newZone).." ^2is now the active Zone! (^7/zones^2)"}}
  )

  ZoneNotification("CHAR_SOCIAL_CLUB",
    "Zone Change", "~g~New Zone Active",
    "Zone #"..newZone.." is active."
  )

  -- Tell clients and server the zone has changed
  -- This gives the option to use exports['cnrobbers']:CurrentZone(), or to wait for event
  -- DO NOT MAKE THIS EVENT SAFE FOR NETWORKING
  TriggerClientEvent('cnr:zone_change', (-1), newZone)
  TriggerEvent('cnr:zone_change', newZone)
end


-- Runs the zone change timer for choosing which zone is being played
function ZoneLoop()
  while CNR.zones.count > 1 do
    if GetGameTimer() > zone.pick then

      CNR.zones.pick = os.time() + (Config.MinutesPerZone() * 60)
      
      --[[
        Threaded to ensure the (zone.timer) is consistent, and doesn't add
        5 minutes of tick every time the script decides to change the zone.
      ]]
      Citizen.CreateThread(ZoneChange)
      ConsolePrint("The next zone will be chosen at "..(os.date("%x %X", CNR.zones.pick)))
      
    end
    Citizen.Wait(1000)
  end
end


-- When a client has loaded in the game, send them relevant script details
RegisterServerEvent('cnr:client_loaded')
AddEventHandler('cnr:client_loaded', function()
  TriggerClientEvent('cnr:active_zone', source, CNR.zones.active)
end)


-- The primary gamemode driver
Citizen.CreateThread(function()
  while not CNR do Wait(1000) end
  while not CNR.ready do Wait(100) end
  if CNR.zones.count > 1 then 
    ConsolePrint("Zonechange will occur at "..(os.date("%x %X", CNR.zones.pick)))
  else ConsolePrint("Config: Using the entire map. ^3Zone functionality disabled.")
  end
  while true do
    if CNR.zones.count > 1 then ZoneLoop() end
    Citizen.Wait(1000)
  end
end)

