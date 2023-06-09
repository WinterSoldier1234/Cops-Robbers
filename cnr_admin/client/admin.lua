
-- cl admin
RegisterNetEvent('cnr:admin_assigned')
RegisterNetEvent('cnr:admin_do_freeze')
RegisterNetEvent('cnr:admin_do_spawncar')
RegisterNetEvent('cnr:admin_do_delveh')
RegisterNetEvent('cnr:admin_do_togglelock')
RegisterNetEvent('cnr:admin_tp_coords')
RegisterNetEvent('cnr:admin_do_giveweapon')
RegisterNetEvent('cnr:admin_do_sendback')

local aLevel = 1
local aid    = 0
local showHelp = true
local helpNum = 1

-- Emergency close (/menus)
RegisterNetEvent('cnr:close_all_nui')
AddEventHandler('cnr:close_all_nui', function()
  SendNUIMessage({hidehelp = true})
  SetNuiFocus(false)
end)


RegisterCommand('help', function()
  SendNUIMessage({showhelp = true})
  SetNuiFocus(true, true)
end)


local helpMessages = {
  "~r~Red circles~w~ on the map? A ~r~crate~w~ is waiting to be collected!",
  "Help with a job, controls or commands? Type ~y~/help~w~ for info.",
  "Go on/off ~b~police duty~w~ at anytime by entering a station in the active ~y~/zones~w~.",
  "Bored? Why not rob a 24/7? Grab a gun and aim it at the clerk!",
  "Rob an ~g~ATM ~w~by smashing it with a melee weapon!",
  "Need clean cash on the side? Try fishing or hunting!",
  "Try out some legal jobs at one of the briefcases on the map!"
}

Citizen.CreateThread(function()
  local helpNum = math.random(#helpMessages)
  while true do 
    exports['cnr_chat']:ChatNotification("CHAR_SOCIAL_CLUB", "~y~System Help",
    "/togglehelp", helpMessages[helpNum])
    helpNum = helpNum + 1
    if helpNum > #helpMessages then helpNum = 1 end
    Citizen.Wait(300000)
  end
end)

RegisterCommand('togglehelp', function()
  showHelp = not showHelp
  if showHelp then 
    TriggerEvent('chat:addMessage', {templateId = 'sysMsg', args = {
      "Server help messages are now ^1hidden^7 and will no longer appear."
    }})
  else
    TriggerEvent('chat:addMessage', {templateId = 'sysMsg', args = {
      "Server help messages are now being ^2displayed^7."
    }})
  end
end)

--[[
      UNFINISHED COMMANDS 
]]
RegisterCommand('spawnped', function(s,a,r) end)
RegisterCommand('setweather', function(s,a,r) end)
RegisterCommand('settime', function(s,a,r) end)
RegisterCommand('inmates', function() end)
----------------------------------------------------

AddEventHandler('onClientResourceStart', function(rname)
  if rname == GetCurrentResourceName() then
    TriggerEvent('chat:addTemplate', 'asay',
      '<b><font color="#F00">[STAFF CHAT]</font> '..
      '{0}</b><font color="#DDD">: {1}</font>'
    )
  end
end)


local function CommandValid(cmd)
  if cmd then
    if aLevel >= CommandLevel(cmd) then 
      return true
    end
  end
  return false
end


local function CommandInvalid(cmd)
  TriggerEvent('chat:addMessage', {
    templateId = 'cmdMsg', multiline = false, args = {"/"..cmd}
  })
end

  
RegisterCommand('checkadmin', function()
  TriggerServerEvent('cnr:admin_check')
end)


AddEventHandler('cnr:admin_assigned', function(aNumber)
  aid = aNumber
  if     aNumber > 999 then aLevel = 3
  elseif aNumber >  99 then aLevel = 2
  end
  TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
    args = {"^2Successfully logged in as an admin. ^7ID Assigned: "..aid}
  })
end)


