
RegisterNetEvent('cnr:changelog')
RegisterNetEvent('cnr:create_reload')
RegisterNetEvent('cnr:create_character')
RegisterNetEvent('cnr:create_ready')
RegisterNetEvent('cnr:create_finished')

local connected = false
local spawning  = false
local firstSpawn = true
local creator = {
  pos = vector3(-1530.88, -900.61, 10.3), h = 180.0
}

-- Establish server connection
-- No other script should function until after 'cnr:init' is received.
CreateThread(function()
  while not NetworkIsPlayerActive(PlayerId()) do Wait(1) end
  NetworkSetVoiceActive(true)
  StartAudioScene('MP_LEADERBOARD_SCENE')
  SwitchOutPlayer(PlayerPedId(), 32, 1)
  while GetPlayerSwitchState() ~= 5 do
    HideHudAndRadarThisFrame()
    Wait(0)
  end
  --DoScreenFadeOut(0)
  --while not IsScreenFadedOut() do Wait(1) end
  while not CNR.ready do TriggerServerEvent('cnr:init'); Wait(5000) end
end)


function spawnPlayer(spawnInfo, callback)

  if spawning then return false end
  firstSpawn  = false
  spawning    = true
  
  FreezeEntityPosition(PlayerPedId(), true)
  if not GetIsLoadingScreenActive() then 
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end
  end
  
  local x,y,z,h = 0.0, 0.0, 1500.0, (math.random(359) + 0.1)
  if spawnInfo.x then 
    if GetConvar("showdebugprintings", "false") == "true" then
      print("DEBUG - Using provided spawn position.")
    end
    x = spawnInfo.x
    y = spawnInfo.y
    z = spawnInfo.z
  else
    if GetConvar("showdebugprintings", "false") == "true" then
      print("DEBUG - Calculating Z position.")
    end
    local foundZ, groundZ
    while not foundZ do
      foundZ, groundZ = GetGroundZFor_3dCoord(x, y, z)
      Wait(1)
    end
  end
  
  if spawnInfo.h then h = spawnInfo.h end
  
  spawnInfo.pos = vector3(x,y,z)
  --CNR.PassiveMode(true)
  --RequestCollisionAtCoord(x,y,z)
  SetEntityCoordsNoOffset(PlayerPedId(),x,y,z,false,false,false,true)
  NetworkResurrectLocalPlayer(x,y,z,h,true,true,false)
  SetEntityHeading(PlayerPedId(), h)
  
  local hashModel = GetHashKey(spawnInfo.model)
  RequestModel(hashModel)
  while not HasModelLoaded(hashModel) do Wait(1) end
  SetPlayerModel(PlayerId(), spawnInfo.model)
  SetModelAsNoLongerNeeded(hashModel)
  
  ClearPedTasksImmediately(PlayerPedId())
  StopEntityFire(PlayerPedId())
  ClearPedEnvDirt(PlayerPedId())
  ClearPedBloodDamage(PlayerPedId())
  ClearPedWetness(PlayerPedId())
  FreezeEntityPosition(PlayerPedId(), false)
  
  ResetPedMovementClipset(PlayerPedId(), 0.0)
  
  if GetIsLoadingScreenActive() then
    ShutdownLoadingScreen()
  end
  
  if IsScreenFadedOut() then
		DoScreenFadeIn(2000)
		while not IsScreenFadedIn() do
			Citizen.Wait(0)
		end
	end

	TriggerEvent('playerSpawned')
  spawning = false
  
  if callback then callback() end
  
end


--- EVENT: create_finished
-- Called when the player has finished creating their player model
AddEventHandler('cnr:create_finished', function()
  SendNUIMessage({hideallmenus = true})
  SetNuiFocus(false)
  SetCamActive(cam, false)
  RenderScriptCams(false, true, 500, true, true)
  cam = nil
  TriggerEvent('cnr:new_player_ready')
  TriggerEvent('cnr:loaded')
  TriggerServerEvent('cnr:client_loaded')
  Wait(400)
  if IsScreenFadedOut() then DoScreenFadeIn(1000) end
  ReportPosition(true)
end)


