
-- Config (Server)
RegisterServerEvent('cnr:police_stations_req')

--- LoadPoliceStations()
-- Sends list of valid police stations to player (if given) or all players
-- @param client The client to send it to. Defaults to all clients if nil
local function LoadPoliceStations(client)

  -- SQL: Return list of all stations that are law enforcement related
  MySQL.update(
    "SELECT * FROM stations",
    {}, function(stationList)
      local src = client
      if not src then src = (-1) end
      TriggerClientEvent('cnr:police_stations', src, stationList)
    end
  )
  -- cams = {
  --   view = vector4(),
  --   exit = vector4(),
  --   walk = vector4(),
  -- }

end


-- Used to trigger LoadPoliceStations()
AddEventHandler('cnr:client_loaded', function()
  local client = source
  LoadPoliceStations(client)
end)


-- Used to trigger LoadPoliceStations() on resource restart
Citizen.CreateThread(function()
  Citizen.Wait(5000)
  LoadPoliceStations()
end)

AddEventHandler('cnr:police_stations_req', function(stNumber)
  local client = source
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Player #"..client.." requesting Station #"..stNumber.." information.")
  end
  if stNumber then
    if stNumber > 0 then

      -- SQL: Return station information (armory, vehicles, etc)
      MySQL.update(
        "SELECT * FROM stations WHERE id = @n", {['n'] = stNumber},
        function(stationInfo)
          if not stationInfo then stationInfo = {}    end
          if not client      then client      = (-1)  end
          TriggerClientEvent('cnr:police_station_info', client, stationInfo[1])
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - Sent player station info: "..json.encode(stationInfo[1]))
          end
        end
      )

    end -- stNumber > 0
  end -- stNumber
end)