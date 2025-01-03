local HasAlreadyEnteredMarker, IsInShopMenu = false, false
local CurrentAction, CurrentActionMsg, LastZone, currentDisplayVehicle, CurrentVehicleData
local CurrentActionData, Vehicles, Categories = {}, {}, {}
local VehiclesByModel = {}
local vehiclesByCategory = {}

function getVehicleFromModel(model)
    return VehiclesByModel[model]
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    TriggerServerEvent("esx_vehicleshopvip:getVehiclesAndCategories")
end)

RegisterNetEvent('esx_vehicleshopvip:updateVehiclesAndCategories', function(vehicles, categories, vehiclesByModel)
    Vehicles = vehicles
    Categories = categories

    VehiclesByModel = vehiclesByModel

    table.sort(Vehicles, function(a, b)
        return a.name < b.name
    end)

    for _, vehicle in ipairs(Vehicles) do
        if IsModelInCdimage(joaat(vehicle.model)) then
            local category = vehicle.category

            if not vehiclesByCategory[category] then
                vehiclesByCategory[category] = {}
            end

            table.insert(vehiclesByCategory[category], vehicle)
        else
            print(('[^3WARNING^7] Ignoring vehicle ^5%s^7 due to invalid model'):format(vehicle.model))
        end
    end
end)

function DeleteDisplayVehicleInsideShop()
    local attempt = 0

    if currentDisplayVehicle and DoesEntityExist(currentDisplayVehicle) then
        while DoesEntityExist(currentDisplayVehicle) and not NetworkHasControlOfEntity(currentDisplayVehicle) and attempt < 100 do
            Wait(100)
            NetworkRequestControlOfEntity(currentDisplayVehicle)
            attempt = attempt + 1
        end

        if DoesEntityExist(currentDisplayVehicle) and NetworkHasControlOfEntity(currentDisplayVehicle) then
            ESX.Game.DeleteVehicle(currentDisplayVehicle)
        end
    end
end

function StartShopRestriction()
    CreateThread(function()
        while IsInShopMenu do
            Wait(0)

            DisableControlAction(0, 75, true) -- Disable exit vehicle
            DisableControlAction(27, 75, true) -- Disable exit vehicle
        end
    end)
end

function OpenShopMenu()
    if #Vehicles == 0 then
        print('[^3ERROR^7] Vehicleshop has ^50^7 vehicles, please add some!')
        return
    end

    IsInShopMenu = true

    StartShopRestriction()
    ESX.UI.Menu.CloseAll()

    local playerPed = PlayerPedId()

    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false)
    SetEntityCoords(playerPed, Config.Zones.ShopInside.Pos)

    local elements = {}
    local firstVehicleData = nil

    for i = 1, #Categories, 1 do
        local category = Categories[i]
        local categoryVehicles = vehiclesByCategory[category.name]
        local options = {}
        if categoryVehicles == nil then goto continue end
        
        for j = 1, #categoryVehicles, 1 do
            local vehicle = categoryVehicles[j]

            if i == 1 and j == 1 then
                firstVehicleData = vehicle
            end

            local priceDisplay = Config.UseVIPCredits and TranslateCap('generic_shopitem_vip', ESX.Math.GroupDigits(vehicle.price)) or TranslateCap('generic_shopitem', ESX.Math.GroupDigits(vehicle.price))
            table.insert(options, ('%s <span style="color:green;">%s</span>'):format(vehicle.name, priceDisplay))
        end

        table.sort(options)

        table.insert(elements, {
            name = category.name,
            label = category.label,
            value = 0,
            type = 'slider',
            max = #Categories[i],
            options = options
        })
        ::continue::
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
        title = TranslateCap('car_dealer'),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
            title = Config.UseVIPCredits and TranslateCap('buy_vehicle_shop_vip', vehicleData.name, ESX.Math.GroupDigits(vehicleData.price)) or TranslateCap('buy_vehicle_shop', vehicleData.name, ESX.Math.GroupDigits(vehicleData.price)),
            align = 'top-left',
            elements = {
                { label = TranslateCap('no'), value = 'no' },
                { label = TranslateCap('yes'), value = 'yes' }
        }}, function(data2, menu2)
            if data2.current.value == 'yes' then
                local generatedPlate = GeneratePlate()

                ESX.TriggerServerCallback('esx_vehicleshopvip:buyVehicle', function(success)
                    if success then
                        IsInShopMenu = false
                        menu2.close()
                        menu.close()
                        DeleteDisplayVehicleInsideShop()
                        FreezeEntityPosition(playerPed, false)
                        SetEntityVisible(playerPed, true)
                    else
                        local notification = Config.UseVIPCredits and TranslateCap('not_enough_vip_credits') or TranslateCap('not_enough_money')
                        ESX.ShowNotification(notification)
                    end
                end, vehicleData.model, generatedPlate)
            else
                menu2.close()
            end
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
        DeleteDisplayVehicleInsideShop()
        local playerPed = PlayerPedId()

        CurrentAction = 'shop_menu'
        CurrentActionMsg = TranslateCap('shop_menu')
        CurrentActionData = {}

        FreezeEntityPosition(playerPed, false)
        SetEntityVisible(playerPed, true)
        SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

        IsInShopMenu = false
    end, function(data, menu)
        local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]
        local playerPed = PlayerPedId()

        WaitForVehicleToLoad(vehicleData.model)

        ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function(vehicle)
            DeleteDisplayVehicleInsideShop()
            currentDisplayVehicle = vehicle
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            FreezeEntityPosition(vehicle, true)
            SetModelAsNoLongerNeeded(vehicleData.model)
        end)
    end)
    WaitForVehicleToLoad(firstVehicleData.model)

    ESX.Game.SpawnLocalVehicle(firstVehicleData.model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function(vehicle)
        DeleteDisplayVehicleInsideShop()
        currentDisplayVehicle = vehicle
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        FreezeEntityPosition(vehicle, true)
        SetModelAsNoLongerNeeded(firstVehicleData.model)
    end)
