local QBCore = exports['qb-core']:GetCoreObject()

local function createBlip(data)
    for _, value in pairs(data) do
        local blip = AddBlipForCoord(value.coords.x, value.coords.y, value.coords.z)
        SetBlipSprite(blip, 431)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 5)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Lang:t('info.title'))
        EndTextCommandSetBlipName(blip)
    end
end

local function sort(t,v)
    table.sort(t, function(a,b) return a[v] < b[v] end)
end

CreateThread(function()
    QBCore.Functions.TriggerCallback('qb-pawnshop:server:getLocations', function(data)
        createBlip(data)
        for key, value in pairs (data) do 
            if Config.UseTarget then
                exports['qb-target']:AddBoxZone('PawnShop'..key, value.coords, value.length, value.width, {
                    name = 'PawnShop'..key,
                    heading = value.coords.w,
                    minZ = value.coords.z - 2,
                    maxZ = value.coords.z + 2,
                    debugPoly = value.debugPoly,
                }, {
                    options = {
                        {
                            type = 'client',
                            event = 'qb-pawnshop:client:openMenu',
                            icon = 'fas fa-ring',
                            label = 'Pawn Shop',
                        },
                    },
                    distance = value.distance
                })
            else
                local zone = {}
                    zone[#zone+1] = BoxZone:Create(value.coords, value.length, value.width, {
                        name = 'PawnShop'..key,
                        heading = value.coords.w,
                        minZ = value.coords.z - 2,
                        maxZ = value.coords.z + 2,
                    })
                local pawnShopCombo = ComboZone:Create( zone, { name = 'NewPawnShopCombo', debugPoly = value.debugPoly })
                pawnShopCombo:onPlayerInOut(function(isPointInside)
                    if isPointInside then
                        exports['qb-menu']:showHeader({
                            {
                                header = Lang:t('info.title'),
                                txt = Lang:t('info.open_pawn'),
                                params = {
                                    event = 'qb-pawnshop:client:openMenu'
                                }
                            }
                        })
                    else
                        exports['qb-menu']:closeMenu()
                    end
                end)
            end
        end
    end)
end)

RegisterNetEvent('qb-pawnshop:client:openMenu', function()
    local pawnShop = {
        {
            header = Lang:t('info.title'),
            isMenuHeader = true,
        },
        {
            header = Lang:t('info.sell'),
            txt = Lang:t('info.sell_pawn'),
            params = {
                event = 'qb-pawnshop:client:openPawn',
            }
        },
        {
            header = Lang:t('info.melt'),
            txt = Lang:t('info.melt_pawn'),
            params = {
                event = 'qb-pawnshop:client:openMelt',
            }
        }
    }
    if Config.UseTimes then
        if GetClockHours() >= Config.TimeOpen and GetClockHours() <= Config.TimeClosed then
            exports['qb-menu']:openMenu(pawnShop)
        else
            QBCore.Functions.Notify(Lang:t('info.pawn_closed', { value = Config.TimeOpen, value2 = Config.TimeClosed }))
        end
    else
        exports['qb-menu']:openMenu(pawnShop)
    end
end)

RegisterNetEvent('qb-pawnshop:client:openPawn', function(data)
    QBCore.Functions.TriggerCallback('qb-pawnshop:server:getPawnItems', function(pawn)
        if pawn == false then
            return
        end
        sort(pawn.items, 'label')
        local pawnMenu = {
            {
                header = Lang:t('info.title'),
                isMenuHeader = true,
            }
        }
        for k, v in pairs(pawn.items) do
            if QBCore.Functions.HasItem(v.item) then
                pawnMenu[#pawnMenu + 1] = {
                    icon = 'nui://qb-inventory/html/images/'..QBCore.Shared.Items[v.item].image,
                    header = QBCore.Shared.Items[v.item].label  .. ' X ' .. v.amount,
                    txt = Lang:t('info.sell_items', { value = v.price }),
                    params = {
                        event = 'qb-pawnshop:client:pawnitems',
                        args = {
                            label = QBCore.Shared.Items[v.item].label,
                            price = v.price,
                            name = v.item,
                            amount = v.amount
                        }
                    }
                }
            end
        end
        pawnMenu[#pawnMenu + 1] = {
            header = Lang:t('info.back'),
            params = {
                event = 'qb-pawnshop:client:openMenu'
            }
        }
        exports['qb-menu']:openMenu(pawnMenu)
    end)
end)

