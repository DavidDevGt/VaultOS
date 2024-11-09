local TUI = {}
TUI.__index = TUI

function TUI:new(storageInstance)
    local self = setmetatable({}, TUI)

    self.storage = storageInstance

    self.colors = {
        white = 1,
        orange = 2,
        magenta = 4,
        lightBlue = 8,
        yellow = 16,
        lime = 32,
        pink = 64,
        gray = 128,
        lightGray = 256,
        cyan = 512,
        purple = 1024,
        blue = 2048,
        brown = 4096,
        green = 8192,
        red = 16384,
        black = 32768,
    }

    self.menuOptions = {
        { text = "1. Guardar Items", color = self.colors.lightBlue },
        { text = "2. Recuperar Items", color = self.colors.green },
        { text = "3. Agregar Categoria", color = self.colors.yellow },
        { text = "4. Actualizar Categoria", color = self.colors.orange },
        { text = "5. Eliminar Categoria", color = self.colors.red },
        { text = "6. Salir", color = self.colors.purple },
    }
    return self
end

function TUI:setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

function TUI:resetColor()
    self:setColor(self.colors.white)
end

function TUI:displayHeader()
    term.clear()
    local width, _ = term.getSize()
    local headerText = " VaultOS "
    local line = string.rep("-", width)

    self:setColor(self.colors.cyan)
    term.setCursorPos(1, 1)
    print(line)
    term.setCursorPos(math.floor((width - #headerText) / 2) + 1, 2)
    print(headerText)
    term.setCursorPos(1, 3)
    print(line)
    self:resetColor()
end

function TUI:centerText(text, y, color)
    local width, _ = term.getSize()
    local x = math.floor((width - #text) / 2) + 1
    term.setCursorPos(x, y)
    if color then
        self:setColor(color)
    end
    print(text)
    if color then
        self:resetColor()
    end
end

function TUI:displayMenu()
    self:displayHeader()
    local _, headerHeight = term.getCursorPos()
    local startY = headerHeight + 1
    local width, height = term.getSize()
    
    local menuHeight = #self.menuOptions
    local availableHeight = height - startY - 2
    local offsetY = math.floor((availableHeight - menuHeight) / 2)
    local currentY = startY + offsetY

    -- Mostramos las opciones del menú
    for _, option in ipairs(self.menuOptions) do
        self:centerText(option.text, currentY, option.color)
        currentY = currentY + 1
    end

    self:setColor(self.colors.cyan)
    term.setCursorPos(1, height - 1)
    print(string.rep("-", width))
    self:resetColor()
    
    term.setCursorPos(1, height)
    self:setColor(self.colors.white)
    write("Seleccione una opcion: ")
    self:resetColor()
end

function TUI:notify(message, color)
    color = color or self.colors.yellow
    self:setColor(color)
    local width, height = term.getSize()
    local x = 2
    local y = height - 2
    term.setCursorPos(x, y)
    term.clearLine()
    print("** " .. message)
    self:resetColor()
    sleep(1.5)
    term.setCursorPos(x, y)
    term.clearLine()
end

function TUI:showProgress(current, total)
    local percent = math.floor((current / total) * 100)
    local width, height = term.getSize()
    local barWidth = width - 10
    local filledLength = math.floor((percent / 100) * barWidth)
    local emptyLength = barWidth - filledLength
    local bar = "[" .. string.rep("=", filledLength) .. string.rep(" ", emptyLength) .. "]"
    
    local y = height - 1
    term.setCursorPos(1, y)
    self:setColor(self.colors.lightGray)
    term.clearLine()
    self:setColor(self.colors.green)
    term.write(bar)
    term.write(" " .. percent .. "%")
    self:resetColor()
    
    -- Limpiar la barra si se ha completado
    if current == total then
        sleep(0.5)
        term.setCursorPos(1, y)
        term.clearLine()
    end
end

function TUI:searchAndRetrieveItems()
    self:displayHeader()
    self:setColor(self.colors.yellow)
    print("Ingrese el nombre del item a buscar: ")
    self:resetColor()

    local keyword = read()
    local results = self.storage:searchItems(keyword)

    if not next(results) then
        self:setColor(self.colors.red)
        print("No se encontraron items para el término ingresado.")
        self:resetColor()
        return
    end

    self:setColor(self.colors.lightGray)
    print("\nItems encontrados:")
    self:resetColor()
    
    local itemList = {}
    for name, item in pairs(results) do
        table.insert(itemList, item)
    end

    for i, item in ipairs(itemList) do
        self:setColor(self.colors.lightBlue)
        print(string.format("   %d. %-20s", i, item.name))
        self:resetColor()
        self:setColor(self.colors.green)
        print(string.format("       Cantidad disponible: %d", item.count))
        self:resetColor()
    end

    self:setColor(self.colors.yellow)
    print("\nIngrese el numero del item a recuperar: ")
    self:resetColor()
    local choice = tonumber(read())

    if choice and itemList[choice] then
        local item = itemList[choice]
        self:setColor(self.colors.yellow)
        print("Ingrese la cantidad a recuperar: ")
        self:resetColor()
        local count = tonumber(read())
        
        if count and count > 0 then
            self.storage:retrieveItems(
                item.name,
                count,
                function(msg) self:notify(msg) end,
                function(current, total) self:showProgress(current, total) end
            )
            self:setColor(self.colors.green)
            self:notify("Transferencia completada: " .. count .. " de " .. item.name)
            self:resetColor()
        else
            self:setColor(self.colors.red)
            print("Cantidad invalida.")
            self:resetColor()
        end
    else
        self:setColor(self.colors.red)
        print("Seleccion invalida.")
        self:resetColor()
    end
end

function TUI:handleInput()
    while true do
        self:displayMenu()
        local choice = tonumber(read())

        if choice == 1 then
            self.storage:storeItems(function(msg) self:notify(msg) end, function(current, total) self:showProgress(current, total) end)
            self:notify("Transferencia completada.")
        elseif choice == 2 then
            self:searchAndRetrieveItems()
        elseif choice == 3 then
            self:displayHeader()
            -- Mostrar categorías existentes
            self:setColor(self.colors.lightGray)
            print("Categorias existentes:")
            self:resetColor()
            local categories = self.storage:getCategories()
            for i, category in ipairs(categories) do
                print("  " .. i .. ". " .. category)
            end

            print("\nIngrese el nombre de la nueva categoria: ")
            local name = read()
            print("Ingrese los items separados por comas: ")
            local items = {}
            for item in string.gmatch(read(), '([^,]+)') do
                table.insert(items, item)
            end
            local success = self.storage:addCategory(name, items)
            if success then
                self:notify("Categoria '" .. name .. "' agregada exitosamente.")
            else
                self:setColor(self.colors.red)
                self:notify("La categoria '" .. name .. "' ya existe.")
                self:resetColor()
            end
        elseif choice == 4 then
            self:displayHeader()
            -- Mostrar categorías existentes
            self:setColor(self.colors.lightGray)
            print("Categorias existentes:")
            self:resetColor()
            local categories = self.storage:getCategories()
            for i, category in ipairs(categories) do
                print("  " .. i .. ". " .. category)
            end

            print("\nIngrese el nombre de la categoria a actualizar: ")
            local name = read()
            print("Ingrese los nuevos items separados por comas: ")
            local items = {}
            for item in string.gmatch(read(), '([^,]+)') do
                table.insert(items, item)
            end
            local success = self.storage:updateCategory(name, items)
            if success then
                self:notify("Categoria '" .. name .. "' actualizada exitosamente.")
            else
                self:setColor(self.colors.red)
                self:notify("La categoria '" .. name .. "' no existe.")
                self:resetColor()
            end
        elseif choice == 5 then
            self:displayHeader()
            -- Mostrar categorías existentes
            self:setColor(self.colors.lightGray)
            print("Categorias existentes:")
            self:resetColor()
            local categories = self.storage:getCategories()
            for i, category in ipairs(categories) do
                print("  " .. i .. ". " .. category)
            end

            print("\nIngrese el nombre de la categoria a eliminar: ")
            local name = read()
            -- Confirmación antes de eliminar
            self:setColor(self.colors.red)
            print("Esta seguro que desea eliminar la categoria '" .. name .. "'? (s/n): ")
            self:resetColor()
            local confirm = read()
            if confirm == 's' or confirm == 'S' then
                local success = self.storage:deleteCategory(name)
                if success then
                    self:notify("Categoria '" .. name .. "' eliminada exitosamente.")
                else
                    self:setColor(self.colors.red)
                    self:notify("La categoria '" .. name .. "' no existe.")
                    self:resetColor()
                end
            else
                self:notify("Operacion cancelada. Regresando al menu principal.")
            end
        elseif choice == 6 then
            self:setColor(self.colors.purple)
            print("Esta seguro que desea salir? (s/n): ")
            self:resetColor()
            local confirm = read()
            if confirm == 's' or confirm == 'S' then
                self:setColor(self.colors.purple)
                print("Saliendo del sistema...")
                self:resetColor()
                break
            else
                self:notify("Operacion cancelada. Regresando al menu principal.")
            end
        else
            self:setColor(self.colors.red)
            print("Opcion invalida.")
            self:resetColor()
        end
    end
end

return TUI
