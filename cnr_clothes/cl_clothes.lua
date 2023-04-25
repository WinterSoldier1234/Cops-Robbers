
-- client clothes
local oldModel = 0

RegisterCommand('setskin', function(s, args, r)
  local mdl = GetHashKey("mp_m_freemode_01")
  if not args then args = {} end
  if args[1] then mdl = GetHashKey("mp_f_freemode_01")
  end
  
  RequestModel(mdl)
  while not HasModelLoaded(mdl) do Wait(10) end
  oldModel = GetEntityModel(PlayerPedId())
  SetPlayerModel(PlayerId(), (mdl))
  SetPedDefaultComponentVariation(PlayerPedId())
  
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Set model to freemode model (1:Female / nil:Male)")
  end
end)

RegisterCommand('reloadmodel', function()
  RequestModel(oldModel)
  while not HasModelLoaded(oldModel) do Wait(10) end
  SetPlayerModel(oldModel)
  SetPedDefaultComponentVariation(PlayerPedId())
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Reloaded previous model")
  end
end)

RegisterCommand('cset', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] or not args[2] or not args[3] then args = {[1] = 0, [2] = 0, [3] = 0} end
  SetPedComponentVariation(ped, tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), 2)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - SetPedComponentVariation("..ped..", "..args[1]..", "..args[2]..", "..args[3]..")")
  end
end)

RegisterCommand('pset', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] or not args[2] or not args[3] then args = {[1] = 0, [2] = 0, [3] = 0} end
  SetPedPropIndex(ped, tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), true)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - SetPedPropIndex("..ped..", "..args[1]..", "..args[2]..", "..args[3]..")")
  end
end)

RegisterCommand('nextitem', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] then args = {[1] = 0} end
  local slot = tonumber(args[1])
  local draw = GetPedDrawableVariation(ped, slot) + 1
  SetPedComponentVariation(ped, slot, draw, 0, true)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - NEXT ITEM - SetPedPropIndex(ped, "..slot..", "..draw..", 0, true)")
  end
end)

RegisterCommand('lastitem', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] then args = {[1] = 0} end
  local slot = tonumber(args[1])
  local draw  = GetPedDrawableVariation(ped, slot) - 1
  SetPedComponentVariation(ped, slot, draw, 0, true)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - PREV ITEM - SetPedPropIndex(ped, "..slot..", "..draw..", 0, true)")
  end
end)

RegisterCommand('nextprop', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] then args = {[1] = 0} end
  local slot = tonumber(args[1])
  local pidx = GetPedPropIndex(ped, slot) + 1
  SetPedPropIndex(ped, slot, pidx, 0, true)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - NEXT ITEM - SetPedPropIndex(ped, "..slot..", "..pidx..", 0, true)")
  end
end)

RegisterCommand('lastprop', function(s, args, r)
  local ped = PlayerPedId()
  if not args then args = {} end
  if not args[1] then args = {[1] = 0} end
  local slot = tonumber(args[1])
  local pidx = GetPedPropIndex(ped, slot) - 1
  SetPedPropIndex(ped, slot, pidx, 0, true)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - PREV ITEM - SetPedPropIndex(ped, "..slot..", "..pidx..", 0, true)")
  end
end)

RegisterCommand('clearprops', function(s, args, r)
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - ")
  end
end)


