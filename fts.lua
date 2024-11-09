-- fts.lua

local Utils = require("utils")

local function paginado(lista, elementosPorPagina, titulo)
    elementosPorPagina = elementosPorPagina or 10
    local fullList = lista
    local currentList = fullList
    local totalElementos = #currentList
    local totalPaginas = math.ceil(totalElementos / elementosPorPagina)
    local paginaActual = 1

    while true do
        term.clear()
        term.setCursorPos(1, 1)
        if titulo then
            print(titulo)
            print("-------------------------------------")
        end
        print("Pagina " .. paginaActual .. " de " .. totalPaginas)
        print("-------------------------------------")

        local inicio = (paginaActual - 1) * elementosPorPagina + 1
        local fin = math.min(inicio + elementosPorPagina - 1, totalElementos)

        for i = inicio, fin do
            print(i .. ". " .. currentList[i])
        end

        print("\n[N] Siguiente pagina | [P] Pagina anterior | [S] Seleccionar elemento | [B] Buscar | [C] Cancelar")
        print("Ingrese una opcion:")
        local input = read()

        if input:lower() == "n" then
            if paginaActual < totalPaginas then
                paginaActual = paginaActual + 1
            else
                print("Ya estas en la ultima pagina. Presiona ENTER para continuar.")
                read()
            end
        elseif input:lower() == "p" then
            if paginaActual > 1 then
                paginaActual = paginaActual - 1
            else
                print("Ya estas en la primera pagina. Presiona ENTER para continuar.")
                read()
            end
        elseif input:lower() == "s" then
            print("Ingresa el numero del elemento a seleccionar:")
            local seleccion = tonumber(read())
            if seleccion and currentList[seleccion] then
                for index, value in ipairs(fullList) do
                    if value == currentList[seleccion] then
                        return index
                    end
                end
            else
                print("Seleccion invalida. Presiona ENTER para intentar de nuevo.")
                read()
            end
        elseif input:lower() == "b" then
            print("Ingresa el nombre o parte del nombre del cofre a buscar:")
            local termino = read():lower()
            if termino == "" then
                currentList = fullList
            else
                local filtrados = {}
                for _, item in ipairs(fullList) do
                    if string.find(item:lower(), termino) then
                        table.insert(filtrados, item)
                    end
                end
                if #filtrados == 0 then
                    print("No se encontraron cofres que coincidan con el termino. Presiona ENTER para continuar.")
                    read()
                else
                    currentList = filtrados
                    totalElementos = #currentList
                    totalPaginas = math.ceil(totalElementos / elementosPorPagina)
                    paginaActual = 1
                end
            end
        elseif input:lower() == "c" then
            return nil
        else
            print("Opcion no reconocida. Presiona ENTER para intentar de nuevo.")
            read()
        end
    end
end

