local function getFileSize(path)
    local file = fs.open(path, "rb")
    if not file then
        return 0
    end
    local size = 0
    while true do
        local data = file.read(1024)
        if not data then break end
        size = size + #data
    end
    file.close()
    return size
end

local function getDirectorySize(path)
    local totalSize = 0
    local function traverse(dir)
        for _, item in ipairs(fs.list(dir)) do
            local currentPath = fs.combine(dir, item)
            if fs.isDir(currentPath) then
                traverse(currentPath)
            else
                totalSize = totalSize + getFileSize(currentPath)
            end
        end
    end
    traverse(path)
    return totalSize
end

local function getFreeSpace(path)
    return fs.getFreeSpace(path) or 0  -- Retorna 0 si no se puede obtener información
end

local rootPath = "/"  -- Puedes cambiar esto si deseas verificar otra carpeta
local usedSpace = getDirectorySize(rootPath)
local freeSpace = getFreeSpace(rootPath)
print("Espacio total usado: " .. usedSpace .. " bytes")
print("Espacio total disponible: " .. freeSpace .. " bytes")
