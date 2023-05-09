local QBCore = exports['qb-core']:GetCoreObject()
local CratePlace = false
local crateInventory = {}
local crateObject = nil
local cratesCreated = {}
local targetsAdded = {}

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal, materialHash
end

CheckSurface = function()
    local ped = PlayerPedId()
    local pedLoc = GetEntityCoords(ped)
    local groundLoc = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, -3.0)
    local testRay = StartExpensiveSynchronousShapeTestLosProbe(pedLoc, groundLoc, 17, ped, 7)
    local _, hit, endCoords, surfaceNormal, materialHash, _ = GetShapeTestResultIncludingMaterial(testRay)
    return hit, materialHash
end

--- Object Creation START ---
--- Object Creation START ---
--- Object Creation START ---

local ObjectSelection = function()
    local inputFields = {}

    -- This adds the objects to the list
    local objectOptions = {}
    for name, label in pairs(Config.Objects) do
        objectOptions[#objectOptions + 1] = { text = label .. ' - ' .. name, value = name }
    end

    inputFields[#inputFields + 1] = {
        header = "Object",
        name = "object",
        text = "Select the object",
        type = 'select',
        options = objectOptions, -- use the options table we created
    }

    local dialog = exports['qb-input']:ShowInput({
        header = "",
        submitText = "Create",
        inputs = inputFields
    })

    if dialog then
        crateObject = dialog.object
        CreateInventory(crateObject)
    end
end

ObjectItems = function()
    local inputFields = {}


    local addedItems = {}
    for item, data in pairs(crateInventory) do
        addedItems[item] = true
    end

    -- This adds all the items from QBCore.Shared.Items
    local itemsOptions = {}
    for itemName, itemData in pairs(QBCore.Shared.Items) do
        if not addedItems[itemName] then
            itemsOptions[#itemsOptions + 1] = { text = itemData.label, value = itemName }
        end
    end

    -- This sorts the items in alphabetical order.
    table.sort(itemsOptions, function(a, b)
        if a.text == nil or b.text == nil then
            return false
        end
        return a.text < b.text
    end)

    inputFields[#inputFields + 1] = {
        header = "Item",
        name = "item",
        text = "Select item",
        type = 'select',
        options = itemsOptions,
    }
    inputFields[#inputFields + 1] = {
        header = "Amount",
        name = "minAmount",
        text = "Minimum amount",
        type = 'number',
        isRequired = true,
    }
    inputFields[#inputFields + 1] = {
        header = "Amount",
        name = "maxAmount",
        text = "Maximum amount",
        type = 'number',
        isRequired = true,
    }

    local dialog = exports['qb-input']:ShowInput({
        header = "",
        submitText = "Select",
        inputs = inputFields
    })

    if dialog then
        local minAmount = tonumber(dialog.minAmount)
        local maxAmount = tonumber(dialog.maxAmount)
        local item = dialog.item

        if maxAmount < minAmount then
            QBCore.Functions.Notify("Maximum amount can't be lower than minimum amount.", "error")
            ObjectItems()
            return
        end

        crateInventory[item] = {
            amount = {
                min = minAmount,
                max = maxAmount,
            },
        }
        CreateInventory()
    end
end

CreateInventory = function()
    local list = {}
    list[#list + 1] = {
        isMenuHeader = true,
        header = "Crate creation",
        txt = "",
    }
    list[#list + 1] = {
        header = "Crate object",
        txt = crateObject and tostring(Config.Objects[crateObject]) .. ' - ' .. crateObject or "Select object",
        params = {
            isAction = true,
            event = function()
                ObjectSelection()
            end,
        },
    }
    if crateObject then
        for item, data in pairs(crateInventory) do
            list[#list + 1] = {
                header = QBCore.Shared.Items[item].label,
                txt = 'Minimum: ' .. data.amount.min .. ' Maximum: ' .. data.amount.max,
                params = {
                    isAction = true,
                    event = function()
                        EditItem(item)
                    end,
                },
            }
        end
        list[#list + 1] = {
            header = "Add item",
            txt = 'Press here to add items to the crate!',
            params = {
                isAction = true,
                event = function()
                    ObjectItems()
                end,
            },
        }
        if next(crateInventory) ~= nil then
            list[#list + 1] = {
                header = "Confirm",
                txt = 'Press here to place the crate!',
                params = {
                    isAction = true,
                    event = function()
                        TriggerEvent('synccrate:client:PlaceCreate', crateObject)
                    end,
                },
            }
        end
    end
    exports['qb-menu']:openMenu(list)
end

EditItem = function(item)
    local list = {}
    list[#list + 1] = {
        isMenuHeader = true,
        header = 'Modify item',
        txt = "",
    }
    list[#list + 1] = {
        header = "Remove",
        txt = 'Press here to remove ' .. QBCore.Shared.Items[item].label .. ' from the crate.',
        params = {
            isAction = true,
            event = function()
                local confirmationMenu = {}
                confirmationMenu[#confirmationMenu + 1] = {
                    header = "Confirm Removal",
                    isMenuHeader = true,
                }
                confirmationMenu[#confirmationMenu + 1] = {
                    header = "Yes",
                    txt = "Are you sure you want to remove " .. QBCore.Shared.Items[item].label .. "?",
                    params = {
                        isAction = true,
                        event = function()
                            crateInventory[item] = nil
                            CreateInventory()
                        end,
                    },
                }
                confirmationMenu[#confirmationMenu + 1] = {
                    header = "Cancel",
                    params = {
                        isAction = true,
                        event = function()
                            CreateInventory()
                        end,
                    },
                }
                exports['qb-menu']:openMenu(confirmationMenu)
            end,
        },
    }
    list[#list + 1] = {
        header = "Update amount",
        txt = 'Minimum: ' .. crateInventory[item].amount.min .. ' Maximum: ' .. crateInventory[item].amount.max,
        params = {
            isAction = true,
            event = function()
                EditAmount(item)
            end,
        },
    }
    exports['qb-menu']:openMenu(list)
end

EditAmount = function(item)
    debugPrint(item)
    local inputFields = {}
    inputFields[#inputFields + 1] = {
        header = "Update amount",
        text = "Please select new values.",
    }
    inputFields[#inputFields + 1] = {
        header = "Amount",
        name = "minAmount",
        text = "Minimum amount",
        type = 'number',
        isRequired = true
    }
    inputFields[#inputFields + 1] = {
        header = "Amount",
        name = "maxAmount",
        text = "Maximum amount",
        type = 'number',
        isRequired = true

    }

    local dialog = exports['qb-input']:ShowInput({
        header = "",
        submitText = "Update",
        inputs = inputFields,
    })
    if dialog then
        local minAmount = tonumber(dialog.minAmount)
        local maxAmount = tonumber(dialog.maxAmount)

        if maxAmount < minAmount then
            QBCore.Functions.Notify("Maximum amount can't be lower than minimum amount.", "error")
            CreateInventory()
            return
        end
        crateInventory[item].amount.min = minAmount
        crateInventory[item].amount.max = maxAmount
        CreateInventory()
    end
end

--- Object Creation END ---
--- Object Creation END ---
--- Object Creation END ---

-- Check if the player has access to the crate

CrateUser = function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local citizenid = PlayerData.citizenid
    return Has_Crate_Accsess(citizenid)
end

-- Check if the player's citizen ID is in the list of allowed IDs
Has_Crate_Accsess = function(citizenid)
    if Config.HasCrateAccsess[citizenid] and Config.HasCrateAccsess[citizenid] == true then return true end
    return false
end

RemoveCrate = function(crate)
    local crateNet = NetworkGetNetworkIdFromEntity(crate)
    if cratesCreated[crateNet] then
        cratesCreated[crateNet] = nil
        debugPrint("Crate removed from list: " .. crateNet)
    else
        debugPrint("Crate not found in list: " .. crateNet)
    end
    if targetsAdded[crateNet] then
        targetsAdded[crateNet] = nil
        debugPrint("Target removed from list: " .. crateNet)
    else
        debugPrint("Target not found in list: " .. crateNet)
    end
end

DeleteCratefunction = function(crate)
    TriggerServerEvent("synccrate:server:removeTarget", ObjToNet(crate))
    SetEntityAsMissionEntity(crate, true, true)
    DeleteObject(crate)
end

-- Spawn a crate object and sync it to the server
RegisterCommand("MakeCrate", function(source, args)
    local ModelHash = args[1] -- first argument after the command is the model hash
    if ModelHash then
        TriggerServerEvent('synccrate:server:RegisterCommand', ModelHash)
    else
        CreateInventory()
    end
end)

Citizen.CreateThread(function()
    while true do
        -- loop through the cratesCreated table to find and add the target
        for crate, _ in pairs(cratesCreated) do
            -- check if the crate has already been added
            if not targetsAdded[crate] and NetworkDoesEntityExistWithNetworkId(crate) then
                debugPrint("Adding target for crate: " .. crate)
                local entity = NetworkGetEntityFromNetworkId(crate)
                -- Add target entity to QB-Target
                exports['qb-target']:AddTargetEntity(entity, {
                    options = {
                        {
                            num = 1,
                            icon = "fa-solid fa-magnifying-glass",
                            label = 'Open Crate ',
                            action = function(crate)
                                TriggerEvent('synccrate:client:open', false, crate)
                            end
                        },
                        {
                            num = 2,
                            icon = "fa-solid fa-trash-can",
                            label = 'Remove Create ',
                            canInteract = function() return CrateUser() end,
                            action = function(crate)
                                TriggerEvent('synccrate:client:Remove', false, crate)
                            end
                        }
                    },
                    distance = 2.5,
                })
                targetsAdded[crate] = true -- mark the crate as added
            end
        end
        Citizen.Wait(5000) -- wait 5 seconds before checking again
    end
end)

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/MakeCrate', 'Create an object to spawn of your choosing ', {
        { name = "Model Hash", help = "Model Hash" },
    })
