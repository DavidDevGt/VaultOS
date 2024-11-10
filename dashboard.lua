local Grid = require("grid")

local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard:new(UtilsInstance)
    local self = setmetatable({}, Dashboard)
    self.utils = UtilsInstance
    self.colors = {
        background = colors.black,
        title = colors.yellow,
        text = colors.white,
        progressFull = colors.lime,
        progressEmpty = colors.gray,
        warning = colors.red,
        info = colors.lightBlue,
        success = colors.green,
    }
    return self
end

function Dashboard:clearMonitor(monitor)
    monitor.setBackgroundColor(self.colors.background)
    monitor.setTextColor(self.colors.text)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

function Dashboard:drawProgressBar(grid, row, col, percentage, width)
    width = math.max(width, 3)
    local filled = math.floor((percentage / 100) * (width - 2))  -- -2 para los corchetes
    local empty = (width - 2) - filled

    grid.monitor.setCursorPos(col, row)

    grid.monitor.setTextColor(self.colors.text)
    grid.monitor.write("[")

    grid.monitor.setTextColor(self.colors.progressFull)
    grid.monitor.write(string.rep("=", filled))

    grid.monitor.setTextColor(self.colors.progressEmpty)
    grid.monitor.write(string.rep("-", empty))

    grid.monitor.setTextColor(self.colors.text)
    grid.monitor.write("]")
end

function Dashboard:formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

function Dashboard:getSystemStatus(percentUsed)
    if percentUsed >= 90 then
        return "CRÍTICO", self.colors.warning
    elseif percentUsed >= 75 then
        return "ALTO", self.colors.warning
    elseif percentUsed >= 50 then
        return "MEDIO", self.colors.info
    else
        return "NORMAL", self.colors.success
    end
end

function Dashboard:formatUptime()
    local uptime = os.day() * 24 + os.time()
    local hours = math.floor(uptime)
    local minutes = math.floor((uptime - hours) * 60)
    return string.format("%dh %dm", hours, minutes)
end

function Dashboard:updateClock(grid)
    local monitor = grid.monitor
    monitor.setTextColor(self.colors.title)

    -- Escribe el título en la primera fila
    local title = "=== VaultOS v1.0 ==="
    local timeStr = textutils.formatTime(os.time(), true)
    local dayStr = "Dia " .. os.day()

    grid:writeInCell(1, 1, title, "center", true, 5)
    grid:writeInCell(2, 1, string.format("%s | %s", timeStr, dayStr), "center", true, 5)
end

function Dashboard:formatLastUpdated(epochTime)
    local seconds = math.floor(epochTime / 1000)
    local minutes = math.floor(seconds / 60) % 60
    local hours = math.floor(seconds / 3600) % 24
    local days = math.floor(seconds / 86400)

    local dayPart = string.format("Dia %d", days)
    local timePart = string.format("%02d:%02d", hours, minutes)
    return dayPart .. " - " .. timePart
end

function Dashboard:drawGeneralTab(grid, startRow)
    local storageInfo = self.utils:getStorageInfo()
    local totalSlots = storageInfo.totalSlots
    local usedSlots = storageInfo.usedSlots
    local percentUsed = math.floor((usedSlots / totalSlots) * 100)
    local chestCount = storageInfo.chestCount

    self.utils:getMostCommonItems(3)
    
    local status, statusColor = self:getSystemStatus(percentUsed)
    grid.monitor.setTextColor(statusColor)
    grid:writeInCell(startRow, 1, string.format("Estado: %s", status), "center", true, 5)
    
    grid.monitor.setTextColor(self.colors.text)

    local statsText = string.format(
        "Slots: %s/%s | Cofres conectados: %d\nUso: %d%% | Uptime: %s",
        self:formatNumber(usedSlots),
        self:formatNumber(totalSlots),
        chestCount,
        percentUsed,
        self:formatUptime()
    )
    
    grid:writeInCell(startRow + 1, 1, statsText, "center", true, 5)

    -- Dibujar barra de progreso
    self:drawProgressBar(grid, startRow + 2, 1, percentUsed, math.min(grid.width, grid.cellWidth * 5))

    if percentUsed >= 90 then
        grid.monitor.setTextColor(self.colors.warning)
        grid:writeInCell(startRow + 3, 1, "! ALERTA !", "center", true, 5)
    end
end

function Dashboard:updateDisplay()
    local config = self.utils:loadData("config.txt")
    local monitor = peripheral.wrap(config.monitor)
    self:clearMonitor(monitor)

    local grid = Grid:new(monitor, 5, 5, 0)

    self:updateClock(grid)
    self:drawGeneralTab(grid, 3)
end

function Dashboard:updateDashboard()
    local config = self.utils:loadData("config.txt")
    local monitor = peripheral.wrap(config.monitor)
    self:clearMonitor(monitor)

    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)

    local grid = Grid:new(monitor, 5, 5, 0)

    -- Llamada inicial para mostrar el contenido desde el inicio
    self:updateDisplay()

    parallel.waitForAny(
        function()
            while true do
                self:updateClock(grid)
                sleep(1)
            end
        end
    )
end

return Dashboard
