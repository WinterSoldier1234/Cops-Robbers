
--[[
  Cops and Robbers: Radar Blips (CLIENT)
  Created by Michael Harris (mike@harrisonline.us)
  08/12/2019

  This file handles radar blips for players, and radar locations not necessarily
  belonging to any script (random weapon pickups, etc)

  Permission is granted only for executing this script for the purposes
  of playing the gamemode as intended by the developer.
--]]
RegisterNetEvent('cnr:police_officer_duty')
RegisterNetEvent('cnr:wanted_client')
RegisterNetEvent('cnr:loaded')

local plyBlip = {}
local largeMap = false
local loaded   = true

AddEventHandler('cnr:loaded', function()
  loaded = true
end)

local function CloseBigMap()
  largeMap = false
  SetRadarBigmapEnabled(largeMap, false)
  TriggerEvent('cnr:bigmap', false)
end

Citizen.CreateThread(function()
  while not loaded do Wait(100) end
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Client loaded and ready.")
  end
  while true do

    Citizen.Wait(1)

    if IsControlJustReleased(0, 20) and not exports['cnr_police']:VehicleMenuOpen() then
      largeMap = not largeMap
      SetRadarBigmapEnabled(largeMap, false)
      TriggerEvent('cnr:bigmap', largeMap)
    end

    if largeMap then

		-- Close the map if the pause menu is opened
		if IsPauseMenuActive() then
			CloseBigMap()
		end

		-- Close the map if player is dead
		if IsPlayerDead(PlayerId()) or IsPedDeadOrDying(PlayerPedId()) then
			CloseBigMap()
		end

    end
  end
end)


local function CNRBlipColour(blip, wLevel, cLevel)
  if cLevel then
    if cLevel < 2       then SetBlipColour(blip, 12)
    elseif cLevel < 5   then SetBlipColour(blip, 18)
    elseif cLevel < 8   then SetBlipColour(blip, 30)
    elseif cLevel < 10  then SetBlipColour(blip, 42)
    else                     SetBlipColour(blip, 63)
    end
  else
    if wLevel < 1       then SetBlipColour(blip, 0)
    elseif wLevel < 4   then SetBlipColour(blip, 5)
    elseif wLevel < 7   then SetBlipColour(blip, 44)
    elseif wLevel < 10  then SetBlipColour(blip, 47)
    else                     SetBlipColour(blip, 49)
    end
  end
end


-- Ensures blips are created for all players
function DrawPlayerBlips()
  Citizen.Wait(3000)
  local temp = GetActivePlayers()
  for _,ply in ipairs (temp) do
    if ply ~= PlayerId() then
      local blip = GetBlipFromEntity(GetPlayerPed(ply))
      if DoesBlipExist(blip) then
        if GetConvar("showdebugprintings", "false") == "true" then
          print("DEBUG - Removed existing blip for Player #"..GetPlayerServerId(ply))
        end
        RemoveBlip(blip)
      end
    end
  end
  while true do
    local plys = GetActivePlayers()
    for _,ply in ipairs (plys) do
      if ply ~= PlayerId() then

        local ped    = GetPlayerPed(ply)
        local exists = GetBlipFromEntity(ped)

        if not DoesBlipExist(exists) then
          local blip = AddBlipForEntity(ped)
          local svid = GetPlayerServerId(ply)
          SetBlipAsFriendly(blip, true)
          SetBlipSprite(blip, 1)
          local wLevel = exports['cnr_wanted']:WantedLevel(svid)
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - wLevel = "..wLevel)
          end
          local cLevel = exports['cnr_police']:DutyStatus(svid)
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - cLevel = "..tostring(cLevel))
          end
          CNRBlipColour(blip, wLevel, cLevel)
          SetBlipColour(blip, 0)
          SetBlipScale(blip, 0.8)
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - Created blip for Player #"..svid)
          end
        end
      end
    end
    Citizen.Wait(1000)
  end
end

function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end


AddEventHandler('cnr:wanted_client', function(ply)
  if not ply then return end
  local client = GetPlayerFromServerId(ply)
  local wLevel = exports['cnr_wanted']:WantedLevel(ply)
  local blip = GetBlipFromEntity(GetPlayerPed(client))
  if DoesBlipExist(blip) then
    CNRBlipColour(blip, wLevel, cLevel)
  end
end)


AddEventHandler('cnr:police_officer_duty', function(ply, onDuty, cLevel)
  local client = GetPlayerFromServerId(ply)
  local blip   = GetBlipFromEntity(GetPlayerPed(client))
  if onDuty then
    CNRBlipColour(blip, wLevel, cLevel)
  else
    SetBlipColour(plyBlip[client], 0)
  end
end)


-- Starts functions / loops upon script load
Citizen.CreateThread(DrawPlayerBlips)




