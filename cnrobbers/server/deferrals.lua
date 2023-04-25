-- Connection Verification
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)

  local client = source
	deferrals.defer()
	deferrals.update("Connecting to: 5M Cops n' Robbers")
  
  local ids = GetPlayerInformation(client)
  
  -- Create new player account/ban check prior to them even connecting to the game
  local uid = MySQL.execute.await(
    "SELECT new_player (@steam, @social, @fivem, @discord, @ip, @user)", ids
  )
  if #uid > 0 then
    deferrals.update("Evaluating your credentials...")
    ConsolePrint("^3DEFERRALS: ^7Validating "..playerName.."'s access rights.")
    local banInfo = MySQL.query.await(
      "SELECT perms,bantime,reason FROM players WHERE idUnique = @uid",
      {['uid'] = uid}
    )
    -- if bantime is set, it's a temp ban
    if banInfo['bantime'] and banInfo['bantime'] > 0 then

      local nowDate     = os.time()
      local banRelease  = banInfo["bantime"]/1000

      -- If tempban time has expired, release the ban
      if nowDate > banRelease then
        MySQL.query(
          "UPDATE players SET perms = 1, bantime = NULL, reason = NULL "..
          "WHERE id = @uid", {['uid'] = uid}
        )
        deferrals.update("Tempban expired. Unbanning your account. Welcome back!")
        ConsolePrint(playerName.." was automatically unbanned (tempban expired).")
        Citizen.Wait(2000)
      else
        deferrals.done("You are banned until "..(os.date("%X %x", banRelease))..
          " (GMT -8). Reason: "..banInfo['reason']
        )
        ConsolePrint(playerName.." disconnected - Permabanned.")
        return false
      end

    end

    -- Player is Banned
    if banInfo['perms'] and banInfo['perms'] < 1 then
      deferrals.done("You have been permanently banned from this server.")
      ConsolePrint(playerName.." disconnected. Permabanned: "..banInfo['reason'])
      return false
    -- Player is not banned
    else
      deferrals.update("Connection Authorized. Welcome to 5M Cops n' Robbers!")
      Citizen.Wait(100)
      ConsolePrint(playerName.." is connecting!")
    end
    
  else
    deferrals.done("A FiveM, Steam, or Social Club account"..
      " is required to play on this server."
    )
    ConsolePrint(playerName.." disconnected. No validation methods found.")
    return false
  end
  deferrals.done()
end)
