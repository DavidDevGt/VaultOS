local Grid = require("grid")

local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard:new(UtilsInstance)
    local self = setmetatable({}, Dashboard)
    self.utils = UtilsInstance
    self.useEventUpdates = true
    self.activeTab = 1
    self.colors = {
        background = colors.black,
        title = colors.yellow,
        text = colors.white,
        progressFull = colors.lime,
        progressEmpty = colors.gray,
        warning = colors.red,
        header = colors.cyan,
        info = colors.lightBlue,
        success = colors.green,
        tabActive = colors.blue,
        tabInactive = colors.gray,
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
    local filled = math.floor((percentage / 100) * (width - 2))  -- -2 para los corchetes
    local empty = (width - 2) - filled
    
    grid.monitor.setTextColor(self.colors.text)
    local bar = "["
    
    grid.monitor.setTextColor(self.colors.progressFull)
    bar = bar .. string.rep("=", filled)
    
    grid.monitor.setTextColor(self.colors.progressEmpty)
    bar = bar .. string.rep("-", empty)
    
    grid.monitor.setTextColor(self.colors.text)
    bar = bar .. "]"
    
    grid:writeInCell(row, col, bar, "left")
    grid.monitor.setBackgroundColor(self.colors.background)
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
    local timeStr = textutils.formatTime(os.time(), true)
    local dayStr = "Dia " .. os.day()
    grid:writeInCell(1, 1, string.format("VaultOS v1.0 | %s | %s", timeStr, dayStr), "center", true, 5)
end

function Dashboard:drawTabs(grid)
    local tabs = { "General", "Cofres", "Items" }
    local yPosition = 2

    for i, tabName in ipairs(tabs) do
        grid.monitor.setBackgroundColor(i == self.activeTab and self.colors.tabActive or self.colors.tabInactive)
        grid.monitor.setTextColor(self.colors.text)
        local x = (i - 1) * (grid.width / #tabs) + 1
        grid.monitor.setCursorPos(x, yPosition)
        grid.monitor.write(tabName)
    end
    grid.monitor.setBackgroundColor(self.colors.background)
end

function Dashboard:drawTabContent(grid)
    local contentStartRow = 3
    local maxRows = grid:getMaxRows(contentStartRow)

    if self.activeTab == 1 then
        self:drawGeneralTab(grid, contentStartRow, maxRows)
    elseif self.activeTab == 2 then
        self:drawChestDistributionTab(grid, contentStartRow, maxRows)
    elseif self.activeTab == 3 then
        self:drawMostCommonItemsTab(grid, contentStartRow, maxRows)
    end
end

function Dashboard:drawGeneralTab(grid, startRow, maxRows)
    local storageInfo = self.utils:getStorageInfo()
    local totalSlots = storageInfo.totalSlots
    local usedSlots = storageInfo.usedSlots
    local percentUsed = math.floor((usedSlots / totalSlots) * 100)
    local chestCount = storageInfo.chestCount

    local status, statusColor = self:getSystemStatus(percentUsed)
    grid.monitor.setTextColor(statusColor)
    grid:writeInCell(startRow, 1, string.format("Estado: %s", status), "center", true, 5)
    
    grid.monitor.setTextColor(self.colors.text)
    local statsText = string.format(
        "Slots: %s/%s | Cofres: %d\nUso: %d%% | Uptime: %s",
        self:formatNumber(usedSlots),
        self:formatNumber(totalSlots),
        chestCount,
        percentUsed,
        self:formatUptime()
    )
    grid:writeInCell(startRow + 1, 1, statsText, "center", true, 5)

    if maxRows >= 4 then
        self:drawProgressBar(grid, startRow + 2, 1, percentUsed, math.min(grid.width, grid.cellWidth * 5))
    end

    if percentUsed >= 90 and maxRows >= 5 then
        grid.monitor.setTextColor(self.colors.warning)
        grid:writeInCell(startRow + 3, 1, "! ALERTA !", "center", true, 5)
    end
end

function Dashboard:drawChestDistributionTab(grid, startRow, maxRows)
    local storageInfo = self.utils:getStorageInfo()
    grid.monitor.setTextColor(self.colors.text)
    
    for i = 0, maxRows - 1 do
        local chest = storageInfo.chestStates[i + 1]
        if not chest then break end

        local chestText = string.format(
            "Cofre %d: %d/%d slots (%d%% lleno)", 
            i + 1, chest.itemCount, chest.chestSize, chest.percentFull
        )
        grid:writeInCell(startRow + i, 1, chestText, "left")
    end
end

function Dashboard:drawMostCommonItemsTab(grid, startRow, maxRows)
    local items = self.utils:getMostCommonItems(10)
    grid.monitor.setTextColor(self.colors.text)
    
    for i = 0, maxRows - 1 do
        local item = items[i + 1]
        if not item then break end

        local itemText = string.format("%s: %d", item.name, item.count)
        grid:writeInCell(startRow + i, 1, itemText, "left")
    end
end

function Dashboard:updateDisplay()
    local config = self.utils:loadData("config.txt")
    local monitor = peripheral.wrap(config.monitor)
    self:clearMonitor(monitor)

    local grid = Grid:new(monitor, 4, 5, 0)
    self:updateClock(grid)
    self:drawTabs(grid)
    self:drawTabContent(grid)
end

function Dashboard:switchTab(newTab)
    if newTab >= 1 and newTab <= 3 then
        self.activeTab = newTab
        self:updateDisplay()
    end
end

function Dashboard:updateDashboard()
    local config = self.utils:loadData("config.txt")
    local monitor = peripheral.wrap(config.monitor)
    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)

    local grid = Grid:new(monitor, 4, 5, 0)

    -- Llamada inicial para mostrar título, pestañas y contenido desde el inicio
    self:updateDisplay()

    parallel.waitForAny(
        function()
            while true do
                self:updateClock(grid)
                sleep(1)
            end
        end,
        
        function()
            while true do
                local event, side, x, y = os.pullEvent("monitor_touch")
                local width = grid.width / 3
                if x < width then
                    self:switchTab(1)
                elseif x < width * 2 then
                    self:switchTab(2)
                else
                    self:switchTab(3)
                end
            end
        end
    )
end

return Dashboard