end)

-- Event for placing crate
RegisterNetEvent('synccrate:client:PlaceCreate', function(ModelHash)
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return end
    if CratePlace then return end
    CratePlace = true
    RequestModel(ModelHash)
    while not HasModelLoaded(ModelHash) do Wait(0) end
    exports['qb-core']:DrawText("Press [ G ] to cancel ", 'left')
    local hit, dest, _, _, materialHash = RayCastCamera(Config.rayCastingDistance)
    local crate = CreateObject(ModelHash, dest.x, dest.y, dest.z + Config.ObjectZOffset, false, false, false)
    local heading = 0.0
    SetEntityHeading(crate, 0)
    SetEntityCollision(crate, false, false)
    SetEntityAlpha(crate, 150, true)
    local netId = ObjToNet(crate)
    SetNetworkIdExistsOnAllMachines(netId, true)
    NetworkUseHighPrecisionBlending(netId, true)
    SetNetworkIdCanMigrate(netId, false)
    local plantedcrate = false
    while not plantedcrate do
        Wait(0)
        hit, dest, _, _, materialHash = RayCastCamera(Config.rayCastingDistance)
        CurrentCoords = dest
        if hit == 1 then
            SetEntityCoords(crate, dest.x, dest.y, dest.z + Config.ObjectZOffset)
            PlaceObjectOnGroundProperly(crate)

            if IsDisabledControlJustPressed(0, 99) then                        -- scroll wheel up just pressed
                local delta = IsDisabledControlPressed(0, 36) and 0.5 or
                5                                                              -- Adjust heading change amount based on whether Ctrl is held down
                heading = heading + delta
                if heading > 360 then heading = 0.0 end
            end
            if IsDisabledControlJustPressed(0, 81) then                        -- scroll wheel down just pressed
                local delta = IsDisabledControlPressed(0, 36) and 0.5 or
                5                                                              -- Adjust heading change amount based on whether Ctrl is held down
                heading = heading - delta
                if heading < 0 then heading = 360.0 end
            end
            SetEntityHeading(crate, heading)

            if IsControlJustPressed(0, 38) then
                plantedcrate = true
                exports['qb-core']:KeyPressed(38)
                DeleteObject(crate)
                local ped = PlayerPedId()
                RequestAnimDict('amb@medic@standing@kneel@base')
                RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                while
                    not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
                    not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
                do
                    Wait(0)
                end
                TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0,
                    false, false, false)
                QBCore.Functions.Progressbar("looti", "Placing crate", math.random(1000, 2000), false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    TriggerServerEvent('synccrate:server:CreateNewCrate', dest, heading, crate, ModelHash, crateInventory)
                    plantedcrate = false
                    CratePlace = false
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end, function()
                    QBCore.Functions.Notify("_U('canceled')", 'error', 2500)
                    plantedcrate = false
                    CratePlace = false
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end)
            end
            -- [G] to cancel
            if IsControlJustPressed(0, 47) then
                exports['qb-core']:KeyPressed(47)
                plantedcrate = false
                CratePlace = false
                DeleteObject(crate)
                return
            end
        end
    end
