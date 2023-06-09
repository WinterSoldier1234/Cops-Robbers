
RegisterServerEvent('cnr:inventory_update')
RegisterServerEvent('cnr:inventory_action')
RegisterServerEvent('cnr:inventory_pickup')
RegisterServerEvent('cnr:death_insured')
RegisterServerEvent('cnr:client_loaded')

local cprint = function(msg) exports['cnrobbers']:ConsolePrint(msg) end



AddEventHandler('cnr:death_insured', function(client, isInsured)
  if isInsured < 1 then 
    UpdateInventory(client)
  end
end)

AddEventHandler('cnr:death_insured', function(client, retValue)
  if retValue == 0 then
    TriggerClientEvent('cnr:inventory_receive', client, {})
  end
end)


--- EXPORT: ItemAdd()
-- Adds an item with specified quantity to the inventory
-- @param client The server ID of the client to affect. If nil, returns 0
-- @param itemInfo Table with info (see `__resource.lua`)
-- @param quantity The amount to add. If nil, adds 1
-- @return Returns true if function was successful, false on failure
function ItemAdd(client, itemInfo, quantity)
  if not client then
    cprint("^1[INVENTORY] ^7No Server ID given to ItemAdd() in sv_inventory.lua")
    return false
  end

  if not itemInfo then
    cprint("^1[INVENTORY] ^7No item table given to ItemAdd() in sv_inventory.lua")
    return false
  end

  -- Minimum itemInfo requirement
  if not itemInfo['name'] then
    cprint("^1[INVENTORY] ^7No item game name given to ItemAdd() in sv_inventory.lua")
    return false
  end

  if not itemInfo['consume'] then itemInfo['consume'] = 0 end
  if not itemInfo['title'] then itemInfo['title'] = itemInfo['name'] end
  if not itemInfo['model'] then itemInfo['model'] = "prop_cs_package_01" end
  if not itemInfo['img'] then itemInfo['img'] = "missing" end
  if not itemInfo['resname'] then itemInfo['resname'] = "cnr_inventory" end
  if not itemInfo['stack'] then itemInfo['stack'] = 0 else itemInfo['stack'] = 1 end
  if not quantity then quantity = 1 end
  local response = MySQL.scalar.await(
    "SELECT InvAdd(@uid, @iname, @ititle, @eat, @mdl, @imgsrc, @qty, @rname, @stk)",
    {
      ['uid']    = exports['cnrobbers']:UniqueId(client),
      ['iname']  = itemInfo['name'],
      ['ititle'] = itemInfo['title'],
      ['eat']    = itemInfo['consume'],
      ['mdl']    = itemInfo['model'],
      ['imgsrc'] = itemInfo['img'],
      ['qty']    = quantity,
      ['rname']  = itemInfo['resname'],
      ['stk']    = itemInfo['stack']
    }
  )

  if not response then
    cprint(
      "^1[INVENTORY] "..
      "^7MySQL indicated an error when running ItemAdd() in sv_inventory.lua"
    )
    return false
  else UpdateInventory(client)
  end
  return response
end


--- EXPORT: ItemRemove()
-- Removes an item with specified quantity
-- @param client The server ID of the client to affect
-- @param itemInfo Table with the terms to search for (see `__resource.lua`)
-- @param quantity The amount to remove. If nil, removes the entire item
-- @return Returns true if function was successful, false on failure
function ItemRemove(client, itemInfo, quantity)
  if not client then
    cprint("^1[INVENTORY] ^7No Server ID given to ItemRemove() in sv_inventory.lua")
    return false
  end

  if not itemInfo then
    cprint("^1[INVENTORY] ^7No item table given to ItemRemove() in sv_inventory.lua")
    return false
  end

  -- Minimum itemInfo requirement
  if not itemInfo['name'] then
    cprint("^1[INVENTORY] ^7No item game name given to ItemRemove() in sv_inventory.lua")
    return false
  end

  if not itemInfo['id'] then itemInfo['id'] = 0 end
  local response = MySQL.scalar.await(
    "SELECT InvDelete(@uid, @iid, @qty)",
    {
      ['uid'] = exports['cnrobbers']:UniqueId(client),
      ['iid'] = itemInfo['id'],
      ['qty'] = quantity
    }
  )

  if not response then
    cprint(
      "^1[INVENTORY] "..
      "^7MySQL indicated an error when running ItemRemove() in sv_inventory.lua"
    )
    return false
  else UpdateInventory(client)
  end
  return response
