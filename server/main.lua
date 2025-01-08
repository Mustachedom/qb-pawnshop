local QBCore = exports['qb-core']:GetCoreObject()
local recieved = {} -- no touch, script uses this to store pawn prices

local items = {
    Pawn = {
        goldchain       = {price = {min = 50, max = 100}},
        diamond_ring    = {price = {min = 50, max = 100}},
        rolex           = {price = {min = 50, max = 100}},
        tenkgoldchain   = {price = {min = 50, max = 100}},
        tablet          = {price = {min = 50, max = 100}},
        iphone          = {price = {min = 50, max = 100}},
        samsungphone    = {price = {min = 50, max = 100}},
        laptop          = {price = {min = 50, max = 100}},
    },
    Smelt = { -- time = amount of time in minutes per item
        goldchain     = {time = 15, reward = { goldbar = 1 } },
        diamond_ring  = {time = 15, reward = { goldbar = 1, diamond = 1 } },
        rolex         = {time = 15, reward = { goldbar = 1, diamond = 1, electronickit = 1 } },
        tenkgoldchain = {time = 15, reward = { goldbar = 1, diamond = 5 } },
    }
}

local locations = {
    {coords = vector4(412.34, 314.81, 103.13, 207.0), length = 1.5, width = 1.8,debugPoly = false, distance = 3.0},
}

CreateThread(function() -- simple debug to verify all items required for script are here
    local check = QBCore.Shared.Items
    if check == nil then
        print('^1 qb-core/shared/items.lua is missing, check for , and } :)')
        return
    end
    for k, v in pairs (items.Smelt) do
        if not QBCore.Shared.Items[k] then
            print('^1 Missing Item: ' .. k .. ' in qb-core/shared/items.lua')
        end
        for m, d in pairs (v.reward) do
            if not QBCore.Shared.Items[m] then
                print('^1 Missing Item: ' .. m .. ' in qb-core/shared/items.lua')
            end
        end
    end
    for k, v in pairs (items.Pawn) do
        if not QBCore.Shared.Items[k] then
            print('^1 Missing Item: ' .. k .. ' in qb-core/shared/items.lua')
        end
    end
end)

local function getCid(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.citizenid
end

local function getName(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
end

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(id),
            QBCore.Functions.GetIdentifier(id, 'license'),
            QBCore.Functions.GetIdentifier(id, 'discord'),
            QBCore.Functions.GetIdentifier(id, 'ip'),
            reason,
            2147483647,
            'qb-pawnshop'
        })
    TriggerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red',
        string.format('%s was banned by %s for %s', GetPlayerName(id), 'qb-pawnshop', reason), true)
    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

local function distCheck(source)
    local src = source
    local playerPed = GetPlayerPed(src)
    local pcoords = GetEntityCoords(playerPed)
    local ok
    for k, v in pairs (locations) do
        local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
        if #(pcoords - coords) < v.distance then
            ok = true
        end
    end
    if ok then return true else exploitBan(src, 'Distance Fail For QB-Pawnshop') return false end
end

QBCore.Functions.CreateCallback('qb-pawnshop:server:getLocations', function(source, cb)
    cb(locations)
end)

local function editAmount(source, it)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not items.Pawn[it] then return 0 end
    local item = Player.Functions.GetItemByName(it)
    if item and item.amount > 0 then
        return item.amount
    else
       return 0
    end
end

QBCore.Functions.CreateCallback('qb-pawnshop:server:getPawnItems', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local info = {}

    if recieved[getCid(src)] then
        for k, v in pairs (recieved[getCid(src)].items) do
            recieved[getCid(source)].items[k].amount = editAmount(src, v.item)
        end
        cb(recieved[getCid(src)])
        return
    end

    local has = 0
    for k, v in pairs (items.Pawn) do
        local item = Player.Functions.GetItemByName(k)
        if item and item.amount > 0 then
            has = has + 1
            table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = item.amount, price = math.random(v.price.min, v.price.max)})
        else
            table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = 0, price = math.random(v.price.min, v.price.max)})
        end
    end
    if has == 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_items'), 'error')
        cb(false)
        return
    end
    recieved[getCid(src)] = {name = getName(src), items = info}
    cb(recieved[getCid(src)])
end)

