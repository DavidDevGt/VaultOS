local Utils = require("utils")
local utils = Utils:new()

local function clearCompressedData()
    local file = fs.open(utils.compressedDataFile, "w")
    file.close()
end

-- limpiar data
clearCompressedData()

local Storage = require("storage")
local storage = Storage:new(utils)

local Dashboard = require("dashboard")
local dashboard = Dashboard:new(utils)

local FTS = require("fts")

-- Cargar config
local config = utils:loadData("config.txt")

local TUI = require("tui")
local tui = TUI:new(storage, config)  -- Pasar config aquí

local function initializationTask()
    _G.loadingMessage = "Verificando configuracion..."
    sleep(1)

    if not fs.exists("config.txt") then
        _G.loadingMessage = "Iniciando configuracion inicial..."
        sleep(1)
        local success = FTS.firstTimeSetup(utils)
        if not success then
            _G.loadingMessage = "Error en configuracion inicial."
            sleep(2)
            _G.initializationComplete = true
            return
        end
    end

    _G.loadingMessage = "Cargando configuracion..."
    sleep(1)

    _G.loadingMessage = "Detectando cofres conectados..."
    local chests = utils:getConnectedChests()
    local totalChests = #chests
    local processedChests = 0

    for _, chest in ipairs(chests) do
        processedChests = processedChests + 1
        _G.loadingMessage = "Actualizando cofres: " .. processedChests .. "/" .. totalChests
        local chestName = peripheral.getName(chest)
        storage:updateChestData(chestName, "", 0)
        sleep(0.2) -- Simula un pequeño retraso para hacer más visible el progreso
    end

    _G.loadingMessage = "Inicializacion completada. Cargando interfaz..."
    sleep(2)
    _G.initializationComplete = true
end

local function main()
    _G.initializationComplete = false
    _G.loadingMessage = ""

    parallel.waitForAll(
        function() utils:showLoadingScreen() end,
        initializationTask
    )

    parallel.waitForAny(
        function()
            if config and config.monitor then
                dashboard:updateDashboard()
            end
        end,
        function()
            tui:handleInput()
        end
    )
end

main()
