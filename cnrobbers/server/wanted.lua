
--[[
  Cops and Robbers: Wanted Script - Server Dependencies
  Created by Michael Harris (mike@harrisonline.us)
  08/19/2019

  This file contains all information that will be stored, used, and
  manipulated by any CNR scripts in the gamemode. For example, a
  player's level will be stored in this file and then retrieved using
  an export; Rather than making individual SQL queries each time.
--]]


RegisterServerEvent('cnr:wanted_points')
RegisterServerEvent('cnr:client_loaded')
RegisterServerEvent('cnr:crime')


local carUse     = {}  -- Keeps track of vehicle theft actions
local paused     = {}  -- Players to keep from wanted points being reduced
local crimesList = {}
local reduce     = {
  tickTime = 30,   -- Time in seconds between each reduction in wanted points
  points   = 1.25, -- Amount of wanted points to reduce upon (reduce.time)
}

--- EXPORT: WantedPoints()
-- Sets the player's wanted level.
-- @param ply      The player's server ID
-- @param crime    The crime that was committed
-- @param msg      If true, displays "Crime Committed" message
function WantedPoints(ply, crime, msg)
  if not DutyStatus(ply) then
    if not ply              then return 0             end
    if not CNR.wanted[ply]  then CNR.wanted[ply] = 0  end -- Creates ply index
    if not crime            then
      ConsolePrint("^1Crime '^7"..tostring(crime).."^1' not found in sh_wanted.lua!")
      return 0
    end

    if crime == 'prisonbreak' or crime == 'jailbreak' then
      if crime == 'prisonbreak' then
        TriggerClientEvent('cnr:radio_receive', (-1),
          true, "DISPATCH", "An inmate is escaping from Mission Row PD!",
          true, false, false
        )
      else
        TriggerClientEvent('cnr:radio_receive', (-1),
          true, "DISPATCH", "Prisoners are escaping from Bolingbroke Penitentiary!",
          true, false, false
        )
      end
      Citizen.Wait(30000)
    end

    local n = GetCrimeWeight(crime)
    if not n then return 0 end

    local lastWanted = CNR.wanted[ply]

    -- Sends a crime message to the perp
    if msg then
      local cn = GetCrimeName(crime)
      if cn then
        TriggerClientEvent('chat:addMessage', ply,
          {templateId = 'crimeMsg', args = {cn}}
        )
        TriggerClientEvent('cnr:push_notify', ply,
          1, "Crime Committed", cn
        )
      end
    end

    -- Add to criminal history
    if not crimesList[ply] then crimesList[ply] = {} end
    local pcl = #(crimesList[ply])
    crimesList[ply][pcl + 1] = crime
    TriggerClientEvent('cnr:wanted_crimelist', ply, crimesList[ply])

    -- Calculates wanted points increase by each point individually
    -- This makes higher wanted levels harder to obtain
    while n > 0 do -- e^-(0.02x/2)
      local addPoints = true

      -- Ensure crime is NOT a felony
      if (not IsCrimeFelony(crime)) then
        -- If the next point would make them a felon, do nothing.
        if CNR.wanted[ply] + 1 >= CNR.points.felony then addPoints = false end
      end

      -- Crime is a felony, or would not make player a felon (if not a felony)
      if addPoints then

        --[[ OLD FORMULA: e^-(0.02x/2)
        local modifier = math.exp( -1 * ((0.02 * wanted[ply])/2))
        local formula  = math.floor((modifier * 1)*100000)
        ]]

        -- NEW FORMULA: 1(0.98/1 ^x)
        local modifier = (0.98) ^ (CNR.wanted[ply])
        CNR.wanted[ply]    = (CNR.wanted[ply]) + modifier

      else n = 0
      end

      n = n - 1
      Wait(0)

    end

    -- Check for broadcast
    if lastWanted ~= CNR.wanted[ply] then
      local wants = WantedLevel(ply)

      -- Wanted level went up by at least 10 (1 level)
      if lastWanted < CNR.wanted[ply] - 10 then
        if wants > 10 then
          DiscordFeed(
            11027200, "San Andreas' Most Wanted",
            GetPlayerName(ply).." is now on the Most Wanted list!",
            "", 6
          )
        else
          DiscordFeed(
            15105570, GetPlayerName(ply).." had their Wanted Level increased!",
            "WANTED LEVEL "..wants, "", 6
          )
        end

      -- Player is no longer wanted
      elseif lastWanted > 0 and CNR.wanted[ply] <= 0 then
        DiscordFeed(
          8359053, GetPlayerName(ply).." is no longer wanted.",
          "WANTED LEVEL 0", "", 6
        )

      end
    end

    -- Tell other scripts about the change
    TriggerEvent('cnr:points_wanted', ply, lastWanted, CNR.wanted[ply], crime)
    TriggerClientEvent('cnr:wanted_client', (-1), ply, CNR.wanted[ply])
  else
    ConsolePrint("^1[CRIME] ^7"..GetPlayerName(ply).." #"..ply..
        ", a ^5police officer ^7, committed: "..crime)
  end
