Garage = {}
Impound = {}

if Settings.Debug then SetResourceKvp('player_garage', '') end

local DatastoreService = require 'classes.datastore'
local GarageData = DatastoreService:new('player_garage')

Garage.VehicleModelData = LoadResourceFile(GetCurrentResourceName(), "data/vehicle_models.json")
Garage.VehicleModels = {}

Garage.CreateGarageData = function()
    GarageData:save({
        characters = {},
        hasData = true
    })
end

Garage.GetGarageData = function()
    return GarageData.data
end

Garage.GetVehicles = function()
    if not GarageData.data.characters[Core.CurrentCharacter] then
        GarageData.data.characters[Core.CurrentCharacter] = {
            vehicles = {}
        }
        GarageData:save(GarageData.data)
    end
    return GarageData.data.characters[Core.CurrentCharacter].vehicles
end

Garage.LoadVehicleModels = function()
    local vehicleData = json.decode(Garage.VehicleModelData) or {}
    local newData = {}

    for hash, data in pairs(vehicleData) do
        newData[math.floor(hash)] = data
    end

    Garage.VehicleModels = newData
end

Garage.GetGarageDataForCharacter = function(characterId)
    return GarageData.data.characters[characterId]
end

Garage.GetGarageDataForCurrentCharacter = function()
    return GarageData.data.characters[Core.CurrentCharacter]
end

Garage.SaveCurrentVehicle = function()
    if not Core.CurrentCharacter then Utils.DebugPrint('ERROR', 'GARAGE: No character loaded') return end
    local characterId = Core.CurrentCharacter

    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local props = Garage.GetVehicleProperties()
    if not props then return end

    local plate = GetVehicleNumberPlateText(vehicle)

    local input = lib.inputDialog('Save Vehicle', {
        {type = 'input', label = 'Vehicle Name', required = true, min = 2},
    })

    if not input then lib.notify({
        title = 'Garage',
        description = 'Invalid input, please try again.',
        type = 'error'
    }) return end

    local vehicleData = {
        name = input[1],
        model = GetEntityModel(vehicle),
        plate = plate,
        props = props,
        stored = true
    }

    local vehicles = Garage.GetVehicles()
    vehicles[#vehicles + 1] = vehicleData

    GarageData.data.characters[characterId].vehicles = vehicles
    GarageData:save(GarageData.data)

    lib.notify({
        title = 'Garage',
        position = 'top',
        description = ('Vehicle "%s" has been saved successfully'):format(vehicleData.name),
        type = 'success'
    })

    DeleteEntity(vehicle)
end

Garage.SelectVehicle = function(vehicleId)
    local menu = {
        id = 'garage_vehicle_options',
        title = 'Vehicle Options',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Spawn Vehicle',
        onSelect = function()
            Garage.SpawnVehicle(vehicleId)
        end,
        icon = 'check'
    }

    menu.options[#menu.options + 1] = {
        title = 'Delete Vehicle',
        onSelect = function()
            Garage.PromptDeleteVehicle(vehicleId)
        end,
        icon = 'xmark',
        iconColor = '#ff4f42'
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Garage.OpenGarageMenu()
        end,
        icon = 'arrow-left',
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Garage.PromptDeleteVehicle = function(vehicleId)
    local vehicle = Garage.GetVehicles()[vehicleId]
    if not vehicle then return end

    local alert = lib.alertDialog({
        header = 'Vehicle Deletion',
        content = ('Are you sure you want to delete %s?'):format(vehicle.name),
        labels = {
            confirm = 'Delete',
        },
        centered = true,
        cancel = true
    })

    local delete = alert == 'confirm' and true or false

    if delete then
        Garage.GetVehicles()[vehicleId] = nil
        GarageData:save(GarageData.data)

        lib.notify({
            title = 'Garage',
            position = 'top',
            description = ('Vehicle "%s" has been deleted successfully'):format(vehicle.name),
            type = 'success'
        })

        Garage.OpenGarageMenu()
    else
        Garage.OpenGarageMenu()
    end
end

Garage.DeleteVehicles = function(characterId)
    if not GarageData.data.characters[characterId] then return end
    GarageData.data.characters[characterId].vehicles = {}
    GarageData:save(GarageData.data)
end

Garage.SpawnVehicle = function(vehicleId)
    local vehicles = Garage.GetVehicles()
    local vehicleData = vehicles[vehicleId]
    if not vehicleData then return end

    if not vehicleData.stored then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'This vehicle is not stored in the garage.',
            type = 'error'
        })
        return
    end

    local currentVehicle = GetVehiclePedIsIn(cache.ped, false)
    if currentVehicle then
        DeleteEntity(currentVehicle)
    end

    local model = Garage.VehicleModels[vehicleData.model].model
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    local vehicleNet = lib.callback.await('lite-core:spawnVehicle', false, model, coords, heading, true, vehicleData)

    TriggerServerEvent('lite-core:unStoreVehicle', vehicleNet, vehicleId)

    vehicles[vehicleId].stored = false

    GarageData.data.characters[Core.CurrentCharacter].vehicles = vehicles
    GarageData:save(GarageData.data)

    Utils.DebugPrint('INFO', ('Vehicle with plate %s has been spawned successfully'):format(vehicleData.plate))

    lib.notify({
        title = 'Garage',
        position = 'top',
        description = ('Vehicle "%s" has been spawned successfully'):format(vehicleData.name),
        type = 'success'
    })
end

