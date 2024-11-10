-- tui.lua (versión actualizada con limpieza de terminal)
local TUI = {}
TUI.__index = TUI

function TUI:new(storageInstance, config)
    local self = setmetatable({}, TUI)

    self.storage = storageInstance
    self.config = config

    self.colors = {
        white = colors.white,
        orange = colors.orange,
        magenta = colors.magenta,
        lightBlue = colors.lightBlue,
        yellow = colors.yellow,
        lime = colors.lime,
        pink = colors.pink,
        gray = colors.gray,
        lightGray = colors.lightGray,
        cyan = colors.cyan,
        purple = colors.purple,
        blue = colors.blue,
        brown = colors.brown,
        green = colors.green,
        red = colors.red,
        black = colors.black,
    }

    self.menuOptions = {
        { text = "1. Gestionar Items", color = self.colors.lightBlue },
        { text = "2. Gestionar Categorias", color = self.colors.yellow },
        { text = "3. Configuracion", color = self.colors.purple },
        { text = "4. Salir", color = self.colors.red },
    }
    return self
end

-- Funciones auxiliares para manejo de colores y visualizacion
function TUI:setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

function TUI:resetColor()
    self:setColor(self.colors.white)
end

function TUI:displayHeader(title)
    term.clear()
    term.setCursorPos(1, 1)
    local width, _ = term.getSize()
    local headerText = title or "VaultOS"
    local line = string.rep("-", width)

    self:setColor(self.colors.cyan)
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
    self:displayHeader("Menu Principal")
    local _, headerHeight = term.getCursorPos()
    local startY = headerHeight + 1
    local width, height = term.getSize()

    local menuHeight = #self.menuOptions
    local availableHeight = height - startY - 2
    local offsetY = math.floor((availableHeight - menuHeight) / 2)
    local currentY = startY + offsetY

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

-- Funciones de notificacion y progreso
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
    -- Después de la notificación, limpiar la pantalla y mostrar el menú actual
    term.clear()
    term.setCursorPos(1, 1)
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

    if current == total then
        sleep(0.5)
        term.setCursorPos(1, y)
        term.clearLine()
    end
end

-- Gestion de Items
function TUI:manageItems()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        local itemMenuOptions = {
            { text = "1. Guardar Items", color = self.colors.lightBlue },
            { text = "2. Recuperar Items", color = self.colors.green },
            { text = "3. Volver al Menu Principal", color = self.colors.red },
        }

        self:displayHeader("Gestion de Items")
        local _, headerHeight = term.getCursorPos()
        local startY = headerHeight + 1
        local width, height = term.getSize()

        local menuHeight = #itemMenuOptions
        local availableHeight = height - startY - 2
        local offsetY = math.floor((availableHeight - menuHeight) / 2)
        local currentY = startY + offsetY

        for _, option in ipairs(itemMenuOptions) do
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

        local choice = tonumber(read())
        if choice == 1 then
            term.clear()
            term.setCursorPos(1, 1)
            self.storage:storeItems(
                function(msg) self:notify(msg) end,
                function(current, total) self:showProgress(current, total) end
            )
            self:notify("Transferencia completada.")
        elseif choice == 2 then
            term.clear()
            term.setCursorPos(1, 1)
            self:searchAndRetrieveItems()
        elseif choice == 3 then
            break
        else
            self:setColor(self.colors.red)
            print("Opcion invalida.")
            self:resetColor()
            sleep(1.5)
            term.clear()
            term.setCursorPos(1, 1)
        end
    end
end