RegisterCommand('noclip', function()
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    noclip = not noclip
    if noclip then 
      Citizen.CreateThread(function()
        local noPos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), true)
        while noclip do 
          Citizen.Wait(0)
          DisableControlAction(0, 32, true) -- W
          DisableControlAction(0, 33, true) -- S 
          DisableControlAction(0, 34, true) -- A 
          DisableControlAction(0, 147, true) -- A Parachute
          DisableControlAction(0, 35, true) -- D 
          DisableControlAction(0, 9, true) -- D Flying
          DisableControlAction(0, 148, true) -- D Parachute
          DisableControlAction(0, 21, true) -- Shift (Sprint)
          DisableControlAction(0, 22, true) -- Spacebar
          DisableControlAction(0, 36, true) -- Duck (Ctrl)
          
          -- Turning
          if IsDisabledControlPressed(0, 34) or IsDisabledControlPressed(0, 147) then -- A
	  			  heading = (heading + 2.0)
	  		  elseif IsDisabledControlPressed(0, 35) or IsDisabledControlPressed(0, 9)  then -- D
	  			   heading = heading - 2.0
	  		  end
          SetEntityHeading(PlayerPedId(), heading%360)
          
          -- Movement up/down/forward/back
          if IsDisabledControlPressed(0, 32) then -- W
            noPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -1.0, 0.0)
          end
          if IsDisabledControlPressed(0, 33) then -- S
            noPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, 0.0)
          end
          if IsDisabledControlPressed(0, 22) then -- Space Bar
            noPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 1.0)
          end
          if IsDisabledControlPressed(0, 36) then -- Control
            noPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, -1.0)
          end
          SetEntityCoordsNoOffset(PlayerPedId(), noPos.x, noPos.y, noPos.z, 0, 0, 0)
        end
        FreezeEntityPosition(PlayerPedId(), false)
      end)
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('release', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <Reason>"}
      })
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
      local plys = GetActivePlayers()
      
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_release', tgt, table.concat(a, " "))
          break -- End the loop when we find the right person
        end
      end
      
    end
  else
    TriggerEvent('chat:addMessage', {template = 'errMsg', args = {
      "This is an Admin Command",
      "If you're trying to let someone out of jail, try ^3/bail ^7or ^3/lockpick^7."
    }})
  end
end)


RegisterCommand('imprison', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {templateId = 'errMsg', args = {
        "Invalid Arguments", "/"..cmd.." <ID#> <Reason>"
      }})
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
      local plys = GetActivePlayers()
      
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_imprison', tgt, table.concat(a, " "))
          break -- End the loop when we find the right person
        end
      end
      
    end
  else
    TriggerEvent('chat:addMessage', {template = 'errMsg', args = {
      "This is an Admin Command",
      "If you're trying to ticket/jail someone, try ^3F2 ^7or ^3Taser^7."
    }})
  end
end)


RegisterCommand('kick', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <Reason>"}
      })
    
    else
    
      local tgt = tonumber( table.remove(a, 1) )
      local plys = GetActivePlayers()
      
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
    
          if tonumber(a[1]) == GetPlayerServerId(PlayerId()) then
            TriggerEvent('chat:addMessage', {multiline = false,
              args = { "^1Try kicking someone other than yourself."}}
            )
    
          else TriggerServerEvent('cnr:admin_cmd_kick', tgt, table.concat(a, " "))
    
          end
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('ban', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <Reason>"}
      })

    else

      local tgt = tonumber( table.remove(a, 1) )

      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then

          TriggerServerEvent('cnr:admin_cmd_ban', tgt, table.concat(a, " "))
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tempban', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] or not a[2] or not a[3] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <Minutes> <Reason>"}
      })

    else

      local mins = tonumber( table.remove(a, 2) )
      local tgt  = tonumber( table.remove(a, 1) )
      if     mins > 900 then mins = 900
      elseif mins <  15 then mins =  15 end

      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_ban', tgt, table.concat(a, " "), mins)
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('warn', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] or not a[2] or not a[3] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <Reason>"}
      })
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
    
      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_warn', tgt, table.concat(a, " "))
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('setwanted', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <WantedLevel[0/1:Ticket/2:Mis/3:Felon/4:MW]>"}
      })
    
    else
    
      local tgt  = tonumber(a[1])
    
      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_setwanted', tgt, tonumber(a[2]))
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('freeze', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
      })
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
    
      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_freeze', tgt, true)
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('unfreeze', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
   
   if not a[1] then
     TriggerEvent('chat:addMessage', {
       templateId = 'errMsg', multiline = true,
         args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
     })
   
   else
   
     local tgt  = tonumber( table.remove(a, 1) )
   
     local plys = GetActivePlayers()
     for _,i in ipairs (plys) do
       if GetPlayerServerId(i) == tgt then
         TriggerServerEvent('cnr:admin_cmd_freeze', tgt, false)
         break -- End the loop when we find the right person
       end
     end
   end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tphere', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then

    if not a[1] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
      })
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_teleport', 0, tgt)
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tpto', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
      })
    
    else
    
      local tgt  = tonumber( table.remove(a, 1) )
    
      local plys = GetActivePlayers()
      for _,i in ipairs (plys) do
        if GetPlayerServerId(i) == tgt then
          TriggerServerEvent('cnr:admin_cmd_teleport', tgt, 0)
          break -- End the loop when we find the right person
        end
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tpsend', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <send_ID> <to_ID>"}
      })
    
    else
    
      local destPlayer  = tonumber( table.remove(a, 2) )
      local sendPlayer  = tonumber( table.remove(a, 1) )
    
      local plys = GetActivePlayers()
      local count = 0
      for _,i in ipairs (plys) do
        local sid = GetPlayerServerId(i)
        if sid == destPlayer or sid == sendPlayer then count = count + 1 end
      end
      if count > 1 then
        TriggerServerEvent('cnr:admin_cmd_teleport', destPlayer, sendPlayer)
      end
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tpmark', function()
  if CommandValid('tpmark') then
    local ped    = PlayerPedId()
    local blip   = GetFirstBlipInfoId(8) -- Retrieve GPS marker
    local coords = nil
    if DoesBlipExist(blip) then 
      coords = GetBlipInfoIdCoord(blip)
    else 
      if GetConvar("showdebugprintings", "false") == "true" then
        print("DEBUG - Blip does not exist.")
      end
    end
    
    if not coords then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"No Marker Set", "/tpmark requires a map marker to be set"}
      })
    
    else
      local coord = vector3(coords.x, coords.y, 1.05)
      TriggerServerEvent('cnr:admin_cmd_teleport', 0, 0, coord)
      
    end
  else CommandInvalid('tpmark')
  end
