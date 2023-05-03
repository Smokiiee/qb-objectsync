local QBCore = exports['qb-core']:GetCoreObject()
local CratePlace = false

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

function CheckSurface()
    local ped = PlayerPedId()
    local pedLoc = GetEntityCoords(ped)
    local groundLoc = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, -3.0)
    local testRay = StartExpensiveSynchronousShapeTestLosProbe(pedLoc, groundLoc, 17, ped, 7)
    local _, hit, endCoords, surfaceNormal, materialHash, _ = GetShapeTestResultIncludingMaterial(testRay)
    return hit, materialHash
end

-- Spawn a crate object and sync it to the server
RegisterCommand("cratemrdka", function()
	TriggerServerEvent('synccrate:server:RegisterCommand')
end)

RegisterNetEvent('synccrate:client:PlaceCreate', function()
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return end
    if CratePlace then return end
    CratePlace = true
    local ModelHash = "ba_prop_battle_crates_rifles_01a"
    -- local properMaterial = 1333033863
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
	NetworkSetNetworkIdDynamic(netId, true)
	SetNetworkIdCanMigrate(netId, false)

    local plantedcrate = false
    while not plantedcrate do
        Wait(0)
        hit, dest, _, _, materialHash = RayCastCamera(Config.rayCastingDistance)
        CurrentCoords = dest
        if hit == 1 then
            SetEntityCoords(crate, dest.x, dest.y, dest.z + Config.ObjectZOffset)
            PlaceObjectOnGroundProperly_2(crate)

            if IsDisabledControlJustPressed(0, 99) then
                    heading = heading + 5
                    if heading > 360 then heading = 0.0 end
                end    
                if IsDisabledControlJustPressed(0, 81) then
                    heading = heading - 5
                    if heading < 0 then heading = 360.0 end
                end
                SetEntityHeading(crate, heading)
            -- if Config.MaterialHashes[materialHash] then 
                -- print("yes")
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
                    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                    QBCore.Functions.Progressbar("looti", "Placing crate", math.random(1000, 2000), false, true, {
                        disableMovement = true,
                        disableCarMovement = false,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function()
						TriggerServerEvent('synccrate:server:CreateNewCrate', dest, heading, crate)
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
            -- end
                        
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


-- Check if the player has access to the crate
function CrateUser()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local citizenid = PlayerData.citizenid
    return Has_Crate_Accsess(citizenid)
end

-- Check if the player's citizen ID is in the list of allowed IDs
function Has_Crate_Accsess( citizenid )
    if Config.HasCrateAccsess[citizenid] and Config.HasCrateAccsess[citizenid] == true then return true end
    return false
end

-- Event handler for syncing the crate from server to clients
RegisterNetEvent('synccrate:client')
AddEventHandler('synccrate:client', function(coords, heading, crate)
    local ModelHash = "ba_prop_battle_crates_rifles_01a"
    local crateEntity = CreateObjectNoOffset(ModelHash, coords.x, coords.y, coords.z + Config.ObjectZOffset, true, true, false)
    FreezeEntityPosition(crateEntity, true)  
    SetEntityHeading(crateEntity, heading)   
    local crateNet = ObjToNet(crateEntity)
    TriggerServerEvent("synccrate:server:showTarget", crateNet)
end)

-- Event handler for showing the target marker on clients
RegisterNetEvent("synccrate:client:showTarget")
AddEventHandler("synccrate:client:showTarget", function(crate)
	exports['qb-target']:AddTargetEntity(crate, {
		options = {
			{           
				num = 1,
				type = 'client',
				icon = "fa-solid fa-magnifying-glass",
				label = 'Open Crate ',
				action = function(crate)
					TriggerEvent('jmy:crate:open', false, crate)
				end     
			},
			{           
				num = 2,
				type = 'client',
				icon = "fa-solid fa-magnifying-glass",
				label = 'Remove Create ',
				canInteract = function() return CrateUser() end, -- Only show this option if the player has access
				action = function(crate)
					TriggerEvent('jmy:crate:Remove', false, crate)
				end     
			}
		},
		distance = 2.5,
	})
end)

-- Event handler for removing the target marker from clients
RegisterNetEvent("synccrate:client:removeTarget")
AddEventHandler("synccrate:client:removeTarget", function(crate)
	if NetworkDoesEntityExistWithNetworkId(crate) then
		exports['qb-target']:RemoveTargetEntity(crate, 'Open Crate ')				
	end
end)

-- Event handler for opening the crate
RegisterNetEvent('jmy:crate:open')
AddEventHandler('jmy:crate:open', function(zavolano, crate)
	QBCore.Functions.Progressbar("looti", "Searching crate", math.random(1000, 2000), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
		animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
		anim = "machinic_loop_mechandplayer",
		flags = 16,
	}, {}, {}, function() -- Done
        if crate and DoesEntityExist(crate) then -- Check for existence of crate
			exports['ps-ui']:Circle(function(success) 
				if success then
					TriggerServerEvent('synccrate:server:CrateItem')
					TriggerServerEvent("synccrate:server:removeTarget", ObjToNet(crate))
					StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
				else
					QBCore.Functions.Notify("Someone was faster", "error")
				end
			end, 10, 15) -- NumberOfCircles, MS
			StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
        else 
            print("Crate not found")
			QBCore.Functions.Notify("Someone was faster", "error")
        end	 

		StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
	end, function() -- Cancel
		StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
		QBCore.Functions.Notify("He stopped looking at it", "error")
	end)
end)

-- Event handler for removing the crate
RegisterNetEvent('jmy:crate:Remove')
AddEventHandler('jmy:crate:Remove', function(zavolano, crate)
	QBCore.Functions.Progressbar("looti", "Searching crate", math.random(1500, 2500), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
		animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
		anim = "machinic_loop_mechandplayer",
		flags = 16,
	}, {}, {}, function() -- Done
        if crate and DoesEntityExist(crate) then -- Check for existence of crate
			StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)			
			DeleteCratefunction(crate)
        else 
            print("Crate not found")
			QBCore.Functions.Notify("Someone was faster", "error")
        end	 

		StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
	end, function() -- Cancel
		StopAnimTask(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
		QBCore.Functions.Notify("He stopped looking at it", "error")
	end)
end)


function DeleteCratefunction(crate)
    local crateNet = ObjToNet(crate)
    TriggerServerEvent('deleteCrate', crateNet)
    SetEntityAsMissionEntity(crate, true, true)
    DeleteObject(crate)
end