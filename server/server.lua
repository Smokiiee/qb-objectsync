local QBCore = exports['qb-core']:GetCoreObject()
local cratesCreated = {}
local crateItems = {}

print("Server is loaded")

RegisterNetEvent("synccrate:server:addCrates", function()
    local src = source
    TriggerClientEvent('synccrate:client:addCrates', src, cratesCreated)
end)

RegisterNetEvent("synccrate:server:showTarget", function(crate, items, difficulty)
    cratesCreated[crate] = difficulty
    --cratesCreated[crate] = true
    crateItems[crate] = items
    TriggerClientEvent('synccrate:client:addCrates', -1, cratesCreated)
    debugPrint(cratesCreated)
end)

RegisterNetEvent("synccrate:server:removeTarget", function(crate)
    cratesCreated[crate] = nil 
    TriggerClientEvent('synccrate:client:removeTarget', -1, crate)
end)

RegisterNetEvent('synccrate:server:CrateItem', function(crate)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    for key, itemData in pairs(crateItems) do
        if key == crate then
             for item, data in pairs(itemData) do
                local randomAmount = math.random(data.amount.min, data.amount.max)
                player.Functions.AddItem(item, randomAmount, false)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add", randomAmount)
                Wait(500)   
             end     
        end
    end
end)

RegisterNetEvent('synccrate:server:RegisterCommand', function(ModelHash)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    TriggerClientEvent("synccrate:client:PlaceCreate", src, ModelHash)
end)

RegisterNetEvent('synccrate:server:CreateNewCrate', function(coords, heading, crate, ModelHash, items)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end 
    TriggerClientEvent('synccrate:client', src, coords, heading, crate, ModelHash, items)
end)