end)


RegisterCommand('tpcoords', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    --      x           y           z
    if not a[1] or not a[2] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <x> <y> <z(optional)>"}
      })
    
    else
      if not a[3] then a[3] = 1.05 end
      TriggerServerEvent('cnr:admin_cmd_teleport', nil, nil,
        vector3(tonumber(a[1]), tonumber(a[2]), tonumber(a[3]))
      )
      
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('tpback', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] then
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
      })
    
    else
    
      TriggerServerEvent('cnr:admin_cmd_tp_sendback', tonumber(a[1]))
      
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('announce', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <x> <y> <z>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_announce', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('mole', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <x> <y> <z>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_mole', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('asay', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <message>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_asay', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('csay', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <message>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_csay', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)

RegisterCommand('plyinfo', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <message>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_plyinfo', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)
RegisterCommand('vehinfo', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <message>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_vehinfo', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)
RegisterCommand('svinfo', function()
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <message>"}
      })
    else
      TriggerServerEvent('cnr:admin_cmd_svinfo', table.concat(a, " "))
    end
  else CommandInvalid(cmd)
  end
end)

RegisterCommand('spawncar', function(s,a,r)
  local sp  = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
    if not a[1] then 
      TriggerEvent('chat:addMessage', {
        templateId = 'errMsg', multiline = true,
          args = {"Invalid Arguments", "/"..cmd.." <model>"}
      })
    else TriggerServerEvent('cnr:admin_cmd_spawncar', a[1])
    end
  else CommandInvalid(cmd)
  end
end)

RegisterCommand('delveh', function()
  if aLevel > 1 then
    local veh = GetVehiclePedIsIn(PlayerPedId())
    if veh > 0 then TriggerServerEvent('cnr:admin_cmd_delveh')
    else
      TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
        args = { "You must be sitting in the vehicle you want to delete." }
      })
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('togglelock', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    local cVeh, cDist, myPed = 0, math.huge, PlayerPedId()
    for vehs in exports['cnrobbers']:EnumerateVehicles() do 
      local dist = #(GetEntityCoords(vehs) - GetEntityCoords(myPed))
      if dist < cDist then cVeh = vehs; cDist = dist end
    end
  
    if cVeh < 1 or cDist > 8.25 then 
      TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
          args = {"Too far away from the nearest vehicle to toggle it's lock."}
      })
    else TriggerServerEvent('cnr:admin_cmd_togglelock', cVeh)
    end
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('giveweapon', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] or not a[2] or not a[3] then 
      TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <weapon> <ammo>"}
      })
    else TriggerServerEvent('cnr:admin_cmd_giveweapon', a[1], a[2], a[3])
    end
    
  else CommandInvalid(cmd)
  end
