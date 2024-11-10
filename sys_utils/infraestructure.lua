-- Combined Infrastructure Scanner and Report Generator
-- This script scans all connected peripherals, identifies chests and other storage devices,
-- saves their details into 'infrastructure.log', and generates a user-friendly report
-- saved as 'infrastructure_report.txt'.

-- Function to check if a peripheral has an inventory
local function hasInventory(peripheralName)
    local methods = peripheral.getMethods(peripheralName)
    if not methods then return false end
    for _, method in ipairs(methods) do
        if method == "list" then
            return true
        end
    end
    return false
end

-- Function to get inventory details
local function getInventoryDetails(peripheralName)
    local inventory = peripheral.wrap(peripheralName)
    if not inventory then return nil end
    local items = inventory.list()
    local itemDetails = {}
    for slot, item in pairs(items) do
        table.insert(itemDetails, {
            slot = slot,
            name = item.name,
            count = item.count,
            nbt = item.nbt,
        })
    end
    return itemDetails
end

-- Function to scan peripherals and collect data
local function scanInfrastructure()
    local peripherals = peripheral.getNames()
    local logData = {}

    for _, name in ipairs(peripherals) do
        local peripheralType = peripheral.getType(name)
        local peripheralInfo = {
            name = name,
            type = peripheralType,
            methods = peripheral.getMethods(name),
        }

        if hasInventory(name) then
            peripheralInfo.inventory = getInventoryDetails(name)
        end

        table.insert(logData, peripheralInfo)
    end

    return logData
end

-- Function to save data to infrastructure.log
local function saveLogData(logData)
    -- Serialize log data
    local serializedData = textutils.serialize(logData)

    -- Save to log file
    local logFile = fs.open("infrastructure.log", "w")
    logFile.write(serializedData)
    logFile.close()
end

-- Function to generate the report
local function generateReport(data)
    local reportLines = {}

    table.insert(reportLines, "Infrastructure Report")
    table.insert(reportLines, string.rep("=", 20))
    table.insert(reportLines, "")

    for _, peripheralInfo in ipairs(data) do
        local line = string.format("Peripheral Name: %s", peripheralInfo.name)
        table.insert(reportLines, line)
        line = string.format("Type: %s", peripheralInfo.type)
        table.insert(reportLines, line)

        if peripheralInfo.inventory and #peripheralInfo.inventory > 0 then
            table.insert(reportLines, "Inventory Contents:")
            for _, item in ipairs(peripheralInfo.inventory) do
                local itemLine = string.format(
                    "  - Slot %d: %s x%d",
                    item.slot,
                    item.name,
                    item.count
                )
                table.insert(reportLines, itemLine)
            end
        else
            table.insert(reportLines, "Inventory is empty.")
        end

        table.insert(reportLines, "") -- Empty line between peripherals
    end

    return reportLines
end

-- Function to save the report to a file
local function saveReport(reportLines)
    local reportFile = fs.open("infrastructure_report.txt", "w")
    for _, line in ipairs(reportLines) do
        reportFile.write(line .. "\n")
    end
    reportFile.close()
    print("Report generated and saved to 'infrastructure_report.txt'.")
end

-- Main execution
local function main()
    -- Scan the infrastructure
    local data = scanInfrastructure()

    -- Save detailed data to infrastructure.log
    saveLogData(data)
    print("Infrastructure scan complete. Details saved to 'infrastructure.log'.")

    -- Generate and save the report
    local reportLines = generateReport(data)
    saveReport(reportLines)
end

-- Run the script
main()