local function verifyItem(source, itemName, itemPrice, amount, total)
    local src = source
    if not recieved[getCid(src)] then return false end
    for k, v in pairs (recieved[getCid(src)].items) do
        if v.item == itemName and v.price == itemPrice and tonumber(v.amount) >= tonumber(amount) then
            if v.price * amount == total then
                return true
            else
                return false
            end
        end
    end
end

local function handleSell(source, item, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if exports['qb-inventory']:RemoveItem(src, item, tonumber(amount), false, 'qb-pawnshop:server:sellPawnItems') then
        if Config.BankMoney then
            Player.Functions.AddMoney('bank', price, 'qb-pawnshop:server:sellPawnItems')
        else
            Player.Functions.AddMoney('cash', price, 'qb-pawnshop:server:sellPawnItems')
        end
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.sold', { value = tonumber(amount), value2 = QBCore.Shared.Items[item].label, value3 = price }), 'success')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', tonumber(amount))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_items'), 'error')
        return false
    end
    return true
end

RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(itemName, itemAmount, itemPrice)
    local src = source
    local totalPrice = (tonumber(itemAmount) * itemPrice)
    local dist = distCheck(src)
    if not dist then return end
    if not verifyItem(src, itemName, itemPrice, itemAmount, totalPrice) then return end
    handleSell(src, itemName, itemAmount, totalPrice)
    TriggerClientEvent('qb-pawnshop:client:openMenu', src)
end)

local function pickupSmelt(source, data) 
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local dist = distCheck(src)
    if not dist then return end

    for k, v in pairs (items.Smelt[data.item].reward) do 
        Player.Functions.AddItem(k, v * data.amount, false, false, 'qb-pawnshop:server:pickupSmelt')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[k], 'add', v * data.amount)
    end

    MySQL.query('DELETE FROM smelting WHERE citizenid = ?', {getCid(src)})
end

QBCore.Functions.CreateCallback('qb-pawnshop:server:getSmelt', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local smelting = MySQL.query.await('SELECT * FROM smelting WHERE citizenid = ?', {getCid(src)})
    if smelting and smelting[1] then
        if tonumber(smelting[1].time) < os.time() then
            pickupSmelt(src, smelting[1])
            local info = {}
            local has = 0
            for k, v in pairs (items.Smelt) do
                local item = Player.Functions.GetItemByName(k)
                if item and item.amount > 0 then
                    has = has + 1
                    table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = item.amount, time = v.time, recipe = v.reward})
                else
                    table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = 0, time = v.time, recipe = v.reward})
                end
            end
            if has == 0 then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_items'), 'error')
                cb('no items')
                return
            end
            cb(info)
            return
        else
            local time = math.floor(os.difftime(smelting[1].time, os.time()) / 60)
            cb('already smelt', time)
            return
        end
    else
        local info = {}
        local has = 0
        for k, v in pairs (items.Smelt) do
            local item = Player.Functions.GetItemByName(k)
            if item and item.amount > 0 then
                has = has + 1
                table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = item.amount, time = v.time, recipe = v.reward})
            else
                table.insert(info, {label = QBCore.Shared.Items[k].label, item = k, amount = 0, time = v.time, recipe = v.reward})
            end
        end
        if has == 0 then
            cb(false)
            return
        end
        cb(info)
    end
end)

local function verifynremoveSmelt(source, item, amount)
    local src = source
    local has = MySQL.query.await('SELECT * FROM smelting WHERE citizenid = ?', {getCid(src)})
    if has and #has > 0 then
        return 'Already Smelting'
    else
        if exports['qb-inventory']:RemoveItem(src, item, amount, false, 'qb-pawnshop:server:meltItemRemove') then
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', amount)
            MySQL.insert('INSERT INTO smelting (citizenid, item, amount, time) VALUES (?, ?, ?,?)',
            {getCid(src), item, amount, ((amount * items.Smelt[item].time) * 60) + os.time()})
            
            return true
        else
            return false
        end
    end
end

RegisterNetEvent('qb-pawnshop:server:meltItemRemove', function(itemName, itemAmount)
    local src = source
    local dist = distCheck(src)
    if not dist then return end
    local verified = verifynremoveSmelt(src, itemName, itemAmount)
    if verified == 'Already Smelting' then 
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_smelt'), 'error')
          return
    elseif not verified then 
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_items'), 'error')
         return
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.smelt_started', { amount = itemAmount, item = QBCore.Shared.Items[itemName].label }), 'success')
        TriggerClientEvent('qb-pawnshop:client:openMenu', src)
    end
end)