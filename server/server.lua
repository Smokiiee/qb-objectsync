local QBCore = exports['qb-core']:GetCoreObject()
local cratesCreated = {}
local crateItems = {}

print("Server is loaded")

RegisterNetEvent("qb-objectsync:server:addCrates", function()
    local src = source
    TriggerClientEvent('qb-objectsync:client:addCrates', src, cratesCreated)
end)

RegisterNetEvent("qb-objectsync:server:showTarget", function(crate, items, difficulty, money)
    cratesCreated[crate] = difficulty
    --cratesCreated[crate] = true
    crateItems[crate] = {
        items = items,
        money = money
    }
    TriggerClientEvent('qb-objectsync:client:addCrates', -1, cratesCreated)
    debugPrint(cratesCreated)
end)

RegisterNetEvent("qb-objectsync:server:removeTarget", function(crate)
    cratesCreated[crate] = nil
    TriggerClientEvent('qb-objectsync:client:removeTarget', -1, crate)
end)

RegisterNetEvent('qb-objectsync:server:CrateItem', function(crate)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    for key, itemData in pairs(crateItems) do
        if key == crate then
            for item, data in pairs(itemData.items) do
                local randomAmount = math.random(data.amount.min, data.amount.max)
                player.Functions.AddItem(item, randomAmount, false)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add", randomAmount)
                Wait(500)
            end
            if itemData.money.min >= 0 then
                local randomAmount = math.random(itemData.money.min, itemData.money.max)
                player.Functions.AddMoney('cash', randomAmount)
                TriggerClientEvent("QBCore:Notify", src, "You got " .. randomAmount .. " $", "success")
            end
        end
    end
end)

RegisterNetEvent('qb-objectsync:server:RegisterCommand', function(ModelHash)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    TriggerClientEvent("qb-objectsync:client:PlaceCreate", src, ModelHash)
end)