end)
RegisterCommand('takeweapon', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] or not a[2] or not a[3] then 
      TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <weapon> <ammo(optional)>"}
      })
    else TriggerServerEvent('cnr:admin_cmd_takeweapon', a[1], a[2], a[3])
    end
    
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('stripweapons', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] then 
      TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"Invalid Arguments", "/"..cmd.." <ID#>"}
      })
    else TriggerServerEvent('cnr:admin_cmd_stripweapons', a[1])
    end
    
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('setcash', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] or not a[2] then 
      TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <+/->"}
      })
    else
      local val = tonumber(a[2])
      if val > 1000000 then val = 1000000
      elseif val < -1000000 then val = -1000000 end
      TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
        args = { "Modifying ID #"..a[1].."'s WALLET CASH by $"..val}
      })
      TriggerServerEvent('cnr:admin_cmd_setcash', tonumber(a[1]), val)
    end
    
  else CommandInvalid(cmd)
  end
end)


RegisterCommand('setbank', function(s,a,r)
  local sp = string.find(r, ' ')
  if sp then sp = sp - 1 end
  local cmd = string.sub(r, 1, sp)
  if CommandValid(cmd) then
  
    if not a[1] or not a[2] then 
      TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"Invalid Arguments", "/"..cmd.." <ID#> <+/->"}
      })
    else
      local val = tonumber(a[2])
      if val > 1000000 then val = 1000000
      elseif val < -1000000 then val = -1000000 end
      TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
        args = { "Modifying ID #"..a[1].."'s BANK BALANCE by $"..val}
      })
      TriggerServerEvent('cnr:admin_cmd_setbank', tonumber(a[1]), val)
    end
    
  else CommandInvalid(cmd)
  end
end)


AddEventHandler('cnr:admin_do_freeze', function(doFreeze, aid)
  local msg = "You have been frozen in place by Admin #"..aid
  if doFreeze then
    local offset = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 0.3)
    SetEntityCoords(PlayerPedId(), offset.x, offset.y, offset.z)
    FreezeEntityPosition(PlayerPedId(), true)
  
  else
    FreezeEntityPosition(PlayerPedId(), false)
    msg = "You have been unfrozen."
    
  end
  TriggerEvent('chat:addMessage', {templateId = 'sysMsg', args = {msg}})
end)

AddEventHandler('cnr:admin_do_spawncar', function(vModel)
  
  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the teleport request.")
    return 0
  end
  
  local mdl = GetHashKey(vModel)
  if IsModelValid(mdl) then
    RequestModel(mdl)
    while not HasModelLoaded(mdl) do Wait(10) end
    TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
      args = { "Spawning: "..vModel }
    })
    local myPos = GetEntityCoords(PlayerPedId())
    local myHeading = GetEntityHeading(PlayerPedId())
    local veh = CreateVehicle(mdl,
      myPos.x, myPos.y, myPos.z + 0.125, myHeading, true, false
    )
    
    Citizen.Wait(100)
    --TaskEnterVehicle(PlayerPedId(), veh, 10000, (-1), 8.0, 16, 1)
    DecorRegister("OwnerId", 3)
    DecorSetInt(veh, "OwnerId", GetPlayerServerId(PlayerId()))
    SetVehicleEngineOn(veh, true, true, true)
    SetVehicleDoorsLocked(veh, 1)
    SetPedIntoVehicle(PlayerPedId(), veh, (-1))
    
  else
    TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
      args = { "Couldn't find Vehicle Model: "..vModel }
    })
    
  end
  
  
  
  
  
  
end)


AddEventHandler('cnr:admin_do_delveh', function(toPlayer, coords, aid)
  
  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the vehicle deletion.")
    return 0
  end
  
  local veh = GetVehiclePedIsIn(PlayerPedId())
  if veh > 0 then 
    TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
      args = { "Deleted occupied vehicle." }
    })
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
  end
  
end)