end


--- EXPORT: GetInventory()
-- Returns the player's inventory to the calling script
-- It's better to call this as needed, instead of storing all this
-- damned info in a global variable. A LOT less overhead.
-- @param client The server ID of the client to affect. If nil returns empty tbl
-- @return Returns table of inventory items.
function GetInventory(client)

  if not client then return {} end
  local uid = exports['cnrobbers']:UniqueId(client)
  
  if uid > 0 then
    return (
      MySQL.update.await(
        "SELECT * FROM inventories WHERE character_id = @u",
        {['u'] = uid}
      )
    )

  else return {}
  end

end


--- EXPORT: GetWeight()
-- Returns the total weight of the player's inventory
-- @param client The server ID of the client to affect. If nil, returns 0.
-- @return Returns total weight of inventory
function GetWeight(client)
  if not client then return 0 end
  local uid = exports['cnrobbers']:UniqueId(client)
  local weight = MySQL.scalar.await(
    "SELECT SUM(weight * quantity) FROM inventories WHERE character_id = @u",
    {['u'] = uid}
  )
  return weight
end


--- EXPORT: UpdateInventory()
-- Forces an inventory update to the given client
-- @param client The server ID of whose inventory to send the update to
function UpdateInventory(client)

  if not client then return 0 end
  local uid = exports['cnrobbers']:UniqueId(client)
  
  MySQL.update(
    "SELECT * FROM inventories WHERE character_id = @u",
    {['u'] = uid},
    function(invStuff)
      TriggerClientEvent('cnr:inventory_receive', client, invStuff)
    end
  )
  
end


AddEventHandler('cnr:inventory_pickup', function(itemInfo, quantity)
  local client = source
  local uid = exports['cnrobbers']:UniqueId(client)
  
  if not quantity then quantity = 1 end
  if not itemInfo['title'] then itemInfo['title'] = itemInfo['name'] end
  if not itemInfo['consume'] then itemInfo['consume'] = 0
  else itemInfo['consume'] = 1 end
  
  ItemAdd(client, itemInfo, quantity)
  
end)


AddEventHandler('cnr:inventory_action', function(action, idNumber, quantity, coords)
  local client = source
  local uid = exports['cnrobbers']:UniqueId(client)
  
  local itemInfo = MySQL.update.await(
    "SELECT * FROM inventories WHERE id = @n",
    {['n'] = idNumber}
  )
  
  if itemInfo then
    if itemInfo[1] then
      if itemInfo[1]['name'] then 
        
        if not itemInfo[1]['stacks'] then
          quantity = itemInfo[1]['quantity']
        end
        if action == 1 then
          if itemInfo[1]['consume'] then
            quantity = 1
            TriggerEvent('cnr:consume_sv', client, itemInfo[1]['name'])
            TriggerClientEvent('cnr:consume', client, itemInfo[1]['name'])
          else
            TriggerClientEvent('chat:addMessage', client, {templateId = 'sysMsg',
              args = {"That item cannot be used from the inventory."}
            });
            return 0 -- stop on failure
          end
          UpdateInventory(client)
        end
        
        local didPass = ItemRemove(client, itemInfo[1], quantity)
        if not didPass then 
          TriggerClientEvent('chat:addMessage', client, {templateId = 'errMsg',
            args = {
              "Item Action Failed",
              "The database encountered an error while running your request."..
              "\nContact Administration."
            }
          });
        else
          if action == 0 then -- drop item
            TriggerClientEvent('cnr:inventory_drop', (-1),
              itemInfo[1], quantity, coords
            )
          end
          -- Update player's inventory on success
          UpdateInventory(client)
        end
        
      end -- iteminfo name
    end -- iteminfo 1
  end -- iteminfo
  
end)


-- Send player their inventory upon loading in
AddEventHandler('cnr:client_loaded', function()
  local client = source
  Citizen.Wait(3000)
  UpdateInventory(client)
end)


-- Dispatch inventories on resource restart
Citizen.CreateThread(function()
  Citizen.Wait(1000)
  local plys = GetPlayers()
  for _,i in ipairs(plys) do 
    UpdateInventory(i)
  end
end)