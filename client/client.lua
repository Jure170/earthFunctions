local submitFormRegistered = false
local contextMenuItems = {}
local cam = nil

local currentInputConfig = nil

function InputMenuOpen(config, callback)
    currentInputConfig = config
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(1)
    SendNUIMessage({
        action = 'open',
        config = config
    })
    poaljiMiDole = callback
end

function GetCurrentInputConfig()
    return currentInputConfig
end


function ContextMenuOpen(items)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCon',
    })
    contextMenuItems = items
    SendNUIMessage({
        action = 'updateContextMenu',
        items = contextMenuItems
    })
end

RegisterNUICallback('submitForm', function(data, cb)
    local allFilled = true

    local currentConfig = GetCurrentInputConfig()

    for _, input in ipairs(currentConfig.inputs) do
        local value = data[input.id]
        if input.required and (value == "" or value == nil) then
            allFilled = false
        end
    end

    if allFilled then
        cb('ok')
        if poaljiMiDole then
            poaljiMiDole(true, data)
        end
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(0)
        SendNUIMessage({action = "close"})
    else
        cb('error')
        if poaljiMiDole then
            poaljiMiDole(false, data)
        end
    end
end)


RegisterNUICallback('closeMenu', function(data, cb)
    if cam then
        SendNUIMessage({
            action = "hidePin"
        })
        local startCoords = GetCamCoord(cam)
        local playerPed = PlayerPedId()
        local endCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.3, 1.0)

        local startTime = GetGameTimer()
        local duration = 1000
        while GetGameTimer() - startTime < duration do
            local progress = (GetGameTimer() - startTime) / duration
            local newX = startCoords.x + (endCoords.x - startCoords.x) * progress
            local newY = startCoords.y + (endCoords.y - startCoords.y) * progress
            local newZ = startCoords.z + (endCoords.z - startCoords.z) * progress
            SetCamCoord(cam, newX, newY, newZ)
            Wait(10)
        end

        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0)
    SendNUIMessage({action = "close"})
    SendNUIMessage({action = "closeCon"})
    TriggerEvent("earthOutfits:closePed")
end)


RegisterNetEvent("earth:openInput", function(config, callback)
    InputMenuOpen(config, callback)
end)

RegisterNetEvent("earth:openContextMenu", function(items)
    ContextMenuOpen(items)
end)

RegisterCommand("earthInput", function()
    TriggerEvent('earth:openInput', {
        title = 'Primjer Naslova',
        inputs = {
            {type = 'color', id = 'color1', label = 'Vehicle Colors', default = '#0d1116'},
            {type = 'text', id = 'tekstic', label = 'Ovo je kurcina'},
        }
    }, function(success, inputData)
        if success then
        end
    end)
end)
RegisterNUICallback('triggerEvent', function(data, cb)
    local eventName = data.eventName
    local args = data.args or {}

    if eventName then
        if type(args) == "table" and next(args) ~= nil then
            TriggerEvent(eventName, table.unpack(args))
        else
            TriggerEvent(eventName)
        end
    end

    cb('ok')
end)

RegisterCommand("earthContext", function()
    local items = {
        title = "Title Tile",
        menuItems = {
            {label = 'Vehicles', description = 'Edit Vehicles', icon = 'fa-solid fa-car', color = '#FF5733', event = 'vehiclesEvent'},
            {label = 'Bossmenu', description = 'Edit Bossmenu', icon = 'fa-solid fa-briefcase', color = '#33FF57', event = 'bossmenuEvent'},
            {label = 'Outfits', description = 'Edit Outfits', icon = 'fa-solid fa-tshirt', color = '#3357FF', event = 'outfitsEvent'},
            {label = 'Stash', description = 'Edit Stash', icon = 'fa-solid fa-box', color = '#FF33A1', event = 'stashEvent'},
            {label = 'VIP Status', description = 'VIP Status', icon = 'fa-solid fa-star', color = '#F1C40F', event = 'vipStatusEvent'}
        }
    }

    TriggerEvent("earth:openContextMenu", items)
end)



RegisterNetEvent("earthFunctions:createPin")
AddEventHandler("earthFunctions:createPin", function(propName, pinCode, callback)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    local targetPos = playerPos + forwardVector * 2.0  
    local closestProp = GetClosestObjectOfType(targetPos, 2.0, GetHashKey(propName), false, false, false)
    if closestProp ~= 0 then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local startCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.5, 1.0)
        local endCoords = GetOffsetFromEntityInWorldCoords(closestProp, 0.0, -0.5, 1.7)

        SetCamCoord(cam, startCoords.x, startCoords.y, startCoords.z)
        PointCamAtEntity(cam, closestProp, 0.0, 0.0, 0.0, true)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 2000, true, true)
        Wait(2000)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "showPin",
            pin = pinCode
        })
        RegisterNUICallback("checkPin", function(data, cb)
            local success = data.success
            if callback then
                callback(success)
            end
            if success then
                local startCoords = GetCamCoord(cam)
                local playerPed = PlayerPedId()
                local endCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.3, 1.0)
        
                local startTime = GetGameTimer()
                local duration = 1000
                while GetGameTimer() - startTime < duration do
                    local progress = (GetGameTimer() - startTime) / duration
                    local newX = startCoords.x + (endCoords.x - startCoords.x) * progress
                    local newY = startCoords.y + (endCoords.y - startCoords.y) * progress
                    local newZ = startCoords.z + (endCoords.z - startCoords.z) * progress
                    SetCamCoord(cam, newX, newY, newZ)
                    Wait(10)
                end
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(cam, false)
                cam = nil
            end
            cb("ok")
        end)
    end
end)




