local Grid = {}
Grid.__index = Grid

function Grid:new(monitor, rows, cols, margin)
    local self = setmetatable({}, Grid)
    self.monitor = monitor
    self.rows = rows
    self.cols = cols
    self.margin = margin or 0

    local width, height = monitor.getSize()
    self.width = width
    self.height = height

    self.cellWidth = math.floor((width - (cols + 1) * self.margin) / cols)
    self.cellHeight = math.floor((height - (rows + 1) * self.margin) / rows)

    return self
end

function Grid:getCellArea(row, col)
    local x = (col - 1) * (self.cellWidth + self.margin) + self.margin + 1
    local y = (row - 1) * (self.cellHeight + self.margin) + self.margin + 1
    return x, y, self.cellWidth, self.cellHeight
end

function Grid:writeInCell(row, col, text, align, fullWidth, spanCols)
    local x, y, cellWidth, cellHeight = self:getCellArea(row, col)
    if fullWidth then
        cellWidth = self.cellWidth * (spanCols or 1)
    end
    
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local startY = y
    for i, line in ipairs(lines) do
        if startY + i - 1 > y + cellHeight - 1 then
            break
        end
        
        local lineX = x
        if align == "center" then
            lineX = x + math.floor((cellWidth - #line) / 2)
        elseif align == "right" then
            lineX = x + cellWidth - #line
        end
        
        self.monitor.setCursorPos(lineX, startY + i - 1)
        self.monitor.write(line:sub(1, cellWidth))  -- Limite del texto al ancho de la celda
    end
end

function Grid:getMaxRows(startRow)
    return self.height - startRow + 1
end

return Grid