end

local tracking   = {}
local worstCrime = {}
function ReportCrime(client, crime, posn, ignore911)
  if crime then
    if DoesCrimeExist(crime) then

      -- This is the first crime that has been committed
      if not tracking[client] and not ignore911 then
        worstCrime[client] = crime
        tracking[client] = GetGameTimer() + 6000
        Citizen.CreateThread(function()
          while tracking[client] > GetGameTimer() do Citizen.Wait(100) end
          DispatchPolice(worstCrime[client], posn)
          tracking[client] = nil
          worstCrime[client] = nil
        end)
      -- Update with worst crime committed
      else
        local cWeight = GetCrimeWeight(crime)
        if cWeight > GetCrimeWeight(worstCrime[client]) then
          worstCrime[client] = crime
          tracking[client]   = GetGameTimer() + 6000
        end
      end
      WantedPoints(client, crime, msg)
    else
      ConsolePrint("^1Crime '^7"..tostring(crime).."^1' not found in sh_wanted.lua!")
    end
  end
end
AddEventHandler('cnr:crime', function(crime, ignore911)
  local client = source
  ReportCrime(client, crime, GetEntityCoords(GetPlayerPed(client)), ignore911)
end)


AddEventHandler('cnr:imprisoned', function(client)
  CNR.wanted[client] = 0
  TriggerClientEvent('cnr:wanted_client', (-1), ply, 0)
end)


--- AutoReduce()
-- Reduces wanted points per tick
function AutoReduce()
  while not CNR do Wait(100) end
  while not CNR.ready do Wait(100) end
  while true do
    if wanted then
      for idPlayer,wPoints in pairs (CNR.wanted) do
        if wPoints > 0 then
          -- If wanted level is not paused/locked, allow it to reduce
          if not paused[idPlayer] then
            local oldLevel  = WantedLevel(idPlayer)
            local newPoints = wPoints - (CNR.reduce.points)
            CNR.wanted[idPlayer] = newPoints
            if oldLevel > WantedLevel(idPlayer) then
              if GetConvar("showdebugprintings", "false") == "true" then
                print("DEBUG - Wanted Level Reduced: "..GetPlayerName(idPlayer).." ("..idPlayer..")")
              end
              TriggerClientEvent('cnr:wanted_client', (-1), idPlayer, newPoints)
            end
          end
        else
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - "..GetPlayerName(idPlayer).." ("..idPlayer..") is no longer wanted (AutoReduce)")
          end
          if not CNR.crimes[idPlayer] then CNR.crimes[idPlayer] = {} end
          CNR.wanted[idPlayer] = 0
          CNR.crimes[idPlayer] = {}
          TriggerClientEvent('cnr:wanted_client', (-1), k, 0)
          TriggerClientEvent('cnr:crimes_client', k, {})
        end
        Citizen.Wait(10)
      end
    end
    Citizen.Wait((CNR.reduce.timer)*1000)
  end
end
Citizen.CreateThread(AutoReduce)


--- CheckIfWanted()
-- Checks if player is wanted in SQL (Logged off while wanted)
-- If SQL wanted is zero, does nothing. If wanted, sets 'wanted_client' event
-- @param ply The player's server ID. If not given, function returns
function CheckIfWanted(ply)
  local uid = GetUniqueId(ply)

  if uid then
    MySQL.query(
      "SELECT wanted FROM players WHERE id = @uid",
      {['uid'] = uid},
      function(wp)
        -- If player being checked is wanted, send update for that player
        if not wp then
          ConsolePrint("^1SQL gave no response for wanted level query.")
          return
        end
        if wp > 0 then
          CNR.wanted[ply] = wp
          TriggerClientEvent('cnr:wanted_client', (-1), ply, wp)
        end
      end
    )
  else
    print("^1[CNR ERROR] ^7Unique ID was invalid ("..tostring(uid)..").")
  end
end


--- EXPORT: CrimeList()
-- Returns a list of crimes committed by the player
-- @param ply The player server ID to check.
-- @param crime If supplied, adds crime to player's crime list
-- @return List of crimes. If not wanted or not found, returns empty list
function CrimeList(ply, crime)
  if not ply             then return {} end
  if not crimesList[ply] then crimesList[ply] = {} end
  local n = #(crimesList[ply]) + 1
  if crime then crimesList[ply][n] = crime end
  return (crimesList[ply])
end


-- Called when a player signs in. Sends them the wanted persons list.
AddEventHandler('cnr:client_loaded', function()
  local ply = source
  -- Send new player list of wanted players
  TriggerClientEvent('cnr:wanted_client', ply, CNR.wanted)
end)