end)

-- Event for opening the crate
RegisterNetEvent('synccrate:client:open', function(zavolano, crate)
    QBCore.Functions.Progressbar("looti", "Searching crate", math.random(1000, 2000), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        anim = "machinic_loop_mechandplayer",
        flags = 16,
    }, {}, {}, function()                        -- Done
        if crate and DoesEntityExist(crate) then -- Check for existence of crate
            exports['ps-ui']:Circle(function(success)
                if success then
                    --TriggerServerEvent('synccrate:server:CrateItem')
                    TriggerServerEvent('synccrate:server:CrateItem', ObjToNet(crate))
                    TriggerServerEvent("synccrate:server:removeTarget", ObjToNet(crate))
                    StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer",
                        1.0)
                else
                    QBCore.Functions.Notify("Someone was faster", "error")
                end
            end, 1, 15) -- NumberOfCircles, MS
            StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        else
            debugPrint("Crate not found")
            QBCore.Functions.Notify("Someone was faster", "error")
        end

        StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        QBCore.Functions.Notify("He stopped looking at it", "error")
    end)
end)

-- Event for removing the crate
RegisterNetEvent('synccrate:client:Remove', function(zavolano, crate)
    QBCore.Functions.Progressbar("looti", "Searching crate", math.random(1500, 2500), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        anim = "machinic_loop_mechandplayer",
        flags = 16,
    }, {}, {}, function()                        -- Done
        if crate and DoesEntityExist(crate) then -- Check for existence of crate
            StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
            DeleteCratefunction(crate)
        else
            debugPrint("Crate not found")
            QBCore.Functions.Notify("Someone was faster", "error")
        end

        StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        QBCore.Functions.Notify("He stopped looking at it", "error")
    end)
