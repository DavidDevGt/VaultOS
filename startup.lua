local Utils = require("utils")
local utils = Utils:new()

local function clearCompressedData()
    local file = fs.open(utils.compressedDataFile, "w")
    file.close()
end

clearCompressedData()

local Storage = require("storage")
local storage = Storage:new(utils)

local Dashboard = require("dashboard")
local dashboard = Dashboard:new(utils)

local TUI = require("tui")
local tui = TUI:new(storage)

local FTS = require("fts")

local function initializationTask()
    _G.loadingMessage = "Verificando configuracion..."
    if not fs.exists("config.txt") then
        _G.loadingMessage = "Iniciando configuracion por primera vez..."
        local success = FTS.firstTimeSetup(utils)
        if not success then
            _G.loadingMessage = "Error en configuracion inicial."
            sleep(2)
            _G.initializationComplete = true
            return
        end
    end

    _G.loadingMessage = "Cargando configuracion..."
    local config = utils:loadData("config.txt")

    _G.loadingMessage = "Detectando cofres conectados..."
    local chests = utils:getConnectedChests()
    local totalChests = #chests
    local processedChests = 0

    for _, chest in ipairs(chests) do
        processedChests = processedChests + 1
        _G.loadingMessage = "Actualizando cofres: " .. processedChests .. "/" .. totalChests
        local chestName = peripheral.getName(chest)
        storage:updateChestData(chestName, "", 0)
    end

    _G.loadingMessage = "Inicializacion completada."
    sleep(1)
    _G.initializationComplete = true

    _G.config = config
end

local function main()
    _G.initializationComplete = false
    _G.loadingMessage = ""

    parallel.waitForAll(
        function() utils:showLoadingScreen() end,
        initializationTask
    )

    local config = _G.config

    parallel.waitForAny(
        function()
            if config.monitor then
                dashboard:updateDashboard()
            end
        end,
        function()
            tui:handleInput()
        end
    )
end

main()