-- Gestion de Categorias
function TUI:manageCategories()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        local categoryMenuOptions = {
            { text = "1. Crear Categoria", color = self.colors.green },
            { text = "2. Listar Categorias", color = self.colors.lightBlue },
            { text = "3. Actualizar Categoria", color = self.colors.yellow },
            { text = "4. Eliminar Categoria", color = self.colors.red },
            { text = "5. Volver al Menu Principal", color = self.colors.red },
        }

        self:displayHeader("Gestion de Categorias")
        local _, headerHeight = term.getCursorPos()
        local startY = headerHeight + 1
        local width, height = term.getSize()

        local menuHeight = #categoryMenuOptions
        local availableHeight = height - startY - 2
        local offsetY = math.floor((availableHeight - menuHeight) / 2)
        local currentY = startY + offsetY

        for _, option in ipairs(categoryMenuOptions) do
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

        local choice = tonumber(read())
        if choice == 1 then
            term.clear()
            term.setCursorPos(1, 1)
            self:createCategory()
        elseif choice == 2 then
            term.clear()
            term.setCursorPos(1, 1)
            self:listCategories()
        elseif choice == 3 then
            term.clear()
            term.setCursorPos(1, 1)
            self:updateCategory()
        elseif choice == 4 then
            term.clear()
            term.setCursorPos(1, 1)
            self:deleteCategory()
        elseif choice == 5 then
            break
        else
            self:setColor(self.colors.red)
            print("Opcion invalida.")
            self:resetColor()
            sleep(1.5)
            term.clear()
            term.setCursorPos(1, 1)
        end
    end
end

function TUI:createCategory()
    self:displayHeader("Crear Categoria")
    self:setColor(self.colors.yellow)
    print("Ingrese el nombre de la nueva categoria: ")
    self:resetColor()
    local name = read()

    if self.storage:categoryExists(name) then
        self:setColor(self.colors.red)
        self:notify("La categoria '" .. name .. "' ya existe.")
        self:resetColor()
        return
    end

    self:setColor(self.colors.yellow)
    print("Ingrese los items separados por comas: ")
    self:resetColor()
    local items = {}
    for item in string.gmatch(read(), '([^,]+)') do
        table.insert(items, item:match("^%s*(.-)%s*$")) -- Eliminar espacios en blanco
    end

    local success = self.storage:addCategory(name, items)
    if success then
        self:notify("Categoria '" .. name .. "' creada exitosamente.")
    else
        self:setColor(self.colors.red)
        self:notify("Error al crear la categoria.")
        self:resetColor()
    end
end

function TUI:listCategories()
    self:displayHeader("Listado de Categorias")
    local categories = self.storage:getCategories()
    if #categories == 0 then
        self:setColor(self.colors.red)
        print("No hay categorias disponibles.")
        self:resetColor()
    else
        self:setColor(self.colors.lightBlue)
        for i, category in ipairs(categories) do
            print(string.format("  %d. %s", i, category))
        end
        self:resetColor()
    end
    self:setColor(self.colors.white)
    print("\nPresione Enter para continuar...")
    self:resetColor()
    read()
    term.clear()
    term.setCursorPos(1, 1)
end

function TUI:updateCategory()
    self:displayHeader("Actualizar Categoria")
    local categories = self.storage:getCategories()
    if #categories == 0 then
        self:setColor(self.colors.red)
        print("No hay categorias disponibles.")
        self:resetColor()
        sleep(1.5)
        return
    end
    self:listCategories()

    self:setColor(self.colors.yellow)
    print("Ingrese el nombre de la categoria a actualizar: ")
    self:resetColor()
    local name = read()

    if not self.storage:categoryExists(name) then
        self:setColor(self.colors.red)
        self:notify("La categoria '" .. name .. "' no existe.")
        self:resetColor()
        return
    end

    self:setColor(self.colors.yellow)
    print("Ingrese los nuevos items separados por comas: ")
    self:resetColor()
    local items = {}
    for item in string.gmatch(read(), '([^,]+)') do
        table.insert(items, item:match("^%s*(.-)%s*$")) -- Eliminar espacios en blanco
    end

    local success = self.storage:updateCategory(name, items)
    if success then
        self:notify("Categoria '" .. name .. "' actualizada exitosamente.")
    else
        self:setColor(self.colors.red)
        self:notify("Error al actualizar la categoria.")
        self:resetColor()
    end
