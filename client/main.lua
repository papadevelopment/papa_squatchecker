local ESX, QBCore = nil, nil

local function DebugPrint(msg)
    if Config.Debug then
        print(('[papa_squatchecker] %s'):format(msg))
    end
end

local function DetectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end

    if GetResourceState('es_extended') == 'started' then return 'esx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('ox_core') == 'started' then return 'ox' end

    return 'standalone'
end

local Framework = DetectFramework()

CreateThread(function()
    if Framework == 'esx' then
        pcall(function()
            ESX = exports['es_extended']:getSharedObject()
        end)
    elseif Framework == 'qb' then
        pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
    end

    DebugPrint(('Framework detected: %s'):format(Framework))
end)

local function TableEmpty(tbl)
    if type(tbl) ~= 'table' then return true end
    return next(tbl) == nil
end

local function HasAllowedJob()
    if Config.AllowedJobs == false or TableEmpty(Config.AllowedJobs) then
        return true
    end

    local jobName

    if Framework == 'esx' then
        if not ESX then
            pcall(function()
                ESX = exports['es_extended']:getSharedObject()
            end)
        end

        local data = ESX and ESX.GetPlayerData and ESX.GetPlayerData()
        jobName = data and data.job and data.job.name
    elseif Framework == 'qb' then
        if not QBCore then
            pcall(function()
                QBCore = exports['qb-core']:GetCoreObject()
            end)
        end

        local data = QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData()
        jobName = data and data.job and data.job.name
    elseif Framework == 'qbox' then
        local ok, playerData = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)

        if ok and playerData then
            jobName = playerData.job and playerData.job.name
        end
    elseif Framework == 'ox' then
        local ok, player = pcall(function()
            return exports.ox_core:GetPlayer()
        end)

        if ok and player then
            local groups = player.getGroups and player.getGroups()
            if type(groups) == 'table' then
                for groupName in pairs(groups) do
                    if Config.AllowedJobs[groupName] then return true end
                end
            end
        end
    elseif Framework == 'standalone' then
        -- No framework means no job data. Change this to false if you want to block everyone by default.
        return true
    end

    return jobName and Config.AllowedJobs[jobName] == true
end

local function Notify(message, notifyType)
    notifyType = notifyType or 'info'

    -- okokNotify commonly uses this client event/export style.
    if GetResourceState('okokNotify') == 'started' then
        local ok = pcall(function()
            exports['okokNotify']:Alert(Config.Notify.title, message, Config.Notify.duration, notifyType, Config.Notify.playSound)
        end)

        if not ok then
            TriggerEvent('okokNotify:Alert', Config.Notify.title, message, Config.Notify.duration, notifyType, Config.Notify.playSound)
        end
        return
    end

    -- Fallback so the script still gives feedback if okokNotify is missing.
    lib.notify({
        title = Config.Notify.title,
        description = message,
        type = notifyType,
        duration = Config.Notify.duration
    })
end

local function GetBoneWorldCoords(vehicle, possibleBones)
    for i = 1, #possibleBones do
        local boneIndex = GetEntityBoneIndexByName(vehicle, possibleBones[i])
        if boneIndex ~= -1 then
            return GetWorldPositionOfEntityBone(vehicle, boneIndex), possibleBones[i]
        end
    end

    return nil, nil
end

local function AverageZ(coords)
    local total = 0.0
    local count = 0

    for i = 1, #coords do
        if coords[i] then
            total += coords[i].z
            count += 1
        end
    end

    if count == 0 then return nil end
    return total / count
end

local function CalculateSuspension(vehicle)
    local frontLeft = GetBoneWorldCoords(vehicle, { 'wheel_lf', 'suspension_lf' })
    local frontRight = GetBoneWorldCoords(vehicle, { 'wheel_rf', 'suspension_rf' })
    local rearLeft = GetBoneWorldCoords(vehicle, { 'wheel_lr', 'suspension_lr' })
    local rearRight = GetBoneWorldCoords(vehicle, { 'wheel_rr', 'suspension_rr' })

    local frontZ = AverageZ({ frontLeft, frontRight })
    local rearZ = AverageZ({ rearLeft, rearRight })

    if not frontZ or not rearZ then
        return nil, 'Could not read this vehicle\'s wheel/suspension bones.'
    end

    local frontInches = (frontZ * Config.Measure.metersToInches) + Config.Measure.displayOffsetInches
    local rearInches = (rearZ * Config.Measure.metersToInches) + Config.Measure.displayOffsetInches
    local rawDifference = frontInches - rearInches
    local difference = math.abs(rawDifference)

    local illegal
    if Config.Measure.differenceMode == 'squat_only' then
        -- Positive means front is higher than rear.
        illegal = rawDifference > Config.Measure.legalDifferenceInches
    else
        illegal = difference > Config.Measure.legalDifferenceInches
    end

    return {
        front = frontInches,
        rear = rearInches,
        difference = difference,
        rawDifference = rawDifference,
        illegal = illegal
    }
end

local function FormatMeasurement(result)
    if not Config.Notify.showMeasurements then return '' end

    return ('\nFront: %.2f in | Rear: %.2f in | Difference: %.2f in'):format(
        result.front,
        result.rear,
        result.difference
    )
end

local function PlayMeasureProgress()
    return lib.progressBar({
        duration = Config.Measure.duration,
        label = 'Measuring suspension height...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            scenario = 'WORLD_HUMAN_INSPECT_CROUCH'
        }
    })
end

local function MeasureVehicle(vehicle)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return end

    if not HasAllowedJob() then
        Notify('You are not authorized to measure suspension.', 'error')
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        Notify('Exit the vehicle before measuring suspension.', 'error')
        return
    end

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(750)

    local success = PlayMeasureProgress()
    ClearPedTasks(ped)

    if not success then
        Notify('Suspension measurement cancelled.', 'error')
        return
    end

    local result, err = CalculateSuspension(vehicle)
    if not result then
        Notify(err or 'Could not measure this vehicle.', 'error')
        return
    end

    if result.illegal then
        Notify(Config.Notify.warningMessage .. FormatMeasurement(result), 'warning')
    elseif Config.Notify.showLegalResult then
        Notify(Config.Notify.legalMessage .. FormatMeasurement(result), 'success')
    end
end

CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end

    exports.ox_target:addGlobalVehicle({
        {
            name = 'papa_squatchecker_measure',
            icon = Config.Target.icon,
            label = Config.Target.label,
            distance = Config.Target.distance,
            canInteract = function(entity)
                return DoesEntityExist(entity) and IsEntityAVehicle(entity) and HasAllowedJob()
            end,
            onSelect = function(data)
                MeasureVehicle(data.entity)
            end
        }
    })
end)