end


function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or joaat(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyspinnerOn('STRING')
		AddTextComponentSubstringPlayerName(TranslateCap('shop_awaiting_model'))
		EndTextCommandBusyspinnerOn(4)

		while not HasModelLoaded(modelHash) do
			Wait(0)
			DisableAllControlActions(0)
		end

		BusyspinnerOff()
	end
end

function hasEnteredMarker(zone)
	if zone == 'ShopEntering' then
		CurrentAction     = 'shop_menu'
		CurrentActionMsg  = TranslateCap('shop_menu')
		CurrentActionData = {}
	end
end

function hasExitedMarker(zone)
	if not IsInShopMenu then
		ESX.UI.Menu.CloseAll()
	end
	ESX.HideUI()
	CurrentAction = nil
end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		if IsInShopMenu then
			ESX.UI.Menu.CloseAll()

			local playerPed = PlayerPedId()

			FreezeEntityPosition(playerPed, false)
			SetEntityVisible(playerPed, true)
			SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)
		end

		DeleteDisplayVehicleInsideShop()
	end
end)

-- Create Blips
if Config.Blip.show then
	CreateThread(function()
		local blip = AddBlipForCoord(Config.Zones.ShopEntering.Pos)

		SetBlipSprite (blip, Config.Blip.Sprite)
		SetBlipDisplay(blip, Config.Blip.Display)
		SetBlipScale  (blip, Config.Blip.Scale)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(TranslateCap('car_dealer'))
		EndTextCommandSetBlipName(blip)
	end)
end

-- Enter / Exit marker events & Draw Markers
CreateThread(function()
	while true do
		Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true

		for k,v in pairs(Config.Zones) do
			local distance = #(playerCoords - v.Pos)

			if distance < Config.DrawDistance then
				letSleep = false

				if v.Type ~= -1 then
					DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
				end

				if distance < v.Size.x then
					isInMarker, currentZone = true, k
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			LastZone = currentZone
			hasEnteredMarker(currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			hasExitedMarker(LastZone)
		end

		if letSleep then
			Wait(500)
		end
	end
end)

-- Key controls
CreateThread(function()
	while true do
		Wait(0)

		if CurrentAction then
			ESX.TextUI(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'shop_menu' then
					if Config.LicenseEnable then
						ESX.TriggerServerCallback('esx_license:checkLicense', function(hasDriversLicense)
							if hasDriversLicense then
								OpenShopMenu()
							else
								ESX.ShowNotification(TranslateCap('license_missing'))
							end
						end, GetPlayerServerId(PlayerId()), 'drive')
					else
						OpenShopMenu()
					end
				end
				ESX.HideUI()
				CurrentAction = nil
			end
		else
			Wait(500)
		end
	end
end)

CreateThread(function()
	RequestIpl('shr_int') -- Load walls and floor

	local interiorID = 7170
	PinInteriorInMemory(interiorID)
	ActivateInteriorEntitySet(interiorID, 'csr_beforeMission') -- Load large window
	RefreshInterior(interiorID)
end)