--- EVENT: create_reload
-- Called when player has an existing character to reload
AddEventHandler('cnr:create_reload', function(myChar)

  CNR.ready = true
  ShutdownLoadingScreen()
  StopAudioScene('MP_LEADERBOARD_SCENE')
  
	spawnPlayer({
		x = myChar['x'], y = myChar['y'], z = myChar['z'],
    model = myChar['model']
	}, function()
    ReportPosition(true)
  end)
  
  SwitchInPlayer(PlayerPedId())
  while GetPlayerSwitchState() ~= 12 do
    HideHudAndRadarThisFrame()
    Wait(0)
  end
  
  --CNR.PassiveMode(true)
  TriggerEvent('cnr:loaded')
  TriggerServerEvent('cnr:client_loaded')
  
end)


--- EVENT: create_session
-- Called if the player hasn't played here before, and needs a character
AddEventHandler('cnr:create_character', function()

  CNR.ready = true
  ShutdownLoadingScreen()
  StopAudioScene('MP_LEADERBOARD_SCENE')
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Spawning at Creator.")
    end

  local pmdl = pedModels[math.random(#pedModels)]

  -- This should be changed later to use a psuedo-ped, not the actual player
	spawnPlayer({
		x     = creator.pos.x,
		y     = creator.pos.y,
		z     = creator.pos.z,
    h     = 180.0,
		model = pmdl
	})

  while IsPlayerDead(PlayerId()) do Wait(100) end
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Player Alive")
    end
  while GetEntityModel(PlayerPedId()) ~= GetHashKey(pmdl) do
    Wait(10)
  end
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Player Model Ready")
    end
  
  local offset = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.9, 1.25, 0.6)
  if not DoesCamExist(cam) then cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true) end
  
  SetCamParams(cam, offset.x, offset.y, offset.z, -10.0, 0.0, 322.0, 50.0)
  RenderScriptCams(true, true, 500, true, true)
  SetCamActive(cam, true)
  if IsScreenFadedOut() then DoScreenFadeIn(1000) end
  SendNUIMessage({show = 'ped-select'})
  
  SwitchInPlayer(PlayerPedId())
  while GetPlayerSwitchState() ~= 12 do
    HideHudAndRadarThisFrame()
    Wait(0)
  end
  
  SendNUIMessage({hide = 'motd_bkgd'})
  SetNuiFocus(true, true)
  
  TriggerServerEvent('cnr:creating')
  
  if GetConvar("showdebugprintings", "false") == "true" then
    print("DEBUG - Creator Ready")
    end
end)


--- NUI: playGame
-- Called when the player clicks "PLAY" at the welcome screen
RegisterNUICallback("playGame", function(data, cb)
  SendNUIMessage({hide = 'motd_bkgd'})
  DoScreenFadeOut(300)
  Citizen.Wait(500)
  SetCamActive(cam, false)
  RenderScriptCams(false, true, 500, true, true)
  cam = nil
  TriggerServerEvent('cnr:create_session')
end)


-- DEBUG - Model Selection
-- This is the temporary ped model selection.
-- We will make the move to the freemode models once we have more time, but
-- this works for the time being.
local pm = 1
function ModelChoice(data, cb)
  local oldPM = pm
  if coolDown then
    TriggerEvent('chatMessage', "^8You're clicking too fast! Please Wait.")
    return 0
  end

  coolDown = true

  if data == "random" then
    oldPM = pm
    pm = math.random(#pedModels)
    while not pedModels[pm] do
      pm = math.random(#pedModels)
      Wait(10)
    end

  elseif data == "last" then
    pm = pm - 1
    if pm < 1 then pm = #pedModels end

  elseif data == "next" then
    pm = pm + 1
    if pm > #pedModels then pm = 1 end

  else
    TriggerServerEvent('cnr:create_save_character', pedModels[pm])
    coolDown = false
    return 0

  end

  local newHash = GetHashKey(pedModels[pm])
  local timeOut = GetGameTimer() + 4000
  RequestModel(newHash)
  while not HasModelLoaded(newHash) do
    if GetGameTimer() > timeOut then
      TriggerEvent('chatMessage', "^1Failed to load model ["..pedModels[pm]..
        "].\nModel was removed from the list. Please try again."
      )
      table.remove(pedModels, pm)
      pm       = oldPM
      coolDown = false
      return 0
    end
    Wait(10)
  end

  SetPlayerModel(PlayerId(), newHash)
  SetModelAsNoLongerNeeded(newHash)
  coolDown = false
  
end
RegisterNUICallback("modelPick", ModelChoice)