Garage.StoreVehicle = function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local identifier = Core.GetPlayerInfoOne('identifier')
    local ownerData = Entity(vehicle).state.ownedvehicle

    if not ownerData or not ownerData.owner then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'You cannot store this vehicle',
            type = 'error'
        })
        return
    end

    if not (ownerData.owner == identifier) or not (ownerData.characterId == Core.CurrentCharacter) then
        lib.notify({
            title = 'Garage',
            position = 'top',
            description = 'You cannot store a vehicle that is not yours.',
            type = 'error'
        })
        return
    end

    local props = Garage.GetVehicleProperties()
    if not props then return end

    local vehicleData = Garage.GetVehicles()[ownerData.vehicleId]
    if not vehicleData then return end

    vehicleData.props = props
    vehicleData.stored = true

    GarageData.data.characters[Core.CurrentCharacter].vehicles[ownerData.vehicleId] = vehicleData
    GarageData:save(GarageData.data)

    lib.notify({
        title = 'Garage',
        position = 'top',
        description = ('Vehicle "%s" has been stored successfully'):format(vehicleData.name),
        type = 'success'
    })

    DeleteEntity(vehicle)
end

Garage.OpenGarageMenu = function()
    if not Core.CurrentCharacter then return end

    local vehicles = Garage.GetVehicles()

    local menu = {
        id = 'garage_menu',
        title = 'Garage',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Store Vehicle',
        onSelect = function()
            Garage.StoreVehicle()
        end,
        icon = 'warehouse'
    }

    for vehicleId, vehicle in pairs(vehicles) do
        menu.options[#menu.options + 1] = {
            title = ('%s (%s) - %s'):format(vehicle.name, vehicle.plate or 'No Plate', Garage.VehicleModels[vehicle.model].name),
            onSelect = function()
                Garage.SelectVehicle(vehicleId)
            end,
            icon = 'car',
            iconColor = vehicle.stored and '#6593c7' or '#e35454'
        }
    end

    if #menu.options == 1 then
        menu.options[#menu.options + 1] = {
            title = 'No Vehicles',
        }
    end

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Garage.ValidateVehicleOwnership = function(netId)
    local vehicle = 0

    lib.waitFor(function()
        vehicle = NetToVeh(netId)
        if vehicle ~= nil or vehicle ~= 0 then return true end
        return false
    end, ('Could not get entity for netId:'):format(netId), 1000)

    local isOwner = false

    lib.waitFor(function()
        isOwner = NetworkGetEntityOwner(vehicle) == PlayerId()
        if isOwner then return true end
        return false
    end, 'Not entity owner', 1000)

    return isOwner
end

Garage.GetVehicleProperties = function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end

    local props = lib.getVehicleProperties(vehicle)

    return props
end

Garage.LoadVehicleModels()

Garage.SetVehicleProperies = function(vehicle, data, fixVehicle)
    if not vehicle or not data then return end

    local plate = data.plate
    if plate then SetVehicleNumberPlateText(vehicle, plate) end

    lib.setVehicleProperties(vehicle, data.props, fixVehicle)
end

Impound.ClaimVehicle = function (vehicleId)
    local vehicles = Garage.GetVehicles()
    vehicles[vehicleId].stored = true

    GarageData.data.characters[Core.CurrentCharacter].vehicles = vehicles
    GarageData:save(GarageData.data)

    lib.notify({
        title = 'Garage',
        position = 'top',
        description = ('Vehicle "%s" has been claimed successfully'):format(vehicles[vehicleId].name),
        type = 'success'
    })
end

Impound.ImpoundOptions = function(vehicleId)
    local menu = {
        id = 'impound_options',
        title = 'Impound Options',
        options = {}
    }

    menu.options[#menu.options + 1] = {
        title = 'Claim Vehicle',
        onSelect = function()
            Impound.ClaimVehicle(vehicleId)
        end,
        icon = 'clipboard'
    }

    menu.options[#menu.options + 1] = {
        title = 'Back',
        onSelect = function()
            Impound.OpenImpoundMenu()
        end,
        icon = 'arrow-left'
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Impound.OpenImpoundMenu = function()
    if not Core.CurrentCharacter then return end

    local vehicles = Garage.GetVehicles()

    local menu = {
        id = 'impound_menu',
        title = 'Impound Lot',
        options = {}
    }

    for vehicleId, vehicle in pairs(vehicles) do
        if not vehicle.stored then
            menu.options[#menu.options + 1] = {
                title = ('%s (%s) - %s'):format(vehicle.name, vehicle.plate or 'No Plate', Garage.VehicleModels[vehicle.model].name),
                onSelect = function()
                    Impound.ImpoundOptions(vehicleId)
                end,
                icon = 'car',
                iconColor = '#2aa5b8'
            }
        end
    end

    if #menu.options == 0 then
        menu.options[#menu.options + 1] = {
            title = 'No Vehicles in Impound',
        }
    end

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

Garage.ResetAll = function()
    GarageData.data = {}
    Garage.CreateGarageData()
    Utils.DebugPrint('WARN', 'Garage data has been reset.')
end

lib.callback.register('lite-core:validateOwnership', function(netId)
    return Garage.ValidateVehicleOwnership(netId)
end)

lib.callback.register('lite-core:setVehicleProperties', function(netId, props)
    local vehicle = NetToVeh(netId)
    Garage.SetVehicleProperies(vehicle, props, false)
end)

if not GarageData.data or not GarageData.data.hasData then
    Utils.DebugPrint('WARN', 'Initializing player garage datastore.')
    Garage.CreateGarageData()
end