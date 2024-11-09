local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard:new(UtilsInstance)
    local self = setmetatable({}, Dashboard)
    self.utils = UtilsInstance
    return self
end

function Dashboard:clearMonitor(monitor)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

function Dashboard:displayHeader(monitor)
    monitor.setTextColor(colors.yellow)
    monitor.setCursorPos(1, 1)
    monitor.write("Sistema de Almacenamiento Inteligente")
    monitor.setTextColor(colors.white)
end

function Dashboard:displayCentralChestInfo(monitor, centralChest)
    monitor.setCursorPos(1, 3)
    local itemCount = #centralChest.list()
    local chestSize = centralChest.size()
    local percentFull = math.floor((itemCount / chestSize) * 100)
    monitor.write(string.format("Cofre Central: %d/%d items (%d%% lleno)", itemCount, chestSize, percentFull))
end


function Dashboard:displayOtherChestsInfo(monitor, chests, config, startLine)
    local chestInfo = {}

    for _, chest in ipairs(chests) do
        local chestName = peripheral.getName(chest)
        if chestName ~= config.centralChest then
            local itemCount = #chest.list()
            local chestSize = chest.size()
            local percentFull = math.floor((itemCount / chestSize) * 100)
            table.insert(chestInfo, {
                name = chestName,
                count = itemCount,
                size = chestSize,
                percent = percentFull
            })
        end
    end

    table.sort(chestInfo, function(a, b)
        return a.count > b.count
    end)

    local line = startLine
    for _, info in ipairs(chestInfo) do
        local color = colors.green
        if info.percent > 75 then
            color = colors.red
        elseif info.percent > 50 then
            color = colors.orange
        end
        monitor.setCursorPos(1, line)
        monitor.setTextColor(color)
        monitor.write(string.format("%s: %d/%d items (%d%% lleno)", info.name, info.count, info.size, info.percent))
        line = line + 1
    end

    monitor.setTextColor(colors.white)
end

function Dashboard:updateDashboard()
    local config = self.utils:loadData("config.txt")
    if not config or not config.monitor then
        print("Error: Configuración del monitor no encontrada.")
        return
    end

    local monitor = peripheral.wrap(config.monitor)
    if not monitor then
        print("Error: No se pudo encontrar el monitor especificado en la configuración.")
        return
    end

    -- Establecer la escala de texto a un tamaño más pequeño
    monitor.setTextScale(0.5)

    local centralChest = peripheral.wrap(config.centralChest)
    if not centralChest then
        print("Error: No se pudo encontrar el cofre central especificado en la configuración.")
        return
    end

    while true do
        self:clearMonitor(monitor)
        self:displayHeader(monitor)
        self:displayCentralChestInfo(monitor, centralChest)
        local chests = self.utils:getConnectedChests()
        self:displayOtherChestsInfo(monitor, chests, config, 5)

        sleep(8) -- Actualizar cada 8 segundos
    end
end

return Dashboard