RegisterNetEvent('qb-pawnshop:client:openMelt', function(data)
    QBCore.Functions.TriggerCallback('qb-pawnshop:server:getSmelt', function(smelt, time)
        if smelt == 'already smelt' then 
            QBCore.Functions.Notify(Lang:t('info.already_melt'), 'error')
            TriggerServerEvent('qb-phone:server:sendNewMail', {
                sender = Lang:t('email.sender'),
                subject = Lang:t('email.subject'),
                message = Lang:t('email.message2', { time = time }),
                button = {}
            })
            return
        elseif smelt == false then
            QBCore.Functions.Notify(Lang:t('error.no_items'), 'error')
            return
        end
        local meltMenu = {
            {
                header = Lang:t('info.melt'),
                isMenuHeader = true,
            }
        }
        sort(smelt, 'label')
        for k, v in pairs(smelt) do
            if QBCore.Functions.HasItem(v.item) then
                local desc = ''
                for m, d in pairs (v.recipe) do desc = desc .. m .. " X " .. d .. ", " end
                meltMenu[#meltMenu + 1] = {
                    icon = 'nui://qb-inventory/html/images/'..QBCore.Shared.Items[v.item].image,
                    header = QBCore.Shared.Items[v.item].label  .. ' | ' .. v.time .. ' Minutes',
                    txt = 'Recieve: ' .. desc:sub(1, -3),
                    params = {
                        event = 'qb-pawnshop:client:meltItems',
                        args = {
                            item = v.item,
                            amount = v.amount,
                            time = v.time
                        }
                    }
                }
            end
        end
        meltMenu[#meltMenu + 1] = {
            header = Lang:t('info.back'),
            params = {
                event = 'qb-pawnshop:client:openMenu'
            }
        }
        exports['qb-menu']:openMenu(meltMenu)
    end)
end)

RegisterNetEvent('qb-pawnshop:client:pawnitems', function(item)
    local sellingItem = exports['qb-input']:ShowInput({
        header = Lang:t('info.title'),
        submitText = Lang:t('info.sell'),
        inputs = {
            {
                type = 'number',
                isRequired = false,
                name = 'amount',
                text = Lang:t('info.max', { value = item.amount })
            }
        }
    })
    if sellingItem then
        if not sellingItem.amount then
            return
        end

        if tonumber(sellingItem.amount) > 0 then
            if tonumber(sellingItem.amount) <= item.amount then
                TriggerServerEvent('qb-pawnshop:server:sellPawnItems', item.name, sellingItem.amount, item.price)
            else
                QBCore.Functions.Notify(Lang:t('error.no_items'), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t('error.negative'), 'error')
        end
    end
end)


RegisterNetEvent('qb-pawnshop:client:meltItems', function(item)
    local meltingItem = exports['qb-input']:ShowInput({
        header = Lang:t('info.melt'),
        submitText = Lang:t('info.submit'),
        inputs = {
            {
                type = 'number',
                isRequired = false,
                name = 'amount',
                text = Lang:t('info.max', { value = item.amount })
            }
        }
    })
    if meltingItem then
        if not meltingItem.amount then
            return
        end
        if meltingItem.amount ~= nil then
            if tonumber(meltingItem.amount) > 0 then
                TriggerServerEvent('qb-pawnshop:server:meltItemRemove',item.item, meltingItem.amount)
                TriggerServerEvent('qb-phone:server:sendNewMail', {
                    sender = Lang:t('email.sender'),
                    subject = Lang:t('email.subject'),
                    message = Lang:t('email.message', { item = QBCore.Shared.Items[item.item].label, amount = meltingItem.amount, time = item.time * meltingItem.amount }),
                    button = {}
                })
            else
                QBCore.Functions.Notify(Lang:t('error.no_melt'), 'error')
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_melt'), 'error')
        end
    end
end)