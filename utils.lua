local Utils = {}
Utils.__index = Utils

function Utils:new()
    local self = setmetatable({}, Utils)

    self.compressedDataFile = "compressed_chest_data.txt"

    if not fs.exists(self.compressedDataFile) then
        fs.open(self.compressedDataFile, "w").close()
    end

    return self
end

function Utils:saveAllChestData(data)
    local file = fs.open(self.compressedDataFile, "w")
    file.write(textutils.serializeJSON(data))
    file.close()
end

function Utils:loadAllChestData()
    if not fs.exists(self.compressedDataFile) then return {} end
    local file = fs.open(self.compressedDataFile, "r")
    local data = textutils.unserializeJSON(file.readAll()) or {}
    file.close()
    return data
end

function Utils:saveData(filename, data)
    local file = fs.open(filename, "w")
    file.write(textutils.serialize(data))
    file.close()
end

function Utils:loadData(filename)
    if not fs.exists(filename) then return nil end
    local file = fs.open(filename, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
end

function Utils:contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Utils:getConnectedChests()
    local chests = {}
    for _, name in ipairs(peripheral.getNames()) do
        local type = peripheral.getType(name)
        if type == "minecraft:chest" or type == "minecraft:barrel" or type == "storagedrawers:basicdrawers" then
            table.insert(chests, peripheral.wrap(name))
        end
    end
    return chests
end

function Utils:getStorageInfo()
    local chests = self:getConnectedChests()
    local totalSlots = 0
    local usedSlots = 0
    local chestStates = {}

    for _, chest in ipairs(chests) do
        local chestName = peripheral.getName(chest)
        local chestSize = chest.size()
        local itemCount = #chest.list()
        totalSlots = totalSlots + chestSize
        usedSlots = usedSlots + itemCount

        table.insert(chestStates, {
            name = chestName,
            connected = true,
            itemCount = itemCount,
            chestSize = chestSize,
            percentFull = math.floor((itemCount / chestSize) * 100)
        })
    end

    return {
        totalSlots = totalSlots,
        usedSlots = usedSlots,
        chestCount = #chests,
        chestStates = chestStates
    }
end

Utils.cache = {
    mostCommonItems = nil,
    lastUpdated = 0,
    cacheDuration = 30  -- Duración en segundos para actualizar la caché
}

function Utils:getMostCommonItems(limit)
    local currentTime = os.epoch("utc") / 1000
    
    if self.cache.mostCommonItems and (currentTime - self.cache.lastUpdated) < self.cache.cacheDuration then
        return self.cache.mostCommonItems  -- Devolver la caché si aún es válida
    end

    -- Recargar datos si la caché ha expirado
    local itemCounts = {}
    local chests = self:getConnectedChests()

    for _, chest in pairs(chests) do
        local items = chest.list()
        for _, item in pairs(items) do
            local itemName = item.name
            itemCounts[itemName] = (itemCounts[itemName] or 0) + item.count
        end
    end

    local mostCommonItems = {}
    for name, count in pairs(itemCounts) do
        table.insert(mostCommonItems, { name = name, count = count })
    end

    table.sort(mostCommonItems, function(a, b) return a.count > b.count end)
    self.cache.mostCommonItems = mostCommonItems
    self.cache.lastUpdated = currentTime  -- Actualizar `lastUpdated`

    return mostCommonItems
end

function Utils:showLoadingScreen()
    term.clear()
    term.setCursorPos(1, 1)
    local width, height = term.getSize()
    local loadingText = "Inicializando..."
    local message = ""
    local animation = { "-", "\\", "|", "/" }
    local animIndex = 1

    while not _G.initializationComplete do
        term.setCursorPos(math.floor((width - #loadingText) / 2) + 1, math.floor(height / 2) - 2)
        term.clearLine()
        term.write(loadingText)

        term.setCursorPos(2, math.floor(height / 2))
        term.clearLine()
        term.write(message)

        term.setCursorPos(width - 2, height - 1)
        term.write(animation[animIndex])
        animIndex = (animIndex % #animation) + 1

        sleep(0.1)

        message = _G.loadingMessage or ""
    end

    term.clear()
    term.setCursorPos(1, 1)
end

return Utils