AddEventHandler('cnr:admin_do_giveweapon', function(aid, wHash, wAmmo)
  
  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the vehicle deletion.")
    return 0
  end
  
  if not wAmmo then wAmmo = 24 end
  TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
    args = {"Admin #"..aid.." gave you "..wHash..". It will NOT save when you log off."}
  })
  GiveWeaponToPed(PlayerPedId(), GetHashKey(wHash), wAmmo, false, true)
  
end)


AddEventHandler('cnr:admin_do_togglelock', function(veh)

  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the vehicle deletion.")
    return 0
  end
  
  if veh then 
    if veh > 0 then 
      if DoesEntityExist(veh) then 
        local lockStatus = GetVehicleDoorLockStatus(veh)
        if lockStatus > 1 then 
          TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
            args = {GetDisplayNameFromVehicleModel(GetEntityModel(veh)).." ^2unlocked^7."}
          })
          SetVehicleDoorsLocked(veh, 1)
          Citizen.CreateThread(function()
            local sec = GetGameTimer() + 100
            while sec > GetGameTimer() do 
              SoundVehicleHornThisFrame(veh); Wait(0)
            end
            Citizen.Wait(100)
            sec = GetGameTimer() + 100
            while sec > GetGameTimer() do 
              SoundVehicleHornThisFrame(veh); Wait(0)
            end
          end)
        else
          TriggerEvent('chat:addMessage', {templateId = 'sysMsg',
            args = {GetDisplayNameFromVehicleModel(GetEntityModel(veh)).." ^1locked^7."}
          })
          SetVehicleDoorsLocked(veh, 2)
          Citizen.CreateThread(function()
            local sec = GetGameTimer() + 100
            while sec > GetGameTimer() do 
              SoundVehicleHornThisFrame(veh); Wait(0)
            end
          end)
        end
      else
        TriggerEvent('chat:addMessage', {templateId = 'errMsg',
          args = {"TOGGLELOCK", "Vehicle ID didn't return a Vehicle Entity"}
        })
      end
    end
  end
  
end)


local function FindZCoord(coord, ent)
  local zFound, zCoord
  local ht = 1000.0
  repeat
    Wait(10)
    ht = ht - 10.0
    SetEntityCoords(ent, coord.x, coord.y, ht)
    zFound, zCoord = GetGroundZFor_3dCoord(coord.x, coord.y, ht)
    if ht < 1.5 then break end
  until zFound
  if not zCoord then return 0.0 end
  return zCoord
end

AddEventHandler('cnr:admin_tp_coords', function(toPlayer, coords, aid)
  
  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the teleport request.")
    return 0
  end
  
  if coords then
  
    local ent = GetVehiclePedIsIn(PlayerPedId())
    if not DoesEntityExist(ent) then ent = PlayerPedId() end
  
    local lastPosition = GetEntityCoords(ent)
    local zCoord = coords.z
    if zCoord > 1.0 and zCoord < 2.0 then zCoord = FindZCoord(coords, ent) end
    if zCoord > 0.0 then 
      SetEntityCoords(ent, coords.x, coords.y, zCoord)
    else
      SetEntityCoords(ent, lastPosition)
      TriggerEvent('cnr:chatMessage', {templateId = 'sysMsg',
        args = {"Teleport destination was unsafe for arrival. Returned."}
      })
    end
    FreezeEntityPosition(ent, true)
    Citizen.Wait(2000)
    FreezeEntityPosition(ent, false)
  
  else
    local ent = PlayerPedId()
    local pedPos = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(toPlayer)))
    SetEntityCoords(ent, pedPos.x, pedPos.y, pedPos.z + 1.0)
    FreezeEntityPosition(ent, true)
    Citizen.Wait(2000)
    FreezeEntityPosition(ent, false)
  
  end
  
end)

AddEventHandler('cnr:admin_do_sendback', function(aid)
  
  -- Only allow if the event comes from the server, not the client
  if source == "" then
    print("^1CNR ERROR: ^7Unable to authorize the teleport request.")
    return 0
  end
  
  if lastPosition then 
    SetEntityCoords(PlayerPedId(), lastPosition)
    TriggerEvent('cnr:chatMessage', {templateId = 'sysMsg',
      args = {"Admin #"..aid.." sent you back to your previous position."}
    })
  end
end)


RegisterNUICallback("helpMenu", function(data, callback)
  if data.action == "action" then 
  
  -- All other actions default to exit/close
  else
    SendNUIMessage({hidehelp = true})
    SetNuiFocus(false)
  
  end
end)