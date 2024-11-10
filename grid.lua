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
    
    self.colors = {
        background = colors.black,
        text = colors.white,
        button = colors.gray,
        buttonHover = colors.lightGray,
        buttonActive = colors.blue,
    }    

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
        self.monitor.write(line:sub(1, cellWidth))  -- Limitando el texto al ancho de la celda
    end
end

function Grid:getMaxRows(startRow)
    return self.height - startRow + 1
end

function Grid:writePagedContent(startRow, col, data, maxRows, align, currentPage, itemsPerPage)
    itemsPerPage = itemsPerPage or maxRows
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #data)
    
    for i = startIndex, endIndex do
        local item = data[i]
        if not item then break end
        self:writeInCell(startRow + (i - startIndex), col, item, align or "left")
    end
end

function Grid:drawPaginationControls(currentPage, totalPages)
    local controlRow = self.rows
    local prevButton = "< Anterior"
    local nextButton = "Siguiente >"
    
    -- Dibujar botón Anterior
    self.monitor.setBackgroundColor(self.colors.button)
    self.monitor.setTextColor(self.colors.text)
    self:writeInCell(controlRow, 1, prevButton, "center", false, 2)
    local prevButtonWidth = #prevButton  -- Ancho del botón "Anterior"
    
    -- Dibujar número de página
    local pageInfo = string.format("Página %d/%d", currentPage, totalPages)
    self:writeInCell(controlRow, math.ceil(self.cols / 2), pageInfo, "center", false, 1)
    
    -- Dibujar botón Siguiente
    self:writeInCell(controlRow, self.cols - 1, nextButton, "center", false, 2)
    local nextButtonWidth = #nextButton  -- Ancho del botón "Siguiente"
    
    -- Restaurar colores
    self.monitor.setBackgroundColor(self.colors.background)
    self.monitor.setTextColor(self.colors.text)

    -- Guardamos el ancho de los botones para su uso en `isPaginationButtonTouched`
    self.prevButtonWidth = prevButtonWidth
    self.nextButtonWidth = nextButtonWidth
end

function Grid:isPaginationButtonTouched(x, y, currentPage, totalPages)
    local controlRow = self.rows
    if y ~= controlRow then return nil end

    -- Calcular posición para el botón "Anterior"
    local prevStartX, _, prevWidth = self:getCellArea(controlRow, 1)
    local prevEndX = prevStartX + self.prevButtonWidth

    -- Calcular posición para el botón "Siguiente"
    local nextStartX, _, nextWidth = self:getCellArea(controlRow, self.cols - 1)
    local nextEndX = nextStartX + self.nextButtonWidth

    if x >= prevStartX and x <= prevEndX then
        return "prev"
    elseif x >= nextStartX and x <= nextEndX then
        return "next"
    end
    return nil
end

return Grid