end

function TUI:deleteCategory()
    self:displayHeader("Eliminar Categoria")
    local categories = self.storage:getCategories()
    if #categories == 0 then
        self:setColor(self.colors.red)
        print("No hay categorias disponibles.")
        self:resetColor()
        sleep(1.5)
        return
    end
    self:listCategories()

    self:setColor(self.colors.yellow)
    print("Ingrese el nombre de la categoria a eliminar: ")
    self:resetColor()
    local name = read()

    if not self.storage:categoryExists(name) then
        self:setColor(self.colors.red)
        self:notify("La categoria '" .. name .. "' no existe.")
        self:resetColor()
        return
    end

    -- Confirmacion antes de eliminar
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
            self:notify("Error al eliminar la categoria.")
            self:resetColor()
        end
    else
        self:notify("Operacion cancelada.")
    end
end

-- Function to search and retrieve items
function TUI:searchAndRetrieveItems()
    local currentPage = 1
    local itemList = {}
    local keyword = ""

    -- Function to calculate items per page based on terminal size
    local function calculateItemsPerPage()
        local width, height = term.getSize()
        -- Estimate lines used for fixed UI elements
        local fixedLines = 1 -- Header
        fixedLines = fixedLines + 2 -- Search display ("Busqueda actual", empty line)
        fixedLines = fixedLines + 1 -- Separator line
        fixedLines = fixedLines + 1 -- Page info
        fixedLines = fixedLines + 2 -- "Opciones:" and empty line
        fixedLines = fixedLines + 5 -- Maximum possible options
        local availableLines = height - fixedLines
        local linesPerItem = 3 -- Lines used per item
        local itemsPerPage = math.floor(availableLines / linesPerItem)
        if itemsPerPage < 1 then
            itemsPerPage = 1
        end
        return itemsPerPage
    end

    local itemsPerPage = calculateItemsPerPage()

    -- Function to display the current page of results
    local function displaySearchResults(page, items)
        local width, height = term.getSize()
        itemsPerPage = calculateItemsPerPage()

        self:displayHeader("Resultados de Busqueda")

        -- Show the current search
        self:setColor(self.colors.yellow)
        print("Busqueda actual: '" .. keyword .. "'")
        print()
        self:resetColor()

        -- Calculate indices of the current page
        local startIndex = (page - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, #items)
        local totalPages = math.ceil(#items / itemsPerPage)

        -- Display items
        for i = startIndex, endIndex do
            local item = items[i]
            local prefix = string.format("%d. ", i)
            local maxNameWidth = width - string.len(prefix)
            local itemName = item.name
            if string.len(itemName) > maxNameWidth then
                itemName = string.sub(itemName, 1, maxNameWidth - 3) .. "..."
            end
            self:setColor(self.colors.lightBlue)
            print(prefix .. itemName)
            self:resetColor()
            self:setColor(self.colors.green)
            print(string.format("   Cantidad disponible: %d", item.count))
            self:resetColor()
            print() -- Space between items
        end

        -- Show navigation
        print(string.rep("-", width))

        -- Display available options
        self:setColor(self.colors.lightGray)
        print(string.format("Pagina %d de %d", page, totalPages))
        print()
        self:setColor(self.colors.white)
        print("Opciones:")
        print("1. Seleccionar item")
        if currentPage < totalPages then
            print("2. Siguiente pagina")
        end
        if currentPage > 1 then
            print("3. Pagina anterior")
        end
        print("4. Nueva busqueda")
        print("5. Volver al menu")
        self:resetColor()
    end

    -- Main search function
    local function performSearch()
        self:displayHeader("Buscar Items")
        self:setColor(self.colors.yellow)
        print("Ingrese el nombre del item a buscar:")
        print("(puede ser parte del nombre)")
        self:resetColor()

        keyword = read()
        if keyword == "" then
            self:notify("Busqueda cancelada")
            return false
        end

        local results = self.storage:searchItems(keyword)
        if not next(results) then
            self:notify("No se encontraron items para '" .. keyword .. "'")
            return false
        end

        -- Convert results to ordered list
        itemList = {}
        for _, item in pairs(results) do
            table.insert(itemList, item)
        end
        table.sort(itemList, function(a, b) return a.name < b.name end)

        return true
    end

    -- Function to retrieve an item
    local function retrieveItem()
        self:setColor(self.colors.yellow)
        print("\nIngrese el numero del item que desea recuperar (1-" .. #itemList .. "):")
        self:resetColor()

        local choice = tonumber(read())
        if not choice or choice < 1 or choice > #itemList then
            self:notify("Numero de item invalido")
            return false
        end

        local item = itemList[choice]
        local width = term.getSize()
        local prompt = "Cuantos " .. item.name .. " desea recuperar? (maximo " .. item.count .. "):"
        if string.len(prompt) > width then
            -- Truncate item.name if necessary
            local maxNameWidth = width - string.len("Cuantos ") - string.len(" desea recuperar? (maximo " .. item.count .. "):")
            if maxNameWidth > 3 then
                itemName = string.sub(item.name, 1, maxNameWidth - 3) .. "..."
            else
                itemName = "..."
            end
            prompt = "Cuantos " .. itemName .. " desea recuperar? (maximo " .. item.count .. "):"
        end
        self:setColor(self.colors.yellow)
        print(prompt)
        self:resetColor()

        local count = tonumber(read())
        if not count or count < 1 or count > item.count then
            self:notify("Cantidad invalida")
            return false
        end

        -- Perform transfer
        self.storage:retrieveItems(
            item.name,
            count,
            function(msg) self:notify(msg) end,
            function(current, total) self:showProgress(current, total) end
        )

        -- Update the list after transfer
        item.count = item.count - count
        if item.count == 0 then
            -- Remove item from list if no longer available
            for i, listItem in ipairs(itemList) do
                if listItem.name == item.name then
                    table.remove(itemList, i)
                    break
                end
            end
        end

        self:notify("Se recuperaron " .. count .. " " .. item.name)
        return true
    end

    -- Main loop
    if not performSearch() then
        return
    end

    while true do
        term.clear()
        term.setCursorPos(1, 1)

        -- Recalculate itemsPerPage in case terminal size has changed
        itemsPerPage = calculateItemsPerPage()

        -- If no items left after transfer, search again
        if #itemList == 0 then
            self:notify("No hay mas items disponibles")
            if not performSearch() then
                return
            end
            currentPage = 1
        end

        displaySearchResults(currentPage, itemList)

        self:setColor(self.colors.white)
        write("\nSeleccione una opcion: ")
        self:resetColor()

        local choice = tonumber(read())
        if not choice then
            self:notify("Opcion invalida")
        else
            local totalPages = math.ceil(#itemList / itemsPerPage)

            if choice == 1 then
                -- Select and retrieve item
                if retrieveItem() then
                    -- Adjust current page if necessary
                    if #itemList <= (currentPage - 1) * itemsPerPage and currentPage > 1 then
                        currentPage = currentPage - 1
                    end
                end
            elseif choice == 2 and currentPage < totalPages then
                -- Next page
                currentPage = currentPage + 1
            elseif choice == 3 and currentPage > 1 then
                -- Previous page
                currentPage = currentPage - 1
            elseif choice == 4 then
                -- New search
                if not performSearch() then
                    return
                end
                currentPage = 1
            elseif choice == 5 then
                -- Return to menu
                break
            else
                self:notify("Opcion invalida")
            end
        end
    end
end

-- Gestion de Configuracion
function TUI:manageConfig()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        self:displayHeader("Configuracion")
        local configMenuOptions = {
            { text = "1. Ver Configuracion Actual", color = self.colors.lightBlue },
            { text = "2. Modificar Configuracion", color = self.colors.yellow },
            { text = "3. Volver al Menu Principal", color = self.colors.red },
        }

        local _, headerHeight = term.getCursorPos()
        local startY = headerHeight + 1
        local width, height = term.getSize()

        local menuHeight = #configMenuOptions
        local availableHeight = height - startY - 2
        local offsetY = math.floor((availableHeight - menuHeight) / 2)
        local currentY = startY + offsetY

        for _, option in ipairs(configMenuOptions) do
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

        local choice = tonumber(read())
        if choice == 1 then
            term.clear()
            term.setCursorPos(1, 1)
            self:displayCurrentConfig()
        elseif choice == 2 then
            term.clear()
            term.setCursorPos(1, 1)
            self:launchConfigEditor()
        elseif choice == 3 then
            break
        else
            self:setColor(self.colors.red)
            print("Opcion invalida.")
            self:resetColor()
            sleep(1.5)
            term.clear()
            term.setCursorPos(1, 1)
        end
    end
end

function TUI:displayCurrentConfig()
    self:displayHeader("Configuracion Actual")
    self:setColor(self.colors.lightBlue)
    print(textutils.serialize(self.config))
    self:resetColor()
    self:setColor(self.colors.white)
    print("\nPresione Enter para continuar...")
    self:resetColor()
    read()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Function to launch the configuration editor using code.lua
function TUI:launchConfigEditor()
    self:displayHeader("Modificar Configuracion")
    self:setColor(self.colors.yellow)
    print("Abriendo el editor para modificar 'config.txt'...")
    self:resetColor()

    -- Check if code.lua exists
    if not fs.exists("code.lua") then
        self:setColor(self.colors.red)
        print("El archivo 'code.lua' no se encontro. Por favor, instale code.lua antes de continuar.")
        self:resetColor()
        print("\nPresione Enter para continuar...")
        read()
        return
    end

    -- Open config.txt using code.lua
    shell.run("code.lua config.txt")

    -- After editing, reload the configuration
    if fs.exists("config.txt") then
        self:loadConfig()
        self:notify("Configuracion actualizada.")
    else
        self:notify("El archivo 'config.txt' no existe o fue eliminado.")
    end
end

-- Function to load the configuration from 'config.txt'
function TUI:loadConfig()
    local configFile = fs.open("config.txt", "r")
    if configFile then
        local content = configFile.readAll()
        configFile.close()
        -- Deserialize the configuration
        local configData = textutils.unserialize(content)
        if configData then
            self.config = configData
        else
            self:notify("Error al cargar la configuracion. El formato es invalido.")
        end
    else
        self:notify("No se pudo abrir 'config.txt'.")
    end
end

function TUI:saveConfig()
    local configFile = fs.open("config.txt", "w")
    configFile.write(textutils.serialize(self.config))
    configFile.close()
end

-- Funcion principal para manejar la entrada del usuario
function TUI:handleInput()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        self:displayMenu()
        local choice = tonumber(read())

        if choice == 1 then
            self:manageItems()
        elseif choice == 2 then
            self:manageCategories()
        elseif choice == 3 then
            self:manageConfig()
        elseif choice == 4 then
            self:setColor(self.colors.purple)
            print("Esta seguro que desea salir? (s/n): ")
            self:resetColor()
            local confirm = read()
            if confirm == 's' or confirm == 'S' then
                self:setColor(self.colors.purple)
                print("Saliendo del sistema...")
                self:resetColor()
                sleep(1.5)
                term.clear()
                term.setCursorPos(1, 1)
                break
            else
                self:notify("Operacion cancelada.")
            end
        else
            self:setColor(self.colors.red)
            print("Opcion invalida.")
            self:resetColor()
            sleep(1.5)
            term.clear()
            term.setCursorPos(1, 1)
        end
    end
end

return TUI