local function firstTimeSetup(utils)
    term.clear()
    term.setCursorPos(1, 1)
    print("=====================================")
    print("    Asistente de Configuracion Inicial")
    print("=====================================")
    print("Este asistente lo guiara a traves de la configuracion del sistema.")
    print("Presione ENTER para continuar...")
    read()

    -- Detectar perifericos conectados
    local peripherals = peripheral.getNames()
    local chests = {}
    local monitors = {}

    for _, name in ipairs(peripherals) do
        local tipo = peripheral.getType(name)
        if tipo == "minecraft:chest" or tipo == "minecraft:barrel" or tipo == "storagedrawers:basicdrawers" then
            table.insert(chests, name)
        elseif tipo == "monitor" then
            table.insert(monitors, name)
        end
    end

    if #chests == 0 then
        print("No se detectaron cofres conectados. Conecte al menos un cofre y reinicie el programa.")
        return false
    end

    -- Seleccionar el cofre central
    local centralChestName = nil
    while not centralChestName do
        local titulo = "=====================================\n      Seleccion del Cofre Central\n=====================================\nSeleccione el cofre central (donde depositara los items para almacenar):\n"
        local seleccion = paginado(chests, 10, titulo)
        if seleccion then
            centralChestName = chests[seleccion]
        else
            print("Seleccion cancelada. Presione ENTER para intentarlo de nuevo.")
            read()
        end
    end

    -- Seleccionar el monitor
    local monitorName = nil
    if #monitors > 0 then
        local monitorSelected = false
        while not monitorSelected do
            local titulo = "=====================================\n        Seleccion del Monitor\n=====================================\nMonitores detectados:\n"
            local seleccion = paginado(monitors, 10, titulo)
            if seleccion then
                monitorName = monitors[seleccion]
                monitorSelected = true
            else
                print("Desea omitir la configuracion del monitor? (s/n)")
                local input = read()
                if input:lower() == "s" then
                    monitorSelected = true
                end
            end
        end
    else
        print("No se detectaron monitores conectados. Continuando sin configurar el monitor.")
        print("Presione ENTER para continuar.")
        read()
    end

    -- Configurar categorias
    local categories = {}
    local categoriesData = {}

    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("=====================================")
        print("        Configuracion de Categoria")
        print("=====================================")
        print("Desea agregar una nueva categoria? (s/n)")
        local addCategory = read()
        if addCategory:lower() ~= "s" then
            break
        end

        print("Ingrese el nombre de la categoria:")
        local categoryName = read()
        while categoryName == "" do
            print("El nombre de la categoria no puede estar vacio. Presione ENTER para intentarlo de nuevo.")
            read()
            print("Ingrese el nombre de la categoria:")
            categoryName = read()
        end

        local categoryChests = {}
        while true do
            local titulo = "=====================================\n   Asignacion de Cofres a Categoria\n=====================================\nCofres disponibles para asignar a la categoria '" .. categoryName .. "':\n"
            local disponibles = {}
            for _, chestName in ipairs(chests) do
                if not categories[categoryName] or not utils:contains(categories[categoryName], chestName) then
                    table.insert(disponibles, chestName)
                end
            end

            if #disponibles == 0 then
                print("No hay cofres disponibles para asignar.")
                print("Presiona ENTER para continuar.")
                read()
                break
            end

            local seleccion = paginado(disponibles, 10, titulo)
            if seleccion then
                local chestName = disponibles[seleccion]
                table.insert(categoryChests, chestName)
                print("Cofre '" .. chestName .. "' asignado a la categoria. Presiona ENTER para continuar.")
                read()
            else
                if #categoryChests == 0 then
                    print("Debe asignar al menos un cofre a la categoria. Presiona ENTER para continuar.")
                    read()
                else
                    break
                end
            end
        end

        local items = {}
        print("Ingrese los items para la categoria '" .. categoryName .. "' separados por comas:")
        local itemsInput = read()
        for item in string.gmatch(itemsInput, '([^,]+)') do
            table.insert(items, item:match("^%s*(.-)%s*$"))
        end

        categories[categoryName] = categoryChests
        table.insert(categoriesData, {name = categoryName, items = items})
    end

    -- Configurar categoria de items aleatorios
    local randomChests = {}
    while true do
        local titulo = "=====================================\n     Configuracion de 'randomItems'\n=====================================\nCofres disponibles para 'randomItems':\n"
        local disponibles = {}
        for _, chestName in ipairs(chests) do
            if not utils:contains(randomChests, chestName) then
                table.insert(disponibles, chestName)
            end
        end

        if #disponibles == 0 then
            print("No hay cofres disponibles para asignar a 'randomItems'.")
            print("Presiona ENTER para continuar.")
            read()
            break
        end

        local seleccion = paginado(disponibles, 10, titulo)
        if seleccion then
            local chestName = disponibles[seleccion]
            table.insert(randomChests, chestName)
            print("Cofre '" .. chestName .. "' asignado a 'randomItems'. Presiona ENTER para continuar.")
            read()
        else
            if #randomChests == 0 then
                print("Debe asignar al menos un cofre a 'randomItems'. Presiona ENTER para continuar.")
                read()
            else
                break
            end
        end
    end

    -- Configuracion final
    local config = {
        centralChest = centralChestName,
        monitor = monitorName,
        categories = categories
    }
    config.categories["randomItems"] = randomChests

    -- Guardar configuracion y categorias
    utils:saveData("config.txt", config)
    utils:saveData("categories.txt", categoriesData)

    print("\nConfiguracion completada exitosamente. Presione ENTER para continuar.")
    read()
    return true
end

return {
    firstTimeSetup = firstTimeSetup
}