end)

-- Event for syncing the crate from server to clients
RegisterNetEvent('synccrate:client', function(coords, heading, crate, ModelHash, crateItems)
    -- local ModelHash = "ba_prop_battle_crates_rifles_01a"
    local crateEntity = CreateObject(ModelHash, coords.x, coords.y, coords.z + Config.ObjectZOffset, true, true, false)
    FreezeEntityPosition(crateEntity, true)
    SetEntityHeading(crateEntity, heading)
    local crateNet = ObjToNet(crateEntity)

    SetNetworkIdCanMigrate(crateNet, true)
    SetNetworkIdExistsOnAllMachines(crateNet, true)
    PlaceObjectOnGroundProperly(crateEntity)
    TriggerServerEvent("synccrate:server:showTarget", crateNet, crateItems)
end)

-- Event for removing the target marker from clients
RegisterNetEvent("synccrate:client:removeTarget", function(crate)
    RemoveCrate(crate)
    if NetworkDoesEntityExistWithNetworkId(crate) then
        local entity = NetworkGetEntityFromNetworkId(crate)
        exports['qb-target']:RemoveTargetEntity(entity, 'Open Crate ')
        debugPrint('RemoveTargetEntity')
    end
end)

RegisterNetEvent('synccrate:client:addCrates', function(crates)
    for crate, _ in pairs(crates) do
        if not cratesCreated[crate] then
            cratesCreated[crate] = true
            debugPrint("Crate added to list: " .. crate)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('synccrate:server:addCrates')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    targetsAdded = {}
    cratesCreated = {}
end)


