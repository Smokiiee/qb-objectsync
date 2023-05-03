local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('synccrate')
AddEventHandler('synccrate', function(crate)
    print("Server Side")
    TriggerClientEvent('synccrate:client', -1, crate)
end)

RegisterNetEvent("synccrate:server:showTarget", function(crate)
    TriggerClientEvent('synccrate:client:showTarget', -1, crate)
end)

RegisterNetEvent("synccrate:server:removeTarget", function(crate)
    TriggerClientEvent('synccrate:client:removeTarget', -1, crate)
end)

RegisterNetEvent('synccrate:server:CrateItem'', function(type)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local bags = math.random(2, 4)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weapon_combatmg'], "add", bags)
    player.Functions.AddItem('weapon_combatmg', bags, false)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['mg_ammo'], "add", bags)
    player.Functions.AddItem('mg_ammo', bags, false)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weapon_assaultrifle'], "add", bags)
    player.Functions.AddItem('weapon_assaultrifle', bags, false)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['rifle_ammo'], "add", bags)
    player.Functions.AddItem('rifle_ammo', bags, false)
end)

RegisterNetEvent('synccrate:server:RegisterCommand', function()
    local src = source
    TriggerClientEvent("synccrate:client:PlaceCreate", source)
end)


RegisterNetEvent('synccrate:server:CreateNewCrate', function(coords, heading, crate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end    
    -- print("CreateNewPlant",coords, crate)
    TriggerClientEvent('synccrate:client', -1, coords, heading, crate)
end)
