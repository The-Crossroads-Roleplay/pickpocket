local QRCore = exports['qr-core']:GetCoreObject()

-- Initializing variables.
local contrabandselling = false
local hasTarget = false
local startLocation = nil
local lastPed = {}
local stealingPed = nil
local stealData = {}
local availableContraband = {}
local currentOfferContraband = nil
local CurrentLawmen = 0
local lastPed = nil

RegisterCommand('pickpocket', function()
    TriggerEvent('dwrp-pickpocket:client:pickpocket')
end)

local robbedPeds = {}

function variableExistsInTable(table, variable)
    for _, value in pairs(robbedPeds) do
        if value == variable then
            return true
        end
    end
    return false
end

RegisterNetEvent('dwrp-pickpocket:client:pickpocket', function()
    QRCore.Functions.TriggerCallback('police:GetCops', function(lawmen)
        CurrentLawmen = lawmen
        if CurrentLawmen >= Config.MinimumLawmen then 
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            local PlayerPeds = {}

            -- Fills PlayerPeds table with all active players on the server. Doing this to make sure players cannot pickpocket other players via this mechanic.
            if next(PlayerPeds) == nil then
                for _, activePlayer in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(activePlayer)
                    PlayerPeds[#PlayerPeds+1] = ped
                end
            end

            local closestPed, closestDistance = QRCore.Functions.GetClosestPed(coords, PlayerPeds)

            -- Checks if the closest ped has not been previously pickpocketed.
            if variableExistsInTable(robbedPeds, closestPed) == false then
                if closestDistance < 1.0 and closestPed ~= 0 and not IsPedInAnyVehicle(closestPed) and GetPedType(closestPed) ~= 28 then
                    local caughtRNG = math.random(1,100)

                    if caughtRNG < Config.CaughtChance then 
                        QRCore.Functions.Notify('You got caught!', 'primary')
                        TriggerServerEvent('dwrp-pickpocket:server:reward')

                        local responseRNG = math.random(1,2)

                        if responseRNG == 1 then 
                            -- ped fights back.
                            print('fighting ped')
                            local knifeRNG = math.random(1,2)
                            if knifeRNG == 2 then
                                GiveWeaponToPed_2(closestPed, GetHashKey('weapon_melee_knife'), 500, true, 1, false, 0.0)
                            end

                            SetBlockingOfNonTemporaryEvents(closestPed, true)
                            SetPedFleeAttributes(closestPed, 0, 0)
                            SetPedCombatAttributes(closestPed, 46, true)
                            SetPedCombatAttributes(closestPed, 50, true)
                            SetPedCombatAttributes(closestPed, 5, true)
                            SetPedCombatAbility(closestPed, CAL_PROFESSIONAL)
                            SetPedCombatMovement(closestPed, 3)
                            SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(closestPed), GetPedRelationshipGroupHash(player))
                            TaskCombatPed(closestPed, PlayerPedId(), 0, 16)

                            lastPed = closestPed
                            table.insert(robbedPeds, lastPed)

                            if IsPedDeadOrDying(closestPed) then 
                                closestPed = nil 
                            end
                        else 
                            print('fleeing ped')
                            TaskSmartFleePed(closestPed, player, 300, 120, 3, 3.0, player)
                            lastPed = closestPed
                            table.insert(robbedPeds, lastPed)
                        end
                    else 
                        print('success')
                        QRCore.Functions.Notify('You sneakily picked someone\'s pocket!', 'primary')
                        TriggerServerEvent('dwrp-pickpocket:server:reward')
                        lastPed = closestPed
                        table.insert(robbedPeds, lastPed)
                    end
                else 
                    QRCore.Functions.Notify('Can\'t pickpocket this NPC!', 'primary')
                end
            else 
                QRCore.Functions.Notify('Already been pickpocketed!', 'primary')
            end
        end
    end)
end)
