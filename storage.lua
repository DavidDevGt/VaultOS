local Storage = {}
Storage.__index = Storage

-- Abre el archivo de log al iniciar el módulo
local logFile = fs.open("storage_log.txt", "w")

-- Función para escribir en el log
local function log(message)
    logFile.writeLine(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message)
    logFile.flush() -- Asegúrate de que los datos se escriban en el disco
end

function Storage:new(utilsInstance)
    local self = setmetatable({}, Storage)
    self.utils = utilsInstance
    self:initializeChestData() -- Llama a la función para inicializar los datos del cofre
    return self
end

function Storage:initializeChestData()
    local allData = self.utils:loadAllChestData()
    if next(allData) == nil then -- Verifica si el archivo está vacío
        log("compressed_chest_data.txt está vacío. Iniciando análisis de cofres conectados...")

        -- Detectar cofres conectados y sus contenidos
        local chests = self.utils:getConnectedChests()
        for _, chest in ipairs(chests) do
            local chestName = peripheral.getName(chest)
            local chestItems = chest.list()
            local chestData = {}

            for slot, item in pairs(chestItems) do
                if item.name and item.count then
                    table.insert(chestData, {item.name, item.count})
                end
            end

            allData[chestName] = chestData
            log("Análisis completado para " .. chestName .. " con " .. #chestData .. " items registrados.")
        end

        -- Guarda los datos iniciales de todos los cofres en compressed_chest_data.txt
        self.utils:saveAllChestData(allData)
        log("Datos iniciales de cofres guardados en compressed_chest_data.txt")
    else
        log("compressed_chest_data.txt ya tiene datos. No se necesita inicialización.")
    end
end

function Storage:getItemDetail(chest, slot)
    local items = chest.list()
    local item = items[slot]
    if item and item.name and item.count then
        return {name = item.name, count = item.count}
    else
        return nil -- Slot está vacío o datos incompletos
    end
end

function Storage:updateChestData(chestName, itemName, count)
    local allData = self.utils:loadAllChestData()
    local chestData = allData[chestName] or {}

    local found = false
    for _, item in ipairs(chestData) do
        if item[1] == itemName then
            item[2] = math.max(0, item[2] + count)
            if item[2] == 0 then
                found = false
            else
                found = true
            end
            break
        end
    end

    if not found and count > 0 then
        table.insert(chestData, {itemName, count})
    end

    local actualChest = peripheral.wrap(chestName)
    if actualChest then
        local actualItems = actualChest.list()
        local verifiedChestData = {}

        for slot, actualItem in pairs(actualItems) do
            if actualItem.name and actualItem.count and actualItem.count > 0 then
                table.insert(verifiedChestData, {actualItem.name, actualItem.count})
            end
        end

        chestData = verifiedChestData
    end

    allData[chestName] = #chestData > 0 and chestData or {}
    self.utils:saveAllChestData(allData)
end

function Storage:storeItems(notify, showProgress)
    local config = self.utils:loadData("config.txt")
    local centralChest = peripheral.wrap(config.centralChest)
    if not centralChest then
        notify("Error: No se pudo encontrar el cofre central.")
        return
    end

    local items = centralChest.list()
    local totalItems = #items
    local transferredItems = 0

    for slot, item in pairs(items) do
        local itemDetail = self:getItemDetail(centralChest, slot)
        if itemDetail then
            local category = self:categorizeItem(itemDetail.name)
            local targetChests = category and config.categories[category] or config.categories["randomItems"]
            local transferred = 0

            for _, chestName in ipairs(targetChests) do
                local targetChest = peripheral.wrap(chestName)
                if targetChest then
                    transferred = centralChest.pushItems(peripheral.getName(targetChest), slot)
                    self:updateChestData(peripheral.getName(targetChest), itemDetail.name, transferred)
                    if transferred > 0 then
                        break
                    end
                end
            end

            if transferred == 0 then
                notify("Todos los cofres de la categoría " .. (category or "randomItems") .. " están llenos.")
            end

            transferredItems = transferredItems + 1
            showProgress(transferredItems, totalItems)
        end
    end
end

function Storage:retrieveItems(itemName, count, notify, showProgress)
    local config = self.utils:loadData("config.txt")
    local centralChest = peripheral.wrap(config.centralChest)
    if not centralChest then
        notify("Error: No se pudo encontrar el cofre central.")
        return
    end

    local allData = self.utils:loadAllChestData()
    local remaining = count
    local checkedChests = 0
    local totalChests = 0
    for _ in pairs(allData) do
        totalChests = totalChests + 1
    end

    for chestName, chestData in pairs(allData) do
        local chest = peripheral.wrap(chestName)
        if chest then
            for slot, item in ipairs(chestData) do
                local itemDetail = self:getItemDetail(chest, slot)
                if itemDetail and itemDetail.name == itemName then
                    local availableCount = itemDetail.count
                    local toTransfer = math.min(remaining, availableCount)

                    if toTransfer > 0 then
                        local transferred = chest.pushItems(peripheral.getName(centralChest), slot, toTransfer)
                        if transferred > 0 then
                            item[2] = math.max(0, item[2] - transferred)
                            remaining = remaining - transferred

                            local newItemDetail = self:getItemDetail(chest, slot)
                            if newItemDetail and newItemDetail.count ~= item[2] then
                                log("Advertencia: Inconsistencia en la cantidad de " .. itemName .. " en " .. chestName)
                            elseif not newItemDetail then
                                log("Advertencia: Slot vacío después de transferencia en " .. chestName)
                            end

                            if remaining <= 0 then
                                self.utils:saveAllChestData(allData)
                                return
                            end
                        end
                    end
                end
            end
        end
        checkedChests = checkedChests + 1
        showProgress(checkedChests, totalChests)
    end

    self.utils:saveAllChestData(allData)
end

function Storage:searchItems(keyword)
    local allData = self.utils:loadAllChestData()
    local foundItems = {}

    for chestName, chestData in pairs(allData) do
        for _, item in ipairs(chestData) do
            if string.match(item[1]:lower(), keyword:lower()) then
                if foundItems[item[1]] then
                    foundItems[item[1]].count = foundItems[item[1]].count + item[2]
                else
                    foundItems[item[1]] = {name = item[1], count = item[2]}
                end
            end
        end
    end

    return foundItems
end

function Storage:categorizeItem(itemName)
    local categories = self.utils:loadData("categories.txt") or {}
    for _, category in ipairs(categories) do
        if self.utils:contains(category.items, itemName) then
            return category.name
        end
    end
    return nil
end

function Storage:getCategories()
    local categoriesData = self.utils:loadData("categories.txt") or {}
    local categories = {}
    for _, category in ipairs(categoriesData) do
        table.insert(categories, category.name)
    end
    table.sort(categories)
    return categories
end

function Storage:addCategory(name, items)
    local categories = self.utils:loadData("categories.txt") or {}
    for _, category in ipairs(categories) do
        if category.name == name then
            -- La categoría ya existe
            print("La categoria '" .. name .. "' ya existe.")
            return false
        end
    end
    -- Agregar la nueva categoría
    table.insert(categories, {name = name, items = items})
    self.utils:saveData("categories.txt", categories)
    return true
end

function Storage:updateCategory(name, newItems)
    local categories = self.utils:loadData("categories.txt") or {}
    local found = false
    for _, category in ipairs(categories) do
        if category.name == name then
            category.items = newItems
            found = true
            break
        end
    end
    if found then
        self.utils:saveData("categories.txt", categories)
        return true
    else
        -- La categoría no existe
        print("La categoria '" .. name .. "' no existe.")
        return false
    end
end

function Storage:deleteCategory(name)
    local categories = self.utils:loadData("categories.txt") or {}
    local indexToRemove = nil
    for i, category in ipairs(categories) do
        if category.name == name then
            indexToRemove = i
            break
        end
    end
    if indexToRemove then
        table.remove(categories, indexToRemove)
        self.utils:saveData("categories.txt", categories)
        return true
    else
        -- La categoría no existe
        print("La categoria '" .. name .. "' no existe.")
        return false
    end
end

function Storage:closeLog()
    logFile.close()
end

return Storage
