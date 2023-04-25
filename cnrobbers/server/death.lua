RegisterServerEvent('cnr:death_check')     -- Checks for criminal death
RegisterServerEvent('cnr:death_respawned') -- Player reports respawn
RegisterServerEvent('cnr:death_noted')
RegisterServerEvent('cnr:player_death')
RegisterServerEvent('cnr:death_nonpassive')
RegisterServerEvent('cnr:death_buy_insurance')


local hiCost   = 5000
local passives = {}


AddEventHandler('cnr:death_nonpassive', function()
  passives[source] = nil
end)


AddEventHandler('cnr:death_respawn', function(hTitle)
  local client = source
  local pInfo  = GetPlayerName(client) .. " (" .. client .. ")"
  if not hTitle then hTitle = "General Medical" end

  if IsWanted(client) then
    local ped = GetPlayerPed(client)
    if DoesEntityExist(ped) then
      TriggerClientEvent('cnr:dispatch', "Wanted Patient", hTitle,
        GetEntityCoords(ped),
        "Security reporting a wanted person was just released"
      )
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - " .. pInfo .. " respawned as a wanted person!")
      end
    else
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - " ..
        pInfo ..
        " was wanted on respawn, but could not dispatch police.\n" ..
        "Player Coordinates were invalid (GetPlayerPed() failed).")
      end
    end
  end

  ConsolePrint(pInfo .. " has respawned")
end)


function IsPassive(client, isPassive)
  if not client then return false end
  if isPassive then passives[client] = isPassive end
  if passives[client] then return passives[client] end
  return false
end

AddEventHandler('cnr:death_buy_insurance', function()
  local client    = source
  local uid       = UniqueId(client)

  local isInsured = MySQL.execute.await(
    "SELECT insurance_life FROM characters WHERE idUnique = @u",
    { ['u'] = uid }
  )

  if isInsured > 4 then
    TriggerClientEvent('chat:addMessage', client, {
      templateId = 'sysMsg',
      args = {
        "You already have the maximum number of insurance policies!"
      }
    })
  else
    local cash = GetPlayerCash(client)
    local bank = GetPlayerBank(client)

    local adjustedCost = hiCost * isInsured

    if cash >= adjustedCost or bank >= adjustedCost then
      if cash >= adjustedCost then
        CashTransaction(client, (0 - adjustedCost))
        TriggerClientEvent('chat:addMessage', client, {
          templateId = 'sysMsg',
          args = {
            "You have purchased Health Insurance! (Paid $^2" .. adjustedCost .. "^7 from cash)"
          }
        })
      else
        BankTransaction(client, (0 - adjustedCost))
        TriggerClientEvent('chat:addMessage', client, {
          templateId = 'sysMsg',
          args = {
            "You have purchased Health Insurance! (Paid $^2" .. adjustedCost .. "^7 from bank)"
          }
        })
      end
      TriggerClientEvent('chat:addMessage', client, {
        templateId = 'sysMsg',
        args = {
          "You will retain your personal belongings the next ^3" ..
          (isInured + 1) .. " time(s) ^7you die."
        }
      })

      MySQL.execute(
        "UPDATE characters SET insurance_life = insurance_life + 1 " ..
        "WHERE idUnique = @u", { ['u'] = uid }
      )
    else
      TriggerClientEvent('chat:addMessage', client, {
        templateId = 'sysMsg',
        args = {
          "You cannot afford to buy Health Insurance! (Costs $^1" .. adjustedCost .. "^7)"
        }
      })
    end
  end
end)


-- Check if the death was a crime, and then notify the players
AddEventHandler('cnr:death_check', function(killer)
  local victim = source
  local dMessage = GetPlayerName(victim) .. " died"
  passives[victim] = true
  if killer then
    if killer ~= victim then
      local isCop = DutyStatus(killer)
      if not isCop then
        if GetConvar("showdebugprintings", "false") == "true" then
          print("DEBUG - cnr:death_check determined MURDER.")
        end
        dMessage = GetPlayerName(killer) .. " killed " .. GetPlayerName(victim)
        WantedPoints(killer, 'murder', true)
        local uid = UniqueId(killer)
        if killer then
          SRP.SQL.EXECUTE(
            "UPDATE characters SET kills = kills + 1 WHERE idUnique = @uid",
            { ['uid'] = uid }
          )
        end
      else
        -- If victim was not a wanted person
        local wLevel = WantedLevel(victim)
        if wLevel > 3 then
          dMessage = GetPlayerName(killer) .. " neutralized " .. GetPlayerName(victim)
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - cnr:death_check determined JUSTIFIED POLICE SHOOTING.")
          end
        else
          dMessage = GetPlayerName(killer) .. " unjustly killed " .. GetPlayerName(victim)
          if GetConvar("showdebugprintings", "false") == "true" then
            print("DEBUG - cnr:death_check determined UNJUSTIFIED POLICE SHOOTING")
          end

          local msgg = GetPlayerName(victim) .. " for a ticket-only offense."
          if wLevel < 1 then
            msgg = GetPlayerName(victim) .. ", an innocent civilian."
          end
          AdminMessage(
            "Officer " .. GetPlayerName(killer) .. " killed " .. msgg
          )
        end
      end
    else
      dMessage = GetPlayerName(victim) .. " killed themselves."
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - cnr:death_check determined SUICIDE.")
      end
    end
    TriggerClientEvent('cnr:death_notify', (-1), victim, killer)
  end
  ConsolePrint(dMessage)
  DiscordFeed(9807270, dMessage, "", "")
end)


-- Just note the death and notify the players
AddEventHandler('cnr:death_noted', function(killer)
  local victim     = source
  local dMessage   = GetPlayerName(victim) .. " died"
  passives[victim] = true
  ConsolePrint(dMessage)
  DiscordFeed(9807270, dMessage, "", "")
  TriggerClientEvent('cnr:death_notify', (-1), victim, killer)
end)


AddEventHandler('cnr:player_death', function(fadeTime)
  local client    = source
  local uid       = UniqueId(client)
  local insurance = 0
  local pInfo     = GetPlayerName(client) .. " (" .. client .. ")"

  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - " .. pInfo .. " reports that they have died! ('cnr:player_death')")
  end

  if Imprisoned(client) then
    if GetConvar("showdebugprintings", "false") == "true" then
      print("DEBUG - " .. pInfo .. " died in prison. No penalty.")
    end
  else
    if GetConvar("showdebugprintings", "false") == "true" then
      print("DEBUG - " .. pInfo .. " died NOT in prison. Checking for insurance.")
    end

    insurance = MySQL.execute.await(
      "SELECT insurance_life FROM characters WHERE idUnique = @u",
      { ['u'] = uid }
    )

    if not insurance then insurance = 0 end
    if insurance > 0 then
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - " .. pInfo .. " ^2DID ^7have life insurance.")
      end
    else
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - " .. pInfo .. " ^1DID NOT ^7have life insurance.")
      end
    end
  end
end)
